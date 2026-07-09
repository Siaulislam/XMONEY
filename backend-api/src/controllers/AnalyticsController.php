<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\Database;
use XMoney\Services\WalletService;
use XMoney\Utils\Response;

final class AnalyticsController
{
    public function customerSummary(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $pdo = Database::connection();

        $stats = $pdo->prepare(
            "SELECT
                COUNT(*) AS total_transfers,
                SUM(CASE WHEN status = 'completed' THEN send_amount ELSE 0 END) AS volume_completed,
                SUM(CASE WHEN status = 'completed' THEN fee_amount ELSE 0 END) AS fees_paid,
                SUM(CASE WHEN status IN ('processing','pending_payment','under_review') THEN 1 ELSE 0 END) AS in_progress,
                SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_count
             FROM transactions WHERE sender_user_id = :uid"
        );
        $stats->execute(['uid' => $userId]);
        $summary = $stats->fetch() ?: [];

        $monthly = $pdo->prepare(
            "SELECT DATE_FORMAT(created_at, '%Y-%m') AS period,
                    COUNT(*) AS count,
                    SUM(CASE WHEN status = 'completed' THEN send_amount ELSE 0 END) AS volume
             FROM transactions
             WHERE sender_user_id = :uid AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
             GROUP BY DATE_FORMAT(created_at, '%Y-%m')
             ORDER BY period ASC"
        );
        $monthly->execute(['uid' => $userId]);

        $wallets = $pdo->prepare(
            'SELECT currency_code, balance, available_balance, held_balance FROM wallets WHERE user_id = :uid'
        );
        $wallets->execute(['uid' => $userId]);

        $unread = $pdo->prepare(
            "SELECT COUNT(*) FROM notifications WHERE user_id = :uid AND channel = 'in_app' AND read_at IS NULL"
        );
        $unread->execute(['uid' => $userId]);

        Response::success([
            'transfers' => $summary,
            'monthly_volume' => $monthly->fetchAll(),
            'wallets' => $wallets->fetchAll(),
            'unread_notifications' => (int) $unread->fetchColumn(),
        ]);
    }

    public function adminOverview(array $request): void
    {
        $pdo = Database::connection();
        $days = min(90, max(7, (int) ($request['query']['days'] ?? 30)));

        $kpis = [
            'users_total' => (int) $pdo->query('SELECT COUNT(*) FROM users WHERE deleted_at IS NULL')->fetchColumn(),
            'users_active' => (int) $pdo->query("SELECT COUNT(*) FROM users WHERE status = 'active'")->fetchColumn(),
            'kyc_pending' => (int) $pdo->query("SELECT COUNT(*) FROM kyc_documents WHERE status = 'pending'")->fetchColumn(),
            'volume_today' => (float) $pdo->query("SELECT COALESCE(SUM(send_amount),0) FROM transactions WHERE DATE(created_at)=CURDATE() AND status='completed'")->fetchColumn(),
            'revenue_today' => (float) $pdo->query("SELECT COALESCE(SUM(fee_amount),0) FROM transactions WHERE DATE(created_at)=CURDATE() AND status='completed'")->fetchColumn(),
            'payments_pending' => (int) $pdo->query("SELECT COUNT(*) FROM payments WHERE status IN ('initiated','pending','authorized')")->fetchColumn(),
            'wallet_topups_today' => (int) $pdo->query("SELECT COUNT(*) FROM payments WHERE purpose='wallet_topup' AND DATE(created_at)=CURDATE()")->fetchColumn(),
        ];

        $daily = $pdo->prepare(
            "SELECT DATE(created_at) AS day,
                    COUNT(*) AS txn_count,
                    SUM(CASE WHEN status='completed' THEN send_amount ELSE 0 END) AS volume,
                    SUM(CASE WHEN status='completed' THEN fee_amount ELSE 0 END) AS revenue
             FROM transactions
             WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
             GROUP BY DATE(created_at) ORDER BY day ASC"
        );
        $daily->bindValue('days', $days, \PDO::PARAM_INT);
        $daily->execute();

        $byStatus = $pdo->query(
            "SELECT status, COUNT(*) AS count FROM transactions GROUP BY status ORDER BY count DESC"
        )->fetchAll();

        $topCorridors = $pdo->prepare(
            "SELECT source_currency, target_currency, COUNT(*) AS count,
                    SUM(CASE WHEN status='completed' THEN send_amount ELSE 0 END) AS volume
             FROM transactions
             WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
             GROUP BY source_currency, target_currency
             ORDER BY volume DESC LIMIT 10"
        );
        $topCorridors->bindValue('days', $days, \PDO::PARAM_INT);
        $topCorridors->execute();

        $paymentStats = $pdo->query(
            "SELECT provider_code, status, COUNT(*) AS count, SUM(amount) AS total
             FROM payments GROUP BY provider_code, status ORDER BY count DESC"
        )->fetchAll();

        Response::success([
            'kpis' => $kpis,
            'daily' => $daily->fetchAll(),
            'by_status' => $byStatus,
            'top_corridors' => $topCorridors->fetchAll(),
            'payments' => $paymentStats,
            'days' => $days,
        ]);
    }
}
