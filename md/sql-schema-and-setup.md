# SQL schema and setup

## Database and script

The database setup and application objects are defined in [`../sql/CafeteriaFoodTracker.sql`](../sql/CafeteriaFoodTracker.sql). The script targets Microsoft SQL Server. It creates or selects the `CafeteriaFoodTracker` database, ensures core tables and indexes exist, adds/updates views and stored procedures, migrates existing account-owned data to the seeded `demo` account when ownership is missing, cleans a known description-encoding artifact, and seeds sample categories/products/sales when the corresponding tables are empty. The complete script header lists its description, author (`Jonas Balate`), and date (`10/4/2026`).

### Topic scripts

The SQL folder also contains the setup split into ordered scripts. Each file has a description, author, and date header. Run these in numeric order when applying the split set; alternatively, run only `CafeteriaFoodTracker.sql` for the complete all-in-one setup. Do not run the complete script and split set back-to-back unless you specifically intend to reapply the idempotent setup steps.

1. [`../sql/01_Database-Schema-Migration.sql`](../sql/01_Database-Schema-Migration.sql) — create/select database, tables, account ownership migration, and description cleanup.
2. [`../sql/02_Indexes.sql`](../sql/02_Indexes.sql) — indexes for account-scoped catalog, sales, and inventory queries.
3. [`../sql/03_Views.sql`](../sql/03_Views.sql) — product, transaction, low-stock, and analytics views.
4. [`../sql/04_Stored-Procedures.sql`](../sql/04_Stored-Procedures.sql) — product, sales, inventory, and snapshot procedures.
5. [`../sql/05_Seed-Data.sql`](../sql/05_Seed-Data.sql) — default categories, demo-owned products, and sample sales.
6. [`../sql/06_Admin-Role-Migration.sql`](../sql/06_Admin-Role-Migration.sql) — for an existing database, adds `IsAdmin` and ensures the demo `admin` account is active and promoted. This script can be rerun safely.

The script header mentions `./sql/CafeteriaFoodTracker.mdf`, but the script's `CREATE DATABASE CafeteriaFoodTracker` statement does not specify file paths; SQL Server therefore uses its configured default data/log locations when it creates the database. The checked-in `.mdf` and `.ldf` files are separate repository files and are not attached by that statement.

## Tables and relationships

The schema includes an `IsAdmin` bit column used by the Overview account-management panel. `sql/01_Database-Schema-Migration.sql` (and the all-in-one script) adds and backfills this column. For an existing database that already has the base schema, run [`../sql/06_Admin-Role-Migration.sql`](../sql/06_Admin-Role-Migration.sql) to add the column and provision the seeded admin account before using the role-aware dashboard.

| Table | Purpose and key fields |
| --- | --- |
| `AppUsers` | Login/account records: `UserID` primary key, unique `Username`, `DisplayName`, versioned `PasswordHash`, `IsAdmin` role flag, active flag, and creation timestamp. |
| `Categories` | Shared product categories with a unique name and active flag. No `UserID` is defined, so categories are shared across accounts. |
| `Products` | Account-owned catalog and inventory: `UserID`, `CategoryID`, product/description, selling and cost prices, stock/reorder quantity, image URL, and active/timestamps. References `Categories`. |
| `SalesTransactions` | Account-owned receipt/header: `UserID`, timestamp, session, total and discount, computed persisted `NetAmount`, payment method, cashier, notes. |
| `SalesTransactionItems` | Receipt lines: transaction and product references, captured selling price and cost at time of sale, quantity, computed line total and profit. Deleting a transaction cascades to its items; product references are foreign keys. |
| `StockAdjustments` | Account-owned inventory audit entries: `UserID`, `ProductID`, signed quantity change, adjustment type, reason, actor, and timestamp. |
| `DailySalesSnapshots` | Account/date analytics summary: `UserID`, date, transaction/unit/revenue/cost totals, computed gross profit, optional top product, and generation time. A unique index enforces one snapshot per account/date. |

The ownership foreign keys connect `Products`, `SalesTransactions`, `StockAdjustments`, and `DailySalesSnapshots` to `AppUsers`. `SalesTransactionItems` has no `UserID`; ownership is obtained through its transaction and product. Application queries must keep the transaction and referenced product in the same account scope.

### Important numeric rules

The schema checks non-negative product selling/cost prices, stock and reorder levels, transaction totals/discounts, and sale prices/costs. Sale quantity must be greater than zero. `NetAmount` is computed as total less discount; item `LineTotal` and `LineProfit` are computed from captured unit amounts and quantities.

## Views

The script defines these database views:

- `vw_ProductPerformance`: product-level sales performance metrics, grouped by account and product.
- `vw_ProductSalesSummary`: UI-oriented product data with total units, revenue, profit, and number of orders.
- `vw_BestSellingProducts`: ranked products by units and revenue per account, limited to ranks up to 20.
- `vw_DailySalesTrends`: daily transaction count, units, revenue, profit, and average order value per account.
- `vw_DailyRevenue`: compatibility projection over `vw_DailySalesTrends`.
- `vw_TransactionDetail`: transaction headers joined to their item/product/category detail.
- `vw_LowStockAlert`: active products whose stock is at or below their reorder level.

