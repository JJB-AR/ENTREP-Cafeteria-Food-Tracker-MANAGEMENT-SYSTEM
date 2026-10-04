# Data layer and application flows

This guide explains how a request moves through the application and how the Web Forms code interacts with SQL Server. For a schema reference, see [SQL schema and setup](sql-schema-and-setup.md); for the overall application map, see [Application architecture](architecture.md).

## Data-layer shape

The application uses a straightforward, page-oriented data layer rather than a separate repository/service project:

```text
.aspx markup (form controls, repeaters, validators)
  -> page code-behind event handlers
  -> connection string from Web.config
  -> ADO.NET SqlConnection + SqlCommand
  -> SQL query, view, or stored procedure
  -> SQL Server tables
  -> reader/DataTable result bound to server controls
```

The application targets .NET Framework 4.7.2 and uses `System.Data.SqlClient`. Page code creates and disposes connections/commands with `using` blocks. It uses `SqlDataReader` for streamed/single-row results and `SqlDataAdapter` to fill `DataTable` instances for repeater binding. User-supplied values are generally passed as typed SQL parameters. Some pages compose optional SQL filter clauses, but filter values are parameterized.

There is no separate API, Entity Framework model, or general-purpose repository abstraction in the current project. SQL and page concerns therefore meet in code-behind: event handlers validate Web Forms inputs, create SQL calls, and update page controls with the results.

## Connection and identity resolution

`Web.config` defines the `CafeteriaFoodTrackerDB` connection string. The code connects to this configured server/catalog; it does not select a database per account. Authentication is Forms Authentication, whose ticket identity name is the account username.

For account-scoped data, `Login.GetCurrentUserId(connection, Context.User.Identity.Name)` looks up `AppUsers.UserID` for the username and requires `IsActive = 1`. This integer is the data partition key passed into SQL as `@UserID`. Product and transaction queries must scope by this value; shared `Categories` are intentionally not account-owned.

The `Global.asax.cs` `Application_PostAuthenticateRequest` handler also checks that an authenticated username still has an active account row. If the account is missing or inactive, it signs out the Forms Authentication cookie and redirects to Login. The shared master page controls navigation and its logout button clears the auth ticket/session.

### Login to an account-scoped page

1. The user enters credentials in `Login.aspx`; the form posts to `Login.aspx.cs` (`LoginButton_Click`).
2. `Login.aspx.cs` calls `Authenticate(username, password)`. That method opens `CafeteriaFoodTrackerDB` from `Web.config` and executes a parameterized query against `AppUsers` using `@Username` (trimmed) and `IsActive = 1`; it reads `DisplayName` and `PasswordHash`, then verifies the PBKDF2 password hash in C#.
3. On success, `LoginButton_Click` issues a Forms Authentication cookie whose identity name is the trimmed username, then redirects to `Dashboard.aspx`.
4. The redirected request runs `Global.asax.cs`'s `Application_PostAuthenticateRequest`. It checks the cookie username against `AppUsers.Username` with `IsActive = 1`. A missing/inactive account is signed out and redirected to Login.
5. `Site.Master.cs` handles the shared shell/navigation. The destination page's code-behind opens the SQL connection and calls `Login.GetCurrentUserId(connection, Context.User.Identity.Name)`. That lookup has one parameter, `@Username`, and returns `AppUsers.UserID` for the active account.
6. The page passes the resulting integer as `@UserID` to account-scoped queries or procedures. The cookie contains the username, not the numeric ID; the ID is resolved from SQL for page operations.

Account registration follows `Login.aspx` -> `Login.aspx.cs` (`SignUpButton_Click`) -> `Register`. `Register` hashes the password and inserts `@Username`, `@DisplayName`, and `@PasswordHash` into `AppUsers`; duplicate usernames return a registration error. After insert, the username is put in the auth cookie and the browser is redirected to Dashboard. Registration does not create product or sales rows.

## Read path: product catalog

On the first request to `Products.aspx`, `Page_Load` binds shared active categories, account-scoped summary metrics, and the product list. `BindSummaryMetrics` resolves the `UserID`, then counts that account's products and active categories and reads `vw_LowStockAlert`. `BindProducts` reads `vw_ProductSalesSummary` for the same user and optionally adds category, free-text, and stock-state predicates. SQL results are bound to `ProductRepeater` and the empty/count labels.

The product list view combines product/category fields with aggregate sales-item data. The page still applies `WHERE UserID = @UserID`; use of a view does not itself establish which user is allowed to see a row.

## Write path: product create/edit/deactivate

1. The product form validates the name, category, selling price, cost, stock, and reorder level in `Products.aspx.cs`.
2. The handler resolves the current `UserID` and calls `usp_UpsertProduct` with typed parameters. `@ProductID` is null for a new product and identifies an existing product for edits.
3. The procedure inserts with the provided account ID, or updates only when both `ProductID` and `UserID` match. The code then refreshes summary metrics and the product list.
4. Deactivation uses `usp_DeleteProduct`, which sets `IsActive = 0` only for the matching product/account. It is a soft delete, preserving transaction references and history.

