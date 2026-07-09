<?php

declare(strict_types=1);

namespace XMoney\Middleware;

use XMoney\Utils\Security;

final class RequestIdMiddleware
{
    public static function handle(): string
    {
        $id = $_SERVER['HTTP_X_REQUEST_ID'] ?? Security::randomToken(16);
        $_SERVER['HTTP_X_REQUEST_ID'] = $id;
        header('X-Request-Id: ' . $id);
        return $id;
    }
}
