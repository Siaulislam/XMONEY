# XMONEY — cPanel Deployment Guide

This guide deploys XMONEY **without affecting** any existing website or database on the same account.

Full isolation rules: [ISOLATION.md](ISOLATION.md)

---

## What you will create on cPanel (XMONEY only)

| Resource | Example logical name | Typical cPanel name |
|----------|----------------------|---------------------|
| Folder | `public_html/xmoney/` | same |
| Database | `xmoney_db` | `{user}_xmoney_db` |
| DB user | `xmoney_user` | `{user}_xmoney_user` |
| Privileges | ALL on XMONEY DB only | via MySQL Databases UI |

Replace `{user}` with your cPanel username. **Never reuse** the existing app’s DB or user.

---

## Phase A — You provide credentials (when ready)

Fill `deploy/cpanel/CREDENTIALS.template.txt` and send securely. Required:

- cPanel URL / username / password (or API token)
- Preferred folder: `public_html/xmoney/`
- Domain or subdomain for XMONEY
- Confirmation that a **new** database + user may be created

Until then, nothing is uploaded or connected to your server.

---

## Phase B — Create database (cPanel UI — safest)

1. cPanel → **MySQL® Databases**
2. Create database: `xmoney_db` → becomes `{user}_xmoney_db`
3. Create user: `xmoney_user` + strong password → `{user}_xmoney_user`
4. **Add User To Database** → select XMONEY DB + XMONEY user → **ALL PRIVILEGES**
5. Do **not** add this user to any other database

SQL templates (if you have remote MySQL access):  
`database/cpanel/01_create_database_and_user.sql.template`

---

## Phase C — Import XMONEY tables only

Import into the **new** database only:

1. `database/cpanel/02_schema_no_create_db.sql` — tables (no `CREATE DATABASE`)
2. `database/cpanel/03_seed.sql` — roles, currencies, rates, admin row
3. `database/migrations/000_schema_migrations.sql`
4. `database/migrations/001_core_schema.sql`

Via phpMyAdmin: select `{user}_xmoney_db` → Import → choose files in order.

Or CLI (example):

```bash
mysql -h localhost -u {user}_xmoney_user -p {user}_xmoney_db < 02_schema_no_create_db.sql
mysql -h localhost -u {user}_xmoney_user -p {user}_xmoney_db < 03_seed.sql
```

---

## Phase D — Upload project (XMONEY folder only)

Upload the built package into **`public_html/xmoney/`** only.

Build locally:

```powershell
cd C:\XMONEY\deploy\cpanel
.\Build-CpanelPackage.ps1
```

Output: `deploy/cpanel/dist/xmoney-cpanel-package/`

Upload contents of that folder into `public_html/xmoney/`.

---

## Phase E — Configure environment (no hard-coded secrets)

1. Copy `api/.env.example` → `api/.env` on the server
2. Set **only** XMONEY values:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com/xmoney/api

DB_HOST=localhost
DB_NAME={user}_xmoney_db
DB_USER={user}_xmoney_user
DB_PASS=********

JWT_SECRET=<generate-64-char-random>
CORS_ALLOWED_ORIGINS=https://your-domain.com
```

3. Copy `config/runtime-config.example.js` → `config/runtime-config.js` and set public API URL (no DB password).
4. Set admin password:

```bash
cd ~/public_html/xmoney/api
php scripts/seed-admin.php "YourStrongAdminPassword"
```

5. Ensure `storage/uploads` and `storage/logs` are writable (`755` or `775`).

---

## Phase F — Verify isolation

- Existing site URL still loads unchanged
- `https://your-domain.com/xmoney/` loads XMONEY
- `https://your-domain.com/xmoney/api/v1/health` returns healthy
- phpMyAdmin shows XMONEY tables **only** under `{user}_xmoney_db`
- Existing database table list unchanged

---

## Future updates

- Deploy only into `public_html/xmoney/`
- Run new migrations only against `{user}_xmoney_db`
- Never run XMONEY SQL against the existing app database
