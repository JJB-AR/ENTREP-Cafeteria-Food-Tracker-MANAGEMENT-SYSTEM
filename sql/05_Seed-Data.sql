-- ============================================================================
-- Description: Seeds categories, demo products, and sample sales if the tables are empty.
-- Author: Jonas Balate
-- Date: 10/4/2026
-- Run this file after the preceding numbered scripts.
-- ============================================================================

USE CafeteriaFoodTracker;
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
