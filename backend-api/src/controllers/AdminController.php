<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\Database;
use XMoney\Services\AuditService;
use XMoney\Services\AuthService;
use XMoney\Services\ExchangeService;
use XMoney\Services\NotificationService;
use XMoney\Services\TransactionService;
use XMoney\Utils\Response;
use XMoney\Utils\Security;
use XMoney\Utils\Validator;

final class AdminController
{
    public function login(array $request): void
    {
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'email' => 'required|email',
            'password' => 'required',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT a.*, r.code AS role_code FROM admin_users a
             JOIN roles r ON r.id = a.role_id
             WHERE a.email = :email AND a.deleted_at IS NULL LIMIT 1'
        );
        $stmt->execute(['email' => strtolower(trim($body['email']))]);
        $admin = $stmt->fetch();

        if (!$admin || !Security::verifyPassword($body['password'], $admin['password_hash'])) {
            Response::error('Invalid credentials', 401);
        }
        if ($admin['status'] !== 'active') {
            Response::error('Admin account is ' . $admin['status'], 403);
        }

        $pdo->prepare('UPDATE admin_users SET last_login_at = NOW(3), last_login_ip = :ip WHERE id = :id')
            ->execute(['ip' => Security::clientIp(), 'id' => $admin['id']]);

        $auth = new AuthService();
        $access = $auth->issueAccessToken([
            'sub' => (int) $admin['id'],
            'email' => $admin['email'],
            'role' => $admin['role_code'],
            'type' => 'admin',
        ], 'admin');
        $refresh = $auth->createRefreshToken(null, (int) $admin['id']);

        (new AuditService())->log('admin', (int) $admin['id'], 'admin.login', 'admin_user', (int) $admin['id']);

