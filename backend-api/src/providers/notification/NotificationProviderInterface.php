<?php

declare(strict_types=1);

namespace XMoney\Providers\Notification;

interface NotificationProviderInterface
{
    /** Channel this provider handles: email, sms, push, in_app */
    public function channel(): string;

    public function send(string $title, string $body, array $context = []): bool;
}
