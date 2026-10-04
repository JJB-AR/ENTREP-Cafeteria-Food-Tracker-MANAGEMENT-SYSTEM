# Cafeteria Food Tracker documentation

This folder documents the application code, its architecture, and the SQL Server database setup.

## Documents

- [Application architecture](architecture.md) — application structure, request/authentication flow, page responsibilities, and SQL access patterns.
- [Data layer and application flows](data-layer-and-flows.md) — how pages, account identity, ADO.NET, SQL objects, and data mutations work together.
- [SQL schema and setup](sql-schema-and-setup.md) — tables and relationships, views, stored procedures, seed/migration behavior, and local setup guidance.

## Repository references

- Application project: `ENTREP Cafeteria Food Tracker MANAGEMENT SYSTEM.csproj`
- SQL setup script: [`../sql/CafeteriaFoodTracker.sql`](../sql/CafeteriaFoodTracker.sql)
- Ordered SQL topic scripts: `../sql/01_Database-Schema-Migration.sql` through `../sql/06_Admin-Role-Migration.sql`
- Runtime configuration: [`../Web.config`](../Web.config)
