-- ============================================================
-- XMONEY cPanel Schema Import
-- IMPORTANT:
-- 1. Select ONLY the XMONEY database in phpMyAdmin first
--    (e.g. {cpanel_user}_xmoney_db)
-- 2. Do NOT run this against any existing application database
-- 3. This file does NOT create/drop databases
-- ============================================================
-- ============================================================
-- XMONEY Money Transfer Platform
-- Professional Database Schema (MySQL 8.0+)
-- ============================================================
-- Charset: utf8mb4 | Engine: InnoDB
-- Designed for security, auditability, and international scale
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- ROLES & PERMISSIONS
-- ------------------------------------------------------------

CREATE TABLE roles (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code          VARCHAR(50)  NOT NULL,
  name          VARCHAR(100) NOT NULL,
  description   VARCHAR(255) NULL,
  is_system     TINYINT(1)   NOT NULL DEFAULT 1,
  created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE permissions (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code          VARCHAR(100) NOT NULL,
  name          VARCHAR(150) NOT NULL,
  module        VARCHAR(80)  NOT NULL,
  description   VARCHAR(255) NULL,
  created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_permissions_code (code),
  KEY idx_permissions_module (module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE role_permissions (
  role_id       BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- USERS (customers)
-- ------------------------------------------------------------

CREATE TABLE users (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid              CHAR(36)     NOT NULL,
  email             VARCHAR(255) NOT NULL,
  mobile_country    VARCHAR(5)   NOT NULL DEFAULT '+971',
  mobile_number     VARCHAR(30)  NOT NULL,
  password_hash     VARCHAR(255) NOT NULL,
  status            ENUM('pending','active','suspended','blocked','closed') NOT NULL DEFAULT 'pending',
  email_verified_at DATETIME(3)  NULL,
  mobile_verified_at DATETIME(3) NULL,
  kyc_status        ENUM('none','pending','approved','rejected','expired') NOT NULL DEFAULT 'none',
  role_id           BIGINT UNSIGNED NOT NULL,
  failed_login_count INT UNSIGNED NOT NULL DEFAULT 0,
  locked_until      DATETIME(3)  NULL,
  last_login_at     DATETIME(3)  NULL,
  last_login_ip     VARCHAR(45)  NULL,
  created_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at        DATETIME(3)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_uuid (uuid),
  UNIQUE KEY uq_users_email (email),
  UNIQUE KEY uq_users_mobile (mobile_country, mobile_number),
  KEY idx_users_status (status),
  KEY idx_users_kyc_status (kyc_status),
  KEY idx_users_role (role_id),
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE profiles (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id         BIGINT UNSIGNED NOT NULL,
  full_name       VARCHAR(200) NOT NULL,
  date_of_birth   DATE NULL,
  gender          ENUM('male','female','other','unspecified') NOT NULL DEFAULT 'unspecified',
  nationality     CHAR(2) NULL COMMENT 'ISO 3166-1 alpha-2',
  country_code    CHAR(2) NOT NULL COMMENT 'ISO 3166-1 alpha-2',
  city            VARCHAR(120) NULL,
  address_line1   VARCHAR(255) NULL,
  address_line2   VARCHAR(255) NULL,
  postal_code     VARCHAR(30)  NULL,
  avatar_path     VARCHAR(500) NULL,
  preferred_language VARCHAR(10) NOT NULL DEFAULT 'en',
  preferred_currency CHAR(3) NOT NULL DEFAULT 'AED',
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_profiles_user (user_id),
  KEY idx_profiles_country (country_code),
  CONSTRAINT fk_profiles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- ADMIN USERS (staff)
-- ------------------------------------------------------------

CREATE TABLE admin_users (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid            CHAR(36)     NOT NULL,
  email           VARCHAR(255) NOT NULL,
  password_hash   VARCHAR(255) NOT NULL,
  full_name       VARCHAR(200) NOT NULL,
  role_id         BIGINT UNSIGNED NOT NULL,
  status          ENUM('active','suspended','inactive') NOT NULL DEFAULT 'active',
  last_login_at   DATETIME(3)  NULL,
  last_login_ip   VARCHAR(45)  NULL,
  created_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at      DATETIME(3)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_admin_uuid (uuid),
  UNIQUE KEY uq_admin_email (email),
  KEY idx_admin_role (role_id),
  CONSTRAINT fk_admin_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- AUTH: OTP, SESSIONS, DEVICES, PASSWORD RESET
-- ------------------------------------------------------------

CREATE TABLE otp_verifications (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NULL,
  channel       ENUM('email','sms') NOT NULL,
  destination   VARCHAR(255) NOT NULL,
  purpose       ENUM('registration','login','password_reset','transfer','device','kyc') NOT NULL,
  otp_hash      VARCHAR(255) NOT NULL,
  attempts      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  max_attempts  TINYINT UNSIGNED NOT NULL DEFAULT 5,
  expires_at    DATETIME(3) NOT NULL,
  verified_at   DATETIME(3) NULL,
  created_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_otp_dest_purpose (destination, purpose),
  KEY idx_otp_user (user_id),
  KEY idx_otp_expires (expires_at),
  CONSTRAINT fk_otp_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_devices (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id         BIGINT UNSIGNED NOT NULL,
  device_uuid     VARCHAR(100) NOT NULL,
  device_name     VARCHAR(150) NULL,
  platform        ENUM('web','android','ios','other') NOT NULL DEFAULT 'web',
  push_token      VARCHAR(500) NULL,
  ip_address      VARCHAR(45) NULL,
  user_agent      VARCHAR(500) NULL,
  is_trusted      TINYINT(1) NOT NULL DEFAULT 0,
  last_seen_at    DATETIME(3) NULL,
  revoked_at      DATETIME(3) NULL,
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_device_user_uuid (user_id, device_uuid),
  KEY idx_devices_user (user_id),
  CONSTRAINT fk_devices_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE refresh_tokens (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NULL,
  admin_user_id BIGINT UNSIGNED NULL,
  token_hash    CHAR(64) NOT NULL,
  device_id     BIGINT UNSIGNED NULL,
  expires_at    DATETIME(3) NOT NULL,
  revoked_at    DATETIME(3) NULL,
  created_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_refresh_hash (token_hash),
  KEY idx_refresh_user (user_id),
  KEY idx_refresh_admin (admin_user_id),
  CONSTRAINT fk_refresh_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_refresh_admin FOREIGN KEY (admin_user_id) REFERENCES admin_users(id) ON DELETE CASCADE,
  CONSTRAINT fk_refresh_device FOREIGN KEY (device_id) REFERENCES user_devices(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE password_resets (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NOT NULL,
  token_hash    CHAR(64) NOT NULL,
  expires_at    DATETIME(3) NOT NULL,
  used_at       DATETIME(3) NULL,
  created_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_pwreset_hash (token_hash),
  KEY idx_pwreset_user (user_id),
  CONSTRAINT fk_pwreset_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- KYC
-- ------------------------------------------------------------

CREATE TABLE kyc_documents (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid            CHAR(36) NOT NULL,
  user_id         BIGINT UNSIGNED NOT NULL,
  document_type   ENUM('passport','national_id','emirates_id','address_proof','selfie') NOT NULL,
  document_number VARCHAR(100) NULL,
  country_code    CHAR(2) NULL,
  file_path       VARCHAR(500) NOT NULL,
  file_mime       VARCHAR(100) NOT NULL,
  file_size       INT UNSIGNED NOT NULL,
  status          ENUM('pending','approved','rejected','expired') NOT NULL DEFAULT 'pending',
  expires_on      DATE NULL,
  reviewed_by     BIGINT UNSIGNED NULL,
  reviewed_at     DATETIME(3) NULL,
  rejection_reason VARCHAR(500) NULL,
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_kyc_uuid (uuid),
  KEY idx_kyc_user (user_id),
  KEY idx_kyc_status (status),
  KEY idx_kyc_type (document_type),
  CONSTRAINT fk_kyc_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_kyc_reviewer FOREIGN KEY (reviewed_by) REFERENCES admin_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- CURRENCIES, RATES, FEES
-- ------------------------------------------------------------

CREATE TABLE currencies (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code            CHAR(3) NOT NULL COMMENT 'ISO 4217',
  name            VARCHAR(100) NOT NULL,
  symbol          VARCHAR(10) NOT NULL,
  decimal_places  TINYINT UNSIGNED NOT NULL DEFAULT 2,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  is_source       TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Can send from',
  is_destination  TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Can receive in',
  sort_order      INT NOT NULL DEFAULT 100,
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_currency_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE exchange_rates (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  source_currency   CHAR(3) NOT NULL,
  target_currency   CHAR(3) NOT NULL,
  market_rate       DECIMAL(18,8) NOT NULL COMMENT 'External market mid rate',
  margin            DECIMAL(10,6) NOT NULL DEFAULT 0 COMMENT 'XMONEY margin units',
  customer_rate     DECIMAL(18,8) NOT NULL COMMENT 'Rate shown to customer',
  provider          VARCHAR(80) NULL,
  effective_from    DATETIME(3) NOT NULL,
  effective_to      DATETIME(3) NULL,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  created_by        BIGINT UNSIGNED NULL,
  created_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_rates_pair_active (source_currency, target_currency, is_active),
  KEY idx_rates_effective (effective_from),
  CONSTRAINT fk_rates_source FOREIGN KEY (source_currency) REFERENCES currencies(code),
  CONSTRAINT fk_rates_target FOREIGN KEY (target_currency) REFERENCES currencies(code),
  CONSTRAINT fk_rates_admin FOREIGN KEY (created_by) REFERENCES admin_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE fees (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name              VARCHAR(120) NOT NULL,
  fee_type          ENUM('flat','percent','tiered') NOT NULL DEFAULT 'flat',
  source_currency   CHAR(3) NULL,
  target_currency   CHAR(3) NULL,
  destination_country CHAR(2) NULL,
  flat_amount       DECIMAL(18,4) NULL,
  percent_value     DECIMAL(8,4) NULL,
  min_fee           DECIMAL(18,4) NULL,
  max_fee           DECIMAL(18,4) NULL,
  min_amount        DECIMAL(18,4) NOT NULL DEFAULT 0,
  max_amount        DECIMAL(18,4) NULL,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  priority          INT NOT NULL DEFAULT 100,
  created_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_fees_active (is_active, priority),
  KEY idx_fees_corridor (source_currency, target_currency, destination_country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE settings (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  setting_key   VARCHAR(120) NOT NULL,
  setting_value TEXT NOT NULL,
  value_type    ENUM('string','number','boolean','json') NOT NULL DEFAULT 'string',
  group_name    VARCHAR(80) NOT NULL DEFAULT 'general',
  description   VARCHAR(255) NULL,
  updated_by    BIGINT UNSIGNED NULL,
  created_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_settings_key (setting_key),
  KEY idx_settings_group (group_name),
  CONSTRAINT fk_settings_admin FOREIGN KEY (updated_by) REFERENCES admin_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- BENEFICIARIES
-- ------------------------------------------------------------

CREATE TABLE beneficiaries (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid              CHAR(36) NOT NULL,
  user_id           BIGINT UNSIGNED NOT NULL,
  receiver_name     VARCHAR(200) NOT NULL,
  country_code      CHAR(2) NOT NULL,
  currency_code     CHAR(3) NOT NULL,
  bank_name         VARCHAR(200) NULL,
  account_number    VARCHAR(64) NULL,
  iban              VARCHAR(64) NULL,
  swift_bic         VARCHAR(20) NULL,
  mobile_country    VARCHAR(5) NULL,
  mobile_number     VARCHAR(30) NULL,
  relationship      VARCHAR(80) NULL,
  verification_status ENUM('unverified','pending','verified','failed') NOT NULL DEFAULT 'unverified',
  verified_at       DATETIME(3) NULL,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  created_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at        DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ben_uuid (uuid),
  KEY idx_ben_user (user_id),
  KEY idx_ben_country (country_code),
  CONSTRAINT fk_ben_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ben_currency FOREIGN KEY (currency_code) REFERENCES currencies(code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- WALLETS
-- ------------------------------------------------------------

CREATE TABLE wallets (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid            CHAR(36) NOT NULL,
  user_id         BIGINT UNSIGNED NOT NULL,
  currency_code   CHAR(3) NOT NULL,
  balance         DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
  available_balance DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
  held_balance    DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
  status          ENUM('active','frozen','closed') NOT NULL DEFAULT 'active',
  version         INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Optimistic locking',
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_wallet_uuid (uuid),
  UNIQUE KEY uq_wallet_user_currency (user_id, currency_code),
  CONSTRAINT fk_wallet_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_wallet_currency FOREIGN KEY (currency_code) REFERENCES currencies(code),
  CONSTRAINT chk_wallet_balances CHECK (balance >= 0 AND available_balance >= 0 AND held_balance >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE wallet_transactions (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid              CHAR(36) NOT NULL,
  wallet_id         BIGINT UNSIGNED NOT NULL,
  type              ENUM('deposit','withdrawal','transfer_debit','transfer_credit','fee','refund','adjustment','hold','release') NOT NULL,
  amount            DECIMAL(18,4) NOT NULL,
  balance_before    DECIMAL(18,4) NOT NULL,
  balance_after     DECIMAL(18,4) NOT NULL,
  reference_type    VARCHAR(50) NULL COMMENT 'transaction, payment, etc',
  reference_id      BIGINT UNSIGNED NULL,
  description       VARCHAR(255) NULL,
  created_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_wtx_uuid (uuid),
  KEY idx_wtx_wallet (wallet_id),
  KEY idx_wtx_ref (reference_type, reference_id),
  KEY idx_wtx_created (created_at),
  CONSTRAINT fk_wtx_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TRANSACTIONS (money transfers)
-- ------------------------------------------------------------

CREATE TABLE transactions (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid                  CHAR(36) NOT NULL,
  reference_code        VARCHAR(32) NOT NULL COMMENT 'Human-readable TXN ID',
  sender_user_id        BIGINT UNSIGNED NOT NULL,
  beneficiary_id        BIGINT UNSIGNED NOT NULL,
  source_currency       CHAR(3) NOT NULL,
  target_currency       CHAR(3) NOT NULL,
  destination_country   CHAR(2) NOT NULL,
  send_amount           DECIMAL(18,4) NOT NULL,
  receive_amount        DECIMAL(18,4) NOT NULL,
  market_rate           DECIMAL(18,8) NOT NULL,
  margin                DECIMAL(10,6) NOT NULL,
  customer_rate         DECIMAL(18,8) NOT NULL,
  fee_amount            DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
  fee_currency          CHAR(3) NOT NULL,
  total_debit           DECIMAL(18,4) NOT NULL COMMENT 'send_amount + fee',
  status                ENUM(
                          'created',
                          'pending_payment',
                          'processing',
                          'under_review',
                          'completed',
                          'failed',
                          'cancelled',
                          'refunded'
                        ) NOT NULL DEFAULT 'created',
  payment_method        VARCHAR(50) NULL,
  payment_provider      VARCHAR(80) NULL,
  payment_reference     VARCHAR(120) NULL,
  failure_reason        VARCHAR(500) NULL,
  completed_at          DATETIME(3) NULL,
  cancelled_at          DATETIME(3) NULL,
  refunded_at           DATETIME(3) NULL,
  metadata_json         JSON NULL,
  created_at            DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at            DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_txn_uuid (uuid),
  UNIQUE KEY uq_txn_reference (reference_code),
  KEY idx_txn_sender (sender_user_id),
  KEY idx_txn_beneficiary (beneficiary_id),
  KEY idx_txn_status (status),
  KEY idx_txn_created (created_at),
  KEY idx_txn_corridor (source_currency, target_currency, destination_country),
  CONSTRAINT fk_txn_sender FOREIGN KEY (sender_user_id) REFERENCES users(id),
  CONSTRAINT fk_txn_beneficiary FOREIGN KEY (beneficiary_id) REFERENCES beneficiaries(id),
  CONSTRAINT fk_txn_source_cur FOREIGN KEY (source_currency) REFERENCES currencies(code),
  CONSTRAINT fk_txn_target_cur FOREIGN KEY (target_currency) REFERENCES currencies(code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE transaction_logs (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_id  BIGINT UNSIGNED NOT NULL,
  from_status     VARCHAR(40) NULL,
  to_status       VARCHAR(40) NOT NULL,
  actor_type      ENUM('user','admin','system','provider') NOT NULL,
  actor_id        BIGINT UNSIGNED NULL,
  note            VARCHAR(500) NULL,
  ip_address      VARCHAR(45) NULL,
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_txnlog_txn (transaction_id),
  KEY idx_txnlog_created (created_at),
  CONSTRAINT fk_txnlog_txn FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- PAYMENTS (provider-agnostic layer)
-- ------------------------------------------------------------

CREATE TABLE payments (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid              CHAR(36) NOT NULL,
  transaction_id    BIGINT UNSIGNED NULL,
  user_id           BIGINT UNSIGNED NOT NULL,
  provider_code     VARCHAR(50) NOT NULL COMMENT 'stripe, bank_transfer, etc',
  method            ENUM('card','bank_transfer','wallet','gateway','other') NOT NULL,
  amount            DECIMAL(18,4) NOT NULL,
  currency_code     CHAR(3) NOT NULL,
  status            ENUM('initiated','pending','authorized','captured','failed','refunded','cancelled') NOT NULL DEFAULT 'initiated',
  provider_ref      VARCHAR(200) NULL,
  provider_payload  JSON NULL,
  failure_code      VARCHAR(80) NULL,
  failure_message   VARCHAR(500) NULL,
  created_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_pay_uuid (uuid),
  KEY idx_pay_txn (transaction_id),
  KEY idx_pay_user (user_id),
  KEY idx_pay_status (status),
  CONSTRAINT fk_pay_txn FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL,
  CONSTRAINT fk_pay_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- NOTIFICATIONS
-- ------------------------------------------------------------

CREATE TABLE notifications (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid            CHAR(36) NOT NULL,
  user_id         BIGINT UNSIGNED NULL,
  admin_user_id   BIGINT UNSIGNED NULL,
  channel         ENUM('email','sms','push','in_app') NOT NULL,
  template_code   VARCHAR(80) NULL,
  title           VARCHAR(200) NOT NULL,
  body            TEXT NOT NULL,
  payload_json    JSON NULL,
  status          ENUM('queued','sent','failed','read') NOT NULL DEFAULT 'queued',
  sent_at         DATETIME(3) NULL,
  read_at         DATETIME(3) NULL,
  error_message   VARCHAR(500) NULL,
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_notif_uuid (uuid),
  KEY idx_notif_user (user_id),
  KEY idx_notif_status (status),
  KEY idx_notif_created (created_at),
  CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_notif_admin FOREIGN KEY (admin_user_id) REFERENCES admin_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- AUDIT LOGS (immutable activity trail)
-- ------------------------------------------------------------

CREATE TABLE audit_logs (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  actor_type      ENUM('user','admin','system') NOT NULL,
  actor_id        BIGINT UNSIGNED NULL,
  action          VARCHAR(100) NOT NULL,
  entity_type     VARCHAR(80) NOT NULL,
  entity_id       BIGINT UNSIGNED NULL,
  ip_address      VARCHAR(45) NULL,
  user_agent      VARCHAR(500) NULL,
  request_id      VARCHAR(64) NULL,
  before_json     JSON NULL,
  after_json      JSON NULL,
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_audit_actor (actor_type, actor_id),
  KEY idx_audit_entity (entity_type, entity_id),
  KEY idx_audit_action (action),
  KEY idx_audit_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- END OF SCHEMA
-- ============================================================

