-- ============================================================
-- XMONEY isolation verification (run AFTER deploy)
-- ============================================================
-- 1) Run while connected to the XMONEY database — should list XMONEY tables.
-- 2) Separately open your EXISTING app database — it must NOT contain
--    tables such as exchange_rates, beneficiaries, kyc_documents from XMONEY
--    unless they already existed there for another reason (they should not).

SELECT DATABASE() AS current_database;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY table_name;

-- Expected XMONEY core tables include:
-- users, profiles, kyc_documents, beneficiaries, transactions,
-- wallets, currencies, exchange_rates, admin_users, audit_logs, ...
