<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\Database;
use XMoney\Utils\Security;

/**
 * Trusted device registry for session binding.
 */
final class DeviceService
{
    /**
     * Upsert device for a customer and return device row id.
     */
    public function registerOrUpdate(
        int $userId,
        string $deviceUuid,
        string $platform = 'web',
        ?string $deviceName = null
    ): int {
        $deviceUuid = trim($deviceUuid);
        if ($deviceUuid === '') {
            $deviceUuid = Security::uuid();
        }

        $platform = in_array($platform, ['web', 'android', 'ios', 'other'], true) ? $platform : 'web';
        $pdo = Database::connection();

        $stmt = $pdo->prepare(
            'SELECT id, revoked_at FROM user_devices WHERE user_id = :uid AND device_uuid = :duuid LIMIT 1'
        );
        $stmt->execute(['uid' => $userId, 'duuid' => $deviceUuid]);
        $existing = $stmt->fetch();

        if ($existing) {
            $pdo->prepare(
                'UPDATE user_devices SET
                    device_name = COALESCE(:name, device_name),
                    platform = :platform,
                    ip_address = :ip,
                    user_agent = :ua,
                    last_seen_at = NOW(3),
                    revoked_at = NULL
                 WHERE id = :id'
            )->execute([
                'name' => $deviceName,
                'platform' => $platform,
                'ip' => Security::clientIp(),
                'ua' => Security::userAgent(),
                'id' => $existing['id'],
            ]);
            return (int) $existing['id'];
        }

        $pdo->prepare(
            'INSERT INTO user_devices
             (user_id, device_uuid, device_name, platform, ip_address, user_agent, is_trusted, last_seen_at)
             VALUES (:uid, :duuid, :name, :platform, :ip, :ua, 0, NOW(3))'
        )->execute([
            'uid' => $userId,
            'duuid' => $deviceUuid,
            'name' => $deviceName ?: $this->guessName($platform),
            'platform' => $platform,
            'ip' => Security::clientIp(),
            'ua' => Security::userAgent(),
        ]);

        return (int) $pdo->lastInsertId();
    }

    private function guessName(string $platform): string
    {
        return match ($platform) {
            'android' => 'Android device',
            'ios' => 'iOS device',
            default => 'Web browser',
        };
    }
}
