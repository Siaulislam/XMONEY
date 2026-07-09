<?php

declare(strict_types=1);

/**
 * Generate a bcrypt password hash for admin seeding.
 * Usage: php scripts/hash-password.php "YourSecurePassword"
 */

require dirname(__DIR__) . '/vendor/autoload.php';

$password = $argv[1] ?? null;
if (!$password) {
    fwrite(STDERR, "Usage: php scripts/hash-password.php \"YourSecurePassword\"\n");
    exit(1);
}

$hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
echo $hash . PHP_EOL;
echo "\nSQL:\nUPDATE admin_users SET password_hash = '{$hash}' WHERE email = 'admin@xmoney.local';\n";
