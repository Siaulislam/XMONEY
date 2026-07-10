<?php

declare(strict_types=1);

/**
 * XMONEY API — Front Controller
 */

use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Middleware\CorsMiddleware;
use XMoney\Middleware\RequestIdMiddleware;
use XMoney\Middleware\SecurityHeadersMiddleware;
use XMoney\Utils\I18n;
use XMoney\Utils\Response;
use XMoney\Utils\Router;

require dirname(__DIR__) . '/vendor/autoload.php';

App::bootstrap(dirname(__DIR__));

header('Content-Type: application/json; charset=utf-8');
SecurityHeadersMiddleware::apply();

$requestId = RequestIdMiddleware::handle();
CorsMiddleware::handle();

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    Database::connection();
    // DEVELOPMENT ONLY - REMOVE BEFORE PRODUCTION
    \XMoney\Services\DevAuthBootstrap::syncState();
    $router = require dirname(__DIR__) . '/src/routes/api.php';
    /** @var Router $router */
    $router->dispatch($_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI'] ?? '/');
} catch (Throwable $e) {
    $debug = App::env('APP_DEBUG', 'false') === 'true';
    Response::error(
        I18n::t('response.internal_error', [], I18n::locale()),
        500,
        $debug ? ['exception' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()] : [],
        $requestId
    );
}
