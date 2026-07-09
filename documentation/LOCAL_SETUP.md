# XMONEY — Local Development Setup

Do **not** connect to cPanel yet. Complete local architecture first.

## Prerequisites

Install these on your Windows machine before running locally:

- **PHP 8.1+** with extensions: `pdo_mysql`, `mbstring`, `openssl`, `json`, `fileinfo`  
  (XAMPP / Laragon / official windows.php.net builds all work)
- **Composer** — https://getcomposer.org
- **MySQL 8.0+** (or MariaDB 10.6+)
- Modern browser

> On this workstation, PHP/Composer/MySQL were not yet on PATH when the project was created. Install them, then continue below.

## 1. Database

```bash
mysql -u root -p < C:\XMONEY\database\schema.sql
mysql -u root -p xmoney < C:\XMONEY\database\seeds\001_initial_seed.sql
```

Create a local DB user (optional):

```sql
CREATE USER 'xmoney_user'@'localhost' IDENTIFIED BY 'change_me_local';
GRANT ALL ON xmoney.* TO 'xmoney_user'@'localhost';
FLUSH PRIVILEGES;
```

## 2. Backend API

```bash
cd C:\XMONEY\backend-api
copy .env.example .env
# Edit .env — DB credentials + JWT_SECRET (32+ chars)
composer install
php scripts/seed-admin.php "ChangeMe@XMONEY2026"
composer serve
```

API base: `http://localhost:8080`  
Health: `http://localhost:8080/api/v1/health`  
(If using PHP built-in server with `-t public`, routes are `/v1/health` unless you add an `/api` rewrite.)

### PHP built-in server note

```bash
php -S localhost:8080 -t public
```

Frontend `api.js` defaults to `http://localhost:8080/api`.  
Either:

- Set `localStorage.xm_api_base = 'http://localhost:8080'` in the browser console, **or**
- Serve behind Apache with `/api` → `public/`, **or**
- Change the default in `frontend-web/src/assets/js/api.js`

## 3. Customer web

Open `C:\XMONEY\frontend-web\index.html` via a static server:

```bash
cd C:\XMONEY\frontend-web
npx --yes serve -p 3000
```

Visit `http://localhost:3000`

## 4. Admin panel

```bash
cd C:\XMONEY\admin-panel
npx --yes serve -p 3001
```

Login: `admin@xmoney.local` / password from `seed-admin.php`

## 5. Suggested local smoke test

```bash
php C:\XMONEY\backend-api\scripts\smoke-test.php http://localhost:8080
php C:\XMONEY\backend-api\scripts\e2e-flow-test.php http://localhost:8080
```

Manual checklist: `documentation/E2E_TESTING.md`

1. Register customer → verify OTP (shown in debug / `logs/notifications.log`)
2. Admin approves KYC
3. Deposit wallet (dev endpoint on Wallet page when `APP_DEBUG=true`)
4. Add beneficiary → get quote → create & confirm transfer
5. Admin completes transfer → check reports

## When you are ready for hosting

Provide:

- cPanel URL / username
- MySQL host, database name, user, password
- Domain / subdomain for API and web

We will then configure production `.env`, migrations, and deployment.