The views expose `UserID` for account filtering. They do not enforce application authorization on their own; callers should continue to filter results by the authenticated account's ID.

## Stored procedures

- `usp_UpsertProduct`: inserts a product for `@UserID` or updates an existing product only when its `ProductID` and `UserID` match.
- `usp_DeleteProduct`: soft-deactivates a product only for the specified account. The Products page calls this procedure for deactivation.
- `usp_RecordSale`: parses JSON line items, accepts only active products owned by the supplied `@UserID`, stores a transaction and its item prices/costs, and deducts stock inside a transaction. It returns the transaction ID via `@NewTransactionID`. The page validates available quantity first; the procedure itself uses a floor-at-zero stock update rather than throwing for inadequate stock.
- `usp_AdjustStock`: applies an account-scoped stock change and writes an audit row inside a transaction. If the change would take stock below zero, the product quantity is set to zero; the log records the requested signed change. It is defined in the SQL script but is not currently called by the main page code-behind files.
- `usp_RefreshDailySnapshot`: calculates and merges totals for one account and date into `DailySalesSnapshots`.

Stored procedure definitions being present in the script does not guarantee every UI action calls them. For example, current Dashboard and Analytics code contain direct aggregate SELECT statements.

### Callers and key parameters

- `Products.aspx.cs` calls `usp_UpsertProduct` with `@UserID`, `@ProductID`, `@CategoryID`, `@ProductName`, `@Description`, `@UnitPrice`, `@CostPrice`, `@StockQty`, `@ReorderLevel`, `@ImageURL`, and `@IsActive`. `@ProductID` is null for inserts; for edits the procedure requires both product and account IDs to match.
- `Products.aspx.cs` calls `usp_DeleteProduct` with `@UserID` and `@ProductID`, and the procedure marks the account-owned product inactive.
- `Sales.aspx.cs` calls `usp_RecordSale` with `@UserID`, `@SaleSession`, `@DiscountAmount`, `@PaymentMethod`, `@RecordedBy`, `@Notes`, JSON `@ItemsJSON` (product IDs and quantities), and output `@NewTransactionID`. Product price/cost are read in SQL, then the header, item rows, and stock deduction are written in the procedure transaction.
- `Login.aspx.cs` does not call a stored procedure for sign-in. It executes a parameterized SELECT on `AppUsers` by `@Username` and `IsActive = 1`; after verifying the hash, it issues an auth cookie. Account registration is a parameterized `AppUsers` INSERT.

For the full Web Forms file sequence, named methods, and read/write paths, see [Data layer and application flows](data-layer-and-flows.md).

## Seed and migration behavior

- The script inserts the `demo` account if its username is not already present. The password hash is stored in the script as a versioned PBKDF2-format value. Do not infer a live account's password from the documentation; use the application sign-up flow or an approved reset process.
- The seeded `admin` demo account is inserted when missing; when present, the script resets its display name, password hash to the documented demo password (`admin123`), and active status. Rerunning either setup path therefore resets this demo account. Do not use this shared demo credential in production.
- `IsAdmin` defaults to `0`; migration/seed logic grants administrator status only to the seeded username `admin`. New signups and admin-created accounts are regular users.
- It adds `UserID` to older versions of the four account-owned tables if absent and backfills null ownership to `demo`, then makes those columns non-null and adds account foreign keys.
- It changes the daily snapshot uniqueness rule to `(UserID, SnapshotDate)` so each account may have one snapshot per date.
- Sample categories are inserted only when `Categories` is empty. Sample products are inserted only when `Products` is empty, and sample transactions/items only when `SalesTransactions` is empty. This is conditional seed data, not a general reconciliation or deduplication process.
- Since existing null-owned rows are assigned to `demo`, applying the migration changes their ownership. Back up the database and inspect the target before running against valuable data.

## Applying the script

1. Back up the target database if it contains data that must be preserved.
2. Open `sql/CafeteriaFoodTracker.sql` in SQL Server Management Studio or another SQL Server query tool connected to the intended SQL Server instance.
3. Execute the script with permissions to create/alter the database objects and tables. Review the output for errors; a partially executed script may leave the schema incomplete.
4. Update the `CafeteriaFoodTrackerDB` connection string in `Web.config` to point to the same SQL Server instance and catalog, and ensure the application process identity can connect.
5. Run the application and test account sign-in, product listing, and a sale using a non-production or disposable account/database first.

The checked-in `Web.config` currently targets `WIN-F2NE725JK61\SQLEXPRESS` and uses Windows Integrated Security. This machine-specific configuration may not match another developer's environment. The project also includes `sql/CafeteriaFoodTracker.mdf` and `sql/CafeteriaFoodTracker_log.ldf`; verify how those files are intended to be used in your local setup rather than assuming the SQL script attaches them.

## Troubleshooting account ownership

`Login.GetCurrentUserId` searches `AppUsers` by the Forms Authentication username and requires `IsActive = 1`. If a page reports that the signed-in account is not active, verify all of the following in the database named in the application's connection string:

- The identity username matches `AppUsers.Username` exactly after the login flow's trim behavior.
- That account exists and `IsActive` is set to `1`.
- The app and the SQL query tool are connected to the same server and catalog.
- The ownership migration and account table are present in the database in use.

Do not remove the active-account check to work around this error; doing so would bypass deactivation semantics.
