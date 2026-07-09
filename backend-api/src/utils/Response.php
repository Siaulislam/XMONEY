<?php

declare(strict_types=1);

namespace XMoney\Utils;

final class Response
{
    public static function text(string $key, array $params = [], ?array $request = null, ?string $locale = null): string
    {
        return I18n::t($key, $params, $locale ?? I18n::locale($request));
    }

    public static function json(array $payload, int $status = 200, ?string $requestId = null): void
    {
        http_response_code($status);
        if ($requestId) {
            header('X-Request-Id: ' . $requestId);
        }
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function success(
        mixed $data = null,
        string $message = 'OK',
        int $status = 200,
        ?string $requestId = null,
        ?array $request = null
    ): void
    {
        self::json([
            'success' => true,
            'message' => $message,
            'data' => $data,
            'request_id' => $requestId ?? ($_SERVER['HTTP_X_REQUEST_ID'] ?? null),
        ], $status, $requestId);
    }

    public static function error(
        string $message,
        int $status = 400,
        array $errors = [],
        ?string $requestId = null,
        ?array $request = null
    ): void
    {
        self::json([
            'success' => false,
            'message' => $message,
            'errors' => $errors ?: null,
            'request_id' => $requestId ?? ($_SERVER['HTTP_X_REQUEST_ID'] ?? null),
        ], $status, $requestId);
    }
}
