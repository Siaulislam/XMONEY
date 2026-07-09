<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\Database;
use XMoney\Utils\Response;

final class NotificationController
{
    public function index(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $limit = min(100, max(1, (int) ($request['query']['limit'] ?? 50)));
        $pdo = Database::connection();

        $stmt = $pdo->prepare(
            'SELECT uuid, channel, template_code, title, body, status, sent_at, read_at, created_at
             FROM notifications
             WHERE user_id = :uid
             ORDER BY id DESC
             LIMIT :lim'
        );
        $stmt->bindValue('uid', $userId, \PDO::PARAM_INT);
        $stmt->bindValue('lim', $limit, \PDO::PARAM_INT);
        $stmt->execute();
        $rows = $stmt->fetchAll();

        $unread = $pdo->prepare(
            "SELECT COUNT(*) FROM notifications WHERE user_id = :uid AND status <> 'read' AND read_at IS NULL"
        );
        $unread->execute(['uid' => $userId]);

        Response::success([
            'items' => $rows,
            'unread_count' => (int) $unread->fetchColumn(),
        ]);
    }

    public function markRead(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $uuid = $request['params']['uuid'] ?? '';
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            "UPDATE notifications SET status = 'read', read_at = NOW(3)
             WHERE uuid = :uuid AND user_id = :uid AND read_at IS NULL"
        );
        $stmt->execute(['uuid' => $uuid, 'uid' => $userId]);
        if ($stmt->rowCount() === 0) {
            Response::error('Notification not found', 404);
        }
        Response::success(null, 'Marked as read');
    }

    public function markAllRead(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $pdo = Database::connection();
        $pdo->prepare(
            "UPDATE notifications SET status = 'read', read_at = NOW(3)
             WHERE user_id = :uid AND read_at IS NULL"
        )->execute(['uid' => $userId]);
        Response::success(null, 'All notifications marked as read');
    }
}
