-- ============================================================================
-- Description: Creates product, transaction, low-stock, and analytics reporting views.
-- Author: Jonas Balate
-- Date: 10/4/2026
-- Run this file after the preceding numbered scripts.
-- ============================================================================

USE CafeteriaFoodTracker;
GO

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
