-- ============================================================================
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

-- 2.2 Products Table
-- Manages food products, selling prices, production cost, and inventory quantities
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Products')
BEGIN
    CREATE TABLE Products (
        ProductID       INT IDENTITY(1,1) PRIMARY KEY,
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
        SnapshotDate        DATE NOT NULL UNIQUE,
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

-- ============================================================================
-- 3. INDEXES FOR HIGH-PERFORMANCE QUERYING
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_Category_Active')
    CREATE NONCLUSTERED INDEX IX_Products_Category_Active ON Products(CategoryID, IsActive) INCLUDE (ProductName, UnitPrice, StockQty);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesTransactions_Date')
    CREATE NONCLUSTERED INDEX IX_SalesTransactions_Date ON SalesTransactions(TransactionDate DESC) INCLUDE (NetAmount, TotalAmount);
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

-- ============================================================================
-- 4. ANALYTICS & REPORTING VIEWS
-- ============================================================================

-- 4.1 Product Performance View: Tracks units sold, revenue, profit, and sales frequency
CREATE OR ALTER VIEW vw_ProductPerformance AS
SELECT 
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
    p.ProductID, p.ProductName, c.CategoryName, p.UnitPrice, 
    p.CostPrice, p.StockQty, p.ReorderLevel, p.IsActive;
GO

-- 4.2 Product Sales Summary View (Compatible with UI bindings)
CREATE OR ALTER VIEW vw_ProductSalesSummary AS
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.UnitPrice,
    p.CostPrice,
    p.StockQty,
    p.ReorderLevel,
    ISNULL(SUM(i.QuantitySold), 0)  AS TotalUnitsSold,
    ISNULL(SUM(i.LineTotal), 0.00) AS TotalRevenue,
    ISNULL(SUM(i.LineProfit), 0.00) AS TotalProfit,
    COUNT(DISTINCT i.TransactionID) AS TimesOrdered
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN SalesTransactionItems i ON p.ProductID = i.ProductID
WHERE p.IsActive = 1
GROUP BY 
    p.ProductID, p.ProductName, c.CategoryName, 
    p.UnitPrice, p.CostPrice, p.StockQty, p.ReorderLevel;
GO

-- 4.3 Best-Selling Products View (Ranked by Units and Revenue)
CREATE OR ALTER VIEW vw_BestSellingProducts AS
SELECT TOP 20
    DENSE_RANK() OVER (ORDER BY ISNULL(SUM(i.QuantitySold), 0) DESC) AS RankByUnits,
    DENSE_RANK() OVER (ORDER BY ISNULL(SUM(i.LineTotal), 0) DESC) AS RankByRevenue,
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
GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.UnitPrice
ORDER BY UnitsSold DESC;
GO

-- 4.4 Daily Sales Trends View: Total sales, items sold, gross profit per day
CREATE OR ALTER VIEW vw_DailySalesTrends AS
SELECT 
    CAST(t.TransactionDate AS DATE) AS SaleDate,
    COUNT(DISTINCT t.TransactionID) AS TotalTransactions,
    SUM(i.QuantitySold)             AS TotalUnitsSold,
    SUM(i.LineTotal)                AS TotalRevenue,
    SUM(i.LineProfit)               AS TotalProfit,
    CAST(SUM(i.LineTotal) / NULLIF(COUNT(DISTINCT t.TransactionID), 0) AS DECIMAL(10,2)) AS AvgOrderValue
FROM SalesTransactions t
INNER JOIN SalesTransactionItems i ON t.TransactionID = i.TransactionID
GROUP BY CAST(t.TransactionDate AS DATE);
GO

-- 4.5 Daily Revenue View (Alias for backwards compatibility)
CREATE OR ALTER VIEW vw_DailyRevenue AS
SELECT 
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
            CategoryID, ProductName, Description, UnitPrice, 
            CostPrice, StockQty, ReorderLevel, ImageURL, IsActive
        )
        VALUES (
            @CategoryID, @ProductName, @Description, @UnitPrice, 
            @CostPrice, @StockQty, @ReorderLevel, @ImageURL, @IsActive
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
            UpdatedAt    = SYSUTCDATETIME()
        WHERE ProductID  = @ProductID;
        
        SELECT @ProductID AS NewProductID;
    END
END
GO

-- 5.2 Procedure: Soft Delete Product
CREATE OR ALTER PROCEDURE usp_DeleteProduct
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Products
    SET IsActive = 0,
        UpdatedAt = SYSUTCDATETIME()
    WHERE ProductID = @ProductID;
END
GO

-- 5.3 Procedure: Record Sales Transaction (Atomic Header + Items + Stock Deduction)
CREATE OR ALTER PROCEDURE usp_RecordSale
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
        WHERE p.IsActive = 1;

        IF NOT EXISTS (SELECT 1 FROM @ParsedItems)
        BEGIN
            THROW 50001, 'No valid active products were provided in the sales transaction.', 1;
        END

        -- 2. Calculate transaction total amount
        DECLARE @CalculatedTotal DECIMAL(12,2);
        SELECT @CalculatedTotal = SUM(UnitPrice * Qty) FROM @ParsedItems;

        -- 3. Insert transaction header
        INSERT INTO SalesTransactions (
            SaleSession, TotalAmount, DiscountAmount, 
            PaymentMethod, RecordedBy, Notes
        )
        VALUES (
            @SaleSession, @CalculatedTotal, ISNULL(@DiscountAmount, 0.00), 
            ISNULL(@PaymentMethod, 'Cash'), ISNULL(@RecordedBy, 'Student Cashier'), @Notes
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
            p.UpdatedAt = SYSUTCDATETIME()
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
        WHERE ProductID = @ProductID;

        INSERT INTO StockAdjustments (
            ProductID, QuantityChange, AdjustmentType, Reason, AdjustedBy
        )
        VALUES (
            @ProductID, @QuantityChange, @AdjustmentType, @Reason, @AdjustedBy
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
    WHERE CAST(t.TransactionDate AS DATE) = @SnapshotDate;

    SELECT TOP 1 @TopProd = i.ProductID
    FROM SalesTransactions t
    INNER JOIN SalesTransactionItems i ON t.TransactionID = i.TransactionID
    WHERE CAST(t.TransactionDate AS DATE) = @SnapshotDate
    GROUP BY i.ProductID
    ORDER BY SUM(i.QuantitySold) DESC;

    MERGE DailySalesSnapshots AS target
    USING (SELECT @SnapshotDate AS d) AS src ON target.SnapshotDate = src.d
    WHEN MATCHED THEN
        UPDATE SET TotalTransactions = ISNULL(@Transactions,0),
                   TotalUnitsSold    = ISNULL(@Units,0),
                   TotalRevenue      = ISNULL(@Revenue,0),
                   TotalCost         = ISNULL(@Cost,0),
                   TopProductID      = @TopProd,
                   GeneratedAt       = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (SnapshotDate, TotalTransactions, TotalUnitsSold, TotalRevenue, TotalCost, TopProductID)
        VALUES (@SnapshotDate, ISNULL(@Transactions,0), ISNULL(@Units,0),
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
    DECLARE @CatMeals INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Meals');
    DECLARE @CatSnacks INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Snacks');
    DECLARE @CatDrinks INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Drinks');
    DECLARE @CatDesserts INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Desserts');

    INSERT INTO Products (CategoryID, ProductName, Description, UnitPrice, CostPrice, StockQty, ReorderLevel) VALUES
        -- Meals
        (@CatMeals, N'Chicken Rice Bowl',    N'Crispy chicken fillet with garlic rice and gravy', 65.00, 35.00, 28, 8),
        (@CatMeals, N'Pork Sinigang Rice',   N'Tamarind pork soup bowl served with rice',          70.00, 38.00, 18, 5),
        (@CatMeals, N'Beef Caldereta',       N'Rich beef stew with potatoes and bell peppers',     80.00, 44.00, 15, 5),
        (@CatMeals, N'Vegetable Pancit',     N'Stir-fried canton noodles with fresh vegetables',   55.00, 26.00, 22, 6),
        (@CatMeals, N'Fried Tilapia Meal',   N'Crispy tilapia fish with calamansi & steamed rice', 60.00, 30.00, 14, 5),
        
        -- Snacks
        (@CatSnacks, N'Tuna Sandwich',       N'Flaked tuna with mayo & lettuce on toasted bread',  45.00, 20.00, 25, 8),
        (@CatSnacks, N'Lumpiang Shanghai',   N'Deep-fried spring rolls (4 pcs) with sweet sauce',  30.00, 12.00, 45, 10),
        (@CatSnacks, N'Cheese Sticks',       N'Crunchy mozzarella & cheddar finger sticks (5 pcs)', 25.00, 10.00, 40, 10),
        (@CatSnacks, N'Banana Cue',          N'Deep-fried saba bananas with caramelized brown sugar', 20.00, 8.00, 35, 10),
        
        -- Drinks
        (@CatDrinks, N'Iced Milo',           N'Creamy chocolate malt drink with crushed ice',      30.00, 12.00, 50, 12),
        (@CatDrinks, N'Iced Tea Cooler',     N'House-blend citrus iced tea (16oz)',                25.00,  9.00, 60, 15),
        (@CatDrinks, N'Bottled Mineral Water', N'Chilled purified bottled water 500ml',           15.00,  7.00, 75, 15),
        (@CatDrinks, N'Hot Brewed Coffee',   N'Freshly brewed Benguet Arabica coffee',             30.00, 11.00, 30, 8),
        
        -- Desserts
        (@CatDesserts, N'Buko Pandan',       N'Chilled coconut strips, pandan jelly, and cream',   35.00, 15.00, 20, 5),
        (@CatDesserts, N'Caramel Leche Flan', N'Silky steamed custard with caramel syrup',          40.00, 18.00, 16, 5);
END
GO

-- 6.3 Seed Realistic Recent Sales Transactions (Populates Analytics & Trend Reports)
IF NOT EXISTS (SELECT 1 FROM SalesTransactions)
BEGIN
    DECLARE @Now DATETIME2 = SYSUTCDATETIME();
    
    -- Helper variable IDs
    DECLARE @pChicken INT = (SELECT ProductID FROM Products WHERE ProductName = N'Chicken Rice Bowl');
    DECLARE @pTuna INT = (SELECT ProductID FROM Products WHERE ProductName = N'Tuna Sandwich');
    DECLARE @pMilo INT = (SELECT ProductID FROM Products WHERE ProductName = N'Iced Milo');
    DECLARE @pBanana INT = (SELECT ProductID FROM Products WHERE ProductName = N'Banana Cue');
    DECLARE @pPancit INT = (SELECT ProductID FROM Products WHERE ProductName = N'Vegetable Pancit');
    DECLARE @pWater INT = (SELECT ProductID FROM Products WHERE ProductName = N'Bottled Mineral Water');

    -- Transaction 1: 4 days ago
    INSERT INTO SalesTransactions (TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (DATEADD(DAY, -4, @Now), 'Morning', 155.00, 0.00, 'Cash', 'Jonas B.', 'Student breakfast rush');
    DECLARE @T1 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T1, @pChicken, 65.00, 35.00, 2),
        (@T1, @pWater, 15.00, 7.00, 1),
        (@T1, @pBanana, 20.00, 8.00, 1);

    -- Transaction 2: 3 days ago
    INSERT INTO SalesTransactions (TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (DATEADD(DAY, -3, @Now), 'Afternoon', 190.00, 10.00, 'Cash', 'Mia R.', 'Snack break bundle discount');
    DECLARE @T2 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T2, @pTuna, 45.00, 20.00, 2),
        (@T2, @pMilo, 30.00, 12.00, 2),
        (@T2, @pBanana, 20.00, 8.00, 2);

    -- Transaction 3: 2 days ago
    INSERT INTO SalesTransactions (TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (DATEADD(DAY, -2, @Now), 'Morning', 220.00, 0.00, 'Cash', 'Jonas B.', 'Faculty order');
    DECLARE @T3 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T3, @pChicken, 65.00, 35.00, 2),
        (@T3, @pMilo, 30.00, 12.00, 3);

    -- Transaction 4: Yesterday
    INSERT INTO SalesTransactions (TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (DATEADD(DAY, -1, @Now), 'Afternoon', 170.00, 0.00, 'Cash', 'Jonas B.', 'Lunch order');
    DECLARE @T4 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T4, @pPancit, 55.00, 26.00, 2),
        (@T4, @pMilo, 30.00, 12.00, 2);

    -- Transaction 5: Today Morning
    INSERT INTO SalesTransactions (TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (DATEADD(MINUTE, -180, @Now), 'Morning', 160.00, 0.00, 'Cash', 'Jonas B.', 'Breakfast combo');
    DECLARE @T5 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T5, @pChicken, 65.00, 35.00, 2),
        (@T5, @pMilo, 30.00, 12.00, 1);

    -- Transaction 6: Today Lunch
    INSERT INTO SalesTransactions (TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (DATEADD(MINUTE, -75, @Now), 'Afternoon', 180.00, 0.00, 'Cash', 'Mia R.', 'Lunch meal');
    DECLARE @T6 INT = SCOPE_IDENTITY();
    INSERT INTO SalesTransactionItems (TransactionID, ProductID, UnitPriceSold, UnitCostSold, QuantitySold) VALUES
        (@T6, @pChicken, 65.00, 35.00, 2),
        (@T6, @pTuna, 45.00, 20.00, 1),
        (@T6, @pBanana, 20.00, 8.00, 1);

    -- Transaction 7: Today Snack
    INSERT INTO SalesTransactions (TransactionDate, SaleSession, TotalAmount, DiscountAmount, PaymentMethod, RecordedBy, Notes)
    VALUES (DATEADD(MINUTE, -20, @Now), 'Afternoon', 120.00, 0.00, 'Cash', 'Jonas B.', 'Quick snack');
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
