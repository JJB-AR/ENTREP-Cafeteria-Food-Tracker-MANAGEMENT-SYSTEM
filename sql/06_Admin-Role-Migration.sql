-- ============================================================================
-- Description: Adds the admin role column and provisions the seeded admin account.
-- Author: Jonas Balate
-- Date: 10/4/2026
-- Run this once against the CafeteriaFoodTracker database before using admin pages.
-- ============================================================================

USE CafeteriaFoodTracker;
GO

IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
BEGIN
	THROW 50010, 'AppUsers table was not found. Run the database schema setup first.', 1;
END
GO

IF COL_LENGTH('dbo.AppUsers', 'IsAdmin') IS NULL
BEGIN
	ALTER TABLE dbo.AppUsers
		ADD IsAdmin BIT NOT NULL CONSTRAINT DF_AppUsers_IsAdmin DEFAULT 0 WITH VALUES;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.AppUsers WHERE LOWER(Username) = N'admin')
BEGIN
	INSERT INTO dbo.AppUsers (Username, DisplayName, PasswordHash, IsAdmin, IsActive)
	VALUES (N'admin', N'Demo Administrator',
			N'100000.Zy2bUCX4nCmynUPCYE4reA==.abtXCMUkD9DxjNLH0NhrebwHXmwkELlhcofdSVzDLjc=', 1, 1);
END
ELSE
BEGIN
	UPDATE dbo.AppUsers
	SET DisplayName = N'Demo Administrator',
		PasswordHash = N'100000.Zy2bUCX4nCmynUPCYE4reA==.abtXCMUkD9DxjNLH0NhrebwHXmwkELlhcofdSVzDLjc=',
		IsAdmin = 1,
		IsActive = 1
	WHERE LOWER(Username) = N'admin';
END
GO

UPDATE dbo.AppUsers
SET IsAdmin = 0
WHERE LOWER(Username) <> N'admin';
GO
