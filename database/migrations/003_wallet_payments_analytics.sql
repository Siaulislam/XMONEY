-- ============================================================
-- Migration: 003_wallet_payments_analytics
-- Target database: smartdms_XMONEY (select in phpMyAdmin before import)
-- phpMyAdmin: Import tab → choose this file → Go
-- Safe to re-run: skips objects that already exist
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- payments.wallet_id — link top-up payments to wallets
-- ------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'payments'
    AND COLUMN_NAME = 'wallet_id'
);
SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE `payments` ADD COLUMN `wallet_id` BIGINT UNSIGNED NULL AFTER `transaction_id`',
  'SELECT ''payments.wallet_id already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- payments.purpose — transfer | wallet_topup | other
-- ------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'payments'
    AND COLUMN_NAME = 'purpose'
);
SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE `payments` ADD COLUMN `purpose` ENUM(''transfer'',''wallet_topup'',''other'') NOT NULL DEFAULT ''transfer'' AFTER `method`',
  'SELECT ''payments.purpose already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- Foreign key: payments.wallet_id → wallets.id
-- ------------------------------------------------------------
SET @fk_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'payments'
    AND CONSTRAINT_NAME = 'fk_pay_wallet'
    AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);
SET @sql := IF(
  @fk_exists = 0,
  'ALTER TABLE `payments` ADD CONSTRAINT `fk_pay_wallet` FOREIGN KEY (`wallet_id`) REFERENCES `wallets` (`id`) ON DELETE SET NULL',
  'SELECT ''fk_pay_wallet already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- Performance indexes (analytics, wallet history, payment monitoring)
-- ------------------------------------------------------------
SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'transactions'
    AND INDEX_NAME = 'idx_txn_sender_status_created'
);
SET @sql := IF(
  @idx_exists = 0,
  'CREATE INDEX `idx_txn_sender_status_created` ON `transactions` (`sender_user_id`, `status`, `created_at`)',
  'SELECT ''idx_txn_sender_status_created already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'transactions'
    AND INDEX_NAME = 'idx_txn_created_status'
);
SET @sql := IF(
  @idx_exists = 0,
  'CREATE INDEX `idx_txn_created_status` ON `transactions` (`created_at`, `status`)',
  'SELECT ''idx_txn_created_status already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'wallet_transactions'
    AND INDEX_NAME = 'idx_wallet_txn_wallet_created'
);
SET @sql := IF(
  @idx_exists = 0,
  'CREATE INDEX `idx_wallet_txn_wallet_created` ON `wallet_transactions` (`wallet_id`, `created_at`)',
  'SELECT ''idx_wallet_txn_wallet_created already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'payments'
    AND INDEX_NAME = 'idx_payments_user_status'
);
SET @sql := IF(
  @idx_exists = 0,
  'CREATE INDEX `idx_payments_user_status` ON `payments` (`user_id`, `status`, `created_at`)',
  'SELECT ''idx_payments_user_status already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'payments'
    AND INDEX_NAME = 'idx_payments_purpose'
);
SET @sql := IF(
  @idx_exists = 0,
  'CREATE INDEX `idx_payments_purpose` ON `payments` (`purpose`, `created_at`)',
  'SELECT ''idx_payments_purpose already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- Record migration
-- ------------------------------------------------------------
INSERT INTO `schema_migrations` (`version`, `description`)
VALUES ('003_wallet_payments_analytics', 'Wallet top-up payment columns and analytics indexes')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`);

SET FOREIGN_KEY_CHECKS = 1;
