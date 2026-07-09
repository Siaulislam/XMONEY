<?php

declare(strict_types=1);

/**
 * Seed admin password with a real bcrypt hash.
 * Usage: php scripts/seed-admin.php "ChangeMe@XMONEY2026"
 */

require dirname(__DIR__) . '/vendor/autoload.php';

use XMoney\Config\App;
use XMoney\Config\Database;

App::bootstrap(dirname(__DIR__));

$password = $argv[1] ?? 'ChangeMe@XMONEY2026';
$hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

$pdo = Database::connection();
$stmt = $pdo->prepare('UPDATE admin_users SET password_hash = :hash WHERE email = :email');
$stmt->execute(['hash' => $hash, 'email' => 'admin@xmoney.local']);

if ($stmt->rowCount() === 0) {
    echo "No admin row updated. Ensure seed SQL has been applied.\n";
    exit(1);
}

echo "Admin password updated for admin@xmoney.local\n";
echo "Password: {$password}\n";
echo "Change this immediately after first login.\n";
