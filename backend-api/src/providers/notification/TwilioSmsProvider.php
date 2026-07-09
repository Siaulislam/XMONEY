<?php

declare(strict_types=1);

namespace XMoney\Providers\Notification;

final class TwilioSmsProvider extends AbstractPlaceholderSmsProvider
{
    public function providerCode(): string
    {
        return 'twilio';
    }

    protected function requiredEnv(): array
    {
        return ['TWILIO_ACCOUNT_SID', 'TWILIO_AUTH_TOKEN', 'TWILIO_FROM_NUMBER'];
    }

    protected function sendConfigured(string $title, string $body, array $context): bool
    {
        throw new \RuntimeException('Twilio SMS provider is not implemented yet.');
    }
}
