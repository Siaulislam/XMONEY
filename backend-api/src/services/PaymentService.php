<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Providers\Payment\PaymentProviderInterface;
use XMoney\Providers\Payment\StubPaymentProvider;
use XMoney\Utils\Security;

/**
 * Provider-agnostic payment service layer.
 * Payment Service Layer → Payment Provider API
 */
final class PaymentService
{
    public function __construct(
        private readonly PaymentProviderInterface $provider = new StubPaymentProvider()
    ) {
    }

    public static function resolve(?string $code = null): self
    {
        $code = $code ?: (App::env('PAYMENT_DEFAULT_PROVIDER', 'stub') ?? 'stub');
        return match ($code) {
            default => new self(new StubPaymentProvider()),
        };
    }

    public function initiatePayment(int $userId, float $amount, string $currency, ?int $transactionId, string $method = 'gateway'): array
    {
        $pdo = Database::connection();
        $uuid = Security::uuid();

        $result = $this->provider->initiate([
            'user_id' => $userId,
            'amount' => $amount,
            'currency' => $currency,
            'transaction_id' => $transactionId,
            'method' => $method,
        ]);

        $stmt = $pdo->prepare(
            'INSERT INTO payments
             (uuid, transaction_id, user_id, provider_code, method, amount, currency_code, status, provider_ref, provider_payload)
             VALUES
             (:uuid, :txn, :user_id, :provider, :method, :amount, :currency, :status, :ref, :payload)'
        );
        $stmt->execute([
            'uuid' => $uuid,
            'txn' => $transactionId,
            'user_id' => $userId,
            'provider' => $this->provider->code(),
            'method' => $method,
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
        ];
    }
}
