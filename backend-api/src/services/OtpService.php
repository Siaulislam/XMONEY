<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Utils\Security;

final class OtpService
{
    public function __construct(private readonly NotificationService $notifications = new NotificationService())
    {
    }

    public function issue(?int $userId, string $channel, string $destination, string $purpose): array
    {
        $otp = Security::generateOtp(6);
        $minutes = max(1, (int) (App::env('OTP_EXPIRY_MINUTES', '10') ?? '10'));
        $expires = (new \DateTimeImmutable("+{$minutes} minutes"))->format('Y-m-d H:i:s.v');

        $pdo = Database::connection();

        // Invalidate prior unused OTPs for same destination + purpose
        $pdo->prepare(
            'UPDATE otp_verifications
             SET verified_at = NOW(3), attempts = max_attempts
             WHERE destination = :destination AND purpose = :purpose
               AND verified_at IS NULL AND expires_at > NOW(3)'
        )->execute([
            'destination' => $destination,
            'purpose' => $purpose,
        ]);

        $stmt = $pdo->prepare(
            'INSERT INTO otp_verifications (user_id, channel, destination, purpose, otp_hash, expires_at)
             VALUES (:user_id, :channel, :destination, :purpose, :otp_hash, :expires_at)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'channel' => $channel,
            'destination' => $destination,
            'purpose' => $purpose,
            'otp_hash' => Security::hashToken($otp),
            'expires_at' => $expires,
        ]);

        $this->notifications->sendOtp($channel, $destination, $otp, $purpose);

        $payload = [
            'destination' => $this->maskDestination($channel, $destination),
            'expires_in_minutes' => $minutes,
            'channel' => $channel,
        ];

        if (App::isDebug()) {
            $payload['debug_otp'] = $otp;
        }

        return $payload;
    }

    public function verify(string $destination, string $purpose, string $otp): bool
    {
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT * FROM otp_verifications
             WHERE destination = :destination AND purpose = :purpose
               AND verified_at IS NULL AND expires_at > NOW(3)
             ORDER BY id DESC LIMIT 1'
        );
        $stmt->execute(['destination' => $destination, 'purpose' => $purpose]);
        $row = $stmt->fetch();
        if (!$row) {
            return false;
        }

        if ((int) $row['attempts'] >= (int) $row['max_attempts']) {
            return false;
        }

        if (!hash_equals($row['otp_hash'], Security::hashToken($otp))) {
            $pdo->prepare('UPDATE otp_verifications SET attempts = attempts + 1 WHERE id = :id')
                ->execute(['id' => $row['id']]);
            return false;
        }

        $pdo->prepare('UPDATE otp_verifications SET verified_at = NOW(3) WHERE id = :id')
            ->execute(['id' => $row['id']]);

        return true;
    }

    private function maskDestination(string $channel, string $destination): string
    {
        if ($channel === 'email') {
            $parts = explode('@', $destination);
            if (count($parts) !== 2) {
                return '***';
            }
            return substr($parts[0], 0, 2) . '***@' . $parts[1];
        }
        $len = strlen($destination);
        return str_repeat('*', max(0, $len - 4)) . substr($destination, -4);
    }
}
