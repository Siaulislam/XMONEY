<?php

declare(strict_types=1);

use XMoney\Controllers\AdminController;
use XMoney\Controllers\AuthController;
use XMoney\Controllers\BeneficiaryController;
use XMoney\Controllers\HealthController;
use XMoney\Controllers\KycController;
use XMoney\Controllers\NotificationController;
use XMoney\Controllers\TransferController;
use XMoney\Controllers\UserController;
use XMoney\Controllers\WalletController;
use XMoney\Middleware\AuthMiddleware;
use XMoney\Middleware\RateLimitMiddleware;
use XMoney\Utils\Router;

$router = new Router();

$auth = new AuthController();
$user = new UserController();
$kyc = new KycController();
$ben = new BeneficiaryController();
$transfer = new TransferController();
$wallet = new WalletController();
$admin = new AdminController();
$health = new HealthController();
$notifications = new NotificationController();

$customerAuth = [AuthMiddleware::customer()];
$adminOps = [AuthMiddleware::admin(['super_admin', 'admin', 'support_staff', 'compliance_officer'])];
$adminFull = [AuthMiddleware::admin(['super_admin', 'admin'])];
$compliance = [AuthMiddleware::admin(['super_admin', 'admin', 'compliance_officer'])];

$rlLogin = [RateLimitMiddleware::forAuth('login')];
$rlRegister = [RateLimitMiddleware::forAuth('register')];
$rlOtp = [RateLimitMiddleware::forAuth('otp')];
$rlForgot = [RateLimitMiddleware::forAuth('forgot')];
$rlResend = [RateLimitMiddleware::forAuth('resend')];
$rlRefresh = [RateLimitMiddleware::forAuth('refresh')];

// Health
$router->get('/v1/health', [$health, 'check']);

// Auth (logout/refresh intentionally public — authenticated via refresh_token body)
$router->post('/v1/auth/register', [$auth, 'register'], $rlRegister);
$router->post('/v1/auth/verify-otp', [$auth, 'verifyOtp'], $rlOtp);
$router->post('/v1/auth/resend-otp', [$auth, 'resendOtp'], $rlResend);
$router->post('/v1/auth/login', [$auth, 'login'], $rlLogin);
$router->post('/v1/auth/refresh', [$auth, 'refresh'], $rlRefresh);
$router->post('/v1/auth/logout', [$auth, 'logout']);
$router->post('/v1/auth/forgot-password', [$auth, 'forgotPassword'], $rlForgot);
$router->post('/v1/auth/reset-password', [$auth, 'resetPassword'], $rlOtp);

// User profile & security
$router->get('/v1/me', [$user, 'profile'], $customerAuth);
$router->put('/v1/me', [$user, 'updateProfile'], $customerAuth);
$router->post('/v1/me/change-password', [$user, 'changePassword'], $customerAuth);
$router->get('/v1/me/devices', [$user, 'devices'], $customerAuth);
$router->delete('/v1/me/devices/{id}', [$user, 'revokeDevice'], $customerAuth);

// Notifications
$router->get('/v1/notifications', [$notifications, 'index'], $customerAuth);
$router->post('/v1/notifications/{uuid}/read', [$notifications, 'markRead'], $customerAuth);
$router->post('/v1/notifications/read-all', [$notifications, 'markAllRead'], $customerAuth);

// KYC
$router->get('/v1/kyc', [$kyc, 'listMine'], $customerAuth);
$router->post('/v1/kyc/upload', [$kyc, 'upload'], $customerAuth);

// Beneficiaries
$router->get('/v1/beneficiaries', [$ben, 'index'], $customerAuth);
$router->post('/v1/beneficiaries', [$ben, 'store'], $customerAuth);
$router->put('/v1/beneficiaries/{uuid}', [$ben, 'update'], $customerAuth);
$router->delete('/v1/beneficiaries/{uuid}', [$ben, 'destroy'], $customerAuth);
$router->post('/v1/beneficiaries/{uuid}/verify', [$ben, 'verify'], $customerAuth);

// Transfers & FX
$router->get('/v1/currencies', [$transfer, 'currencies']);
$router->get('/v1/rates', [$transfer, 'rates']);
$router->post('/v1/transfers/quote', [$transfer, 'quote'], $customerAuth);
$router->get('/v1/transfers', [$transfer, 'index'], $customerAuth);
$router->post('/v1/transfers', [$transfer, 'create'], $customerAuth);
$router->get('/v1/transfers/{uuid}', [$transfer, 'show'], $customerAuth);
$router->post('/v1/transfers/{uuid}/confirm', [$transfer, 'confirm'], $customerAuth);
$router->post('/v1/transfers/{uuid}/cancel', [$transfer, 'cancel'], $customerAuth);

// Wallet
$router->get('/v1/wallet', [$wallet, 'show'], $customerAuth);
$router->get('/v1/wallet/history', [$wallet, 'history'], $customerAuth);
$router->post('/v1/wallet/deposit', [$wallet, 'deposit'], $customerAuth);

// Admin auth
$router->post('/v1/admin/auth/login', [$admin, 'login'], $rlLogin);
$router->post('/v1/admin/auth/logout', [$admin, 'logout']);
$router->post('/v1/admin/auth/refresh', [$auth, 'refresh'], $rlRefresh);

// Admin operations
$router->get('/v1/admin/dashboard', [$admin, 'dashboard'], $adminOps);
$router->get('/v1/admin/users', [$admin, 'users'], $adminOps);
$router->get('/v1/admin/users/{uuid}', [$admin, 'showUser'], $adminOps);
$router->post('/v1/admin/users/{uuid}/block', [$admin, 'blockUser'], $adminFull);
$router->post('/v1/admin/users/{uuid}/unblock', [$admin, 'unblockUser'], $adminFull);
$router->get('/v1/admin/kyc/pending', [$admin, 'kycPending'], $compliance);
$router->post('/v1/admin/kyc/{uuid}/review', [$admin, 'reviewKyc'], $compliance);
$router->get('/v1/admin/transactions', [$admin, 'transactions'], $adminOps);
$router->post('/v1/admin/transactions/{uuid}/status', [$admin, 'updateTransactionStatus'], $adminFull);
$router->post('/v1/admin/rates', [$admin, 'updateRate'], $adminFull);
$router->get('/v1/admin/reports', [$admin, 'reports'], $adminOps);
$router->get('/v1/admin/fees', [$admin, 'fees'], $adminFull);
$router->post('/v1/admin/fees', [$admin, 'upsertFee'], $adminFull);
$router->get('/v1/admin/currencies', [$admin, 'currenciesAdmin'], $adminFull);
$router->patch('/v1/admin/currencies/{code}', [$admin, 'updateCurrency'], $adminFull);
$router->get('/v1/admin/audit-logs', [$admin, 'auditLogs'], $adminOps);
$router->get('/v1/admin/settings', [$admin, 'settings'], $adminFull);
$router->put('/v1/admin/settings', [$admin, 'updateSettings'], $adminFull);

return $router;
