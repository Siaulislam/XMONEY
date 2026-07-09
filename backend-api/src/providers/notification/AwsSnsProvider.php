<?php

declare(strict_types=1);

namespace XMoney\Providers\Notification;

final class AwsSnsProvider extends AbstractPlaceholderSmsProvider
{
    public function providerCode(): string
    {
        return 'aws_sns';
    }

    protected function requiredEnv(): array
    {
        return ['AWS_SNS_REGION', 'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY'];
    }

    protected function sendConfigured(string $title, string $body, array $context): bool
    {
        throw new \RuntimeException('AWS SNS SMS provider is not implemented yet.');
    }
}
