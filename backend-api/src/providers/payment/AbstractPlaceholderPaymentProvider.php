<?php

declare(strict_types=1);

namespace XMoney\Providers\Payment;

use XMoney\Config\App;

/**
 * Base class for future payment gateways.
 * When credentials are missing, operations delegate to the stub provider.
 * When credentials exist but integration is not yet implemented, a clear error is thrown.
 */
abstract class AbstractPlaceholderPaymentProvider implements PaymentProviderInterface
{
    abstract public function code(): string;

    /** @return list<string> Environment variable names required for this provider */
    abstract protected function requiredEnv(): array;

    abstract protected function initiateConfigured(array $payment): array;

    abstract protected function captureConfigured(string $providerRef): array;

    abstract protected function refundConfigured(string $providerRef, float $amount): array;

    protected function isConfigured(): bool
    {
        foreach ($this->requiredEnv() as $key) {
            if (!App::env($key)) {
                return false;
            }
        }
        return true;
    }

    protected function stub(): StubPaymentProvider
    {
        return new StubPaymentProvider();
    }

    public function initiate(array $payment): array
    {
        if (!$this->isConfigured()) {
            $result = $this->stub()->initiate($payment);
            $result['payload'] = array_merge($result['payload'] ?? [], [
                'fallback' => true,
                'requested_provider' => $this->code(),
                'message' => $this->code() . ' is not configured — stub provider used',
            ]);
            return $result;
        }
        return $this->initiateConfigured($payment);
    }

    public function capture(string $providerRef): array
    {
        if (!$this->isConfigured()) {
            return $this->stub()->capture($providerRef);
        }
        return $this->captureConfigured($providerRef);
    }

    public function refund(string $providerRef, float $amount): array
    {
        if (!$this->isConfigured()) {
            return $this->stub()->refund($providerRef, $amount);
        }
        return $this->refundConfigured($providerRef, $amount);
    }

    protected function notImplemented(string $operation): never
    {
        throw new \RuntimeException(
            sprintf('%s %s is not implemented yet. Provider credentials are configured.', $this->code(), $operation)
        );
    }
}
