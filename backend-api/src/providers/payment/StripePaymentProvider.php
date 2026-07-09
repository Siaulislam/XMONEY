<?php

declare(strict_types=1);

namespace XMoney\Providers\Payment;

final class StripePaymentProvider extends AbstractPlaceholderPaymentProvider
{
    public function code(): string
    {
        return 'stripe';
    }

    protected function requiredEnv(): array
    {
        return ['STRIPE_SECRET_KEY', 'STRIPE_WEBHOOK_SECRET'];
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
