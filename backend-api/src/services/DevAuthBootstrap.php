<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Utils\Security;

/**
 * DEVELOPMENT ONLY - REMOVE BEFORE PRODUCTION
 *
 * Temporary dev test user + OTP bypass support. Kept for later — disabled by default.
 * Credentials are read from .env only (never hardcoded). See config/dev-auth.example.env.
 */
final class DevAuthBootstrap
{
    private const DEV_NAME = 'Dev Test User';
    private const DEV_MOBILE_COUNTRY = '+971';
    private const DEV_MOBILE_SUFFIX = '000091';

    public static function syncState(): void
    {
        $email = self::devEmail();
        if ($email === '') {
            return;
        }

        if (App::allowsOtpBypass()) {
            self::ensureTestUser($email);
            return;
        }

        // DEVELOPMENT ONLY - REMOVE BEFORE PRODUCTION
        // Suspend (do not delete) test account while bypass is off.
        self::suspendTestUser($email);
    }

    private static function devEmail(): string
    {
        return strtolower(trim(App::env('DEV_TEST_EMAIL', '') ?? ''));
    }

    private static function devPassword(): string
    {
        return App::env('DEV_TEST_PASSWORD', '') ?? '';
    }

    private static function suspendTestUser(string $email): void
    {
        $pdo = Database::connection();
        $pdo->prepare(
            "UPDATE users SET status = 'suspended'
             WHERE email = :email AND deleted_at IS NULL AND status <> 'suspended'"
        )->execute(['email' => $email]);
    }

    private static function ensureTestUser(string $email): void
    {
        $password = self::devPassword();
        if ($password === '') {
            return;
        }

        $pdo = Database::connection();

        $stmt = $pdo->prepare('SELECT id FROM users WHERE email = :email AND deleted_at IS NULL LIMIT 1');
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
                'pwd' => Security::hashPassword($password),
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
                'mn' => self::DEV_MOBILE_SUFFIX,
                'pwd' => Security::hashPassword($password),
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
