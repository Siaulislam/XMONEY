<?php

declare(strict_types=1);

/**
 * XMONEY API smoke test — run against local or deployed API.
 *
 * Usage:
 *   php scripts/smoke-test.php
 *   php scripts/smoke-test.php https://qamar.tasjeel.ae/xmoney/api
 */

$base = rtrim($argv[1] ?? getenv('XMONEY_API_BASE') ?: 'http://localhost:8080', '/');

function request(string $method, string $url, ?array $body = null, array $headers = []): array
{
    $ch = curl_init($url);
    $hdrs = array_merge(['Accept: application/json'], $headers);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $hdrs,
        CURLOPT_TIMEOUT => 20,
    ]);
    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
        $hdrs[] = 'Content-Type: application/json';
        curl_setopt($ch, CURLOPT_HTTPHEADER, $hdrs);
    }
    $raw = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode((string) $raw, true);
    return ['code' => $code, 'json' => $json, 'raw' => $raw];
}

$failures = 0;
$pass = function (string $name, bool $ok, string $detail = '') use (&$failures): void {
    echo ($ok ? '[PASS] ' : '[FAIL] ') . $name . ($detail ? " — $detail" : '') . PHP_EOL;
    if (!$ok) {
        $failures++;
    }
};

echo "XMONEY smoke test → {$base}\n\n";

$health = request('GET', "{$base}/v1/health");
$pass('GET /v1/health', $health['code'] === 200 && ($health['json']['success'] ?? false));

$currencies = request('GET', "{$base}/v1/currencies");
$pass('GET /v1/currencies', $currencies['code'] === 200 && is_array($currencies['json']['data'] ?? null));

$rates = request('GET', "{$base}/v1/rates");
$pass('GET /v1/rates', $rates['code'] === 200 && is_array($rates['json']['data'] ?? null));

$public = request('GET', "{$base}/v1/settings/public");
$pass('GET /v1/settings/public', $public['code'] === 200 && is_array($public['json']['data'] ?? null));

$adminLogin = request('POST', "{$base}/v1/admin/auth/login", [
    'email' => getenv('XMONEY_ADMIN_EMAIL') ?: 'admin@xmoney.local',
    'password' => getenv('XMONEY_ADMIN_PASSWORD') ?: 'ChangeMe@XMONEY2026',
]);
$token = $adminLogin['json']['data']['access_token'] ?? null;
$pass('POST /v1/admin/auth/login', $adminLogin['code'] === 200 && $token !== null, $adminLogin['json']['message'] ?? '');

if ($token) {
    $dash = request('GET', "{$base}/v1/admin/dashboard", null, ["Authorization: Bearer {$token}"]);
    $pass('GET /v1/admin/dashboard', $dash['code'] === 200 && ($dash['json']['success'] ?? false));
}

echo "\n" . ($failures === 0 ? 'All checks passed.' : "{$failures} check(s) failed.") . PHP_EOL;
exit($failures > 0 ? 1 : 0);
