-- Migration: 005_beneficiary_extended_fields
-- Extended beneficiary metadata for intl transfer flows

SET NAMES utf8mb4;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'delivery_method');
SET @sql := IF(@col = 0, "ALTER TABLE beneficiaries ADD COLUMN delivery_method ENUM('bank','wallet','cnic','local','qr','international') NOT NULL DEFAULT 'bank' AFTER currency_code", 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'wallet_provider_code');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN wallet_provider_code VARCHAR(60) NULL AFTER delivery_method', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'nickname');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN nickname VARCHAR(100) NULL AFTER receiver_name', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'is_favourite');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN is_favourite TINYINT(1) NOT NULL DEFAULT 0 AFTER relationship', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'last_used_at');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN last_used_at DATETIME(3) NULL AFTER is_favourite', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'email');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN email VARCHAR(255) NULL AFTER mobile_number', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'address_line');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN address_line VARCHAR(255) NULL AFTER email', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'receiver_city');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN receiver_city VARCHAR(120) NULL AFTER address_line', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'receiver_state');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN receiver_state VARCHAR(120) NULL AFTER receiver_city', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'postal_code');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN postal_code VARCHAR(30) NULL AFTER receiver_state', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'branch_name');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN branch_name VARCHAR(200) NULL AFTER bank_name', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'purpose_of_transfer');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN purpose_of_transfer VARCHAR(120) NULL AFTER postal_code', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'beneficiaries' AND COLUMN_NAME = 'national_id');
SET @sql := IF(@col = 0, 'ALTER TABLE beneficiaries ADD COLUMN national_id VARCHAR(64) NULL AFTER purpose_of_transfer', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
