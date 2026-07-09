<?php

declare(strict_types=1);

namespace XMoney\Providers\Payment;

final class CheckoutPaymentProvider extends AbstractPlaceholderPaymentProvider
{
    public function code(): string
    {
        return 'checkout';
    }

    protected function requiredEnv(): array
    {
        return ['CHECKOUT_SECRET_KEY', 'CHECKOUT_WEBHOOK_SECRET'];
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
