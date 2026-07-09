<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\Database;
use XMoney\Utils\Security;

final class AuditService
{
    public function log(
        string $actorType,
        ?int $actorId,
        string $action,
        string $entityType,
        ?int $entityId = null,
        ?array $before = null,
        ?array $after = null
    ): void {
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'INSERT INTO audit_logs
             (actor_type, actor_id, action, entity_type, entity_id, ip_address, user_agent, request_id, before_json, after_json)
             VALUES
             (:actor_type, :actor_id, :action, :entity_type, :entity_id, :ip, :ua, :request_id, :before_json, :after_json)'
        );
        $stmt->execute([
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'ip' => Security::clientIp(),
            'ua' => Security::userAgent(),
            'request_id' => $_SERVER['HTTP_X_REQUEST_ID'] ?? null,
            'before_json' => $before !== null ? json_encode($before) : null,
            'after_json' => $after !== null ? json_encode($after) : null,
        ]);
    }
}