        Response::success([
            'access_token' => $access,
            'refresh_token' => $refresh,
            'token_type' => 'Bearer',
            'expires_in' => (int) (\XMoney\Config\App::env('JWT_ACCESS_TTL_MINUTES', '15') ?? '15') * 60,
            'admin' => [
                'uuid' => $admin['uuid'],
                'email' => $admin['email'],
                'full_name' => $admin['full_name'],
                'role' => $admin['role_code'],
            ],
        ], 'Admin login successful');
    }

    public function logout(array $request): void
    {
        $auth = new AuthService();
        $refresh = $request['body']['refresh_token'] ?? null;
        $adminId = null;

        if ($refresh) {
            $row = $auth->findValidRefreshToken((string) $refresh);
            if ($row && !empty($row['admin_user_id'])) {
                $adminId = (int) $row['admin_user_id'];
            }
            $auth->revokeRefreshToken((string) $refresh);
        }

        if (!$adminId && !empty($request['admin']['id'])) {
            $adminId = (int) $request['admin']['id'];
        }

        if ($adminId) {
            (new AuditService())->log('admin', $adminId, 'admin.logout', 'admin_user', $adminId);
        }

        Response::success(null, 'Logged out');
    }

    public function dashboard(array $request): void
    {
        $pdo = Database::connection();
        $stats = [
            'users_total' => (int) $pdo->query('SELECT COUNT(*) FROM users WHERE deleted_at IS NULL')->fetchColumn(),
            'users_active' => (int) $pdo->query("SELECT COUNT(*) FROM users WHERE status = 'active'")->fetchColumn(),
            'kyc_pending' => (int) $pdo->query("SELECT COUNT(*) FROM kyc_documents WHERE status = 'pending'")->fetchColumn(),
            'transactions_today' => (int) $pdo->query('SELECT COUNT(*) FROM transactions WHERE DATE(created_at) = CURDATE()')->fetchColumn(),
            'transactions_processing' => (int) $pdo->query("SELECT COUNT(*) FROM transactions WHERE status IN ('processing','under_review','pending_payment')")->fetchColumn(),
            'volume_today' => (float) $pdo->query('SELECT COALESCE(SUM(send_amount),0) FROM transactions WHERE DATE(created_at) = CURDATE() AND status = \'completed\'')->fetchColumn(),
            'failed_today' => (int) $pdo->query("SELECT COUNT(*) FROM transactions WHERE status = 'failed' AND DATE(created_at) = CURDATE()")->fetchColumn(),
        ];
        Response::success($stats);
    }

    public function users(array $request): void
    {
        $pdo = Database::connection();
        $q = trim((string) ($request['query']['q'] ?? ''));
        $sql = 'SELECT u.uuid, u.email, u.mobile_country, u.mobile_number, u.status, u.kyc_status, u.created_at, p.full_name, p.country_code
                FROM users u JOIN profiles p ON p.user_id = u.id WHERE u.deleted_at IS NULL';
        $params = [];
        if ($q !== '') {
            $sql .= ' AND (u.email LIKE :q OR p.full_name LIKE :q2 OR u.mobile_number LIKE :q3)';
            $params = ['q' => "%{$q}%", 'q2' => "%{$q}%", 'q3' => "%{$q}%"];
        }
        $sql .= ' ORDER BY u.id DESC LIMIT 100';
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        Response::success($stmt->fetchAll());
    }

    public function blockUser(array $request): void
    {
        $uuid = $request['params']['uuid'] ?? '';
        $pdo = Database::connection();
        $stmt = $pdo->prepare("UPDATE users SET status = 'blocked' WHERE uuid = :uuid");
        $stmt->execute(['uuid' => $uuid]);
        if ($stmt->rowCount() === 0) {
            Response::error('User not found', 404);
        }
        (new AuditService())->log('admin', (int) $request['admin']['id'], 'user.blocked', 'user', null, null, ['uuid' => $uuid]);
        Response::success(null, 'User blocked');
    }

    public function unblockUser(array $request): void
    {
        $uuid = $request['params']['uuid'] ?? '';
        $pdo = Database::connection();
        $stmt = $pdo->prepare("UPDATE users SET status = 'active', failed_login_count = 0, locked_until = NULL WHERE uuid = :uuid AND status = 'blocked'");
        $stmt->execute(['uuid' => $uuid]);
        if ($stmt->rowCount() === 0) {
            Response::error('User not found or not blocked', 404);
        }
        (new AuditService())->log('admin', (int) $request['admin']['id'], 'user.unblocked', 'user', null, null, ['uuid' => $uuid]);
        Response::success(null, 'User unblocked');
    }

    public function showUser(array $request): void
    {
        $uuid = $request['params']['uuid'] ?? '';
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT u.uuid, u.email, u.mobile_country, u.mobile_number, u.status, u.kyc_status,
                    u.email_verified_at, u.last_login_at, u.created_at, u.failed_login_count, u.locked_until,
                    p.full_name, p.country_code, p.date_of_birth, p.address_line1, p.city
             FROM users u
             JOIN profiles p ON p.user_id = u.id
             WHERE u.uuid = :uuid AND u.deleted_at IS NULL LIMIT 1'
        );
        $stmt->execute(['uuid' => $uuid]);
        $user = $stmt->fetch();
        if (!$user) {
            Response::error('User not found', 404);
        }

        $kyc = $pdo->prepare(
            'SELECT uuid, document_type, status, created_at, reviewed_at, rejection_reason
             FROM kyc_documents WHERE user_id = (SELECT id FROM users WHERE uuid = :uuid)
             ORDER BY id DESC LIMIT 20'
        );
        $kyc->execute(['uuid' => $uuid]);

        $txns = $pdo->prepare(
            'SELECT uuid, reference_code, send_amount, source_currency, target_currency, status, created_at
             FROM transactions WHERE sender_user_id = (SELECT id FROM users WHERE uuid = :uuid)
             ORDER BY id DESC LIMIT 10'
        );
        $txns->execute(['uuid' => $uuid]);

        $wallets = $pdo->prepare(
            'SELECT currency_code, balance, locked_balance, updated_at
             FROM wallets WHERE user_id = (SELECT id FROM users WHERE uuid = :uuid)'
        );
        $wallets->execute(['uuid' => $uuid]);

        Response::success([
            'user' => $user,
            'kyc_documents' => $kyc->fetchAll(),
            'recent_transactions' => $txns->fetchAll(),
            'wallets' => $wallets->fetchAll(),
        ]);
    }

    public function settings(array $request): void
    {
        $group = $request['query']['group'] ?? null;
        Response::success((new \XMoney\Services\SettingsService())->all($group ? (string) $group : null));
    }

    public function updateSettings(array $request): void
    {
        $body = $request['body'];
        if (!is_array($body) || $body === []) {
            Response::error('No settings provided', 422);
        }
        $updated = (new \XMoney\Services\SettingsService())->updateMany($body, (int) $request['admin']['id']);
        (new AuditService())->log('admin', (int) $request['admin']['id'], 'settings.updated', 'settings', null, null, ['keys' => array_keys($body)]);
        Response::success($updated, 'Settings updated');
    }

    public function kycPending(array $request): void
    {
        $pdo = Database::connection();
        $rows = $pdo->query(
            "SELECT k.uuid, k.document_type, k.document_number, k.country_code, k.status, k.created_at,
                    u.email, p.full_name
             FROM kyc_documents k
             JOIN users u ON u.id = k.user_id
             JOIN profiles p ON p.user_id = u.id
             WHERE k.status = 'pending'
             ORDER BY k.id ASC LIMIT 100"
        )->fetchAll();
        Response::success($rows);
    }

    public function reviewKyc(array $request): void
    {
        $uuid = $request['params']['uuid'] ?? '';
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'decision' => 'required|in:approved,rejected',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }
        if ($body['decision'] === 'rejected' && empty($body['rejection_reason'])) {
            Response::error('rejection_reason is required', 422);
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT * FROM kyc_documents WHERE uuid = :uuid');
        $stmt->execute(['uuid' => $uuid]);
        $doc = $stmt->fetch();
        if (!$doc) {
            Response::error('Document not found', 404);
        }

        $pdo->prepare(
            'UPDATE kyc_documents SET status = :status, reviewed_by = :admin, reviewed_at = NOW(3), rejection_reason = :reason
             WHERE id = :id'
        )->execute([
            'status' => $body['decision'],
            'admin' => $request['admin']['id'],
            'reason' => $body['rejection_reason'] ?? null,
            'id' => $doc['id'],
        ]);

        if ($body['decision'] === 'approved') {
            $pdo->prepare("UPDATE users SET kyc_status = 'approved' WHERE id = :id")
                ->execute(['id' => $doc['user_id']]);
            (new NotificationService())->notifyUser(
                (int) $doc['user_id'],
                'kyc_approved',
                'KYC Approved',
                'Your KYC has been approved. You can now send money with XMONEY.'
            );
        } else {
            $pdo->prepare("UPDATE users SET kyc_status = 'rejected' WHERE id = :id")
                ->execute(['id' => $doc['user_id']]);
            (new NotificationService())->notifyUser(
                (int) $doc['user_id'],
                'kyc_rejected',
                'KYC Rejected',
                'Your KYC was rejected: ' . ($body['rejection_reason'] ?? '')
            );
        }

        (new AuditService())->log('admin', (int) $request['admin']['id'], 'kyc.' . $body['decision'], 'kyc_document', (int) $doc['id']);
        Response::success(null, 'KYC ' . $body['decision']);
    }

    public function transactions(array $request): void
    {
        $pdo = Database::connection();
        $status = $request['query']['status'] ?? null;
        $q = trim((string) ($request['query']['q'] ?? ''));
        $sql = 'SELECT t.uuid, t.reference_code, t.send_amount, t.receive_amount, t.source_currency, t.target_currency,
                       t.fee_amount, t.total_debit, t.status, t.created_at, p.full_name AS sender_name, b.receiver_name
                FROM transactions t
                JOIN users u ON u.id = t.sender_user_id
                JOIN profiles p ON p.user_id = u.id
                JOIN beneficiaries b ON b.id = t.beneficiary_id
                WHERE 1=1';
        $params = [];
        if ($status) {
            $sql .= ' AND t.status = :status';
            $params['status'] = $status;
        }
        if ($q !== '') {
            $sql .= ' AND (t.reference_code LIKE :q OR p.full_name LIKE :q2 OR b.receiver_name LIKE :q3)';
            $params['q'] = "%{$q}%";
            $params['q2'] = "%{$q}%";
            $params['q3'] = "%{$q}%";
        }
        $sql .= ' ORDER BY t.id DESC LIMIT 100';
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        Response::success($stmt->fetchAll());
    }

    public function updateTransactionStatus(array $request): void
    {
        $uuid = $request['params']['uuid'] ?? '';
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'status' => 'required|in:processing,under_review,completed,failed,cancelled,refunded',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT id FROM transactions WHERE uuid = :uuid');
        $stmt->execute(['uuid' => $uuid]);
        $txn = $stmt->fetch();
        if (!$txn) {
            Response::error('Transaction not found', 404);
        }

        try {
            $result = (new TransactionService())->updateStatus(
                (int) $txn['id'],
                $body['status'],
                'admin',
                (int) $request['admin']['id'],
                $body['note'] ?? null
            );
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 400);
        }
        Response::success($result, 'Transaction updated');
    }

    public function updateRate(array $request): void
    {
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'source_currency' => 'required|min:3|max:3',
            'target_currency' => 'required|min:3|max:3',
            'market_rate' => 'required|numeric|min:0',
            'margin' => 'required|numeric',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }

        $market = (float) $body['market_rate'];
        $margin = (float) $body['margin'];
        $customer = (new ExchangeService())->applyMargin($market, $margin);

        $pdo = Database::connection();
        $pdo->prepare(
            'UPDATE exchange_rates SET is_active = 0, effective_to = NOW(3)
             WHERE source_currency = :s AND target_currency = :t AND is_active = 1'
        )->execute([
            's' => strtoupper($body['source_currency']),
            't' => strtoupper($body['target_currency']),
        ]);

        $pdo->prepare(
            'INSERT INTO exchange_rates
             (source_currency, target_currency, market_rate, margin, customer_rate, provider, effective_from, is_active, created_by)
             VALUES (:s, :t, :market, :margin, :customer, \'admin\', NOW(3), 1, :admin)'
        )->execute([
            's' => strtoupper($body['source_currency']),
            't' => strtoupper($body['target_currency']),
            'market' => $market,
            'margin' => $margin,
            'customer' => $customer,
            'admin' => $request['admin']['id'],
        ]);

        (new AuditService())->log('admin', (int) $request['admin']['id'], 'rate.updated', 'exchange_rate', (int) $pdo->lastInsertId());
        Response::success([
            'market_rate' => $market,
            'margin' => $margin,
            'customer_rate' => $customer,
        ], 'Exchange rate updated');
    }

    public function reports(array $request): void
    {
        $type = $request['query']['type'] ?? 'daily';
        $pdo = Database::connection();

        $data = match ($type) {
            'monthly' => $pdo->query(
                "SELECT DATE_FORMAT(created_at, '%Y-%m') AS period,
                        COUNT(*) AS txn_count,
                        SUM(CASE WHEN status='completed' THEN send_amount ELSE 0 END) AS volume,
                        SUM(CASE WHEN status='completed' THEN fee_amount ELSE 0 END) AS revenue,
                        SUM(CASE WHEN status='failed' THEN 1 ELSE 0 END) AS failed_count
                 FROM transactions
                 WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
                 GROUP BY DATE_FORMAT(created_at, '%Y-%m')
                 ORDER BY period DESC"
            )->fetchAll(),
            'revenue' => $pdo->query(
                "SELECT DATE(created_at) AS day, SUM(fee_amount) AS fees, SUM(send_amount) AS volume, COUNT(*) AS completed
                 FROM transactions WHERE status = 'completed' AND created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                 GROUP BY DATE(created_at) ORDER BY day DESC"
            )->fetchAll(),
            'failed' => $pdo->query(
                "SELECT reference_code, send_amount, source_currency, failure_reason, created_at, status
                 FROM transactions WHERE status = 'failed' ORDER BY id DESC LIMIT 100"
            )->fetchAll(),
            default => $pdo->query(
                "SELECT DATE(created_at) AS day,
                        COUNT(*) AS txn_count,
                        SUM(CASE WHEN status='completed' THEN send_amount ELSE 0 END) AS volume,
                        SUM(CASE WHEN status='completed' THEN fee_amount ELSE 0 END) AS revenue,
                        SUM(CASE WHEN status='failed' THEN 1 ELSE 0 END) AS failed_count
                 FROM transactions
                 WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                 GROUP BY DATE(created_at)
                 ORDER BY day DESC"
            )->fetchAll(),
        };

        Response::success(['type' => $type, 'rows' => $data]);
    }

    public function fees(array $request): void
    {
        $pdo = Database::connection();
        $rows = $pdo->query(
            'SELECT id, name, fee_type, source_currency, target_currency, destination_country,
                    flat_amount, percent_value, min_fee, max_fee, min_amount, max_amount, is_active, priority
             FROM fees ORDER BY priority ASC, id ASC'
        )->fetchAll();
        Response::success($rows);
    }

    public function upsertFee(array $request): void
    {
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'name' => 'required|min:2|max:120',
            'fee_type' => 'required|in:flat,percent,tiered',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }

        $pdo = Database::connection();
        $id = isset($body['id']) ? (int) $body['id'] : 0;

        if ($id > 0) {
            $pdo->prepare(
                'UPDATE fees SET name = :name, fee_type = :fee_type,
                 source_currency = :src, target_currency = :tgt, destination_country = :country,
                 flat_amount = :flat, percent_value = :pct, min_fee = :min_fee, max_fee = :max_fee,
                 min_amount = :min_amt, max_amount = :max_amt, is_active = :active, priority = :priority
                 WHERE id = :id'
            )->execute([
                'name' => $body['name'],
                'fee_type' => $body['fee_type'],
                'src' => $body['source_currency'] ?? null,
                'tgt' => $body['target_currency'] ?? null,
                'country' => $body['destination_country'] ?? null,
                'flat' => $body['flat_amount'] ?? null,
                'pct' => $body['percent_value'] ?? null,
                'min_fee' => $body['min_fee'] ?? null,
                'max_fee' => $body['max_fee'] ?? null,
                'min_amt' => $body['min_amount'] ?? 0,
                'max_amt' => $body['max_amount'] ?? null,
                'active' => isset($body['is_active']) ? (int) (bool) $body['is_active'] : 1,
                'priority' => (int) ($body['priority'] ?? 100),
                'id' => $id,
            ]);
            (new AuditService())->log('admin', (int) $request['admin']['id'], 'fee.updated', 'fee', $id);
            Response::success(['id' => $id], 'Fee updated');
        }

        $pdo->prepare(
            'INSERT INTO fees
             (name, fee_type, source_currency, target_currency, destination_country,
              flat_amount, percent_value, min_fee, max_fee, min_amount, max_amount, is_active, priority)
             VALUES
             (:name, :fee_type, :src, :tgt, :country, :flat, :pct, :min_fee, :max_fee, :min_amt, :max_amt, :active, :priority)'
        )->execute([
            'name' => $body['name'],
            'fee_type' => $body['fee_type'],
            'src' => $body['source_currency'] ?? null,
            'tgt' => $body['target_currency'] ?? null,
            'country' => $body['destination_country'] ?? null,
            'flat' => $body['flat_amount'] ?? null,
            'pct' => $body['percent_value'] ?? null,
            'min_fee' => $body['min_fee'] ?? null,
            'max_fee' => $body['max_fee'] ?? null,
            'min_amt' => $body['min_amount'] ?? 0,
            'max_amt' => $body['max_amount'] ?? null,
            'active' => isset($body['is_active']) ? (int) (bool) $body['is_active'] : 1,
            'priority' => (int) ($body['priority'] ?? 100),
        ]);
        $newId = (int) $pdo->lastInsertId();
        (new AuditService())->log('admin', (int) $request['admin']['id'], 'fee.created', 'fee', $newId);
        Response::success(['id' => $newId], 'Fee created', 201);
    }

    public function auditLogs(array $request): void
    {
        $pdo = Database::connection();
        $limit = min(200, max(1, (int) ($request['query']['limit'] ?? 100)));
        $action = trim((string) ($request['query']['action'] ?? ''));

        $sql = 'SELECT id, actor_type, actor_id, action, entity_type, entity_id, ip_address, request_id, created_at
                FROM audit_logs WHERE 1=1';
        $params = [];
        if ($action !== '') {
            $sql .= ' AND action LIKE :action';
            $params['action'] = '%' . $action . '%';
        }
        $sql .= ' ORDER BY id DESC LIMIT ' . $limit;
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        Response::success($stmt->fetchAll());
    }

    public function currenciesAdmin(array $request): void
    {
        $pdo = Database::connection();
        $rows = $pdo->query(
            'SELECT id, code, name, symbol, decimal_places, is_active, is_source, is_destination, sort_order
             FROM currencies ORDER BY sort_order, code'
        )->fetchAll();
        Response::success($rows);
    }

    public function updateCurrency(array $request): void
    {
        $code = strtoupper($request['params']['code'] ?? '');
        $body = $request['body'];
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'UPDATE currencies SET
                is_active = COALESCE(:active, is_active),
                is_source = COALESCE(:src, is_source),
                is_destination = COALESCE(:dst, is_destination),
                sort_order = COALESCE(:sort, sort_order)
             WHERE code = :code'
        );
        $stmt->execute([
            'active' => array_key_exists('is_active', $body) ? (int) (bool) $body['is_active'] : null,
            'src' => array_key_exists('is_source', $body) ? (int) (bool) $body['is_source'] : null,
            'dst' => array_key_exists('is_destination', $body) ? (int) (bool) $body['is_destination'] : null,
            'sort' => isset($body['sort_order']) ? (int) $body['sort_order'] : null,
            'code' => $code,
        ]);
        if ($stmt->rowCount() === 0) {
            Response::error('Currency not found', 404);
        }
        (new AuditService())->log('admin', (int) $request['admin']['id'], 'currency.updated', 'currency', null, null, ['code' => $code]);
        Response::success(null, 'Currency updated');
    }
}
