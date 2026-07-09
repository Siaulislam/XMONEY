<?php

declare(strict_types=1);

namespace XMoney\Providers\Notification;

use XMoney\Config\App;

abstract class AbstractPlaceholderSmsProvider implements NotificationProviderInterface
{
    abstract public function providerCode(): string;

    abstract protected function requiredEnv(): array;

    public function channel(): string
    {
        return 'sms';
    }

    protected function isConfigured(): bool
    {
        foreach ($this->requiredEnv() as $key) {
            if (!App::env($key)) {
                return false;
            }
        }
        return true;
    }

    public function send(string $title, string $body, array $context = []): bool
    {
        if (!$this->isConfigured()) {
            return (new LogNotificationProvider('sms'))->send($title, $body, array_merge($context, [
                'fallback' => true,
                'requested_provider' => $this->providerCode(),
            ]));
        }
        return $this->sendConfigured($title, $body, $context);
    }

    abstract protected function sendConfigured(string $title, string $body, array $context): bool;
}
