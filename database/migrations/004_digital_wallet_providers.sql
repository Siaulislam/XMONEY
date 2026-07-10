-- ============================================================
-- Migration: 004_digital_wallet_providers
-- Digital wallet providers + country mappings (payout rails)
-- Safe to re-run: uses IF NOT EXISTS patterns
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS digital_wallet_providers (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code          VARCHAR(60)  NOT NULL,
  name          VARCHAR(120) NOT NULL,
  description   VARCHAR(255) NOT NULL DEFAULT '',
  logo_url      VARCHAR(500) NULL,
  brand_color   VARCHAR(7)   NOT NULL DEFAULT '#1A4B8C',
  is_active     TINYINT(1)   NOT NULL DEFAULT 1,
  created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_dwp_code (code),
  KEY idx_dwp_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS country_digital_wallets (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  country_code  CHAR(2)      NOT NULL,
  provider_id   BIGINT UNSIGNED NOT NULL,
  sort_order    INT UNSIGNED NOT NULL DEFAULT 0,
  is_active     TINYINT(1)   NOT NULL DEFAULT 1,
  created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_country_provider (country_code, provider_id),
  KEY idx_cdw_country (country_code, is_active, sort_order),
  CONSTRAINT fk_cdw_provider FOREIGN KEY (provider_id) REFERENCES digital_wallet_providers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed providers (idempotent via INSERT IGNORE)
INSERT IGNORE INTO digital_wallet_providers (code, name, description, brand_color) VALUES
('easypaisa', 'Easypaisa', 'Send instantly to any Easypaisa mobile account', '#00A651'),
('jazzcash', 'JazzCash', 'Fast transfers to JazzCash wallets nationwide', '#E4002B'),
('nayapay', 'NayaPay', 'Digital wallet transfers across Pakistan', '#6C2BD9'),
('sadapay', 'SadaPay', 'Send to SadaPay users in seconds', '#FF6B35'),
('upaisa', 'UPaisa', 'Ufone mobile wallet delivery', '#00AEEF'),
('bkash', 'bKash', 'Bangladesh mobile financial service', '#E2136E'),
('nagad', 'Nagad', 'Government-backed digital wallet in Bangladesh', '#F6921E'),
('rocket', 'Rocket', 'Dutch-Bangla mobile banking wallet', '#8B2A7C'),
('upay_bd', 'Upay', 'UCB-backed mobile wallet transfers', '#1E3A8A'),
('paytm', 'Paytm', 'Send to Paytm wallet or linked UPI ID', '#00BAF2'),
('phonepe', 'PhonePe', 'UPI wallet transfers across India', '#5F259F'),
('google_pay', 'Google Pay (UPI)', 'UPI transfers via Google Pay', '#4285F4'),
('amazon_pay', 'Amazon Pay', 'Send to Amazon Pay balance in India', '#FF9900'),
('bhim_upi', 'BHIM UPI', 'Direct UPI payments to any VPA', '#00897B'),
('botim_wallet', 'Botim Wallet', 'UAE digital wallet via Botim', '#00C853'),
('eand_money', 'e& money', 'Etisalat mobile wallet in the UAE', '#E00800'),
('careem_pay', 'Careem Pay', 'Careem Pay wallet top-up and transfer', '#00B140'),
('stc_pay', 'STC Pay', 'Saudi digital wallet by stc', '#4F008C'),
('urpay', 'UrPay', 'Al Rajhi digital wallet in KSA', '#004F9F'),
('gcash', 'GCash', 'Philippines mobile wallet', '#007CFF'),
('maya', 'Maya', 'Send to Maya wallet accounts', '#00D632'),
('esewa', 'eSewa', 'Nepal digital wallet', '#60BB46'),
('khalti', 'Khalti', 'Fast wallet transfers in Nepal', '#5C2D91'),
('ezcash', 'eZ Cash', 'Dialog mobile wallet in Sri Lanka', '#ED1C24'),
('mcash', 'mCash', 'Mobitel wallet transfers in Sri Lanka', '#FF6600'),
('vodafone_cash', 'Vodafone Cash', 'Vodafone mobile money in Egypt', '#E60000'),
('orange_cash', 'Orange Cash', 'Orange mobile wallet in Egypt', '#FF7900'),
('mpesa', 'M-Pesa', 'Kenya mobile money network', '#4CAF50');

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'PK', id, 1 FROM digital_wallet_providers WHERE code = 'easypaisa';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'PK', id, 2 FROM digital_wallet_providers WHERE code = 'jazzcash';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'PK', id, 3 FROM digital_wallet_providers WHERE code = 'nayapay';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'PK', id, 4 FROM digital_wallet_providers WHERE code = 'sadapay';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'PK', id, 5 FROM digital_wallet_providers WHERE code = 'upaisa';

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'BD', id, 1 FROM digital_wallet_providers WHERE code = 'bkash';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'BD', id, 2 FROM digital_wallet_providers WHERE code = 'nagad';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'BD', id, 3 FROM digital_wallet_providers WHERE code = 'rocket';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'BD', id, 4 FROM digital_wallet_providers WHERE code = 'upay_bd';

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'IN', id, 1 FROM digital_wallet_providers WHERE code = 'paytm';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'IN', id, 2 FROM digital_wallet_providers WHERE code = 'phonepe';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'IN', id, 3 FROM digital_wallet_providers WHERE code = 'google_pay';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'IN', id, 4 FROM digital_wallet_providers WHERE code = 'amazon_pay';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'IN', id, 5 FROM digital_wallet_providers WHERE code = 'bhim_upi';

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'AE', id, 1 FROM digital_wallet_providers WHERE code = 'botim_wallet';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'AE', id, 2 FROM digital_wallet_providers WHERE code = 'eand_money';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'AE', id, 3 FROM digital_wallet_providers WHERE code = 'careem_pay';

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'SA', id, 1 FROM digital_wallet_providers WHERE code = 'stc_pay';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'SA', id, 2 FROM digital_wallet_providers WHERE code = 'urpay';

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'PH', id, 1 FROM digital_wallet_providers WHERE code = 'gcash';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'PH', id, 2 FROM digital_wallet_providers WHERE code = 'maya';

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'NP', id, 1 FROM digital_wallet_providers WHERE code = 'esewa';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'NP', id, 2 FROM digital_wallet_providers WHERE code = 'khalti';

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'LK', id, 1 FROM digital_wallet_providers WHERE code = 'ezcash';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'LK', id, 2 FROM digital_wallet_providers WHERE code = 'mcash';

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'EG', id, 1 FROM digital_wallet_providers WHERE code = 'vodafone_cash';
INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'EG', id, 2 FROM digital_wallet_providers WHERE code = 'orange_cash';

INSERT IGNORE INTO country_digital_wallets (country_code, provider_id, sort_order)
SELECT 'KE', id, 1 FROM digital_wallet_providers WHERE code = 'mpesa';

SET FOREIGN_KEY_CHECKS = 1;
