<?php

declare(strict_types=1);

namespace XMoney\Utils;

use XMoney\Utils\Response;

final class Router
{
    /** @var array<int, array{method:string,pattern:string,handler:callable,middleware:array}> */
    private array $routes = [];

    public function add(string $method, string $pattern, callable $handler, array $middleware = []): void
    {
        $this->routes[] = [
            'method' => strtoupper($method),
            'pattern' => $pattern,
            'handler' => $handler,
            'middleware' => $middleware,
        ];
    }

    public function get(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('GET', $pattern, $handler, $middleware);
    }

    public function post(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('POST', $pattern, $handler, $middleware);
    }

    public function put(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('PUT', $pattern, $handler, $middleware);
    }

    public function patch(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('PATCH', $pattern, $handler, $middleware);
    }

    public function delete(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('DELETE', $pattern, $handler, $middleware);
    }

    public function dispatch(string $method, string $uri): void
    {
        $path = parse_url($uri, PHP_URL_PATH) ?: '/';
        $path = self::normalizePath($path);

        $method = strtoupper($method);

        foreach ($this->routes as $route) {
            if ($route['method'] !== $method) {
                continue;
            }

            $regex = '@^' . preg_replace('@\{([a-zA-Z_]+)\}@', '(?P<$1>[^/]+)', $route['pattern']) . '$@';
            if (!preg_match($regex, $path, $matches)) {
                continue;
            }

            $params = array_filter(
                $matches,
                static fn ($k) => !is_int($k),
                ARRAY_FILTER_USE_KEY
            );

            $request = [
                'method' => $method,
                'path' => $path,
                'params' => $params,
                'query' => $_GET,
                'body' => self::parseBody(),
                'user' => null,
                'admin' => null,
            ];

            $handler = $route['handler'];
            foreach (array_reverse($route['middleware']) as $mw) {
                $next = $handler;
                $handler = static function (array $req) use ($mw, $next) {
                    return $mw($req, $next);
                };
            }

            $handler($request);
            return;
        }

        Response::error('Endpoint not found', 404);
    }

    private static function parseBody(): array
    {
        $contentType = $_SERVER['CONTENT_TYPE'] ?? $_SERVER['HTTP_CONTENT_TYPE'] ?? '';
        if (str_contains($contentType, 'application/json')) {
            $raw = file_get_contents('php://input') ?: '';
            $decoded = json_decode($raw, true);
            return is_array($decoded) ? $decoded : [];
        }
        return array_merge($_POST, $_GET);
    }

    /**
     * Normalize paths for local (/v1/...) and cPanel (/api/v1/...).
     */
    private static function normalizePath(string $path): string
    {
        // Strip known deployment prefixes until /v1 or /
        $prefixes = [
            '/api/public',
            '/api',
        ];
        foreach ($prefixes as $prefix) {
            if (str_starts_with($path, $prefix)) {
                $path = substr($path, strlen($prefix)) ?: '/';
                break;
            }
        }
        if ($path === '' || $path[0] !== '/') {
            $path = '/' . ltrim($path, '/');
        }
        return $path;
    }
}
