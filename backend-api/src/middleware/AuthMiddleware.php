<?php

declare(strict_types=1);

namespace XMoney\Middleware;

use XMoney\Services\AuthService;
use XMoney\Utils\Response;

final class AuthMiddleware
{
    public static function customer(): callable
    {
        return static function (array $request, callable $next) {
            $payload = self::bearerPayload();
            if (!$payload || ($payload->type ?? '') !== 'customer') {
                Response::error('Unauthorized', 401);
            }
            $request['user'] = [
                'id' => (int) $payload->sub,
                'email' => $payload->email ?? null,
                'role' => $payload->role ?? 'customer',
            ];
            return $next($request);
        };
    }

    public static function admin(array $allowedRoles = []): callable
    {
        return static function (array $request, callable $next) use ($allowedRoles) {
            $payload = self::bearerPayload();
            if (!$payload || ($payload->type ?? '') !== 'admin') {
                Response::error('Unauthorized', 401);
            }
            $role = $payload->role ?? '';
            if ($allowedRoles && !in_array($role, $allowedRoles, true)) {
                Response::error('Forbidden', 403);
            }
            $request['admin'] = [
                'id' => (int) $payload->sub,
                'email' => $payload->email ?? null,
                'role' => $role,
            ];
            return $next($request);
        };
    }

    private static function bearerPayload(): ?object
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
        if (!preg_match('/Bearer\s+(\S+)/i', $header, $m)) {
            return null;
        }
        try {
            return (new AuthService())->decodeToken($m[1]);
        } catch (\Throwable) {
            return null;
        }
    }
}
