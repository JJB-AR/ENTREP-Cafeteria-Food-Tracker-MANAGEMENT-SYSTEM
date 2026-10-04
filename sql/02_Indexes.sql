-- ============================================================================
-- Description: Creates indexes for account-scoped catalog, sales, and inventory queries.
-- Author: Jonas Balate
-- Date: 10/4/2026
-- Run this file after the preceding numbered scripts.
-- ============================================================================

USE CafeteriaFoodTracker;
GO

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
