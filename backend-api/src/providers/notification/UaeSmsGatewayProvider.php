<?php

declare(strict_types=1);

namespace XMoney\Providers\Notification;

final class UaeSmsGatewayProvider extends AbstractPlaceholderSmsProvider
{
    public function providerCode(): string
    {
        return 'uae_sms';
    }

    protected function requiredEnv(): array
    {
        return ['UAE_SMS_API_URL', 'UAE_SMS_API_KEY', 'UAE_SMS_SENDER_ID'];
    }

    protected function sendConfigured(string $title, string $body, array $context): bool
    {
        throw new \RuntimeException('UAE SMS gateway provider is not implemented yet.');
    }
}
