<?php

declare(strict_types=1);

namespace XMoney\Providers\Notification;

use XMoney\Config\App;

final class PushNotificationProvider implements NotificationProviderInterface
{
    public function channel(): string
    {
        return 'push';
    }

    public function send(string $title, string $body, array $context = []): bool
    {
        $required = ['PUSH_FCM_SERVER_KEY'];
        foreach ($required as $key) {
            if (!App::env($key)) {
                return (new LogNotificationProvider('push'))->send($title, $body, array_merge($context, [
                    'fallback' => true,
                    'requested_provider' => 'push',
                ]));
            }
        }
        throw new \RuntimeException('Push notification provider is not implemented yet.');
    }
}
