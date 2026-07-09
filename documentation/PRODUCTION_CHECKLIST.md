# XMONEY Production Deployment Checklist

**Do not deploy to cPanel until every item below is signed off.**

## Database

- [ ] `smartdms_XMONEY` imported with core schema (`database/schema.sql` or migration `001`)
- [ ] Migration `002_transfer_daily_limit_setting.sql` applied
- [ ] Migration `003_wallet_payments_analytics.sql` applied via phpMyAdmin
- [ ] `schema_migrations` table lists all applied versions
- [ ] Admin user seeded (`php backend-api/scripts/seed-admin.php`)
- [ ] Production DB credentials in `backend-api/.env` (not committed)

## Backend API

- [ ] `APP_ENV=production` and `APP_DEBUG=false`
- [ ] Strong `JWT_SECRET` (32+ random bytes)
- [ ] `CORS_ALLOWED_ORIGINS` restricted to production domains
- [ ] Upload directory writable (`storage/uploads` or configured path)
- [ ] `php scripts/smoke-test.php https://your-domain/xmoney/api` — all checks pass
- [ ] Rate limits verified on auth endpoints
- [ ] Payment/SMS providers remain placeholder until authorized

## Security

- [ ] HTTPS enforced (HSTS header active)
- [ ] Security headers present (run smoke test)
- [ ] No `.env` or credentials in git
- [ ] File upload limits configured (`UPLOAD_MAX_MB`)
- [ ] Admin passwords rotated from default seed
- [ ] OTP debug bypass disabled in production

## Frontend (Customer + Admin)

- [ ] `config/runtime-config.js` points to production API URL
- [ ] Official XMONEY branding assets deployed
- [ ] PWA manifest and favicons load correctly
- [ ] Login, register, OTP, transfer, wallet flows tested end-to-end

## Mobile

- [ ] `assets/config.json` API URL set for production
- [ ] `flutter create` completed; native icons copied from `assets/android` and `assets/ios`
- [ ] Release builds tested on Android and iOS devices

## Infrastructure

- [ ] FTP/deploy path: `/home/smartdms/public_html/xmoney/`
- [ ] `.htaccess` routes API to `backend-api/public`
- [ ] PHP 8.1+ with required extensions (pdo_mysql, json, mbstring, fileinfo)
- [ ] Cron/queue not required for phase 1 (document if added later)
- [ ] Backups configured for database and uploads

## Post-deploy verification

- [ ] `GET /v1/health` returns 200
- [ ] Customer registration + OTP + login
- [ ] Admin login + dashboard analytics
- [ ] Wallet top-up (placeholder provider) + transfer quote
- [ ] Audit log entries created for sensitive actions

## Rollback

- [ ] Previous release tag documented
- [ ] Database backup taken before migration
- [ ] Rollback procedure tested on staging
