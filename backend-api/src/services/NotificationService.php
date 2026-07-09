<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\Database;
use XMoney\Providers\Notification\NotificationProviderRegistry;
use XMoney\Utils\I18n;
use XMoney\Utils\Security;

final class NotificationService
{
    public function queue(
        ?int $userId,
        string $channel,
        string $title,
        string $body,
        ?string $templateCode = null,
        ?array $payload = null
    ): void {
        $pdo = Database::connection();
        $uuid = Security::uuid();
        $stmt = $pdo->prepare(
            'INSERT INTO notifications (uuid, user_id, channel, template_code, title, body, payload_json, status)
             VALUES (:uuid, :user_id, :channel, :template_code, :title, :body, :payload_json, :status)'
        );
        $stmt->execute([
            'uuid' => $uuid,
            'user_id' => $userId,
            'channel' => $channel,
            'template_code' => $templateCode,
            'title' => $title,
            'body' => $body,
            'payload_json' => $payload ? json_encode($payload) : null,
            'status' => 'queued',
        ]);

        $provider = NotificationProviderRegistry::forChannel($channel);
        $ok = $provider->send($title, $body, array_merge($payload ?? [], ['channel' => $channel]));
        $pdo->prepare(
            'UPDATE notifications SET status = :status, sent_at = NOW(3) WHERE uuid = :uuid'
        )->execute([
            'status' => $ok ? 'sent' : 'failed',
            'uuid' => $uuid,
        ]);
    }

    public function sendOtp(string $channel, string $destination, string $otp, string $purpose, ?string $locale = null): void
    {
        $locale ??= 'en';
        $minutes = max(1, (int) (\XMoney\Config\App::env('OTP_EXPIRY_MINUTES', '10') ?? '10'));
        $purposeLabel = I18n::t('notification.purpose.' . $purpose, [], $locale);
        $title = I18n::t('notification.otp_title', [], $locale);
        $body = I18n::t('notification.otp_body', [
            'purpose' => $purposeLabel,
            'otp' => $otp,
            'minutes' => $minutes,
        ], $locale);
        $deliveryChannel = $channel === 'sms' ? 'sms' : 'email';

        $provider = NotificationProviderRegistry::forChannel($deliveryChannel);
        $provider->send($title, $body, [
            'destination' => $destination,
            'purpose' => $purpose,
            'channel' => $deliveryChannel,
        ]);

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'INSERT INTO notifications (uuid, user_id, channel, template_code, title, body, payload_json, status, sent_at)
             VALUES (:uuid, NULL, :channel, :template, :title, :body, :payload, \'sent\', NOW(3))'
        );
        $stmt->execute([
            'uuid' => Security::uuid(),
            'channel' => $deliveryChannel,
            'template' => 'otp_' . $purpose,
            'title' => $title,
            'body' => \XMoney\Config\App::isDebug() ? $body : I18n::t('notification.otp_confirmation', [], $locale),
            'payload' => json_encode(['destination' => $destination, 'purpose' => $purpose]),
        ]);
    }

    public function notifyUser(int $userId, string $template, string $title, string $body): void
    {
        $this->queue($userId, 'email', $title, $body, $template);
        $this->queue($userId, 'in_app', $title, $body, $template);
    }
}
