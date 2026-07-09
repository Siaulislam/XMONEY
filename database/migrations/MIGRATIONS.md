# XMONEY Database Migrations

Apply in order on `smartdms_XMONEY` via phpMyAdmin (select database first, then Import).

| Version | File | Description |
|---------|------|-------------|
| 000 | `000_schema_migrations.sql` | Migration tracking table |
| 001 | `001_core_schema.sql` | Records core schema (use `schema.sql` for fresh install) |
| 002 | `002_transfer_daily_limit_setting.sql` | Daily transfer limit setting |
| 003 | `003_wallet_payments_analytics.sql` | Wallet top-up columns + analytics indexes |

## Latest: 003_wallet_payments_analytics

Import `003_wallet_payments_analytics.sql` only if not yet applied. Safe to re-run.

Adds to `payments`:
- `wallet_id` (nullable FK → `wallets`)
- `purpose` (`transfer`, `wallet_topup`, `other`)

Indexes for analytics and wallet history performance.
