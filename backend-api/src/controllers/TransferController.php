<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\Database;
use XMoney\Services\ExchangeService;
use XMoney\Services\PaymentService;
use XMoney\Services\TransactionService;
use XMoney\Services\WalletService;
use XMoney\Utils\I18n;
use XMoney\Utils\Response;
use XMoney\Utils\Validator;

final class TransferController
{
    public function __construct(
        private readonly ExchangeService $exchange = new ExchangeService(),
        private readonly TransactionService $transactions = new TransactionService(),
        private readonly WalletService $wallets = new WalletService()
    ) {
    }

    public function quote(array $request): void
    {
        $body = $request['body'] ?: $request['query'];
        $locale = I18n::locale($request);
        $errors = Validator::validate($body, [
            'source_currency' => 'required|min:3|max:3',
            'target_currency' => 'required|min:3|max:3',
            'send_amount' => 'required|numeric|min:1',
        ], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        $quote = $this->exchange->quote(
            strtoupper($body['source_currency']),
            strtoupper($body['target_currency']),
            (float) $body['send_amount'],
            isset($body['destination_country']) ? strtoupper($body['destination_country']) : null
        );
        if (!$quote) {
            Response::error(I18n::t('error.exchange_unavailable', [], $locale), 404);
        }
        Response::success($quote);
    }

    public function rates(array $request): void
    {
        $pdo = Database::connection();
        $rows = $pdo->query(
            'SELECT source_currency, target_currency, market_rate, margin, customer_rate, provider, effective_from
             FROM exchange_rates WHERE is_active = 1
             ORDER BY source_currency, target_currency'
        )->fetchAll();
        Response::success($rows);
    }

    public function currencies(array $request): void
    {
        $pdo = Database::connection();
        $rows = $pdo->query(
            'SELECT code, name, symbol, decimal_places, is_source, is_destination
             FROM currencies WHERE is_active = 1 ORDER BY sort_order, code'
        )->fetchAll();
        Response::success($rows);
    }

    public function create(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $body = $request['body'];
        $locale = I18n::locale($request);
        $errors = Validator::validate($body, [
            'beneficiary_uuid' => 'required',
            'send_amount' => 'required|numeric|min:1',
            'source_currency' => 'required|min:3|max:3',
        ], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        $pdo = Database::connection();
        $ben = $pdo->prepare(
            'SELECT id FROM beneficiaries WHERE uuid = :uuid AND user_id = :uid AND deleted_at IS NULL'
        );
        $ben->execute(['uuid' => $body['beneficiary_uuid'], 'uid' => $userId]);
        $beneficiary = $ben->fetch();
        if (!$beneficiary) {
            Response::error(I18n::t('error.beneficiary_not_found', [], $locale), 404);
        }

        try {
            $txn = $this->transactions->create(
                $userId,
                (int) $beneficiary['id'],
                (float) $body['send_amount'],
                strtoupper($body['source_currency']),
                $body['payment_method'] ?? null
            );
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 400);
        }

        Response::success($txn, Response::text('response.transfer_created', [], $request, $locale), 201);
    }

    public function confirm(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $uuid = $request['params']['uuid'] ?? '';
        $body = $request['body'];
        $method = $body['payment_method'] ?? 'wallet';
        $locale = I18n::locale($request);

        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT * FROM transactions WHERE uuid = :uuid AND sender_user_id = :uid');
        $stmt->execute(['uuid' => $uuid, 'uid' => $userId]);
        $txn = $stmt->fetch();
        if (!$txn) {
            Response::error(I18n::t('error.transaction_not_found', [], $locale), 404);
        }
        if ($txn['status'] !== 'created') {
            Response::error(I18n::t('error.invalid_status_transition', [
                'from' => I18n::t('domain.status.' . $txn['status'], [], $locale),
                'to' => I18n::t('domain.status.pending_payment', [], $locale),
            ], $locale), 400);
        }

        try {
            $this->transactions->updateStatus((int) $txn['id'], 'pending_payment', 'user', $userId, 'Awaiting payment');

            if ($method === 'wallet') {
                $wallet = $this->wallets->getOrCreate($userId, $txn['source_currency']);
                $this->wallets->debit(
                    (int) $wallet['id'],
                    (float) $txn['total_debit'],
                    'transfer_debit',
                    'transaction',
                    (int) $txn['id'],
                    'Transfer ' . $txn['reference_code']
                );
                $this->transactions->updateStatus((int) $txn['id'], 'processing', 'system', null, 'Paid via wallet');
                $this->transactions->updateStatus((int) $txn['id'], 'completed', 'system', null, 'Wallet transfer settled');
            } else {
                $payment = PaymentService::resolve()->initiatePayment(
                    $userId,
                    (float) $txn['total_debit'],
                    $txn['source_currency'],
                    (int) $txn['id'],
                    $method === 'card' ? 'card' : 'gateway'
                );
                Response::success([
                    'transaction' => $this->transactions->findById((int) $txn['id'], $userId),
                    'payment' => $payment,
                ], Response::text('response.ok', [], $request, $locale));
            }
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 400);
        }

        Response::success(
            $this->transactions->findById((int) $txn['id'], $userId),
            Response::text('response.transfer_confirmed', [], $request, $locale)
        );
    }

    public function index(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $limit = min(100, max(1, (int) ($request['query']['limit'] ?? 50)));
        $offset = max(0, (int) ($request['query']['offset'] ?? 0));
        $filters = [
            'status' => $request['query']['status'] ?? null,
            'q' => trim((string) ($request['query']['q'] ?? '')) ?: null,
            'from' => $request['query']['from'] ?? null,
            'to' => $request['query']['to'] ?? null,
        ];
        Response::success([
            'rows' => $this->transactions->listForUser($userId, $limit, $offset, $filters),
            'total' => $this->transactions->countForUser($userId, $filters),
            'limit' => $limit,
            'offset' => $offset,
        ]);
    }

    public function show(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $uuid = $request['params']['uuid'] ?? '';
        $locale = I18n::locale($request);
        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT id FROM transactions WHERE uuid = :uuid AND sender_user_id = :uid');
        $stmt->execute(['uuid' => $uuid, 'uid' => $userId]);
        $row = $stmt->fetch();
        if (!$row) {
            Response::error(I18n::t('error.transaction_not_found', [], $locale), 404);
        }

        $txn = $this->transactions->findById((int) $row['id'], $userId);
        $logs = $pdo->prepare(
            'SELECT from_status, to_status, actor_type, note, created_at
             FROM transaction_logs WHERE transaction_id = :id ORDER BY id ASC'
        );
        $logs->execute(['id' => $row['id']]);
        $txn['history'] = $logs->fetchAll();
        Response::success($txn);
    }

    public function cancel(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $uuid = $request['params']['uuid'] ?? '';
        $locale = I18n::locale($request);
        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT id, status FROM transactions WHERE uuid = :uuid AND sender_user_id = :uid');
        $stmt->execute(['uuid' => $uuid, 'uid' => $userId]);
        $txn = $stmt->fetch();
        if (!$txn) {
            Response::error(I18n::t('error.transaction_not_found', [], $locale), 404);
        }
        try {
            $result = $this->transactions->updateStatus((int) $txn['id'], 'cancelled', 'user', $userId, 'Cancelled by user');
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 400);
        }
        Response::success($result, Response::text('response.transfer_cancelled', [], $request, $locale));
    }
}
