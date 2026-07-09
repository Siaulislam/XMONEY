# XMONEY — Database Design

Schema file: `database/schema.sql`  
Seed file: `database/seeds/001_initial_seed.sql`

## Core tables

| Table | Purpose |
|-------|---------|
| `roles` / `permissions` / `role_permissions` | RBAC |
| `users` / `profiles` | Customers |
| `admin_users` | Staff accounts |
| `otp_verifications` | OTP challenges |
| `user_devices` / `refresh_tokens` / `password_resets` | Auth & devices |
| `kyc_documents` | Identity verification |
| `beneficiaries` | Receivers |
| `currencies` / `exchange_rates` / `fees` | FX & pricing |
| `transactions` / `transaction_logs` | Transfers + history |
| `payments` | Provider-agnostic payments |
| `wallets` / `wallet_transactions` | Wallet ledger |
| `notifications` | Outbound messages |
| `audit_logs` | Platform activity trail |
| `settings` | Runtime configuration |

## Key indexes

- Unique email / mobile on `users`
- Corridor indexes on `transactions` and `fees`
- Active rate lookup on `(source_currency, target_currency, is_active)`
- Audit entity + time indexes for compliance queries

## Apply locally

```bash
mysql -u root -p < database/schema.sql
mysql -u root -p xmoney < database/seeds/001_initial_seed.sql
mysql -u root -p xmoney < database/migrations/000_schema_migrations.sql
mysql -u root -p xmoney < database/migrations/001_core_schema.sql
```

Then set a real admin password:

```bash
cd backend-api
php scripts/seed-admin.php "YourSecurePassword"
```

## Apply on cPanel (XMONEY database only)

Use `database/cpanel/` — these files do **not** create or select a database by name.
You must select `smartdms_XMONEY` in phpMyAdmin first.

Never import into your existing application database.

See [CPANEL_DEPLOYMENT.md](CPANEL_DEPLOYMENT.md) and [ISOLATION.md](ISOLATION.md).
