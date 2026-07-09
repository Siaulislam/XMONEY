# Import XMONEY schema into smartdms_XMONEY ONLY
#
# SAFETY:
# - Use only 02_schema_no_create_db.sql then 03_seed.sql
# - These files do NOT create/drop databases and do NOT contain USE statements

## phpMyAdmin steps (recommended on cPanel)

1. Open cPanel → phpMyAdmin
2. In the LEFT sidebar, click **smartdms_XMONEY** (must be highlighted)
3. Confirm the top breadcrumb shows database **smartdms_XMONEY**
4. Click **Import**
5. Choose file:
   `C:\XMONEY\database\cpanel\02_schema_no_create_db.sql`
6. Click **Go** — wait until success
7. Still on **smartdms_XMONEY**, Import again:
   `C:\XMONEY\database\cpanel\03_seed.sql`
8. Click **Go**
9. Open **SQL** tab and paste contents of:
   `C:\XMONEY\database\cpanel\05_verify_tables.sql`
10. Confirm:
    - `current_database` = `smartdms_XMONEY`
    - `table_count` = **23** (or more)
    - List includes: users, transactions, wallets, currencies, admin_users, ...

## Do NOT

- Import into any database other than `smartdms_XMONEY`
- Click "Create database" during import
- Import `database/schema.sql` (that file contains CREATE DATABASE for local use)

## After import — set admin password (on server later)

```bash
cd ~/public_html/api
php scripts/seed-admin.php "ChangeMe@XMONEY2026"
```

Or run locally against production only if remote MySQL is enabled (usually not).
