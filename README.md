# ENTREP Cafeteria Food Tracker

An ASP.NET Web Forms application for managing cafeteria products, inventory, sales transactions, and sales analytics. Accounts have separate product and transaction data. Administrators can manage accounts and view recent transactions attributed to their owning users; regular users see their sales dashboard and account-scoped pages.

## Technology

- ASP.NET Web Forms with C# and .NET Framework 4.7.2
- Microsoft SQL Server and ADO.NET (`System.Data.SqlClient`)
- Bootstrap, jQuery, and application styles in `Content/Site.css`

## Requirements

- Visual Studio 2022 or later with the **ASP.NET and web development** workload
- .NET Framework 4.7.2 Developer Pack / Targeting Pack
- SQL Server Express or another supported SQL Server instance
- SQL Server Management Studio (SSMS) or another SQL client to run setup scripts

## Setup

1. Clone or download the repository and open `ENTREP Cafeteria Food Tracker MANAGEMENT SYSTEM.sln` in Visual Studio.
2. Restore NuGet packages if Visual Studio does not restore them automatically.
3. Create/update the database by running **either**:
   - `sql/CafeteriaFoodTracker.sql` for the complete setup, or
   - `sql/01_Database-Schema-Migration.sql` through `sql/06_Admin-Role-Migration.sql` in numeric order.

   Run the scripts against SQL Server using an account allowed to create/modify the database. The scripts target the `CafeteriaFoodTracker` database. Do not run the complete script and the ordered scripts back-to-back unless you intend to reapply the setup.
4. Update the `CafeteriaFoodTrackerDB` connection string in `Web.config` for your SQL Server instance and authentication method. The checked-in value targets `WIN-F2NE725JK61\SQLEXPRESS` with Windows Integrated Security; change it for your machine. Keep production credentials out of source control.
5. Build the solution and run the Web Forms project from Visual Studio (IIS Express or configured IIS).
6. Sign in with a seeded account. The seeded administrator credentials are `admin` / `admin123`. Change demo credentials before deploying outside a local/demo environment.

## Main features

- Register and authenticate user accounts with hashed passwords and Forms Authentication.
- Manage products, categories, prices, and inventory.
- Record sales and track their transaction items.
- View account-scoped sales summaries, trends, and product performance.
- Manage user accounts as an administrator and review recent transactions by account.

## Project layout

- `Dashboard.aspx` — overview and administrator account management.
- `Products.aspx` — product catalog and inventory management.
- `Sales.aspx` — transaction history and sale entry.
- `Analytics.aspx` — date-range sales analytics.
- `Login.aspx` — sign-in and registration.
- `Site.Master` — shared navigation, account display, and logout.
- `sql/` — complete database setup plus ordered schema, index, view, procedure, seed, and admin migration scripts.
- `md/` — extended architecture, data-flow, and schema documentation.

## Database and account notes

- Update the database connection string before running the application; successful compilation does not confirm the database is reachable or has the required schema.
- Transactions and products belong to an `AppUsers.UserID`. Application queries use that ownership relationship to scope regular users' data. The admin transaction overview identifies the account from `SalesTransactions.UserID`; `RecordedBy` is a separate cashier label.
- `sql/06_Admin-Role-Migration.sql` adds the administrator role to an existing database. The full setup scripts also include the role schema and seeded administrator.
- SQL scripts are intended for SQL Server and include SQL Server batch separators (`GO`); execute them with SSMS or a compatible SQL tooling environment.

## More documentation

- [Application architecture](md/architecture.md)
- [Data layer and application flows](md/data-layer-and-flows.md)
- [SQL schema and setup](md/sql-schema-and-setup.md)
- [Documentation index](md/README.md)
