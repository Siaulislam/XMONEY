<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\Database;
use XMoney\Services\AuditService;
use XMoney\Services\AuthService;
use XMoney\Services\DeviceService;
use XMoney\Services\OtpService;
use XMoney\Services\WalletService;
use XMoney\Utils\I18n;
use XMoney\Utils\Response;
use XMoney\Utils\Security;
use XMoney\Utils\Validator;

final class AuthController
{
    public function __construct(
        private readonly AuthService $auth = new AuthService(),
        private readonly OtpService $otp = new OtpService(),
        private readonly AuditService $audit = new AuditService(),
        private readonly WalletService $wallets = new WalletService(),
        private readonly DeviceService $devices = new DeviceService()
    ) {
    }

    public function register(array $request): void
    {
        $body = $request['body'];
        $locale = I18n::locale($request);
        $errors = Validator::validate($body, [
            'full_name' => 'required|min:2|max:200',
            'email' => 'required|email|max:255',
            'mobile_country' => 'required|max:5',
            'mobile_number' => 'required|min:6|max:30',
            'password' => 'required|password',
            'country_code' => 'required|min:2|max:2',
        ], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        $pdo = Database::connection();
        $email = strtolower(trim($body['email']));

        $exists = $pdo->prepare(
            'SELECT id FROM users WHERE email = :email OR (mobile_country = :mc AND mobile_number = :mn) LIMIT 1'
        );
        $exists->execute([
            'email' => $email,
            'mc' => $body['mobile_country'],
            'mn' => $body['mobile_number'],
        ]);
        if ($exists->fetch()) {
            Response::error(Response::text('response.email_or_mobile_exists', [], $request, $locale), 409);
        }

        $roleId = (int) $pdo->query("SELECT id FROM roles WHERE code = 'customer' LIMIT 1")->fetchColumn();
        if (!$roleId) {
            Response::error(Response::text('response.system_roles_missing', [], $request, $locale), 500);
        }

        $uuid = Security::uuid();
        $pdo->beginTransaction();
        try {
            $pdo->prepare(
                'INSERT INTO users (uuid, email, mobile_country, mobile_number, password_hash, status, role_id)
                 VALUES (:uuid, :email, :mc, :mn, :pwd, \'pending\', :role)'
            )->execute([
                'uuid' => $uuid,
                'email' => $email,
                'mc' => $body['mobile_country'],
                'mn' => $body['mobile_number'],
                'pwd' => Security::hashPassword($body['password']),
                'role' => $roleId,
            ]);
            $userId = (int) $pdo->lastInsertId();

            $pdo->prepare(
                'INSERT INTO profiles (user_id, full_name, country_code, city, address_line1)
                 VALUES (:uid, :name, :country, :city, :address)'
            )->execute([
                'uid' => $userId,
                'name' => trim($body['full_name']),
                'country' => strtoupper($body['country_code']),
                'city' => $body['city'] ?? null,
                'address' => $body['address'] ?? null,
            ]);

            $this->wallets->getOrCreate($userId, 'AED');
            $this->audit->log('user', $userId, 'user.registered', 'user', $userId);
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $otpPayload = $this->otp->issue($userId, 'email', $email, 'registration', $locale);

        Response::success([
            'user_uuid' => $uuid,
            'otp' => $otpPayload,
        ], Response::text('response.registration_success', [], $request, $locale), 201);
    }

    public function verifyOtp(array $request): void
    {
        $body = $request['body'];
        $locale = I18n::locale($request);
        $errors = Validator::validate($body, [
            'email' => 'required|email',
            'otp' => 'required|min:6|max:6',
            'purpose' => 'required|in:registration,login,password_reset,transfer,device,kyc',
        ], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        $email = strtolower(trim($body['email']));
        if (!$this->otp->verify($email, $body['purpose'], $body['otp'])) {
            Response::error(Response::text('response.otp_invalid', [], $request, $locale), 400);
        }

        $pdo = Database::connection();
        if ($body['purpose'] === 'registration') {
            $pdo->prepare(
                'UPDATE users SET status = \'active\', email_verified_at = NOW(3)
                 WHERE email = :email AND status = \'pending\''
            )->execute(['email' => $email]);
            $this->audit->log('user', null, 'user.email_verified', 'user', null, null, ['email' => $email]);
        }

        Response::success(null, Response::text('response.otp_verified', [], $request, $locale));
    }

    public function resendOtp(array $request): void
    {
        $body = $request['body'];
        $locale = I18n::locale($request);
        $errors = Validator::validate($body, [
            'email' => 'required|email',
            'purpose' => 'required|in:registration,password_reset,login',
        ], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        $email = strtolower(trim($body['email']));
        $purpose = $body['purpose'];
        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT id, status FROM users WHERE email = :email AND deleted_at IS NULL LIMIT 1');
        $stmt->execute(['email' => $email]);
        $user = $stmt->fetch();

        // Anti-enumeration: always succeed outwardly
        if ($user) {
            if ($purpose === 'registration' && $user['status'] !== 'pending') {
                Response::success(null, Response::text('response.otp_sent_if_required', [], $request, $locale));
            }
            $otpPayload = $this->otp->issue((int) $user['id'], 'email', $email, $purpose, $locale);
            Response::success(['otp' => $otpPayload], Response::text('response.otp_sent_if_exists', [], $request, $locale));
        }

        Response::success(null, Response::text('response.otp_sent_if_exists', [], $request, $locale));
    }

    public function login(array $request): void
    {
        $body = $request['body'];
        $locale = I18n::locale($request);
        $errors = Validator::validate($body, [
            'email' => 'required|email',
            'password' => 'required',
        ], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT u.*, r.code AS role_code FROM users u
             JOIN roles r ON r.id = u.role_id
             WHERE u.email = :email AND u.deleted_at IS NULL LIMIT 1'
        );
        $stmt->execute(['email' => strtolower(trim($body['email']))]);
        $user = $stmt->fetch();

        if (!$user) {
            Response::error(Response::text('response.invalid_credentials', [], $request, $locale), 401);
        }

        // Lock check before password verify (same generic message when locked + wrong pwd)
        if ($user['locked_until'] && strtotime($user['locked_until']) > time()) {
            Response::error(Response::text('response.account_locked', [], $request, $locale), 423);
        }

        if (!Security::verifyPassword($body['password'], $user['password_hash'])) {
            $this->auth->recordFailedLogin((int) $user['id'], (int) $user['failed_login_count']);
            Response::error(Response::text('response.invalid_credentials', [], $request, $locale), 401);
        }

        if ($user['status'] === 'pending') {
            Response::error(Response::text('response.email_unverified', [], $request, $locale), 403, [
                'code' => 'email_unverified',
            ]);
        }

        if (in_array($user['status'], ['blocked', 'suspended', 'closed'], true)) {
            Response::error(Response::text('response.account_status', [
                'status' => I18n::t('domain.status.' . $user['status'], [], $locale),
            ], $request, $locale), 403);
        }

        $pdo->prepare(
            'UPDATE users SET failed_login_count = 0, locked_until = NULL,
             last_login_at = NOW(3), last_login_ip = :ip WHERE id = :id'
        )->execute(['ip' => Security::clientIp(), 'id' => $user['id']]);

        $deviceUuid = $this->resolveDeviceUuid($request, $body);
        $platform = $body['platform'] ?? 'web';
        $deviceId = $this->devices->registerOrUpdate(
            (int) $user['id'],
            $deviceUuid,
            is_string($platform) ? $platform : 'web',
            isset($body['device_name']) ? (string) $body['device_name'] : null
        );

        $access = $this->auth->issueAccessToken([
            'sub' => (int) $user['id'],
            'email' => $user['email'],
            'role' => $user['role_code'],
            'type' => 'customer',
        ], 'customer');
        $refresh = $this->auth->createRefreshToken((int) $user['id'], null, $deviceId);

        $this->audit->log('user', (int) $user['id'], 'user.login', 'user', (int) $user['id']);

        Response::success([
            'access_token' => $access,
            'refresh_token' => $refresh,
            'token_type' => 'Bearer',
            'expires_in' => (int) (\XMoney\Config\App::env('JWT_ACCESS_TTL_MINUTES', '15') ?? '15') * 60,
            'device_uuid' => $deviceUuid,
            'user' => [
                'uuid' => $user['uuid'],
                'email' => $user['email'],
                'status' => $user['status'],
                'kyc_status' => $user['kyc_status'],
            ],
        ], Response::text('response.login_success', [], $request, $locale));
    }

    public function refresh(array $request): void
    {
        $body = $request['body'];
        $locale = I18n::locale($request);
        $errors = Validator::validate($body, ['refresh_token' => 'required|min:20'], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        try {
            $tokens = $this->auth->rotateRefreshToken((string) $body['refresh_token']);
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 401);
        }

        $payload = [
            'access_token' => $tokens['access_token'],
            'refresh_token' => $tokens['refresh_token'],
            'token_type' => 'Bearer',
            'expires_in' => (int) (\XMoney\Config\App::env('JWT_ACCESS_TTL_MINUTES', '15') ?? '15') * 60,
        ];

        if (($tokens['actor']['type'] ?? '') === 'customer') {
            $payload['user'] = [
                'uuid' => $tokens['actor']['uuid'],
                'email' => $tokens['actor']['email'],
                'status' => $tokens['actor']['status'],
                'kyc_status' => $tokens['actor']['kyc_status'],
            ];
        } else {
            $payload['admin'] = $tokens['actor'];
        }

        Response::success($payload, Response::text('response.token_refreshed', [], $request, $locale));
    }

    /**
     * Logout accepts refresh_token without requiring a valid access JWT
     * so expired sessions can still revoke server-side refresh tokens.
     */
    public function logout(array $request): void
    {
        $refresh = $request['body']['refresh_token'] ?? null;
        $userId = null;

        if ($refresh) {
            $row = $this->auth->findValidRefreshToken((string) $refresh);
            if ($row && !empty($row['user_id'])) {
                $userId = (int) $row['user_id'];
            }
            $this->auth->revokeRefreshToken((string) $refresh);
        }

        if (!$userId && !empty($request['user']['id'])) {
            $userId = (int) $request['user']['id'];
        }

        if ($userId) {
            $this->audit->log('user', $userId, 'user.logout', 'user', $userId);
        }

        Response::success(null, Response::text('response.logged_out', [], $request));
    }

    public function forgotPassword(array $request): void
    {
        $body = $request['body'];
        $locale = I18n::locale($request);
        $errors = Validator::validate($body, ['email' => 'required|email'], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        $email = strtolower(trim($body['email']));
        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT id FROM users WHERE email = :email AND deleted_at IS NULL');
        $stmt->execute(['email' => $email]);
        $user = $stmt->fetch();

        $otpPayload = null;
        if ($user) {
            $otpPayload = $this->otp->issue((int) $user['id'], 'email', $email, 'password_reset', $locale);
        }

        // Anti-enumeration message; debug OTP only when APP_DEBUG=true and user exists
        $data = null;
        if ($otpPayload && \XMoney\Config\App::isDebug()) {
            $data = ['otp' => $otpPayload];
        }

        Response::success($data, Response::text('response.otp_sent_if_exists', [], $request, $locale));
    }

    public function resetPassword(array $request): void
    {
        $body = $request['body'];
        $locale = I18n::locale($request);
        $errors = Validator::validate($body, [
            'email' => 'required|email',
            'otp' => 'required|min:6|max:6',
            'password' => 'required|password',
        ], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        $email = strtolower(trim($body['email']));
        if (!$this->otp->verify($email, 'password_reset', $body['otp'])) {
            Response::error(Response::text('response.otp_invalid', [], $request, $locale), 400);
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT id FROM users WHERE email = :email AND deleted_at IS NULL LIMIT 1');
        $stmt->execute(['email' => $email]);
        $user = $stmt->fetch();
        if (!$user) {
            Response::error(Response::text('response.otp_invalid', [], $request, $locale), 400);
        }

        $pdo->prepare('UPDATE users SET password_hash = :pwd WHERE id = :id')
            ->execute([
                'pwd' => Security::hashPassword($body['password']),
                'id' => $user['id'],
            ]);

        $this->auth->revokeAllUserRefreshTokens((int) $user['id']);
        $this->audit->log('user', (int) $user['id'], 'password.reset', 'user', (int) $user['id']);

        Response::success(null, Response::text('response.password_updated', [], $request, $locale));
    }

    private function resolveDeviceUuid(array $request, array $body): string
    {
        $fromHeader = $_SERVER['HTTP_X_DEVICE_ID'] ?? '';
        $fromBody = isset($body['device_uuid']) ? (string) $body['device_uuid'] : '';
        $uuid = trim($fromHeader !== '' ? $fromHeader : $fromBody);
        return $uuid !== '' ? $uuid : Security::uuid();
    }
}
