-- Add daily transfer limit setting (safe to re-run)
INSERT INTO settings (setting_key, setting_value, value_type, group_name, description)
SELECT 'transfer.daily_limit_aed', '100000', 'number', 'transfer', 'Daily cumulative transfer limit in AED'
WHERE NOT EXISTS (
  SELECT 1 FROM settings WHERE setting_key = 'transfer.daily_limit_aed'
);
