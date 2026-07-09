<?php

declare(strict_types=1);

namespace XMoney\Providers\Payment;

/**
 * Stub payment provider for local development.
 * Swap via PaymentService for bank_transfer / card / gateway providers.
 */
final class StubPaymentProvider implements PaymentProviderInterface
{
    public function code(): string
    {
        return 'stub';
    }

    public function initiate(array $payment): array
    {
        return [
            'status' => 'pending',
            'provider_ref' => 'STUB-' . strtoupper(bin2hex(random_bytes(6))),
            'payload' => ['message' => 'Stub payment initiated — replace with real provider'],
        ];
    }

    public function capture(string $providerRef): array
    {
        return [
            'status' => 'captured',
            'provider_ref' => $providerRef,
            'payload' => ['message' => 'Stub payment captured'],
        ];
    }

    public function refund(string $providerRef, float $amount): array
    {
        return [
            'status' => 'refunded',
            'provider_ref' => $providerRef,
            'payload' => ['amount' => $amount],
        ];
    }
}
