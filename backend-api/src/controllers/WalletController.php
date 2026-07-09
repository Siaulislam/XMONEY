<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Services\PaymentService;
use XMoney\Services\WalletService;
use XMoney\Utils\I18n;
use XMoney\Utils\Response;
use XMoney\Utils\Validator;

final class WalletController
{
    public function __construct(private readonly WalletService $wallets = new WalletService())
    {
    }

    public function listAll(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT uuid, currency_code, balance, available_balance, held_balance, status, updated_at
             FROM wallets WHERE user_id = :uid ORDER BY currency_code'
        );
        $stmt->execute(['uid' => $userId]);
        Response::success($stmt->fetchAll());
    }

    public function show(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $currency = strtoupper($request['query']['currency'] ?? 'AED');
        $wallet = $this->wallets->getOrCreate($userId, $currency);
        Response::success([
            'uuid' => $wallet['uuid'],
            'currency' => $wallet['currency_code'],
            'balance' => (float) $wallet['balance'],
            'available_balance' => (float) $wallet['available_balance'],
            'held_balance' => (float) $wallet['held_balance'],
            'status' => $wallet['status'],
        ]);
    }

    public function history(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $currency = strtoupper($request['query']['currency'] ?? 'AED');
        $type = trim((string) ($request['query']['type'] ?? ''));
        $limit = min(100, max(1, (int) ($request['query']['limit'] ?? 50)));
        $offset = max(0, (int) ($request['query']['offset'] ?? 0));

        $wallet = $this->wallets->getOrCreate($userId, $currency);
        $pdo = Database::connection();

        $sql = 'SELECT uuid, type, amount, balance_before, balance_after, reference_type, description, created_at
                FROM wallet_transactions WHERE wallet_id = :wid';
        $params = ['wid' => $wallet['id']];
        if ($type !== '') {
            $sql .= ' AND type = :type';
            $params['type'] = $type;
        }
        $sql .= ' ORDER BY id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        $countSql = 'SELECT COUNT(*) FROM wallet_transactions WHERE wallet_id = :wid';
        $countParams = ['wid' => $wallet['id']];
        if ($type !== '') {
            $countSql .= ' AND type = :type';
            $countParams['type'] = $type;
        }
        $count = $pdo->prepare($countSql);
        $count->execute($countParams);

        Response::success([
            'rows' => $stmt->fetchAll(),
            'total' => (int) $count->fetchColumn(),
            'limit' => $limit,
            'offset' => $offset,
        ]);
    }

    public function topUp(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'amount' => 'required|numeric|min:1',
            'currency' => 'required|min:3|max:3',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }

        $currency = strtoupper($body['currency']);
        $amount = (float) $body['amount'];
        $method = $body['payment_method'] ?? 'card';
        $wallet = $this->wallets->getOrCreate($userId, $currency);

        $payment = PaymentService::resolve()->initiateWalletTopUp(
            $userId,
            (int) $wallet['id'],
            $amount,
            $currency,
            $method === 'gateway' ? 'gateway' : 'card'
        );

        if (App::isDebug() && ($body['auto_capture'] ?? true)) {
            $payment = PaymentService::resolve()->simulateCaptureForDevelopment($payment['payment_uuid']);
        }

        $wallet = $this->wallets->getOrCreate($userId, $currency);
        Response::success([
            'payment' => $payment,
            'wallet' => [
                'uuid' => $wallet['uuid'],
                'currency' => $wallet['currency_code'],
                'balance' => (float) $wallet['balance'],
                'available_balance' => (float) $wallet['available_balance'],
            ],
        ], 'Wallet top-up initiated', 201);
    }

    public function deposit(array $request): void
    {
        $locale = I18n::locale($request);
        if (!App::isDebug()) {
            Response::error(Response::text('response.manual_deposit_disabled', [], $request, $locale), 403);
        }

        $userId = (int) $request['user']['id'];
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'amount' => 'required|numeric|min:1',
            'currency' => 'required|min:3|max:3',
        ], $locale);
        if ($errors) {
            Response::error(Response::text('response.validation_failed', [], $request, $locale), 422, $errors);
        }

        $wallet = $this->wallets->getOrCreate($userId, strtoupper($body['currency']));
        try {
            $this->wallets->credit(
                (int) $wallet['id'],
                (float) $body['amount'],
                'deposit',
                'manual',
                null,
                'Wallet deposit (development)'
            );
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 400);
        }

        Response::success(
            $this->wallets->getOrCreate($userId, strtoupper($body['currency'])),
            Response::text('response.deposit_recorded', [], $request, $locale)
        );
    }
}
