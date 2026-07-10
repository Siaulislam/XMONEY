<?php

declare(strict_types=1);

namespace XMoney\Config;

use Dotenv\Dotenv;

final class App
{
    private static bool $booted = false;
    private static string $basePath = '';

    public static function bootstrap(string $basePath): void
    {
        if (self::$booted) {
            return;
        }

        self::$basePath = $basePath;

        if (is_file($basePath . '/.env')) {
            Dotenv::createImmutable($basePath)->safeLoad();
        }

        date_default_timezone_set(self::env('APP_TIMEZONE', 'Asia/Dubai'));
        self::$booted = true;
    }

    public static function basePath(string $path = ''): string
    {
        return self::$basePath . ($path !== '' ? DIRECTORY_SEPARATOR . ltrim($path, '/\\') : '');
    }

    public static function env(string $key, ?string $default = null): ?string
    {
        $value = $_ENV[$key] ?? $_SERVER[$key] ?? getenv($key);
        if ($value === false || $value === null || $value === '') {
            return $default;
        }
        return (string) $value;
    }

    public static function isDebug(): bool
    {
        return self::env('APP_DEBUG', 'false') === 'true';
    }

    /**
     * DEVELOPMENT ONLY - REMOVE BEFORE PRODUCTION
     * OTP bypass and dev test-user seeding are allowed only outside production APP_ENV.
     */
    public static function allowsOtpBypass(): bool
    {
        if (self::env('APP_ENV', 'production') === 'production') {
            return false;
        }

        $env = self::env('APP_ENV', '');
        return in_array($env, ['development', 'staging', 'local'], true) || self::isDebug();
    }
}
