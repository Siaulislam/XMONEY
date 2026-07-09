<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Utils\Response;

final class HealthController
{
    public function check(array $request): void
    {
        $dbOk = false;
        $dbError = null;
        try {
            Database::connection()->query('SELECT 1');
            $dbOk = true;
        } catch (\Throwable $e) {
            $dbError = App::isDebug() ? $e->getMessage() : 'unavailable';
        }

        Response::success([
            'app' => App::env('APP_NAME', 'XMONEY'),
            'env' => App::env('APP_ENV', 'local'),
            'status' => $dbOk ? 'healthy' : 'degraded',
            'database' => $dbOk ? 'ok' : 'error',
            'database_error' => $dbError,
            'time' => date('c'),
            'version' => '0.1.0',
        ]);
    }
}