The `usp_UpsertProduct` call in `Products.aspx.cs` supplies these SQL parameters: `@UserID`, `@ProductID`, `@CategoryID`, `@ProductName`, `@Description`, `@UnitPrice`, `@CostPrice`, `@StockQty`, `@ReorderLevel`, `@ImageURL`, and `@IsActive`. SQL inserts for a null `@ProductID`; otherwise it updates only the row matching both `@ProductID` and `@UserID`. The procedure is defined in [`../sql/04_Stored-Procedures.sql`](../sql/04_Stored-Procedures.sql).

## Write path: record a sale

The current Sales page records one selected product per submission:

1. `Sales.aspx.cs` validates the selected product and positive quantity and resolves the current account's `UserID`.
2. It queries `Products` by `ProductID`, `UserID`, and `IsActive = 1` to display the product and check stock before submission.
3. The page constructs a small JSON array containing the product ID and quantity, then calls `usp_RecordSale` with sale metadata and an output transaction ID.
4. `usp_RecordSale` parses the JSON, keeps active products owned by the supplied user, obtains current price and cost, inserts a transaction header and captured-price line item(s), and deducts stock inside a SQL transaction. On an SQL error, its catch block rolls back and rethrows.
5. The page refreshes the available-product list, today's totals, and recent transaction list.

For `usp_RecordSale`, `Sales.aspx.cs` passes `@UserID`, `@SaleSession`, `@DiscountAmount`, `@PaymentMethod`, `@RecordedBy`, `@Notes`, `@ItemsJSON`, and output parameter `@NewTransactionID`. `@ItemsJSON` contains product/quantity pairs, for example `[{"ProductID":12,"Qty":2}]`. SQL looks up the current product price/cost itself; those amounts are not trusted from the browser. The procedure inserts `SalesTransactions` and `SalesTransactionItems`, then updates `Products.StockQty` in the same transaction. It is defined in [`../sql/04_Stored-Procedures.sql`](../sql/04_Stored-Procedures.sql).

The pre-check gives the user a useful insufficient-stock message. Stock can change between that check and the procedure call, so it should not be treated as a concurrency guarantee. The checked-in procedure applies a floor-at-zero deduction rather than rejecting a quantity greater than stock; if strict no-overselling behavior is required under concurrent requests, enforce the stock condition within the SQL transaction and fail atomically.

## Read paths: Dashboard and Analytics

`Dashboard.aspx.cs` opens one connection, resolves the account ID once, and uses parameterized SQL to populate sales totals, units, daily revenue chart, product performance, recent transactions, and low-stock alert. Product performance and low stock use SQL views; several metrics are direct aggregate queries.

`Analytics.aspx.cs` validates dates in `yyyy-MM-dd` form and rejects invalid or reversed ranges. It turns the selected end date into an exclusive next-day bound, so the user-selected dates are inclusive while SQL uses `TransactionDate >= @StartDate AND TransactionDate < @EndDateExclusive`. Its trend, summary, and top-product queries are filtered by both account and range. The separate activity count is for the current day, regardless of the selected date range.

These pages calculate from `SalesTransactions` and `SalesTransactionItems` directly; `DailySalesSnapshots` and `usp_RefreshDailySnapshot` are available in the SQL script but are not used by these two page code-behind files for their shown metrics.
### Overview account-management path

`Dashboard.aspx.cs` resolves the current active `UserID` and calls `Login.IsAdministrator`. If the database row has `IsAdmin = 1`, it shows the user-management panel instead of the sales dashboard. Otherwise it leaves the existing account-scoped sales overview in place. Hiding the panel is only a UI choice: create, reset, and activate/deactivate handlers each re-check the admin flag against SQL.

- Create user: `Dashboard.aspx` form -> `Dashboard.aspx.cs` / `CreateAccountButton_Click` -> parameterized `AppUsers` INSERT for `@Username`, `@DisplayName`, and PBKDF2 `@PasswordHash`, with `IsAdmin = 0` and `IsActive = 1`.
- List accounts: `Dashboard.aspx.cs` / `BindUsers` -> `SELECT` from `AppUsers`, showing username, display name, role, and active state. Password hashes are not selected.
- Edit display name: GridView `SaveDisplayName` -> `UsersGrid_RowCommand` -> parameterized `AppUsers.DisplayName` update restricted by `UserID` and `IsAdmin = 0`.
- Reset password: GridView `SelectReset` -> `UsersGrid_RowCommand` selects an eligible regular user's username; `ResetPasswordButton_Click` rechecks admin authority and updates `PasswordHash` using the existing PBKDF2 routine. Passwords shorter than 8 characters are rejected.
- Toggle access: GridView `ToggleActive` -> `UsersGrid_RowCommand` updates `IsActive` only if the target is not an admin and is not the current admin. The SQL `WHERE` clause enforces those restrictions as well as the server-side check.

