<?php

declare(strict_types=1);

namespace XMoney\Middleware;

use XMoney\Config\App;

final class CorsMiddleware
{
    public static function handle(): void
    {
        $origins = App::env('CORS_ALLOWED_ORIGINS', '*') ?? '*';
        $requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? '';

        if ($origins === '*') {
            header('Access-Control-Allow-Origin: *');
        } else {
            $allowed = array_map('trim', explode(',', $origins));
            if (in_array($requestOrigin, $allowed, true)) {
                header('Access-Control-Allow-Origin: ' . $requestOrigin);
                header('Vary: Origin');
            }
        }

        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Request-Id, X-Device-Id');
        header('Access-Control-Expose-Headers: X-Request-Id');
        header('Access-Control-Max-Age: 86400');
    }
}
