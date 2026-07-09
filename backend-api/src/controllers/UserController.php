<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\Database;
use XMoney\Services\AuditService;
use XMoney\Services\AuthService;
use XMoney\Utils\Response;
use XMoney\Utils\Security;
use XMoney\Utils\Validator;

final class UserController
{
    public function profile(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT u.uuid, u.email, u.mobile_country, u.mobile_number, u.status, u.kyc_status,
                    u.email_verified_at, u.mobile_verified_at, u.created_at,
                    p.full_name, p.date_of_birth, p.gender, p.nationality, p.country_code,
                    p.city, p.address_line1, p.address_line2, p.postal_code,
                    p.preferred_language, p.preferred_currency
             FROM users u
             JOIN profiles p ON p.user_id = u.id
             WHERE u.id = :id'
        );
        $stmt->execute(['id' => $userId]);
        $profile = $stmt->fetch();
        if (!$profile) {
            Response::error('Profile not found', 404);
        }
        Response::success($profile);
    }

    public function updateProfile(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'full_name' => 'required|min:2|max:200',
            'country_code' => 'required|min:2|max:2',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }

        $pdo = Database::connection();
        $pdo->prepare(
            'UPDATE profiles SET
                full_name = :name,
                country_code = :country,
                city = :city,
                address_line1 = :a1,
                address_line2 = :a2,
                postal_code = :postal,
                preferred_language = COALESCE(:lang, preferred_language),
                preferred_currency = COALESCE(:cur, preferred_currency)
             WHERE user_id = :uid'
        )->execute([
            'name' => trim($body['full_name']),
            'country' => strtoupper($body['country_code']),
            'city' => $body['city'] ?? null,
            'a1' => $body['address_line1'] ?? null,
            'a2' => $body['address_line2'] ?? null,
            'postal' => $body['postal_code'] ?? null,
            'lang' => $body['preferred_language'] ?? null,
            'cur' => isset($body['preferred_currency']) ? strtoupper($body['preferred_currency']) : null,
            'uid' => $userId,
        ]);

        (new AuditService())->log('user', $userId, 'profile.updated', 'user', $userId);
        $this->profile($request);
    }

    public function devices(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT id, device_uuid, device_name, platform, is_trusted, last_seen_at, created_at, revoked_at
             FROM user_devices WHERE user_id = :uid ORDER BY last_seen_at DESC'
        );
        $stmt->execute(['uid' => $userId]);
        Response::success($stmt->fetchAll());
    }

    public function revokeDevice(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $deviceId = (int) ($request['params']['id'] ?? 0);
        $pdo = Database::connection();

        $stmt = $pdo->prepare(
            'SELECT id FROM user_devices WHERE id = :id AND user_id = :uid LIMIT 1'
        );
        $stmt->execute(['id' => $deviceId, 'uid' => $userId]);
        if (!$stmt->fetch()) {
            Response::error('Device not found', 404);
        }

        $pdo->prepare(
            'UPDATE user_devices SET revoked_at = NOW(3) WHERE id = :id AND user_id = :uid AND revoked_at IS NULL'
        )->execute(['id' => $deviceId, 'uid' => $userId]);

        (new AuthService())->revokeRefreshTokensForDevice($deviceId);
        (new AuditService())->log('user', $userId, 'device.revoked', 'user_device', $deviceId);
        Response::success(null, 'Device revoked');
    }

    public function changePassword(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'current_password' => 'required',
            'new_password' => 'required|password',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT password_hash FROM users WHERE id = :id');
        $stmt->execute(['id' => $userId]);
        $user = $stmt->fetch();
        if (!$user || !Security::verifyPassword($body['current_password'], $user['password_hash'])) {
            Response::error('Current password is incorrect', 400);
        }

        $pdo->prepare('UPDATE users SET password_hash = :pwd WHERE id = :id')
            ->execute(['pwd' => Security::hashPassword($body['new_password']), 'id' => $userId]);

        // Invalidate all sessions after password change
        (new AuthService())->revokeAllUserRefreshTokens($userId);
        (new AuditService())->log('user', $userId, 'password.changed', 'user', $userId);
        Response::success(null, 'Password changed. Please sign in again.');
    }
}
