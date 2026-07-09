<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\Database;
use XMoney\Utils\Security;

final class WalletService
{
    public function getOrCreate(int $userId, string $currency = 'AED'): array
    {
        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT * FROM wallets WHERE user_id = :uid AND currency_code = :cur LIMIT 1');
        $stmt->execute(['uid' => $userId, 'cur' => strtoupper($currency)]);
        $wallet = $stmt->fetch();
        if ($wallet) {
            return $wallet;
        }

        $uuid = Security::uuid();
        $pdo->prepare(
            'INSERT INTO wallets (uuid, user_id, currency_code, balance, available_balance, held_balance, status)
             VALUES (:uuid, :uid, :cur, 0, 0, 0, \'active\')'
        )->execute(['uuid' => $uuid, 'uid' => $userId, 'cur' => strtoupper($currency)]);

        $stmt->execute(['uid' => $userId, 'cur' => strtoupper($currency)]);
        return $stmt->fetch();
    }

    public function credit(int $walletId, float $amount, string $type, ?string $refType = null, ?int $refId = null, ?string $description = null): void
    {
        $this->mutate($walletId, $amount, $type, $refType, $refId, $description);
    }

    public function debit(int $walletId, float $amount, string $type, ?string $refType = null, ?int $refId = null, ?string $description = null): void
    {
        $this->mutate($walletId, -abs($amount), $type, $refType, $refId, $description);
    }

    private function mutate(int $walletId, float $signedAmount, string $type, ?string $refType, ?int $refId, ?string $description): void
    {
        $pdo = Database::connection();
        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare('SELECT * FROM wallets WHERE id = :id FOR UPDATE');
            $stmt->execute(['id' => $walletId]);
            $wallet = $stmt->fetch();
            if (!$wallet || $wallet['status'] !== 'active') {
                throw new \RuntimeException('Wallet unavailable');
            }

            $before = (float) $wallet['balance'];
            $after = round($before + $signedAmount, 4);
            if ($after < 0) {
                throw new \RuntimeException('Insufficient wallet balance');
            }

            $available = round((float) $wallet['available_balance'] + $signedAmount, 4);
            if ($available < 0) {
                throw new \RuntimeException('Insufficient available balance');
            }

            $pdo->prepare(
                'UPDATE wallets SET balance = :bal, available_balance = :avail, version = version + 1 WHERE id = :id AND version = :ver'
            )->execute([
                'bal' => $after,
                'avail' => $available,
                'id' => $walletId,
                'ver' => $wallet['version'],
            ]);

            $pdo->prepare(
                'INSERT INTO wallet_transactions
                 (uuid, wallet_id, type, amount, balance_before, balance_after, reference_type, reference_id, description)
                 VALUES (:uuid, :wid, :type, :amount, :before, :after, :ref_type, :ref_id, :desc)'
            )->execute([
                'uuid' => Security::uuid(),
                'wid' => $walletId,
                'type' => $type,
                'amount' => abs($signedAmount),
                'before' => $before,
                'after' => $after,
                'ref_type' => $refType,
                'ref_id' => $refId,
                'desc' => $description,
            ]);

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }
}
