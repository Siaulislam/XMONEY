<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Providers\Payment\PaymentProviderRegistry;
use XMoney\Utils\Security;

/**
 * Provider-agnostic payment service layer.
 * Select provider via PAYMENT_DEFAULT_PROVIDER — no hard-coded gateways.
 */
final class PaymentService
{
    public function __construct(private readonly \XMoney\Providers\Payment\PaymentProviderInterface $provider)
    {
    }

    public static function resolve(?string $code = null): self
    {
        return new self(PaymentProviderRegistry::create($code));
    }

    public function providerCode(): string
    {
        return $this->provider->code();
    }

    public function initiatePayment(int $userId, float $amount, string $currency, ?int $transactionId, string $method = 'gateway'): array
    {
        return $this->createPayment($userId, $amount, $currency, $method, 'transfer', $transactionId, null);
    }

    public function initiateWalletTopUp(int $userId, int $walletId, float $amount, string $currency, string $method = 'card'): array
    {
        return $this->createPayment($userId, $amount, $currency, $method, 'wallet_topup', null, $walletId);
    }

    private function createPayment(
        int $userId,
        float $amount,
        string $currency,
        string $method,
        string $purpose,
        ?int $transactionId,
        ?int $walletId
    ): array {
        $pdo = Database::connection();
        $uuid = Security::uuid();

        $result = $this->provider->initiate([
            'user_id' => $userId,
            'amount' => $amount,
            'currency' => $currency,
            'transaction_id' => $transactionId,
            'wallet_id' => $walletId,
            'purpose' => $purpose,
            'method' => $method,
        ]);

        $stmt = $pdo->prepare(
            'INSERT INTO payments
             (uuid, transaction_id, wallet_id, user_id, provider_code, method, purpose, amount, currency_code, status, provider_ref, provider_payload)
             VALUES
             (:uuid, :txn, :wallet, :user_id, :provider, :method, :purpose, :amount, :currency, :status, :ref, :payload)'
        );
        $stmt->execute([
            'uuid' => $uuid,
            'txn' => $transactionId,
            'wallet' => $walletId,
            'user_id' => $userId,
            'provider' => $this->provider->code(),
            'method' => $method,
            'purpose' => $purpose,
            'amount' => $amount,
            'currency' => $currency,
            'status' => $result['status'],
            'ref' => $result['provider_ref'],
            'payload' => json_encode($result['payload'] ?? []),
        ]);

        return [
            'payment_uuid' => $uuid,
            'status' => $result['status'],
            'provider' => $this->provider->code(),
            'provider_ref' => $result['provider_ref'],
            'purpose' => $purpose,
            'payload' => $result['payload'] ?? [],
        ];
    }

    public function captureByUuid(string $paymentUuid): array
    {
        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT * FROM payments WHERE uuid = :uuid LIMIT 1');
        $stmt->execute(['uuid' => $paymentUuid]);
        $payment = $stmt->fetch();
        if (!$payment) {
            throw new \RuntimeException('Payment not found');
        }
        if (!$payment['provider_ref']) {
            throw new \RuntimeException('Payment has no provider reference');
        }

        $provider = PaymentProviderRegistry::create($payment['provider_code']);
        $result = $provider->capture((string) $payment['provider_ref']);

        $pdo->prepare(
            'UPDATE payments SET status = :status, provider_payload = :payload WHERE id = :id'
        )->execute([
            'status' => $result['status'] === 'captured' ? 'captured' : $result['status'],
            'payload' => json_encode($result['payload'] ?? []),
            'id' => $payment['id'],
        ]);

        if (!empty($payment['transaction_id']) && in_array($result['status'], ['captured', 'completed'], true)) {
            $txn = new TransactionService();
            $txn->updateStatus((int) $payment['transaction_id'], 'processing', 'system', null, 'Payment captured');
            $txn->updateStatus((int) $payment['transaction_id'], 'completed', 'system', null, 'Transfer completed');
        }

        if (($payment['purpose'] ?? '') === 'wallet_topup' && !empty($payment['wallet_id'])
            && in_array($result['status'], ['captured', 'completed'], true)) {
            $wallets = new WalletService();
            $wallets->credit(
                (int) $payment['wallet_id'],
                (float) $payment['amount'],
                'deposit',
                'payment',
                (int) $payment['id'],
                'Wallet top-up via ' . $payment['provider_code']
            );
        }

        return $this->findByUuid($paymentUuid);
    }

    public function handleWebhook(string $providerCode, array $payload): array
    {
        $providerRef = $payload['provider_ref'] ?? $payload['payment_ref'] ?? null;
        if (!$providerRef) {
            throw new \RuntimeException('Webhook missing provider_ref');
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT uuid FROM payments WHERE provider_code = :provider AND provider_ref = :ref LIMIT 1'
        );
        $stmt->execute(['provider' => $providerCode, 'ref' => $providerRef]);
        $row = $stmt->fetch();
        if (!$row) {
            throw new \RuntimeException('Payment not found for webhook');
        }

        return $this->captureByUuid((string) $row['uuid']);
    }

    public function findByUuid(string $uuid, ?int $userId = null): array
    {
        $pdo = Database::connection();
        $sql = 'SELECT uuid, transaction_id, wallet_id, user_id, provider_code, method, purpose, amount, currency_code, status, provider_ref, created_at
                FROM payments WHERE uuid = :uuid';
        $params = ['uuid' => $uuid];
        if ($userId !== null) {
            $sql .= ' AND user_id = :uid';
            $params['uid'] = $userId;
        }
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch();
        if (!$row) {
            throw new \RuntimeException('Payment not found');
        }
        return $row;
    }

    public function simulateCaptureForDevelopment(string $paymentUuid): array
    {
        if (!App::isDebug()) {
            throw new \RuntimeException('Simulation only available in debug mode');
        }
        return $this->captureByUuid($paymentUuid);
    }
}
