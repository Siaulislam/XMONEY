<?php

declare(strict_types=1);

namespace XMoney\Providers\Notification;

use XMoney\Config\App;

/**
 * Resolves notification drivers from MAIL_DRIVER, SMS_DRIVER, PUSH_DRIVER env vars.
 */
final class NotificationProviderRegistry
{
    /** @var array<string, class-string<NotificationProviderInterface>> */
    private const EMAIL = [
        'log' => LogNotificationProvider::class,
        'smtp' => SmtpNotificationProvider::class,
    ];

    /** @var array<string, class-string<NotificationProviderInterface>> */
    private const SMS = [
        'log' => LogNotificationProvider::class,
        'twilio' => TwilioSmsProvider::class,
        'aws_sns' => AwsSnsProvider::class,
        'aws-sns' => AwsSnsProvider::class,
        'uae_sms' => UaeSmsGatewayProvider::class,
        'uae-sms' => UaeSmsGatewayProvider::class,
    ];

    /** @var array<string, class-string<NotificationProviderInterface>> */
    private const PUSH = [
        'log' => LogNotificationProvider::class,
        'fcm' => PushNotificationProvider::class,
        'apns' => PushNotificationProvider::class,
    ];

    public static function forChannel(string $channel): NotificationProviderInterface
    {
        $channel = strtolower($channel);

        if ($channel === 'email' || $channel === 'in_app') {
            $driver = strtolower((string) (App::env('MAIL_DRIVER', 'log') ?? 'log'));
            if ($channel === 'email' && App::env('SMTP_HOST') && $driver === 'log') {
                $driver = 'smtp';
            }
            $class = self::EMAIL[$driver] ?? LogNotificationProvider::class;
            return self::instantiate($class, $channel);
        }

        if ($channel === 'sms') {
            $driver = strtolower((string) (App::env('SMS_DRIVER', 'log') ?? 'log'));
            $class = self::SMS[$driver] ?? LogNotificationProvider::class;
            return self::instantiate($class, $channel);
        }

        if ($channel === 'push') {
            $driver = strtolower((string) (App::env('PUSH_DRIVER', 'log') ?? 'log'));
            $class = self::PUSH[$driver] ?? LogNotificationProvider::class;
            return self::instantiate($class, $channel);
        }

        return new LogNotificationProvider($channel);
    }

    private static function instantiate(string $class, string $channel): NotificationProviderInterface
    {
        $provider = new $class();
        if ($provider instanceof LogNotificationProvider) {
            return new LogNotificationProvider($channel);
        }
        return $provider;
    }
}
