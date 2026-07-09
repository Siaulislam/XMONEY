<?php

declare(strict_types=1);

namespace XMoney\Providers\Payment;

final class WisePaymentProvider extends AbstractPlaceholderPaymentProvider
{
    public function code(): string
    {
        return 'wise';
    }

    protected function requiredEnv(): array
    {
        return ['WISE_API_TOKEN', 'WISE_PROFILE_ID'];
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
