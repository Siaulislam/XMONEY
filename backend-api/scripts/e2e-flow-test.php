<?php

declare(strict_types=1);

/**
 * XMONEY API end-to-end flow test (write operations).
 * Requires APP_DEBUG=true for OTP debug + wallet auto-capture.
 *
 * Usage:
 *   php scripts/e2e-flow-test.php
 *   php scripts/e2e-flow-test.php https://qamar.tasjeel.ae/api
 */

$base = rtrim($argv[1] ?? getenv('XMONEY_API_BASE') ?: 'http://localhost:8080', '/');
$device = 'e2e-' . bin2hex(random_bytes(8));
$email = getenv('XMONEY_E2E_EMAIL') ?: ('e2e+' . time() . '@xmoney.test');
$password = getenv('XMONEY_E2E_PASSWORD') ?: 'Test@XMONEY2026!';

function req(string $method, string $url, ?array $body = null, ?string $token = null, string $device = ''): array
{
    $ch = curl_init($url);
    $hdrs = ['Accept: application/json', 'Content-Type: application/json', 'X-Device-Id: ' . $device];
    if ($token) {
        $hdrs[] = 'Authorization: Bearer ' . $token;
    }
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $hdrs,
        CURLOPT_TIMEOUT => 30,
    ]);
    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }
    $raw = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode((string) $raw, true);
    return ['code' => $code, 'json' => $json, 'raw' => $raw];
}

$failures = 0;
$step = function (string $name, bool $ok, string $detail = '') use (&$failures): void {
    echo ($ok ? '[PASS] ' : '[FAIL] ') . $name . ($detail ? " — $detail" : '') . PHP_EOL;
    if (!$ok) {
        $failures++;
    }
};

echo "XMONEY E2E flow test → {$base}\n";
echo "Test user: {$email}\n\n";

// 1. Register
$reg = req('POST', "{$base}/v1/auth/register", [
    'full_name' => 'E2E Test User',
    'email' => $email,
    'mobile_country' => '+971',
    'mobile_number' => '50' . random_int(1000000, 9999999),
    'password' => $password,
    'country_code' => 'AE',
], null, $device);
$otp = $reg['json']['data']['otp']['debug_otp'] ?? null;
$step('POST /v1/auth/register', $reg['code'] === 201 && $reg['json']['success'] ?? false, $reg['json']['message'] ?? '');
if (!$otp) {
    echo "[WARN] No debug_otp — set APP_DEBUG=true or check notification logs\n";
    exit(1);
}

// 2. Verify OTP
$verify = req('POST', "{$base}/v1/auth/verify-otp", [
    'email' => $email,
    'otp' => $otp,
    'purpose' => 'registration',
], null, $device);
$step('POST /v1/auth/verify-otp', $verify['code'] === 200 && ($verify['json']['success'] ?? false));

// 3. Login
$login = req('POST', "{$base}/v1/auth/login", [
    'email' => $email,
    'password' => $password,
], null, $device);
$token = $login['json']['data']['access_token'] ?? null;
$step('POST /v1/auth/login', $login['code'] === 200 && $token !== null);

if (!$token) {
    echo "\n{$failures} check(s) failed.\n";
    exit(1);
}

// 4. Profile
$me = req('GET', "{$base}/v1/me", null, $token, $device);
$step('GET /v1/me', $me['code'] === 200 && ($me['json']['success'] ?? false));

// 5. Wallet deposit (debug)
$dep = req('POST', "{$base}/v1/wallet/deposit", [
    'amount' => 5000,
    'currency' => 'AED',
], $token, $device);
$step('POST /v1/wallet/deposit', $dep['code'] === 200 && ($dep['json']['success'] ?? false), $dep['json']['message'] ?? '');

// 6. Beneficiary
$ben = req('POST', "{$base}/v1/beneficiaries", [
    'receiver_name' => 'E2E Receiver',
    'country_code' => 'PK',
    'currency_code' => 'PKR',
    'bank_name' => 'Test Bank',
    'account_number' => 'PK00TEST' . random_int(1000, 9999),
], $token, $device);
$benUuid = $ben['json']['data']['uuid'] ?? null;
$step('POST /v1/beneficiaries', $ben['code'] === 201 && $benUuid !== null);

// 7. Quote
$quote = req('POST', "{$base}/v1/transfers/quote", [
    'source_currency' => 'AED',
    'target_currency' => 'PKR',
    'send_amount' => 100,
    'destination_country' => 'PK',
], $token, $device);
$step('POST /v1/transfers/quote', $quote['code'] === 200 && ($quote['json']['success'] ?? false));

// 8. Transfer (wallet)
if ($benUuid && ($quote['json']['success'] ?? false)) {
    $create = req('POST', "{$base}/v1/transfers", [
        'beneficiary_uuid' => $benUuid,
        'send_amount' => $quote['json']['data']['send_amount'],
        'source_currency' => 'AED',
        'payment_method' => 'wallet',
    ], $token, $device);
    $txnUuid = $create['json']['data']['uuid'] ?? null;
    $step('POST /v1/transfers', $create['code'] === 201 && $txnUuid !== null);

    if ($txnUuid) {
        $confirm = req('POST', "{$base}/v1/transfers/{$txnUuid}/confirm", [
            'payment_method' => 'wallet',
        ], $token, $device);
        $step('POST /v1/transfers/{uuid}/confirm', $confirm['code'] === 200 && ($confirm['json']['success'] ?? false));
    }
}

// 9. List transfers
$list = req('GET', "{$base}/v1/transfers?limit=5", null, $token, $device);
$step('GET /v1/transfers', $list['code'] === 200 && ($list['json']['success'] ?? false));

// 10. Admin login
$adminLogin = req('POST', "{$base}/v1/admin/auth/login", [
    'email' => getenv('XMONEY_ADMIN_EMAIL') ?: 'admin@xmoney.local',
    'password' => getenv('XMONEY_ADMIN_PASSWORD') ?: 'ChangeMe@XMONEY2026',
], null, $device);
$adminToken = $adminLogin['json']['data']['access_token'] ?? null;
$step('POST /v1/admin/auth/login', $adminLogin['code'] === 200 && $adminToken !== null);

if ($adminToken) {
    $dash = req('GET', "{$base}/v1/admin/dashboard", null, $adminToken, $device);
    $step('GET /v1/admin/dashboard', $dash['code'] === 200 && ($dash['json']['success'] ?? false));
}

echo "\n" . ($failures === 0 ? 'E2E flow completed successfully.' : "{$failures} step(s) failed.") . PHP_EOL;
exit($failures > 0 ? 1 : 0);
