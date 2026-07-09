# XMONEY cPanel SQL pack

These scripts are for the **XMONEY database only**.

| File | Purpose |
|------|---------|
| `00_IMPORT_ORDER.sql` | Import order reminder |
| `01_create_database_and_user.sql.template` | Template for dedicated DB + user |
| `02_schema_no_create_db.sql` | All XMONEY tables (no CREATE DATABASE) |
| `03_seed.sql` | Roles, currencies, rates, admin row |
| `../migrations/003_wallet_payments_analytics.sql` | `payments.wallet_id`, `payments.purpose` (apply after core schema) |

## Critical

1. In phpMyAdmin, **select** `smartdms_XMONEY` before importing.
2. Never import into your existing application database.
3. Prefer creating the database/user in the cPanel **MySQL® Databases** UI.

See also: `documentation/CPANEL_DEPLOYMENT.md` and `documentation/ISOLATION.md`.
