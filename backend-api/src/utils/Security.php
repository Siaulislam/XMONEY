<?php

declare(strict_types=1);

namespace XMoney\Utils;

use Ramsey\Uuid\Uuid;

final class Security
{
    public static function hashPassword(string $password): string
    {
        $cost = (int) (\XMoney\Config\App::env('BCRYPT_COST', '12') ?? '12');
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => max(10, min($cost, 14))]);
    }

    public static function verifyPassword(string $password, string $hash): bool
    {
        return password_verify($password, $hash);
    }

    public static function hashToken(string $token): string
    {
        return hash('sha256', $token);
    }

    public static function randomToken(int $bytes = 32): string
    {
        return bin2hex(random_bytes($bytes));
    }

    public static function uuid(): string
    {
        return Uuid::uuid4()->toString();
    }

    public static function generateOtp(int $digits = 6): string
    {
        $max = (10 ** $digits) - 1;
        return str_pad((string) random_int(0, $max), $digits, '0', STR_PAD_LEFT);
    }

    public static function clientIp(): string
    {
        return $_SERVER['HTTP_X_FORWARDED_FOR']
            ?? $_SERVER['REMOTE_ADDR']
            ?? '0.0.0.0';
    }

    public static function userAgent(): string
    {
        return substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 500);
    }
}
