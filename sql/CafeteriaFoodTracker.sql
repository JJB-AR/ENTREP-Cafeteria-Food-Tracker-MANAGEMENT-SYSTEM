-- ============================================================================
-- Description: Complete all-in-one setup for the CafeteriaFoodTracker database.
-- Author: Jonas Balate
-- Date: 10/4/2026
-- ENTREP CAFETERIA FOOD TRACKER MANAGEMENT SYSTEM
-- Complete SQL Database Creation & Setup Script
-- Target: Microsoft SQL Server / SQL Server LocalDB
-- Database: CafeteriaFoodTracker
-- Storage Location: ./sql/CafeteriaFoodTracker.mdf
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

IF NOT EXISTS (SELECT 1 FROM AppUsers WHERE Username = N'demo')
BEGIN
    INSERT INTO AppUsers (Username, DisplayName, PasswordHash)
    VALUES (N'demo', N'Demo Cafeteria Admin',
            N'100000.AAECAwQFBgcICQoLDA0ODw==.EYeC2Hq+uBbnQjlLqPJR0AU+NSvmuZ0Jil0NaiEIkw4=');
END
GO

IF NOT EXISTS (SELECT 1 FROM AppUsers WHERE Username COLLATE Latin1_General_100_BIN2 = N'admin')
BEGIN
    INSERT INTO AppUsers (Username, DisplayName, PasswordHash, IsAdmin)
    VALUES (N'admin', N'Demo Administrator',
            N'100000.Zy2bUCX4nCmynUPCYE4reA==.abtXCMUkD9DxjNLH0NhrebwHXmwkELlhcofdSVzDLjc=', 1);
END
ELSE
BEGIN
    UPDATE AppUsers
    SET DisplayName = N'Demo Administrator',
        PasswordHash = N'100000.Zy2bUCX4nCmynUPCYE4reA==.abtXCMUkD9DxjNLH0NhrebwHXmwkELlhcofdSVzDLjc=',
        IsAdmin = 1,
        IsActive = 1
    WHERE LOWER(Username) = N'admin';
END
GO

