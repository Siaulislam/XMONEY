<?php

declare(strict_types=1);

namespace XMoney\Providers\Payment;

final class UaeBankPaymentProvider extends AbstractPlaceholderPaymentProvider
{
    public function code(): string
    {
        return 'uae_bank';
    }

    protected function requiredEnv(): array
    {
        return ['UAE_BANK_API_URL', 'UAE_BANK_CLIENT_ID', 'UAE_BANK_CLIENT_SECRET'];
    }

    protected function initiateConfigured(array $payment): array
    {
        return $this->notImplemented('initiate');
    }

    protected function captureConfigured(string $providerRef): array
    {
        return $this->notImplemented('capture');
    }

    protected function refundConfigured(string $providerRef, float $amount): array
    {
        return $this->notImplemented('refund');
    }
}
