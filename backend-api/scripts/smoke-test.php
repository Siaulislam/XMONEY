<?php

declare(strict_types=1);

/**
 * XMONEY API smoke & integration test suite.
 *
 * Usage:
 *   php scripts/smoke-test.php
 *   php scripts/smoke-test.php https://qamar.tasjeel.ae/api
 *
 * Optional env:
 *   XMONEY_API_BASE, XMONEY_ADMIN_EMAIL, XMONEY_ADMIN_PASSWORD
 *   XMONEY_TEST_EMAIL, XMONEY_TEST_PASSWORD (customer — skips customer tests if unset)
 */

$base = rtrim($argv[1] ?? getenv('XMONEY_API_BASE') ?: 'http://localhost:8080', '/');

function request(string $method, string $url, ?array $body = null, array $headers = []): array
{
    $ch = curl_init($url);
    $hdrs = array_merge(['Accept: application/json'], $headers);
    if ($body !== null) {
        $hdrs[] = 'Content-Type: application/json';
    }
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $hdrs,
        CURLOPT_TIMEOUT => 25,
        CURLOPT_HEADER => true,
    ]);
    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }
    $raw = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $headerSize = (int) curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    curl_close($ch);
    $respHeaders = substr((string) $raw, 0, $headerSize);
    $respBody = substr((string) $raw, $headerSize);
    $json = json_decode($respBody, true);
    return ['code' => $code, 'json' => $json, 'raw' => $respBody, 'headers' => $respHeaders];
}

$failures = 0;
$pass = function (string $name, bool $ok, string $detail = '') use (&$failures): void {
    echo ($ok ? '[PASS] ' : '[FAIL] ') . $name . ($detail ? " — $detail" : '') . PHP_EOL;
    if (!$ok) {
        $failures++;
    }
};

echo "XMONEY API test suite → {$base}\n\n";

// --- Public endpoints ---
$health = request('GET', "{$base}/v1/health");
$pass('GET /v1/health', $health['code'] === 200 && ($health['json']['success'] ?? false));

$secHeaders = $health['headers'] ?? '';
$pass('Security: X-Content-Type-Options', str_contains($secHeaders, 'X-Content-Type-Options: nosniff'));
$pass('Security: X-Frame-Options', str_contains($secHeaders, 'X-Frame-Options: DENY'));

$currencies = request('GET', "{$base}/v1/currencies");
$pass('GET /v1/currencies', $currencies['code'] === 200 && is_array($currencies['json']['data'] ?? null));

$rates = request('GET', "{$base}/v1/rates");
$pass('GET /v1/rates', $rates['code'] === 200 && is_array($rates['json']['data'] ?? null));

$public = request('GET', "{$base}/v1/settings/public");
$pass('GET /v1/settings/public', $public['code'] === 200 && is_array($public['json']['data'] ?? null));

$unauth = request('GET', "{$base}/v1/me");
$pass('GET /v1/me without token → 401', $unauth['code'] === 401);

// --- Admin ---
$adminLogin = request('POST', "{$base}/v1/admin/auth/login", [
    'email' => getenv('XMONEY_ADMIN_EMAIL') ?: 'admin@xmoney.local',
    'password' => getenv('XMONEY_ADMIN_PASSWORD') ?: 'ChangeMe@XMONEY2026',
]);
$adminToken = $adminLogin['json']['data']['access_token'] ?? null;
$pass('POST /v1/admin/auth/login', $adminLogin['code'] === 200 && $adminToken !== null, $adminLogin['json']['message'] ?? '');

if ($adminToken) {
    $auth = ["Authorization: Bearer {$adminToken}"];
    foreach ([
        'GET /v1/admin/dashboard' => "{$base}/v1/admin/dashboard",
        'GET /v1/admin/analytics' => "{$base}/v1/admin/analytics?days=7",
        'GET /v1/admin/users' => "{$base}/v1/admin/users?limit=5",
        'GET /v1/admin/transactions' => "{$base}/v1/admin/transactions?limit=5",
        'GET /v1/admin/payments' => "{$base}/v1/admin/payments?limit=5",
        'GET /v1/admin/kyc/pending' => "{$base}/v1/admin/kyc/pending",
        'GET /v1/admin/settings' => "{$base}/v1/admin/settings",
        'GET /v1/admin/audit-logs' => "{$base}/v1/admin/audit-logs?limit=5",
    ] as $label => $url) {
        $r = request('GET', $url, null, $auth);
        $pass($label, $r['code'] === 200 && ($r['json']['success'] ?? false));
    }
}

// --- Customer (optional) ---
$customerEmail = getenv('XMONEY_TEST_EMAIL') ?: '';
$customerPass = getenv('XMONEY_TEST_PASSWORD') ?: '';
if ($customerEmail && $customerPass) {
    $login = request('POST', "{$base}/v1/auth/login", [
        'email' => $customerEmail,
        'password' => $customerPass,
    ]);
    $token = $login['json']['data']['access_token'] ?? null;
    $pass('POST /v1/auth/login (customer)', $login['code'] === 200 && $token !== null);

    if ($token) {
        $auth = ["Authorization: Bearer {$token}"];
        foreach ([
            'GET /v1/me' => "{$base}/v1/me",
            'GET /v1/wallet' => "{$base}/v1/wallet",
            'GET /v1/wallet/history' => "{$base}/v1/wallet/history?limit=5",
            'GET /v1/wallets' => "{$base}/v1/wallets",
            'GET /v1/beneficiaries' => "{$base}/v1/beneficiaries",
            'GET /v1/transfers' => "{$base}/v1/transfers?limit=5",
            'GET /v1/notifications' => "{$base}/v1/notifications?limit=5",
            'GET /v1/kyc' => "{$base}/v1/kyc",
            'GET /v1/analytics/summary' => "{$base}/v1/analytics/summary",
        ] as $label => $url) {
            $r = request('GET', $url, null, $auth);
            $pass($label, $r['code'] === 200 && ($r['json']['success'] ?? false));
        }
    }
} else {
    echo "[SKIP] Customer authenticated tests — set XMONEY_TEST_EMAIL and XMONEY_TEST_PASSWORD\n";
}

echo "\n" . ($failures === 0 ? 'All checks passed.' : "{$failures} check(s) failed.") . PHP_EOL;
exit($failures > 0 ? 1 : 0);
