-- ============================================================================
-- Description: Creates the database and tables, migrates account ownership, and cleans product descriptions.
-- Author: Jonas Balate
-- Date: 10/4/2026
-- Run this file after the preceding numbered scripts.
-- ============================================================================


SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
GO

USE master;
GO

-- 1. DATABASE CREATION (Creates database if it does not exist)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'CafeteriaFoodTracker')
BEGIN
    CREATE DATABASE CafeteriaFoodTracker;
END
GO

USE CafeteriaFoodTracker;
GO

-- ============================================================================
-- 2. TABLES DEFINITIONS
-- ============================================================================

-- 2.1 Categories Table
-- Classifies food products into logical groups (e.g., Meals, Snacks, Drinks, Desserts)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories')
BEGIN
    CREATE TABLE Categories (
        CategoryID      INT IDENTITY(1,1) PRIMARY KEY,
        CategoryName    NVARCHAR(100) NOT NULL UNIQUE,
        Description     NVARCHAR(255) NULL,
        IsActive        BIT NOT NULL DEFAULT 1,
        CreatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

-- 2.2 User Accounts Table
-- Passwords are stored as versioned PBKDF2 hashes created by the application.
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AppUsers')
BEGIN
    CREATE TABLE AppUsers (
        UserID          INT IDENTITY(1,1) PRIMARY KEY,
        Username        NVARCHAR(50) NOT NULL,
        DisplayName     NVARCHAR(100) NOT NULL,
        PasswordHash    NVARCHAR(256) NOT NULL,
        IsAdmin         BIT NOT NULL CONSTRAINT DF_AppUsers_IsAdmin DEFAULT 0,
        IsActive        BIT NOT NULL CONSTRAINT DF_AppUsers_IsActive DEFAULT 1,
        CreatedAt       DATETIME2 NOT NULL CONSTRAINT DF_AppUsers_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_AppUsers_Username UNIQUE (Username)
    );
END
GO

IF COL_LENGTH('dbo.AppUsers', 'IsAdmin') IS NULL
BEGIN
    ALTER TABLE dbo.AppUsers ADD IsAdmin BIT NOT NULL CONSTRAINT DF_AppUsers_IsAdmin DEFAULT 0 WITH VALUES;
END
GO

UPDATE dbo.AppUsers
SET IsAdmin = CASE WHEN LOWER(Username) = N'admin' THEN 1 ELSE 0 END;
GO

IF NOT EXISTS (SELECT 1 FROM AppUsers WHERE Username = N'demo')
BEGIN
    INSERT INTO AppUsers (Username, DisplayName, PasswordHash)
    VALUES (N'demo', N'Demo Cafeteria Admin',
            N'100000.AAECAwQFBgcICQoLDA0ODw==.EYeC2Hq+uBbnQjlLqPJR0AU+NSvmuZ0Jil0NaiEIkw4=');
END
GO

-- 2.2 Products Table
-- Manages food products, selling prices, production cost, and inventory quantities
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Products')
BEGIN
    CREATE TABLE Products (
        ProductID       INT IDENTITY(1,1) PRIMARY KEY,
        UserID          INT NULL,
        CategoryID      INT NOT NULL,
        ProductName     NVARCHAR(150) NOT NULL,
        Description     NVARCHAR(500) NULL,
        UnitPrice       DECIMAL(10,2) NOT NULL CONSTRAINT CHK_Products_UnitPrice CHECK (UnitPrice >= 0),
        CostPrice       DECIMAL(10,2) NOT NULL DEFAULT 0.00 CONSTRAINT CHK_Products_CostPrice CHECK (CostPrice >= 0),
        StockQty        INT NOT NULL DEFAULT 0 CONSTRAINT CHK_Products_StockQty CHECK (StockQty >= 0),
        ReorderLevel    INT NOT NULL DEFAULT 5 CONSTRAINT CHK_Products_ReorderLevel CHECK (ReorderLevel >= 0),
        ImageURL        NVARCHAR(500) NULL,
        IsActive        BIT NOT NULL DEFAULT 1,
        CreatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        
        CONSTRAINT FK_Products_Category FOREIGN KEY (CategoryID) 
            REFERENCES Categories(CategoryID) ON UPDATE CASCADE
    );
END
GO

-- 2.3 SalesTransactions Table (Receipt Header)
-- Stores each sales transaction, date/time, shift/session, discount, and net revenue
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SalesTransactions')
BEGIN
    CREATE TABLE SalesTransactions (
        TransactionID   INT IDENTITY(1,1) PRIMARY KEY,
        UserID          INT NULL,
        TransactionDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        SaleSession     NVARCHAR(50) NULL DEFAULT 'All Day', -- Morning, Afternoon, Evening, All Day
        TotalAmount     DECIMAL(12,2) NOT NULL DEFAULT 0.00 CONSTRAINT CHK_ST_TotalAmount CHECK (TotalAmount >= 0),
        DiscountAmount  DECIMAL(12,2) NOT NULL DEFAULT 0.00 CONSTRAINT CHK_ST_DiscountAmount CHECK (DiscountAmount >= 0),
        NetAmount       AS (TotalAmount - DiscountAmount) PERSISTED,
        PaymentMethod   NVARCHAR(50) NOT NULL DEFAULT 'Cash',
        RecordedBy      NVARCHAR(100) NULL DEFAULT 'Student Cashier',
        Notes           NVARCHAR(500) NULL,
        CreatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

-- 2.4 SalesTransactionItems Table (Line Items)
-- Stores individual food items sold within a transaction, freezing price & cost at moment of sale
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SalesTransactionItems')
BEGIN
    CREATE TABLE SalesTransactionItems (
        ItemID          INT IDENTITY(1,1) PRIMARY KEY,
        TransactionID   INT NOT NULL,
        ProductID       INT NOT NULL,
        UnitPriceSold   DECIMAL(10,2) NOT NULL CONSTRAINT CHK_STI_UnitPriceSold CHECK (UnitPriceSold >= 0),
        UnitCostSold    DECIMAL(10,2) NOT NULL DEFAULT 0.00 CONSTRAINT CHK_STI_UnitCostSold CHECK (UnitCostSold >= 0),
        QuantitySold    INT NOT NULL CONSTRAINT CHK_STI_QuantitySold CHECK (QuantitySold > 0),
        LineTotal       AS (UnitPriceSold * QuantitySold) PERSISTED,
        LineProfit      AS ((UnitPriceSold - UnitCostSold) * QuantitySold) PERSISTED,
        
        CONSTRAINT FK_STI_Transaction FOREIGN KEY (TransactionID) 
            REFERENCES SalesTransactions(TransactionID) ON DELETE CASCADE,
        CONSTRAINT FK_STI_Product FOREIGN KEY (ProductID) 
            REFERENCES Products(ProductID)
    );
END
GO

-- 2.5 StockAdjustments Table (Inventory Audit Log)
-- Tracks all stock alterations (restock batches, kitchen spoilage, batch recount corrections)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAdjustments')
BEGIN
    CREATE TABLE StockAdjustments (
        AdjustmentID    INT IDENTITY(1,1) PRIMARY KEY,
        UserID          INT NULL,
        ProductID       INT NOT NULL,
        QuantityChange  INT NOT NULL, -- Positive for Restock, Negative for Spoilage/Damage
        AdjustmentType  NVARCHAR(50) NOT NULL, -- 'Restock', 'Spoilage', 'Inventory Recount', 'Damaged'
        Reason          NVARCHAR(500) NULL,
        AdjustedBy      NVARCHAR(100) NULL DEFAULT 'Admin',
        AdjustedAt      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        
        CONSTRAINT FK_SA_Product FOREIGN KEY (ProductID) 
            REFERENCES Products(ProductID)
    );
END
GO

-- 2.6 DailySalesSnapshots Table (Analytics Cache)
-- Caches daily financial totals for quick dashboard and trend reporting
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DailySalesSnapshots')
BEGIN
    CREATE TABLE DailySalesSnapshots (
        SnapshotID          INT IDENTITY(1,1) PRIMARY KEY,
        UserID              INT NULL,
        SnapshotDate        DATE NOT NULL,
        TotalTransactions   INT NOT NULL DEFAULT 0,
        TotalUnitsSold      INT NOT NULL DEFAULT 0,
        TotalRevenue        DECIMAL(14,2) NOT NULL DEFAULT 0.00,
        TotalCost           DECIMAL(14,2) NOT NULL DEFAULT 0.00,
        GrossProfit         AS (TotalRevenue - TotalCost) PERSISTED,
        TopProductID        INT NULL,
        GeneratedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        
        CONSTRAINT FK_DSS_TopProduct FOREIGN KEY (TopProductID) 
            REFERENCES Products(ProductID)
    );
END
GO

DECLARE @DemoUserID INT = (SELECT UserID FROM AppUsers WHERE Username = N'demo');

IF COL_LENGTH('dbo.Products', 'UserID') IS NULL
    ALTER TABLE dbo.Products ADD UserID INT NULL;
IF COL_LENGTH('dbo.SalesTransactions', 'UserID') IS NULL
    ALTER TABLE dbo.SalesTransactions ADD UserID INT NULL;
IF COL_LENGTH('dbo.StockAdjustments', 'UserID') IS NULL
    ALTER TABLE dbo.StockAdjustments ADD UserID INT NULL;
IF COL_LENGTH('dbo.DailySalesSnapshots', 'UserID') IS NULL
    ALTER TABLE dbo.DailySalesSnapshots ADD UserID INT NULL;

UPDATE dbo.Products SET UserID = @DemoUserID WHERE UserID IS NULL;
UPDATE dbo.SalesTransactions SET UserID = @DemoUserID WHERE UserID IS NULL;
UPDATE dbo.StockAdjustments SET UserID = @DemoUserID WHERE UserID IS NULL;
UPDATE dbo.DailySalesSnapshots SET UserID = @DemoUserID WHERE UserID IS NULL;

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Products') AND name = N'UserID' AND is_nullable = 1)
    ALTER TABLE dbo.Products ALTER COLUMN UserID INT NOT NULL;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.SalesTransactions') AND name = N'UserID' AND is_nullable = 1)
    ALTER TABLE dbo.SalesTransactions ALTER COLUMN UserID INT NOT NULL;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.StockAdjustments') AND name = N'UserID' AND is_nullable = 1)
    ALTER TABLE dbo.StockAdjustments ALTER COLUMN UserID INT NOT NULL;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.DailySalesSnapshots') AND name = N'UserID' AND is_nullable = 1)
    ALTER TABLE dbo.DailySalesSnapshots ALTER COLUMN UserID INT NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Products_AppUsers')
    ALTER TABLE dbo.Products ADD CONSTRAINT FK_Products_AppUsers FOREIGN KEY (UserID) REFERENCES dbo.AppUsers(UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SalesTransactions_AppUsers')
    ALTER TABLE dbo.SalesTransactions ADD CONSTRAINT FK_SalesTransactions_AppUsers FOREIGN KEY (UserID) REFERENCES dbo.AppUsers(UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockAdjustments_AppUsers')
    ALTER TABLE dbo.StockAdjustments ADD CONSTRAINT FK_StockAdjustments_AppUsers FOREIGN KEY (UserID) REFERENCES dbo.AppUsers(UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_DailySalesSnapshots_AppUsers')
    ALTER TABLE dbo.DailySalesSnapshots ADD CONSTRAINT FK_DailySalesSnapshots_AppUsers FOREIGN KEY (UserID) REFERENCES dbo.AppUsers(UserID);

DECLARE @SnapshotDateConstraint SYSNAME;
SELECT TOP 1 @SnapshotDateConstraint = kc.name
FROM sys.key_constraints kc
INNER JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.DailySalesSnapshots')
  AND kc.type = N'UQ'
GROUP BY kc.name
HAVING COUNT(*) = 1 AND MAX(c.name) = N'SnapshotDate';

IF @SnapshotDateConstraint IS NOT NULL
BEGIN
    DECLARE @DropSnapshotConstraintSql NVARCHAR(300);
    SET @DropSnapshotConstraintSql = N'ALTER TABLE dbo.DailySalesSnapshots DROP CONSTRAINT ' + QUOTENAME(@SnapshotDateConstraint);
    EXEC sys.sp_executesql @DropSnapshotConstraintSql;
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_DailySalesSnapshots_User_Date' AND object_id = OBJECT_ID(N'dbo.DailySalesSnapshots'))
    CREATE UNIQUE INDEX UX_DailySalesSnapshots_User_Date ON dbo.DailySalesSnapshots(UserID, SnapshotDate);

UPDATE dbo.Products
SET Description = LTRIM(RTRIM(REPLACE(REPLACE(Description, NCHAR(194) + NCHAR(183), N''), NCHAR(194), N'')))
WHERE Description IS NOT NULL AND CHARINDEX(NCHAR(194), Description) > 0;
GO

-- ============================================================================