The `IsAdmin` column is added by `sql/01_Database-Schema-Migration.sql` (or the corresponding section of the all-in-one script). That migration marks the username `admin` as administrator and other existing accounts as regular users. Run the updated schema script before launching the modified application. Admin account management is demo functionality; protect or remove the seeded admin credentials before deploying outside a controlled demo environment.

## Page-to-database map

| User action/page | Web Forms path | Database call and data affected |
| --- | --- | --- |
| Sign in | `Login.aspx` -> `Login.aspx.cs` / `LoginButton_Click` -> `Authenticate` | Parameterized `AppUsers` SELECT (`@Username`); password hash is verified in C#. Success issues a username auth ticket and redirects to Dashboard. |
| Register | `Login.aspx` -> `Login.aspx.cs` / `SignUpButton_Click` -> `Register` | `AppUsers` INSERT with `@Username`, `@DisplayName`, `@PasswordHash`; password hash is generated in C#. |
| Dashboard request | `Dashboard.aspx` -> `Dashboard.aspx.cs` / `LoadDashboard` | Resolves `@Username` to `UserID`, then runs account-filtered aggregate SELECTs; reads `vw_ProductSalesSummary` and `vw_LowStockAlert`. |
| List/filter products | `Products.aspx` -> `Products.aspx.cs` / `BindProducts`, `BindSummaryMetrics` | Reads `Categories`, `vw_ProductSalesSummary`, `vw_LowStockAlert`, and account-filtered `Products`; `@UserID` scopes private product data. |
| Save product | Product form -> `Products.aspx.cs` / `BtnSaveProduct_Click` | Calls `usp_UpsertProduct` with identity, form values, and active state; writes `Products`. |
| Deactivate product | Product row command -> `Products.aspx.cs` / `ProductRepeater_ItemCommand` | Calls `usp_DeleteProduct` with `@UserID` and `@ProductID`; updates `Products.IsActive`. |
| Record sale | Sales form -> `Sales.aspx.cs` / `BtnSubmitSale_Click` | Selects and checks product; calls `usp_RecordSale` with account, sale metadata, JSON product/quantity, and output transaction ID; writes header/items and deducts product stock. |
| View sales | `Sales.aspx` -> `Sales.aspx.cs` / `BindSales`, `BindSalesSummary` | Reads `SalesTransactions`, `SalesTransactionItems`, and `Products` with account/date/filter predicates. |
| Analytics range | `Analytics.aspx` -> `Analytics.aspx.cs` / `ApplyDateRangeButton_Click` -> `BindAnalytics` | Direct SELECTs over `SalesTransactions`, `SalesTransactionItems`, and `Products`, parameterized by `@UserID`, `@StartDate`, and exclusive `@EndDate`. |

The UI's stored-procedure definitions live in `sql/04_Stored-Procedures.sql`; the tables and ownership migration are in `sql/01_Database-Schema-Migration.sql`; reusable indexes and views are in `sql/02_Indexes.sql` and `sql/03_Views.sql`. `sql/05_Seed-Data.sql` supplies optional initial sample data. The original `sql/CafeteriaFoodTracker.sql` combines the setup in one script.

## What the SQL layer guarantees (and what it does not)

- Table constraints enforce several basic numeric and relationship rules, such as nonnegative stock/prices and positive line-item quantity.
- Foreign keys preserve transaction-to-item and item-to-product references. Sales line items record price/cost at sale time, so later product price changes do not rewrite historical line amounts.
- Account ownership is represented by `UserID` on products, transaction headers, stock adjustments, and snapshots; the associated foreign keys require an existing account.
- Views provide reusable projections/aggregates, but callers still need to apply account filters.
- Stored procedures such as product upsert and sale recording perform scoped writes. Not every operation in the script currently has a corresponding UI flow; `usp_AdjustStock` and `usp_RefreshDailySnapshot` are defined, but are not called by the main page code-behind flows documented here.
- SQL setup/seed definitions describe the checked-in script, not necessarily the live database. Confirm that the script has been applied to the same connection-string target before assuming those objects/data exist.

## Debugging a data-layer failure

1. Check the full exception and identify whether it occurs opening the connection, executing SQL, resolving `UserID`, or binding results.
2. Compare `CafeteriaFoodTrackerDB` in `Web.config` with the server/catalog used in SQL Server Management Studio.
3. Confirm the required schema objects exist in that database, especially `AppUsers`, account ownership columns, views, and stored procedures referenced by the failing page.
4. For “The signed-in account is not active,” compare `Context.User.Identity.Name` with `AppUsers.Username` and confirm the matching row has `IsActive = 1`. Do not bypass the active-account filter to hide a stale cookie or mismatched database.
5. Verify expected account ownership: a correctly functioning account sees its own `UserID` rows, while rows from other accounts should not appear in product and transaction queries.
