-- ============================================================
-- XMONEY — Verify tables in smartdms_XMONEY ONLY
-- Run this in phpMyAdmin AFTER selecting database: smartdms_XMONEY
-- ============================================================

SELECT DATABASE() AS current_database;

-- Must show: smartdms_XMONEY
-- If it does not show smartdms_XMONEY — STOP. Wrong database.

SELECT COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_type = 'BASE TABLE';

SELECT table_name
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Expected core tables (23):
-- admin_users, audit_logs, beneficiaries, currencies, exchange_rates,
-- fees, kyc_documents, notifications, otp_verifications, password_resets,
-- payments, permissions, profiles, refresh_tokens, role_permissions,
-- roles, settings, transaction_logs, transactions, user_devices,
-- users, wallet_transactions, wallets
