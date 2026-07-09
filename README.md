# XMONEY
# International Money Transfer Platform

Professional fintech foundation for web, Android, and iOS.

## Isolation (cPanel)

XMONEY is designed to run **beside** an existing site without touching it:

| Resource | XMONEY | Existing site |
|----------|--------|---------------|
| Folder | `public_html/xmoney/` only | Untouched |
| Database | `smartdms_XMONEY` | Untouched |
| DB user | `smartdms_xmoney` | Untouched |
| Config | `xmoney/api/.env` | Untouched |

Read: [documentation/ISOLATION.md](documentation/ISOLATION.md) · [documentation/CPANEL_DEPLOYMENT.md](documentation/CPANEL_DEPLOYMENT.md)

When you are ready, fill `deploy/cpanel/CREDENTIALS.template.txt` (copy to `CREDENTIALS.local.txt`) and we will create the DB, import tables, upload only into `xmoney/`, and configure env — without modifying your existing project.

## Project structure

```
C:\XMONEY
├── frontend-web      Customer web application
├── mobile-app        Android + iOS foundation
│   ├── android
│   └── ios
├── backend-api       Secure REST API (PHP 8.1+)
├── admin-panel       Operations & compliance console
├── database          Schema, migrations, seeds, cPanel SQL pack
├── config            Env templates (no secrets committed)
├── documentation     Architecture & setup guides
├── deploy/cpanel     Isolated cPanel package builder
├── uploads           KYC / profile files (local)
├── logs              Application logs (local)
└── backups           Backup target (local)
```

## Quick start (local)

See **[documentation/LOCAL_SETUP.md](documentation/LOCAL_SETUP.md)** for full steps.

```bash
# 1) Database
mysql -u root -p < database/schema.sql
mysql -u root -p xmoney < database/seeds/001_initial_seed.sql

# 2) API
cd backend-api
copy .env.example .env
composer install
php scripts/seed-admin.php "ChangeMe@XMONEY2026"
php -S localhost:8080 -t public public/router.php

# 3) Web (separate terminals)
cd frontend-web && npx --yes serve -p 3000
cd admin-panel && npx --yes serve -p 3001
```

## Build cPanel package (no upload yet)

```powershell
cd C:\XMONEY\deploy\cpanel
.\Build-CpanelPackage.ps1
```

Upload the package **only** into `public_html/xmoney/`.

## Documentation

| Doc | Description |
|-----|-------------|
| [ISOLATION.md](documentation/ISOLATION.md) | Never touch existing site/DB |
| [CPANEL_DEPLOYMENT.md](documentation/CPANEL_DEPLOYMENT.md) | Hosting deploy steps |
| [ARCHITECTURE.md](documentation/ARCHITECTURE.md) | System design |
| [DATABASE.md](documentation/DATABASE.md) | Schema & relationships |
| [API.md](documentation/API.md) | REST endpoints |
| [LOCAL_SETUP.md](documentation/LOCAL_SETUP.md) | Local development |

## Modules delivered in this foundation

- User registration, login, logout, OTP, forgot password, profile, devices
- KYC upload + admin approve/reject
- Beneficiaries CRUD + verify request
- Transfer quote (rate + margin + fees) → create → confirm → status machine
- Wallet balance, deposit (dev), history
- Payment provider abstraction (stub ready for bank/card/gateway)
- Admin dashboard, users, KYC, transactions, rates, reports
- Audit logs on critical actions
- Mobile shared API contract for Android/iOS
- cPanel-isolated deploy package + dedicated DB SQL pack
