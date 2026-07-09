<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\Database;

final class SettingsService
{
  private static ?array $cache = null;

  public function all(?string $group = null): array
  {
    $pdo = Database::connection();
    $sql = 'SELECT setting_key, setting_value, value_type, group_name, description, updated_at
            FROM settings';
    $params = [];
    if ($group !== null) {
      $sql .= ' WHERE group_name = :group';
      $params['group'] = $group;
    }
    $sql .= ' ORDER BY group_name, setting_key';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return array_map(fn (array $row) => $this->castRow($row), $stmt->fetchAll());
  }

  public function get(string $key, mixed $default = null): mixed
  {
    if (self::$cache === null) {
      $this->warmCache();
    }
    if (!array_key_exists($key, self::$cache)) {
      return $default;
    }
    return self::$cache[$key];
  }

  public function getNumber(string $key, float $default = 0.0): float
  {
    $value = $this->get($key, $default);
    return is_numeric($value) ? (float) $value : $default;
  }

  public function getBool(string $key, bool $default = false): bool
  {
    $value = $this->get($key, $default);
    if (is_bool($value)) {
      return $value;
    }
    return in_array(strtolower((string) $value), ['1', 'true', 'yes', 'on'], true);
  }

  public function updateMany(array $updates, ?int $adminId = null): array
  {
    $pdo = Database::connection();
    $stmt = $pdo->prepare(
      'UPDATE settings SET setting_value = :value, updated_by = :admin, updated_at = NOW(3)
       WHERE setting_key = :key'
    );

    foreach ($updates as $key => $value) {
      $key = (string) $key;
      $stmt->execute([
        'value' => $this->serializeValue($key, $value),
        'admin' => $adminId,
        'key' => $key,
      ]);
    }

    self::$cache = null;
    return $this->all();
  }

  private function warmCache(): void
  {
    self::$cache = [];
    foreach ($this->all() as $row) {
      self::$cache[$row['setting_key']] = $row['setting_value'];
    }
  }

  private function castRow(array $row): array
  {
    $row['setting_value'] = $this->castValue($row['value_type'], $row['setting_value']);
    return $row;
  }

  private function castValue(string $type, ?string $value): mixed
  {
    return match ($type) {
      'number' => $value === null ? null : (float) $value,
      'boolean' => in_array(strtolower((string) $value), ['1', 'true', 'yes', 'on'], true),
      'json' => $value ? json_decode($value, true) : null,
      default => $value,
    };
  }

  private function serializeValue(string $key, mixed $value): string
  {
    $pdo = Database::connection();
    $stmt = $pdo->prepare('SELECT value_type FROM settings WHERE setting_key = :key LIMIT 1');
    $stmt->execute(['key' => $key]);
    $type = $stmt->fetchColumn() ?: 'string';

    return match ($type) {
      'boolean' => $value ? 'true' : 'false',
      'json' => json_encode($value),
      default => (string) $value,
    };
  }
}
