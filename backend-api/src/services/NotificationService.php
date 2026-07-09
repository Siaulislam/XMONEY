<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\Database;
use XMoney\Providers\Notification\NotificationProviderRegistry;
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

    public function sendOtp(string $channel, string $destination, string $otp, string $purpose): void
    {
        $title = 'XMONEY Verification Code';
        $body = "Your XMONEY OTP for {$purpose} is {$otp}. It expires in 10 minutes.";
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
            'body' => \XMoney\Config\App::isDebug() ? $body : 'Your XMONEY verification code has been sent.',
            'payload' => json_encode(['destination' => $destination, 'purpose' => $purpose]),
        ]);
    }

    public function notifyUser(int $userId, string $template, string $title, string $body): void
    {
        $this->queue($userId, 'email', $title, $body, $template);
        $this->queue($userId, 'in_app', $title, $body, $template);
    }
}
