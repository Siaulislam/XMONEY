<?php

declare(strict_types=1);

namespace XMoney\Middleware;

use XMoney\Config\App;
use XMoney\Utils\Response;
use XMoney\Utils\Security;

/**
 * Simple file-backed rate limiter for auth-sensitive endpoints.
 * Suitable for single-server cPanel; swap for Redis later at scale.
 */
final class RateLimitMiddleware
{
    public static function handle(string $bucket, ?int $maxPerMinute = null): void
    {
        $max = $maxPerMinute ?? (int) (App::env('RATE_LIMIT_PER_MINUTE', '60') ?? '60');
        $ip = Security::clientIp();
        $key = hash('sha256', $bucket . '|' . $ip);
        $dir = App::basePath('../logs/rate-limit');
        if (!is_dir($dir)) {
            @mkdir($dir, 0755, true);
        }
        $file = $dir . DIRECTORY_SEPARATOR . $key . '.json';
        $now = time();
        $window = 60;

        $data = ['start' => $now, 'count' => 0];
        if (is_file($file)) {
            $raw = @file_get_contents($file);
            $decoded = $raw ? json_decode($raw, true) : null;
            if (is_array($decoded) && isset($decoded['start'], $decoded['count'])) {
                $data = $decoded;
            }
        }

        if (($now - (int) $data['start']) >= $window) {
            $data = ['start' => $now, 'count' => 0];
        }

        $data['count'] = (int) $data['count'] + 1;
        @file_put_contents($file, json_encode($data), LOCK_EX);

        $remaining = max(0, $max - (int) $data['count']);
        header('X-RateLimit-Limit: ' . $max);
        header('X-RateLimit-Remaining: ' . $remaining);

        if ((int) $data['count'] > $max) {
            Response::error('Too many requests. Please try again shortly.', 429);
        }
    }

    public static function forAuth(string $action): callable
    {
        return static function (array $request, callable $next) use ($action) {
            $limits = [
                'login' => 20,
                'register' => 10,
                'otp' => 15,
                'forgot' => 10,
                'resend' => 5,
                'refresh' => 60,
            ];
            self::handle('auth:' . $action, $limits[$action] ?? 30);
            return $next($request);
        };
    }
}
