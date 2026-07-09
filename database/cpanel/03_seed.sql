-- ============================================================
-- XMONEY cPanel Seed Import
-- Run ONLY after 02_schema_no_create_db.sql
-- Target database: {cpanel_user}_xmoney_db (selected in phpMyAdmin)
-- ============================================================
-- ============================================================
-- XMONEY Seed Data â€” Local Development
-- ============================================================
-- Roles
INSERT INTO roles (code, name, description) VALUES
('super_admin', 'Super Admin', 'Full platform control'),
('admin', 'Admin', 'Operational administration'),
('support_staff', 'Support Staff', 'Customer support access'),
('compliance_officer', 'Compliance Officer', 'KYC and compliance review'),
('customer', 'Customer', 'End-user customer account');

-- Permissions (core set)
INSERT INTO permissions (code, name, module) VALUES
('users.view', 'View users', 'users'),
('users.block', 'Block users', 'users'),
('users.manage', 'Manage users', 'users'),
('kyc.view', 'View KYC', 'kyc'),
('kyc.approve', 'Approve KYC', 'kyc'),
('kyc.reject', 'Reject KYC', 'kyc'),
('transactions.view', 'View transactions', 'transactions'),
('transactions.manage', 'Manage transactions', 'transactions'),
('transactions.refund', 'Refund transactions', 'transactions'),
('currencies.view', 'View currencies', 'currencies'),
('currencies.manage', 'Manage currencies & rates', 'currencies'),
('fees.manage', 'Manage fees', 'fees'),
('reports.view', 'View reports', 'reports'),
('settings.manage', 'Manage settings', 'settings'),
('audit.view', 'View audit logs', 'audit'),
('wallets.view', 'View wallets', 'wallets'),
('wallets.manage', 'Manage wallets', 'wallets');

-- Map permissions to roles
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p WHERE r.code = 'super_admin';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r
JOIN permissions p ON p.code IN (
  'users.view','users.block','kyc.view','kyc.approve','kyc.reject',
  'transactions.view','transactions.manage','transactions.refund',
  'currencies.view','currencies.manage','fees.manage','reports.view','wallets.view'
) WHERE r.code = 'admin';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r
JOIN permissions p ON p.code IN (
  'users.view','transactions.view','kyc.view','reports.view'
) WHERE r.code = 'support_staff';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r
JOIN permissions p ON p.code IN (
  'users.view','kyc.view','kyc.approve','kyc.reject','transactions.view','audit.view'
) WHERE r.code = 'compliance_officer';

-- Currencies
INSERT INTO currencies (code, name, symbol, decimal_places, is_active, is_source, is_destination, sort_order) VALUES
('AED', 'UAE Dirham', 'Ø¯.Ø¥', 2, 1, 1, 1, 10),
('USD', 'US Dollar', '$', 2, 1, 1, 1, 20),
('INR', 'Indian Rupee', 'â‚¹', 2, 1, 0, 1, 30),
('PKR', 'Pakistani Rupee', 'Rs', 2, 1, 0, 1, 40),
('EUR', 'Euro', 'â‚¬', 2, 1, 1, 1, 50),
('GBP', 'British Pound', 'Â£', 2, 1, 1, 1, 60);

-- Sample exchange rates
INSERT INTO exchange_rates (source_currency, target_currency, market_rate, margin, customer_rate, provider, effective_from, is_active) VALUES
('AED', 'INR', 22.50000000, 0.150000, 22.35000000, 'manual', NOW(3), 1),
('AED', 'PKR', 76.20000000, 0.400000, 75.80000000, 'manual', NOW(3), 1),
('AED', 'USD', 0.27230000, 0.001500, 0.27080000, 'manual', NOW(3), 1),
('USD', 'INR', 83.10000000, 0.350000, 82.75000000, 'manual', NOW(3), 1),
('USD', 'PKR', 278.50000000, 1.200000, 277.30000000, 'manual', NOW(3), 1),
('EUR', 'INR', 90.20000000, 0.400000, 89.80000000, 'manual', NOW(3), 1),
('GBP', 'INR', 105.50000000, 0.500000, 105.00000000, 'manual', NOW(3), 1);

-- Default fees
INSERT INTO fees (name, fee_type, source_currency, target_currency, flat_amount, percent_value, min_fee, max_fee, min_amount, max_amount, is_active, priority) VALUES
('AED to INR Standard', 'flat', 'AED', 'INR', 15.0000, NULL, NULL, NULL, 50.0000, 50000.0000, 1, 10),
('AED to PKR Standard', 'flat', 'AED', 'PKR', 15.0000, NULL, NULL, NULL, 50.0000, 50000.0000, 1, 10),
('USD Corridor Percent', 'percent', 'USD', NULL, NULL, 1.2500, 2.0000, 50.0000, 20.0000, 100000.0000, 1, 20),
('Default Flat Fee', 'flat', NULL, NULL, 10.0000, NULL, NULL, NULL, 10.0000, NULL, 1, 100);

-- Platform settings
INSERT INTO settings (setting_key, setting_value, value_type, group_name, description) VALUES
('app.name', 'XMONEY', 'string', 'general', 'Application name'),
('app.default_source_currency', 'AED', 'string', 'transfer', 'Default send currency'),
('transfer.min_amount_aed', '50', 'number', 'transfer', 'Minimum transfer amount in AED'),
('transfer.max_amount_aed', '50000', 'number', 'transfer', 'Maximum transfer amount in AED'),
('transfer.daily_limit_aed', '100000', 'number', 'transfer', 'Daily cumulative transfer limit in AED'),
('kyc.required_for_transfer', 'true', 'boolean', 'kyc', 'Require approved KYC before transfer'),
('security.jwt_access_ttl_minutes', '15', 'number', 'security', 'Access token lifetime'),
('security.jwt_refresh_ttl_days', '30', 'number', 'security', 'Refresh token lifetime'),
('security.max_login_attempts', '5', 'number', 'security', 'Lock account after N failed logins'),
('security.lockout_minutes', '30', 'number', 'security', 'Account lockout duration'),
('otp.expiry_minutes', '10', 'number', 'security', 'OTP expiry'),
('exchange.default_margin', '0.15', 'number', 'exchange', 'Default margin when creating rates'),
('notifications.email_enabled', 'true', 'boolean', 'notifications', 'Enable email notifications'),
('notifications.sms_enabled', 'false', 'boolean', 'notifications', 'Enable SMS notifications'),
('notifications.push_enabled', 'false', 'boolean', 'notifications', 'Enable push notifications');

-- Default Super Admin row (password set via: php backend-api/scripts/seed-admin.php)
-- Temporary bcrypt for "ChangeMe@XMONEY2026" â€” always re-run seed-admin.php after import
INSERT INTO admin_users (uuid, email, password_hash, full_name, role_id, status)
SELECT
  UUID(),
  'admin@xmoney.local',
  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  'XMONEY Super Admin',
  id,
  'active'
FROM roles WHERE code = 'super_admin' LIMIT 1;

