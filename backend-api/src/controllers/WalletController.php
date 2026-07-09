<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Services\WalletService;
use XMoney\Config\Database;
use XMoney\Utils\Response;
use XMoney\Utils\Validator;

final class WalletController
{
    public function __construct(private readonly WalletService $wallets = new WalletService())
    {
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
        $wallet = $this->wallets->getOrCreate($userId, $currency);
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT uuid, type, amount, balance_before, balance_after, reference_type, description, created_at
             FROM wallet_transactions WHERE wallet_id = :wid ORDER BY id DESC LIMIT 100'
        );
        $stmt->execute(['wid' => $wallet['id']]);
        Response::success($stmt->fetchAll());
    }

    public function deposit(array $request): void
    {
        // Foundation endpoint — real funding via PaymentService in production
        $userId = (int) $request['user']['id'];
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'amount' => 'required|numeric|min:1',
            'currency' => 'required|min:3|max:3',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }

        $wallet = $this->wallets->getOrCreate($userId, strtoupper($body['currency']));
        try {
            $this->wallets->credit(
                (int) $wallet['id'],
                (float) $body['amount'],
                'deposit',
                'manual',
                null,
                'Wallet deposit'
            );
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 400);
        }

        Response::success($this->wallets->getOrCreate($userId, strtoupper($body['currency'])), 'Deposit recorded');
    }
}