UPDATE AppUsers SET IsAdmin = 0 WHERE LOWER(Username) <> N'admin';
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
-- 3. INDEXES FOR HIGH-PERFORMANCE QUERYING
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_Category_Active')
    CREATE NONCLUSTERED INDEX IX_Products_Category_Active ON Products(CategoryID, IsActive) INCLUDE (ProductName, UnitPrice, StockQty);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Products_User_Active' AND object_id = OBJECT_ID(N'dbo.Products'))
    CREATE NONCLUSTERED INDEX IX_Products_User_Active ON Products(UserID, IsActive, CategoryID) INCLUDE (ProductName, UnitPrice, StockQty, ReorderLevel);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesTransactions_Date')
    CREATE NONCLUSTERED INDEX IX_SalesTransactions_Date ON SalesTransactions(TransactionDate DESC) INCLUDE (NetAmount, TotalAmount);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesTransactions_User_Date' AND object_id = OBJECT_ID(N'dbo.SalesTransactions'))
    CREATE NONCLUSTERED INDEX IX_SalesTransactions_User_Date ON SalesTransactions(UserID, TransactionDate DESC) INCLUDE (NetAmount, TotalAmount);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_STI_TransactionID')
    CREATE NONCLUSTERED INDEX IX_STI_TransactionID ON SalesTransactionItems(TransactionID) INCLUDE (ProductID, QuantitySold, LineTotal, LineProfit);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_STI_ProductID')
    CREATE NONCLUSTERED INDEX IX_STI_ProductID ON SalesTransactionItems(ProductID) INCLUDE (QuantitySold, LineTotal, LineProfit);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_StockAdjustments_ProductID')
    CREATE NONCLUSTERED INDEX IX_StockAdjustments_ProductID ON StockAdjustments(ProductID, AdjustedAt DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_StockAdjustments_User_Product' AND object_id = OBJECT_ID(N'dbo.StockAdjustments'))
    CREATE NONCLUSTERED INDEX IX_StockAdjustments_User_Product ON StockAdjustments(UserID, ProductID, AdjustedAt DESC);
GO

-- ============================================================================
-- 4. ANALYTICS & REPORTING VIEWS
-- ============================================================================

-- 4.1 Product Performance View: Tracks units sold, revenue, profit, and sales frequency
CREATE OR ALTER VIEW vw_ProductPerformance AS
SELECT 
    p.UserID,
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.UnitPrice,
    p.CostPrice,
    (p.UnitPrice - p.CostPrice) AS UnitMargin,
    p.StockQty AS CurrentStock,
    p.ReorderLevel,
    CASE 
        WHEN p.StockQty = 0 THEN 'Out of Stock'
        WHEN p.StockQty <= p.ReorderLevel THEN 'Low Stock'
        ELSE 'In Stock'
    END AS StockStatus,
    ISNULL(SUM(i.QuantitySold), 0) AS TotalQuantitySold,
    ISNULL(SUM(i.LineTotal), 0.00) AS TotalRevenue,
    ISNULL(SUM(i.LineProfit), 0.00) AS TotalProfit,
    COUNT(DISTINCT i.TransactionID) AS SalesFrequency,
    CASE 
        WHEN COUNT(DISTINCT i.TransactionID) > 0 
        THEN CAST(CAST(SUM(i.QuantitySold) AS DECIMAL(10,2)) / COUNT(DISTINCT i.TransactionID) AS DECIMAL(10,2))
        ELSE 0.00 
    END AS AvgUnitsPerSale,
    p.IsActive
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN SalesTransactionItems i ON p.ProductID = i.ProductID
GROUP BY 
    p.UserID, p.ProductID, p.ProductName, c.CategoryName, p.UnitPrice, 
    p.CostPrice, p.StockQty, p.ReorderLevel, p.IsActive;
GO

-- 4.2 Product Sales Summary View (Compatible with UI bindings)
CREATE OR ALTER VIEW vw_ProductSalesSummary AS
SELECT 
    p.UserID,
    p.ProductID,
    p.CategoryID,
    p.ProductName,
    p.Description,
    c.CategoryName,
    p.UnitPrice,
    p.CostPrice,
    p.StockQty,
    p.ReorderLevel,
    p.IsActive,
    ISNULL(SUM(i.QuantitySold), 0)  AS TotalUnitsSold,
    ISNULL(SUM(i.LineTotal), 0.00) AS TotalRevenue,
    ISNULL(SUM(i.LineProfit), 0.00) AS TotalProfit,
    COUNT(DISTINCT i.TransactionID) AS TimesOrdered
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN SalesTransactionItems i ON p.ProductID = i.ProductID
GROUP BY 
    p.UserID, p.ProductID, p.CategoryID, p.ProductName, p.Description, c.CategoryName, 
    p.UnitPrice, p.CostPrice, p.StockQty, p.ReorderLevel, p.IsActive;
GO

-- 4.3 Best-Selling Products View (Ranked by Units and Revenue)
CREATE OR ALTER VIEW vw_BestSellingProducts AS
WITH RankedProducts AS
(
    SELECT
        p.UserID,
        DENSE_RANK() OVER (PARTITION BY p.UserID ORDER BY ISNULL(SUM(i.QuantitySold), 0) DESC) AS RankByUnits,
        DENSE_RANK() OVER (PARTITION BY p.UserID ORDER BY ISNULL(SUM(i.LineTotal), 0) DESC) AS RankByRevenue,
        p.ProductID,
        p.ProductName,
        c.CategoryName,
        p.UnitPrice,
        ISNULL(SUM(i.QuantitySold), 0) AS UnitsSold,
        ISNULL(SUM(i.LineTotal), 0.00) AS Revenue,
        ISNULL(SUM(i.LineProfit), 0.00) AS Profit,
        COUNT(DISTINCT i.TransactionID) AS OrdersCount
    FROM Products p
    INNER JOIN Categories c ON p.CategoryID = c.CategoryID
    INNER JOIN SalesTransactionItems i ON p.ProductID = i.ProductID
    GROUP BY p.UserID, p.ProductID, p.ProductName, c.CategoryName, p.UnitPrice
)
SELECT UserID, RankByUnits, RankByRevenue, ProductID, ProductName, CategoryName,
       UnitPrice, UnitsSold, Revenue, Profit, OrdersCount
FROM RankedProducts
WHERE RankByUnits <= 20 OR RankByRevenue <= 20;
GO

-- 4.4 Daily Sales Trends View: Total sales, items sold, gross profit per day
CREATE OR ALTER VIEW vw_DailySalesTrends AS
SELECT 
    t.UserID,
    CAST(t.TransactionDate AS DATE) AS SaleDate,
    COUNT(DISTINCT t.TransactionID) AS TotalTransactions,
    SUM(i.QuantitySold)             AS TotalUnitsSold,
    SUM(i.LineTotal)                AS TotalRevenue,
    SUM(i.LineProfit)               AS TotalProfit,
    CAST(SUM(i.LineTotal) / NULLIF(COUNT(DISTINCT t.TransactionID), 0) AS DECIMAL(10,2)) AS AvgOrderValue
FROM SalesTransactions t
INNER JOIN SalesTransactionItems i ON t.TransactionID = i.TransactionID
GROUP BY t.UserID, CAST(t.TransactionDate AS DATE);
GO

-- 4.5 Daily Revenue View (Alias for backwards compatibility)
CREATE OR ALTER VIEW vw_DailyRevenue AS
SELECT 
    UserID,
    SaleDate,
    TotalTransactions,
    TotalUnitsSold,
    TotalRevenue,
    TotalProfit
FROM vw_DailySalesTrends;
GO

-- 4.6 Full Transaction Details View (Itemized Grid)
CREATE OR ALTER VIEW vw_TransactionDetail AS
SELECT 
    t.UserID,
    t.TransactionID,
    '#' + RIGHT('0000' + CAST(t.TransactionID AS VARCHAR(10)), 4) AS FormattedID,
    t.TransactionDate,
    t.SaleSession,
    t.TotalAmount,
    t.DiscountAmount,
    t.NetAmount,
    t.PaymentMethod,
    t.RecordedBy,
    i.ItemID,
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    i.UnitPriceSold,
    i.QuantitySold,
    i.LineTotal,
    i.LineProfit
FROM SalesTransactions t
INNER JOIN SalesTransactionItems i ON t.TransactionID = i.TransactionID
INNER JOIN Products p ON i.ProductID = p.ProductID
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID;
GO

-- 4.7 Low-Stock Alert View: Kitchen alert for restocking
CREATE OR ALTER VIEW vw_LowStockAlert AS
SELECT 
    p.UserID,
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.StockQty,
    p.ReorderLevel,
    (p.ReorderLevel - p.StockQty) AS UnitsNeededToReorder
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.StockQty <= p.ReorderLevel 
  AND p.IsActive = 1;
GO

-- ============================================================================
-- 5. STORED PROCEDURES (CRUD & ATOMIC OPERATIONS)
-- ============================================================================

-- 5.1 Procedure: Upsert Food Product (Create or Edit Product, Price, Stock)
CREATE OR ALTER PROCEDURE usp_UpsertProduct
    @UserID         INT,
    @ProductID      INT            = NULL, -- NULL = Create new product, NOT NULL = Update existing
    @CategoryID     INT,
    @ProductName    NVARCHAR(150),
    @Description    NVARCHAR(500)  = NULL,
    @UnitPrice      DECIMAL(10,2),
    @CostPrice      DECIMAL(10,2)  = 0.00,
    @StockQty       INT            = 0,
    @ReorderLevel   INT            = 5,
    @ImageURL       NVARCHAR(500)  = NULL,
    @IsActive       BIT            = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @ProductID IS NULL OR @ProductID = 0
    BEGIN
        INSERT INTO Products (
            UserID, CategoryID, ProductName, Description, UnitPrice, 
            CostPrice, StockQty, ReorderLevel, ImageURL, IsActive,
            CreatedAt, UpdatedAt
        )
        VALUES (
            @UserID, @CategoryID, @ProductName, @Description, @UnitPrice, 
            @CostPrice, @StockQty, @ReorderLevel, @ImageURL, @IsActive,
            SYSDATETIME(), SYSDATETIME()
        );
        
        SELECT SCOPE_IDENTITY() AS NewProductID;
    END
    ELSE
    BEGIN
        UPDATE Products
        SET CategoryID   = @CategoryID,
            ProductName  = @ProductName,
            Description  = @Description,
            UnitPrice    = @UnitPrice,
            CostPrice    = @CostPrice,
            StockQty     = @StockQty,
            ReorderLevel = @ReorderLevel,
            ImageURL     = @ImageURL,
            IsActive     = @IsActive,
            UpdatedAt    = SYSDATETIME()
        WHERE ProductID  = @ProductID
          AND UserID = @UserID;

        IF @@ROWCOUNT = 0
        BEGIN
            ;THROW 50002, 'Product was not found for this account.', 1;
        END
        
        SELECT @ProductID AS NewProductID;
    END
END
GO

-- 5.2 Procedure: Soft Delete Product
CREATE OR ALTER PROCEDURE usp_DeleteProduct
    @UserID INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Products
    SET IsActive = 0,
        UpdatedAt = SYSDATETIME()
    WHERE ProductID = @ProductID
      AND UserID = @UserID;
END
GO

-- 5.3 Procedure: Record Sales Transaction (Atomic Header + Items + Stock Deduction)
CREATE OR ALTER PROCEDURE usp_RecordSale
    @UserID             INT,
    @SaleSession        NVARCHAR(50)  = 'All Day',
    @DiscountAmount     DECIMAL(12,2) = 0.00,
    @PaymentMethod      NVARCHAR(50)  = 'Cash',
    @RecordedBy         NVARCHAR(100) = 'Student Cashier',
    @Notes              NVARCHAR(500) = NULL,
    @ItemsJSON          NVARCHAR(MAX), -- JSON format: [{"ProductID": 1, "Qty": 2}, {"ProductID": 3, "Qty": 1}]
    @NewTransactionID   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Parse JSON line items and resolve current selling price and cost
        DECLARE @ParsedItems TABLE (
            ProductID   INT NOT NULL,
            Qty         INT NOT NULL,
            UnitPrice   DECIMAL(10,2) NOT NULL,
            CostPrice   DECIMAL(10,2) NOT NULL
        );

        INSERT INTO @ParsedItems (ProductID, Qty, UnitPrice, CostPrice)
        SELECT 
            j.ProductID,
            j.Qty,
            p.UnitPrice,
            p.CostPrice
        FROM OPENJSON(@ItemsJSON)
        WITH (
            ProductID INT '$.ProductID',
            Qty       INT '$.Qty'
        ) j
        INNER JOIN Products p ON p.ProductID = j.ProductID
        WHERE p.IsActive = 1
          AND p.UserID = @UserID;

        IF NOT EXISTS (SELECT 1 FROM @ParsedItems)
        BEGIN
            ;THROW 50001, 'No valid active products were provided in the sales transaction.', 1;
        END

        -- 2. Calculate transaction total amount
        DECLARE @CalculatedTotal DECIMAL(12,2);
        SELECT @CalculatedTotal = SUM(UnitPrice * Qty) FROM @ParsedItems;

        -- 3. Insert transaction header
        INSERT INTO SalesTransactions (
            UserID, TransactionDate, SaleSession, TotalAmount, DiscountAmount, 
            PaymentMethod, RecordedBy, Notes, CreatedAt
        )
        VALUES (
            @UserID, SYSDATETIME(), @SaleSession, @CalculatedTotal, ISNULL(@DiscountAmount, 0.00), 
            ISNULL(@PaymentMethod, 'Cash'), ISNULL(@RecordedBy, 'Student Cashier'), @Notes, SYSDATETIME()
        );

        SET @NewTransactionID = SCOPE_IDENTITY();

        -- 4. Insert transaction line items
        INSERT INTO SalesTransactionItems (
            TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold
        )
        SELECT 
            @NewTransactionID,
            ProductID,
            UnitPrice,
            CostPrice,
            Qty
        FROM @ParsedItems;

        -- 5. Automatically deduct sold quantity from product stock
        UPDATE p
        SET p.StockQty = CASE 
                            WHEN p.StockQty >= item.Qty THEN p.StockQty - item.Qty 
                            ELSE 0 
                         END,
            p.UpdatedAt = SYSDATETIME()
        FROM Products p
        INNER JOIN @ParsedItems item ON p.ProductID = item.ProductID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- 5.4 Procedure: Adjust Stock (Restock or Spoilage with Audit Trail)
CREATE OR ALTER PROCEDURE usp_AdjustStock
    @UserID         INT,
    @ProductID      INT,
    @QuantityChange INT,            -- Positive to add stock, Negative to reduce
    @AdjustmentType NVARCHAR(50),   -- 'Restock', 'Spoilage', 'Correction'
    @Reason         NVARCHAR(500) = NULL,
    @AdjustedBy     NVARCHAR(100) = 'Admin'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Products
        SET StockQty = CASE 
                        WHEN (StockQty + @QuantityChange) >= 0 THEN StockQty + @QuantityChange 
                        ELSE 0 
                       END,
            UpdatedAt = SYSUTCDATETIME()
        WHERE ProductID = @ProductID
          AND UserID = @UserID;

        IF @@ROWCOUNT = 0
        BEGIN
            ;THROW 50003, 'Product was not found for this account.', 1;
        END

        INSERT INTO StockAdjustments (
            UserID, ProductID, QuantityChange, AdjustmentType, Reason, AdjustedBy
        )
        VALUES (
            @UserID, @ProductID, @QuantityChange, @AdjustmentType, @Reason, @AdjustedBy
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- 5.5 Procedure: Refresh Daily Analytics Snapshot
CREATE OR ALTER PROCEDURE usp_RefreshDailySnapshot
    @UserID INT,
    @SnapshotDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @SnapshotDate IS NULL SET @SnapshotDate = CAST(SYSUTCDATETIME() AS DATE);

    DECLARE @Transactions INT, @Units INT, @Revenue DECIMAL(14,2), @Cost DECIMAL(14,2), @TopProd INT;

    SELECT
        @Transactions = COUNT(DISTINCT t.TransactionID),
        @Units        = ISNULL(SUM(i.QuantitySold), 0),
        @Revenue      = ISNULL(SUM(i.LineTotal), 0.00),
        @Cost         = ISNULL(SUM(i.UnitCostSold * i.QuantitySold), 0.00)
    FROM SalesTransactions t
    INNER JOIN SalesTransactionItems i ON t.TransactionID = i.TransactionID
    WHERE t.UserID = @UserID
      AND CAST(t.TransactionDate AS DATE) = @SnapshotDate;

    SELECT TOP 1 @TopProd = i.ProductID
    FROM SalesTransactions t
    INNER JOIN SalesTransactionItems i ON t.TransactionID = i.TransactionID
    WHERE t.UserID = @UserID
      AND CAST(t.TransactionDate AS DATE) = @SnapshotDate
    GROUP BY i.ProductID
    ORDER BY SUM(i.QuantitySold) DESC;

    MERGE DailySalesSnapshots AS target
    USING (SELECT @UserID AS u, @SnapshotDate AS d) AS src ON target.UserID = src.u AND target.SnapshotDate = src.d
    WHEN MATCHED THEN
        UPDATE SET TotalTransactions = ISNULL(@Transactions,0),
                   TotalUnitsSold    = ISNULL(@Units,0),
                   TotalRevenue      = ISNULL(@Revenue,0),
                   TotalCost         = ISNULL(@Cost,0),
                   TopProductID      = @TopProd,
                   GeneratedAt       = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (UserID, SnapshotDate, TotalTransactions, TotalUnitsSold, TotalRevenue, TotalCost, TopProductID)
        VALUES (@UserID, @SnapshotDate, ISNULL(@Transactions,0), ISNULL(@Units,0),
                ISNULL(@Revenue,0), ISNULL(@Cost,0), @TopProd);
END
GO

-- ============================================================================
-- 6. SEED DATA GENERATION
-- ============================================================================

-- 6.1 Seed Food Categories
IF NOT EXISTS (SELECT 1 FROM Categories)
BEGIN
    INSERT INTO Categories (CategoryName, Description) VALUES
        (N'Meals',    N'Heavy rice bowls, pasta, and viands for breakfast/lunch'),
        (N'Snacks',   N'Quick finger bites, sandwiches, and street foods'),
        (N'Drinks',   N'Cold beverages, fresh shakes, and hot coffee'),
        (N'Desserts', N'Sweet delicacies, pastries, and treats');
END
GO

-- 6.2 Seed Food Products with Realistic Entrepreneurship Pricing & Margins
IF NOT EXISTS (SELECT 1 FROM Products)
BEGIN
    DECLARE @DemoUserID INT = (SELECT UserID FROM AppUsers WHERE Username = N'demo');
    DECLARE @CatMeals INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Meals');
    DECLARE @CatSnacks INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Snacks');
    DECLARE @CatDrinks INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Drinks');
    DECLARE @CatDesserts INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Desserts');

    INSERT INTO Products (UserID, CategoryID, ProductName, Description, UnitPrice, CostPrice, StockQty, ReorderLevel) VALUES
        -- Meals
        (@DemoUserID, @CatMeals, N'Chicken Rice Bowl',    N'Crispy chicken fillet with garlic rice and gravy', 65.00, 35.00, 28, 8),
        (@DemoUserID, @CatMeals, N'Pork Sinigang Rice',   N'Tamarind pork soup bowl served with rice',          70.00, 38.00, 18, 5),
        (@DemoUserID, @CatMeals, N'Beef Caldereta',       N'Rich beef stew with potatoes and bell peppers',     80.00, 44.00, 15, 5),
        (@DemoUserID, @CatMeals, N'Vegetable Pancit',     N'Stir-fried canton noodles with fresh vegetables',   55.00, 26.00, 22, 6),
        (@DemoUserID, @CatMeals, N'Fried Tilapia Meal',   N'Crispy tilapia fish with calamansi & steamed rice', 60.00, 30.00, 14, 5),
        
        -- Snacks
        (@DemoUserID, @CatSnacks, N'Tuna Sandwich',       N'Flaked tuna with mayo & lettuce on toasted bread',  45.00, 20.00, 25, 8),
        (@DemoUserID, @CatSnacks, N'Lumpiang Shanghai',   N'Deep-fried spring rolls (4 pcs) with sweet sauce',  30.00, 12.00, 45, 10),
        (@DemoUserID, @CatSnacks, N'Cheese Sticks',       N'Crunchy mozzarella & cheddar finger sticks (5 pcs)', 25.00, 10.00, 40, 10),
        (@DemoUserID, @CatSnacks, N'Banana Cue',          N'Deep-fried saba bananas with caramelized brown sugar', 20.00, 8.00, 35, 10),
        
        -- Drinks
        (@DemoUserID, @CatDrinks, N'Iced Milo',           N'Creamy chocolate malt drink with crushed ice',      30.00, 12.00, 50, 12),
        (@DemoUserID, @CatDrinks, N'Iced Tea Cooler',     N'House-blend citrus iced tea (16oz)',                25.00,  9.00, 60, 15),
        (@DemoUserID, @CatDrinks, N'Bottled Mineral Water', N'Chilled purified bottled water 500ml',           15.00,  7.00, 75, 15),
        (@DemoUserID, @CatDrinks, N'Hot Brewed Coffee',   N'Freshly brewed Benguet Arabica coffee',             30.00, 11.00, 30, 8),
        
        -- Desserts
        (@DemoUserID, @CatDesserts, N'Buko Pandan',       N'Chilled coconut strips, pandan jelly, and cream',   35.00, 15.00, 20, 5),
        (@DemoUserID, @CatDesserts, N'Caramel Leche Flan', N'Silky steamed custard with caramel syrup',          40.00, 18.00, 16, 5);
END
GO

-- 6.3 Seed Realistic Recent Sales Transactions (Populates Analytics & Trend Reports)
IF NOT EXISTS (SELECT 1 FROM SalesTransactions)
BEGIN
    DECLARE @DemoUserID INT = (SELECT UserID FROM AppUsers WHERE Username = N'demo');
    DECLARE @Now DATETIME2 = SYSDATETIME();
    
    -- Helper variable IDs
    DECLARE @pChicken INT = (SELECT ProductID FROM Products WHERE ProductName = N'Chicken Rice Bowl');
    DECLARE @pTuna INT = (SELECT ProductID FROM Products WHERE ProductName = N'Tuna Sandwich');
    DECLARE @pMilo INT = (SELECT ProductID FROM Products WHERE ProductName = N'Iced Milo');
    DECLARE @pBanana INT = (SELECT ProductID FROM Products WHERE ProductName = N'Banana Cue');
    DECLARE @pPancit INT = (SELECT ProductID FROM Products WHERE ProductName = N'Vegetable Pancit');
    DECLARE @pWater INT = (SELECT ProductID FROM Products WHERE ProductName = N'Bottled Mineral Water');

    -- Transaction 1: 4 days ago
    INSERT INTO SalesTransactions (UserID, TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (@DemoUserID, DATEADD(DAY, -4, @Now), 'Morning', 155.00, 0.00, 'Cash', 'Jonas B.', 'Student breakfast rush');
    DECLARE @T1 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T1, @pChicken, 65.00, 35.00, 2),
        (@T1, @pWater, 15.00, 7.00, 1),
        (@T1, @pBanana, 20.00, 8.00, 1);

    -- Transaction 2: 3 days ago
    INSERT INTO SalesTransactions (UserID, TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (@DemoUserID, DATEADD(DAY, -3, @Now), 'Afternoon', 190.00, 10.00, 'Cash', 'Mia R.', 'Snack break bundle discount');
    DECLARE @T2 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T2, @pTuna, 45.00, 20.00, 2),
        (@T2, @pMilo, 30.00, 12.00, 2),
        (@T2, @pBanana, 20.00, 8.00, 2);

    -- Transaction 3: 2 days ago
    INSERT INTO SalesTransactions (UserID, TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (@DemoUserID, DATEADD(DAY, -2, @Now), 'Morning', 220.00, 0.00, 'Cash', 'Jonas B.', 'Faculty order');
    DECLARE @T3 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T3, @pChicken, 65.00, 35.00, 2),
        (@T3, @pMilo, 30.00, 12.00, 3);

    -- Transaction 4: Yesterday
    INSERT INTO SalesTransactions (UserID, TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (@DemoUserID, DATEADD(DAY, -1, @Now), 'Afternoon', 170.00, 0.00, 'Cash', 'Jonas B.', 'Lunch order');
    DECLARE @T4 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T4, @pPancit, 55.00, 26.00, 2),
        (@T4, @pMilo, 30.00, 12.00, 2);

    -- Transaction 5: Today Morning
    INSERT INTO SalesTransactions (UserID, TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (@DemoUserID, DATEADD(MINUTE, -180, @Now), 'Morning', 160.00, 0.00, 'Cash', 'Jonas B.', 'Breakfast combo');
    DECLARE @T5 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T5, @pChicken, 65.00, 35.00, 2),
        (@T5, @pMilo, 30.00, 12.00, 1);

    -- Transaction 6: Today Lunch
    INSERT INTO SalesTransactions (UserID, TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (@DemoUserID, DATEADD(MINUTE, -75, @Now), 'Afternoon', 180.00, 0.00, 'Cash', 'Mia R.', 'Lunch meal');
    DECLARE @T6 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T6, @pChicken, 65.00, 35.00, 2),
        (@T6, @pTuna, 45.00, 20.00, 1),
        (@T6, @pBanana, 20.00, 8.00, 1);

    -- Transaction 7: Today Snack
    INSERT INTO SalesTransactions (UserID, TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (@DemoUserID, DATEADD(MINUTE, -20, @Now), 'Afternoon', 120.00, 0.00, 'Cash', 'Jonas B.', 'Quick snack');
    DECLARE @T7 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T7, @pTuna, 45.00, 20.00, 2),
        (@T7, @pMilo, 30.00, 12.00, 1);
END
GO

PRINT '============================================================================';
PRINT 'CafeteriaFoodTracker Database successfully created & configured in ./sql/';
PRINT '============================================================================';
GO
