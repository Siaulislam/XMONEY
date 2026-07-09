<?php

declare(strict_types=1);

namespace XMoney\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Utils\Security;

/**
 * Production session lifecycle: access JWT + rotating refresh tokens.
 */
final class AuthService
{
    public function issueAccessToken(array $claims, string $audience = 'customer'): string
    {
        $now = time();
        $ttl = (int) (App::env('JWT_ACCESS_TTL_MINUTES', '15') ?? '15');
        $payload = array_merge($claims, [
            'iss' => App::env('JWT_ISSUER', 'xmoney-api'),
            'aud' => $audience,
            'iat' => $now,
            'nbf' => $now,
            'exp' => $now + max(60, $ttl * 60),
            'jti' => Security::uuid(),
        ]);

        return JWT::encode($payload, $this->secret(), 'HS256');
    }

    public function decodeToken(string $token): object
    {
        return JWT::decode($token, new Key($this->secret(), 'HS256'));
    }

    public function createRefreshToken(?int $userId, ?int $adminId = null, ?int $deviceId = null): string
    {
        $raw = Security::randomToken(48);
        $hash = Security::hashToken($raw);
        $days = (int) (App::env('JWT_REFRESH_TTL_DAYS', '30') ?? '30');
        $expires = (new \DateTimeImmutable("+{$days} days"))->format('Y-m-d H:i:s.v');

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'INSERT INTO refresh_tokens (user_id, admin_user_id, token_hash, device_id, expires_at)
             VALUES (:user_id, :admin_user_id, :token_hash, :device_id, :expires_at)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'admin_user_id' => $adminId,
            'token_hash' => $hash,
            'device_id' => $deviceId,
            'expires_at' => $expires,
        ]);

        return $raw;
    }

    /**
     * @return array<string,mixed>|null
     */
    public function findValidRefreshToken(string $rawToken): ?array
    {
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT * FROM refresh_tokens
             WHERE token_hash = :hash
               AND revoked_at IS NULL
               AND expires_at > NOW(3)
             LIMIT 1'
        );
        $stmt->execute(['hash' => Security::hashToken($rawToken)]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    /**
     * Rotate refresh token (revoke old, issue new) and return new access + refresh.
     *
     * @return array{access_token:string,refresh_token:string,token_type:string,actor:array}
     */
    public function rotateRefreshToken(string $rawToken): array
    {
        $row = $this->findValidRefreshToken($rawToken);
        if (!$row) {
            throw new \RuntimeException('Invalid or expired refresh token');
        }

        $this->revokeRefreshToken($rawToken);

        $pdo = Database::connection();

        if (!empty($row['user_id'])) {
            $stmt = $pdo->prepare(
                'SELECT u.*, r.code AS role_code FROM users u
                 JOIN roles r ON r.id = u.role_id
                 WHERE u.id = :id AND u.deleted_at IS NULL LIMIT 1'
            );
            $stmt->execute(['id' => $row['user_id']]);
            $user = $stmt->fetch();
            if (!$user || $user['status'] !== 'active') {
                throw new \RuntimeException('Account is not active');
            }

            $access = $this->issueAccessToken([
                'sub' => (int) $user['id'],
                'email' => $user['email'],
                'role' => $user['role_code'],
                'type' => 'customer',
            ], 'customer');
            $refresh = $this->createRefreshToken(
                (int) $user['id'],
                null,
                $row['device_id'] !== null ? (int) $row['device_id'] : null
            );

            return [
                'access_token' => $access,
                'refresh_token' => $refresh,
                'token_type' => 'Bearer',
                'actor' => [
                    'type' => 'customer',
                    'uuid' => $user['uuid'],
                    'email' => $user['email'],
                    'status' => $user['status'],
                    'kyc_status' => $user['kyc_status'],
                ],
            ];
        }

        if (!empty($row['admin_user_id'])) {
            $stmt = $pdo->prepare(
                'SELECT a.*, r.code AS role_code FROM admin_users a
                 JOIN roles r ON r.id = a.role_id
                 WHERE a.id = :id AND a.deleted_at IS NULL LIMIT 1'
            );
            $stmt->execute(['id' => $row['admin_user_id']]);
            $admin = $stmt->fetch();
            if (!$admin || $admin['status'] !== 'active') {
                throw new \RuntimeException('Admin account is not active');
            }

            $access = $this->issueAccessToken([
                'sub' => (int) $admin['id'],
                'email' => $admin['email'],
                'role' => $admin['role_code'],
                'type' => 'admin',
            ], 'admin');
            $refresh = $this->createRefreshToken(
                null,
                (int) $admin['id'],
                $row['device_id'] !== null ? (int) $row['device_id'] : null
            );

            return [
                'access_token' => $access,
                'refresh_token' => $refresh,
                'token_type' => 'Bearer',
                'actor' => [
                    'type' => 'admin',
                    'uuid' => $admin['uuid'],
                    'email' => $admin['email'],
                    'full_name' => $admin['full_name'],
                    'role' => $admin['role_code'],
                ],
            ];
        }

        throw new \RuntimeException('Invalid refresh token subject');
    }

    public function revokeRefreshToken(string $rawToken): void
    {
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'UPDATE refresh_tokens SET revoked_at = NOW(3)
             WHERE token_hash = :hash AND revoked_at IS NULL'
        );
        $stmt->execute(['hash' => Security::hashToken($rawToken)]);
    }

    public function revokeAllUserRefreshTokens(int $userId): void
    {
        $pdo = Database::connection();
        $pdo->prepare(
            'UPDATE refresh_tokens SET revoked_at = NOW(3)
             WHERE user_id = :uid AND revoked_at IS NULL'
        )->execute(['uid' => $userId]);
    }

    public function revokeAllAdminRefreshTokens(int $adminId): void
    {
        $pdo = Database::connection();
        $pdo->prepare(
            'UPDATE refresh_tokens SET revoked_at = NOW(3)
             WHERE admin_user_id = :aid AND revoked_at IS NULL'
        )->execute(['aid' => $adminId]);
    }

    public function revokeRefreshTokensForDevice(int $deviceId): void
    {
        $pdo = Database::connection();
        $pdo->prepare(
            'UPDATE refresh_tokens SET revoked_at = NOW(3)
             WHERE device_id = :did AND revoked_at IS NULL'
        )->execute(['did' => $deviceId]);
    }

    /**
     * Record failed login and lock account when threshold reached.
     */
    public function recordFailedLogin(int $userId, int $failedCount): void
    {
        $max = (int) (App::env('SECURITY_MAX_LOGIN_ATTEMPTS', '5') ?? '5');
        $lockMinutes = (int) (App::env('SECURITY_LOCKOUT_MINUTES', '30') ?? '30');
        $next = $failedCount + 1;

        $pdo = Database::connection();
        if ($next >= $max) {
            $pdo->prepare(
                'UPDATE users SET failed_login_count = :c,
                 locked_until = DATE_ADD(NOW(3), INTERVAL :mins MINUTE)
                 WHERE id = :id'
            )->execute(['c' => $next, 'mins' => $lockMinutes, 'id' => $userId]);
            return;
        }

        $pdo->prepare('UPDATE users SET failed_login_count = :c WHERE id = :id')
            ->execute(['c' => $next, 'id' => $userId]);
    }

    private function secret(): string
    {
        $secret = App::env('JWT_SECRET');
        if (!$secret || strlen($secret) < 32) {
            throw new \RuntimeException('JWT_SECRET must be configured (min 32 chars)');
        }
        return $secret;
    }
}
