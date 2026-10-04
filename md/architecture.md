# Application architecture

## At a glance

This repository contains an ASP.NET Web Forms application targeting .NET Framework 4.7.2. It is organized around server-rendered `.aspx` pages and C# code-behind handlers. The code-behind directly accesses Microsoft SQL Server through ADO.NET (`SqlConnection`, `SqlCommand`, `SqlDataReader`, and `SqlDataAdapter`); it does not use a separate API or ORM layer.

```text
Browser
  -> ASP.NET Web Forms page (.aspx + code-behind)
  -> Forms Authentication identity (username)
  -> Login.GetCurrentUserId(...) resolves active account to UserID
  -> ADO.NET query or stored procedure
  -> CafeteriaFoodTracker SQL Server database
```

Most pages use `Site.Master` for the shared navigation and account display. `Site.Master.cs` redirects unauthenticated users to `Login.aspx`, routes `Default.aspx` to Login or Dashboard, and displays navigation for authenticated sessions. `Global.asax.cs` registers routes/bundles at application start and checks authenticated usernames against active rows in `AppUsers`; a missing or inactive account is signed out.

## Request and account data flow

1. `Login.aspx.cs` verifies credentials against an active `AppUsers` row. Passwords are stored as versioned PBKDF2 hashes (iteration count, salt, and derived hash). On success it issues a Forms Authentication cookie containing the trimmed username.
2. During later requests, `Global.asax.cs` checks that the cookie identity still matches an active `AppUsers.Username` in the configured database.
3. Each account-scoped page calls `Login.GetCurrentUserId` to resolve that username to `AppUsers.UserID`.
4. SQL calls pass `@UserID` to filter products, transactions, and related metrics. Product and sale mutations also use the account ID to constrain which records can be changed.

### Login request path

`Login.aspx` contains the login and registration controls. Its postback handlers are in `Login.aspx.cs`: `LoginButton_Click` calls `Authenticate`, which selects an active `AppUsers` record using `@Username` and verifies its stored PBKDF2 hash. On success, the code puts the trimmed username in a Forms Authentication ticket and redirects to `Dashboard.aspx`. Registration uses `SignUpButton_Click` -> `Register`, which inserts `@Username`, `@DisplayName`, and `@PasswordHash` into `AppUsers`, then issues the auth ticket.

On the redirected request, `Global.asax.cs` validates the authenticated username against an active `AppUsers` row. The destination page's code-behind resolves that username to `UserID` via `Login.GetCurrentUserId` in `Login.aspx.cs`; SQL commands then pass `@UserID` alongside page-specific parameters. The username ticket and database `UserID` are separate values: the app stores the username in the ticket and resolves the numeric ID from the database when needed.

`Categories` are shared lookup/reference data. The account-owned records are `Products`, `SalesTransactions`, `StockAdjustments`, and `DailySalesSnapshots`; each stores a `UserID`. Sales line items refer to a transaction and product, and sale queries join through those relationships while checking that the product belongs to the same account.

## Page responsibilities

| Page / files | Responsibility |
| --- | --- |
| `Login.aspx` / `Login.aspx.cs` | Sign in, register accounts, PBKDF2 password verification, issue auth cookies, and expose the shared active-account-to-ID lookup. |
| `Dashboard.aspx` / `Dashboard.aspx.cs` | Show the current account's recent/high-level sales, week-to-date chart, top product performance, and low-stock alert. |
| `Products.aspx` / `Products.aspx.cs` | Filter and list the current account's products, display stock/category metrics, create or edit products through `usp_UpsertProduct`, and deactivate products through the SQL routine. |
| `Sales.aspx` / `Sales.aspx.cs` | List/filter recent transactions and record sales. The page validates selected product and quantity, then invokes `usp_RecordSale`; SQL writes the transaction and line items and deducts stock. |
| `Analytics.aspx` / `Analytics.aspx.cs` | Validate an inclusive start/end date range and query account-scoped transaction and item data for trends, totals, best sellers, and top products. The separate “today” activity count always means today, independent of the selected range. |
| `Site.Master` / `Site.Master.cs` | Shared page shell, navigation, account display, and logout. |
| `Global.asax` / `Global.asax.cs` | Application startup registration and per-request active-account check. |
| `Content/Site.css` | Application-specific styling; Bootstrap assets are under `Content/` and `Scripts/`. |

The `.designer.cs` files declare server controls referenced by code-behind. The `.aspx` files contain the Web Forms markup and data-binding templates.

## SQL access patterns

- The connection string is named `CafeteriaFoodTrackerDB` in `Web.config` and is used throughout the application.
- User inputs are passed to SQL as typed parameters rather than concatenated into query values. Product list filtering builds optional SQL predicates for category, search, and stock state.
- Pages commonly bind SQL results to repeaters using a `DataTable`/`SqlDataAdapter` or stream a single row with `SqlDataReader`.
- `Products` uses `vw_ProductSalesSummary` and `vw_LowStockAlert` for product metrics and listing.
- `Dashboard` and `Analytics` also issue direct parameterized aggregate queries; the views and snapshot table are not proof that every page uses a snapshot cache.
- Product upsert/deactivation and sale recording are implemented as stored procedures, which scope mutations by `@UserID`.

For a trace of concrete form fields to code-behind handlers, SQL parameter names, and affected tables, see [Data layer and application flows](data-layer-and-flows.md#page-to-database-map). The stored-procedure signatures are in `sql/04_Stored-Procedures.sql`; the calling code is in `Products.aspx.cs` and `Sales.aspx.cs`.

`Dashboard.aspx` is role-sensitive: a database-verified administrator (`AppUsers.IsAdmin = 1`) sees account management, while regular users see the sales overview. Every account-management event revalidates administrator status in `Dashboard.aspx.cs`; public signup and admin-created users default to non-admin. The SQL role migration and exact management flow are described in [Data layer and application flows](data-layer-and-flows.md#overview-account-management-path).

## Configuration and local setup notes

- Review `Web.config` before running the application. Its current connection string targets SQL Server instance `WIN-F2NE725JK61\SQLEXPRESS`, catalog `CafeteriaFoodTracker`, and Windows Integrated Security. Change the server/authentication settings for the target machine as needed.
- `sql/CafeteriaFoodTracker.sql` creates or updates schema objects and seeds initial sample data. See [SQL schema and setup](sql-schema-and-setup.md) before applying it.
- A successful compilation does not establish that the configured database is reachable or has the expected schema. The live database's state must be verified separately.

## Source map

- `App_Start/RouteConfig.cs` and `App_Start/BundleConfig.cs`: route and asset bundle registration.
- `Web.config`: target framework, Forms Authentication, connection string, and compiler/runtime configuration.
- `sql/CafeteriaFoodTracker.sql`: database schema, account ownership migration, views, procedures, indexes, and seed data.
