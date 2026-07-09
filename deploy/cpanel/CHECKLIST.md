# XMONEY cPanel Deploy Checklist

Use this when credentials are provided. Tick only XMONEY actions.

## Pre-flight
- [ ] Existing site URL tested (baseline)
- [ ] Confirmed deploy path: `public_html/xmoney/` only
- [ ] Confirmed NEW database name (not existing app DB)
- [ ] Confirmed NEW database user (grants only on XMONEY DB)

## Database (XMONEY only)
- [ ] Create `{user}_xmoney_db`
- [ ] Create `{user}_xmoney_user`
- [ ] Grant ALL on XMONEY DB only
- [ ] Import `02_schema_no_create_db.sql` into XMONEY DB
- [ ] Import `03_seed.sql` into XMONEY DB
- [ ] Import migrations into XMONEY DB
- [ ] Verify existing app DB table count unchanged

## Files
- [ ] Build package: `deploy/cpanel/Build-CpanelPackage.ps1`
- [ ] Upload into `public_html/xmoney/` only
- [ ] Confirm sibling folders untouched
- [ ] `api/.env` created from production template
- [ ] `config/runtime-config.js` set with public API URL
- [ ] `composer install --no-dev` inside `xmoney/api`
- [ ] `php scripts/seed-admin.php` run
- [ ] `storage/` writable

## Verify
- [ ] Existing website still works
- [ ] `/xmoney/` loads customer app
- [ ] `/xmoney/admin/` loads admin
- [ ] `/xmoney/api/v1/health` healthy
- [ ] Admin login works
- [ ] No XMONEY tables in existing database
