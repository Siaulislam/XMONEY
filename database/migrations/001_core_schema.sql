-- Migration: 001_core_schema
-- Applies the full XMONEY core schema.
-- For fresh installs, prefer: mysql < database/schema.sql
-- This file records the migration version after schema.sql is applied.

INSERT INTO schema_migrations (version, description)
VALUES ('001_core_schema', 'Core XMONEY tables: users, KYC, transfers, wallets, audit')
ON DUPLICATE KEY UPDATE description = VALUES(description);
