<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Utils\Security;

/**
 * DEVELOPMENT ONLY - REMOVE BEFORE PRODUCTION
 *
 * Temporary dev test user + OTP bypass support. Kept in codebase for later use.
 * Currently DISABLED by default (DEV_AUTH_BYPASS_ENABLED=false).
 *
 * To re-enable during development:
 *   1. Set DEV_AUTH_BYPASS_ENABLED=true in api/.env
 *   2. Ensure APP_ENV is staging, development, or local (not production)
 *   3. Test user is auto-created on first API request
 */
final class DevAuthBootstrap
{
    private const DEV_EMAIL = 'ziassp91@gmai.com';
    private const DEV_PASSWORD = '123456';
    private const DEV_NAME = 'Dev Test User';
    private const DEV_MOBILE_COUNTRY = '+971';
    private const DEV_MOBILE_NUMBER = '500000091';

    public static function ensureTestUser(): void
    {
        if (!App::allowsOtpBypass()) {
            return;
        }

        $pdo = Database::connection();
        $email = strtolower(self::DEV_EMAIL);

        $stmt = $pdo->prepare('SELECT id, status FROM users WHERE email = :email AND deleted_at IS NULL LIMIT 1');
        $stmt->execute(['email' => $email]);
        $existing = $stmt->fetch();

        if ($existing) {
            $pdo->prepare(
                "UPDATE users
                 SET status = 'active',
                     email_verified_at = COALESCE(email_verified_at, NOW(3)),
                     password_hash = :pwd
                 WHERE id = :id"
            )->execute([
                'pwd' => Security::hashPassword(self::DEV_PASSWORD),
                'id' => $existing['id'],
            ]);
            return;
        }

        $roleId = (int) $pdo->query("SELECT id FROM roles WHERE code = 'customer' LIMIT 1")->fetchColumn();
        if (!$roleId) {
            return;
        }

        $uuid = Security::uuid();
        $pdo->beginTransaction();
        try {
            $pdo->prepare(
                "INSERT INTO users (uuid, email, mobile_country, mobile_number, password_hash, status, email_verified_at, role_id)
                 VALUES (:uuid, :email, :mc, :mn, :pwd, 'active', NOW(3), :role)"
            )->execute([
                'uuid' => $uuid,
                'email' => $email,
                'mc' => self::DEV_MOBILE_COUNTRY,
                'mn' => self::DEV_MOBILE_NUMBER,
                'pwd' => Security::hashPassword(self::DEV_PASSWORD),
                'role' => $roleId,
            ]);
            $userId = (int) $pdo->lastInsertId();

            $pdo->prepare(
                'INSERT INTO profiles (user_id, full_name, country_code, city, address_line1)
                 VALUES (:uid, :name, :country, :city, :address)'
            )->execute([
                'uid' => $userId,
                'name' => self::DEV_NAME,
                'country' => 'AE',
                'city' => 'Dubai',
                'address' => 'Dev seed address',
            ]);

            (new WalletService())->getOrCreate($userId, 'AED');
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }
}
