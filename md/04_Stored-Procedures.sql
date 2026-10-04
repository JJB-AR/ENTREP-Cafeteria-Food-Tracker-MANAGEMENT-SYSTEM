-- ============================================================================
-- Description: Creates product, sales, inventory adjustment, and daily snapshot procedures.
-- Author: Jonas Balate
-- Date: 10/4/2026
-- Run this file after the preceding numbered scripts.
-- ============================================================================

USE CafeteriaFoodTracker;
GO

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
