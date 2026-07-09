<?php

declare(strict_types=1);

namespace XMoney\Providers\Notification;

use XMoney\Config\App;

/**
 * SMTP email driver. Falls back to log when SMTP is not configured.
 */
final class SmtpNotificationProvider implements NotificationProviderInterface
{
    public function channel(): string
    {
        return 'email';
    }

    public function send(string $title, string $body, array $context = []): bool
    {
        $host = App::env('SMTP_HOST');
        $user = App::env('SMTP_USER');
        if (!$host || !$user) {
            return (new LogNotificationProvider('email'))->send($title, $body, $context);
        }

        $to = $context['destination'] ?? $context['email'] ?? null;
        if (!$to) {
            return false;
        }

        $from = App::env('SMTP_FROM', App::env('MAIL_FROM', 'noreply@xmoney.local'));
        $port = (int) (App::env('SMTP_PORT', '587') ?? '587');
        $secure = strtolower((string) (App::env('SMTP_SECURE', 'tls') ?? 'tls'));

        $headers = [
            'MIME-Version: 1.0',
            'Content-type: text/plain; charset=UTF-8',
            'From: ' . $from,
            'Reply-To: ' . $from,
            'X-Mailer: XMONEY',
        ];

        $transport = $secure === 'ssl' ? 'ssl://' . $host : $host;
        $errno = 0;
        $errstr = '';
        $socket = @fsockopen($transport, $port, $errno, $errstr, 10);
        if (!$socket) {
            return (new LogNotificationProvider('email'))->send($title, $body, $context);
        }

        try {
            $this->expect($socket, 220);
            $this->cmd($socket, 'EHLO xmoney.local');
            if ($secure === 'tls') {
                $this->cmd($socket, 'STARTTLS');
                stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT);
                $this->cmd($socket, 'EHLO xmoney.local');
            }
            $pass = App::env('SMTP_PASS', '');
            if ($user) {
                $this->cmd($socket, 'AUTH LOGIN');
                $this->cmd($socket, base64_encode($user));
                $this->cmd($socket, base64_encode((string) $pass));
            }
            $this->cmd($socket, 'MAIL FROM:<' . $this->extractEmail($from) . '>');
            $this->cmd($socket, 'RCPT TO:<' . $to . '>');
            $this->cmd($socket, 'DATA');
            $message = 'Subject: ' . $title . "\r\n" . implode("\r\n", $headers) . "\r\n\r\n" . $body . "\r\n.";
            fwrite($socket, $message . "\r\n");
            $this->expect($socket, 250);
            $this->cmd($socket, 'QUIT');
            return true;
        } catch (\Throwable) {
            return (new LogNotificationProvider('email'))->send($title, $body, $context);
        } finally {
            fclose($socket);
        }
    }

    private function cmd($socket, string $line): void
    {
        fwrite($socket, $line . "\r\n");
        $code = (int) substr($this->read($socket), 0, 3);
        if ($code >= 400) {
            throw new \RuntimeException('SMTP error: ' . $line);
        }
    }

    private function expect($socket, int $code): void
    {
        $response = $this->read($socket);
        if ((int) substr($response, 0, 3) !== $code) {
            throw new \RuntimeException('SMTP unexpected: ' . $response);
        }
    }

    private function read($socket): string
    {
        $data = '';
        while ($line = fgets($socket, 515)) {
            $data .= $line;
            if (isset($line[3]) && $line[3] === ' ') {
                break;
            }
        }
        return $data;
    }

    private function extractEmail(string $from): string
    {
        if (preg_match('/<([^>]+)>/', $from, $m)) {
            return $m[1];
        }
        return $from;
    }
}
