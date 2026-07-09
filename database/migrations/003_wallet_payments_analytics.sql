-- Wallet top-up payments + performance indexes (safe to re-run parts)

-- Link payments to wallets for top-up flows
SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'payments' AND COLUMN_NAME = 'wallet_id');
SET @sql := IF(@col = 0,
  'ALTER TABLE payments ADD COLUMN wallet_id BIGINT UNSIGNED NULL AFTER transaction_id',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'payments' AND COLUMN_NAME = 'purpose');
SET @sql := IF(@col = 0,
  "ALTER TABLE payments ADD COLUMN purpose ENUM('transfer','wallet_topup','other') NOT NULL DEFAULT 'transfer' AFTER method",
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @fk := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'payments' AND CONSTRAINT_NAME = 'fk_pay_wallet');
SET @sql := IF(@fk = 0,
  'ALTER TABLE payments ADD CONSTRAINT fk_pay_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE SET NULL',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Performance indexes (ignore errors if indexes already exist)
CREATE INDEX idx_txn_sender_status_created ON transactions (sender_user_id, status, created_at);
CREATE INDEX idx_txn_created_status ON transactions (created_at, status);
CREATE INDEX idx_wallet_txn_wallet_created ON wallet_transactions (wallet_id, created_at);
CREATE INDEX idx_payments_user_status ON payments (user_id, status, created_at);
CREATE INDEX idx_payments_purpose ON payments (purpose, created_at);
