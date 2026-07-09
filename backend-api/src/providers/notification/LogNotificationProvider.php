<?php

declare(strict_types=1);

namespace XMoney\Providers\Notification;

use XMoney\Config\App;

/**
 * Development / fallback notification provider.
 * Writes to logs/notifications.log — replace with SMTP/SMS/Push providers in production.
 */
final class LogNotificationProvider
{
    public function send(string $channel, string $title, string $body, array $context = []): bool
    {
        $logPath = App::basePath('../logs/notifications.log');
        $dir = dirname($logPath);
        if (!is_dir($dir)) {
            @mkdir($dir, 0755, true);
        }

        $line = sprintf(
            "[%s] channel=%s title=%s body=%s context=%s%s",
            date('c'),
            $channel,
            $title,
            $body,
            json_encode($context),
            PHP_EOL
        );

        return (bool) file_put_contents($logPath, $line, FILE_APPEND | LOCK_EX);
    }
}
