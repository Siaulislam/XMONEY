<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\Database;
use XMoney\Utils\Security;

final class TransactionService
{
    public function __construct(
        private readonly ExchangeService $exchange = new ExchangeService(),
        private readonly AuditService $audit = new AuditService(),
        private readonly NotificationService $notifications = new NotificationService(),
        private readonly SettingsService $settings = new SettingsService()
    ) {
    }

    public function create(int $userId, int $beneficiaryId, float $sendAmount, string $sourceCurrency, ?string $paymentMethod = null): array
    {
        $pdo = Database::connection();

        $sourceCurrency = strtoupper($sourceCurrency);
        $this->assertTransferLimits($userId, $sendAmount, $sourceCurrency);

        $ben = $pdo->prepare(
            'SELECT * FROM beneficiaries WHERE id = :id AND user_id = :uid AND deleted_at IS NULL AND is_active = 1'
        );
        $ben->execute(['id' => $beneficiaryId, 'uid' => $userId]);
        $beneficiary = $ben->fetch();
        if (!$beneficiary) {
            throw new \RuntimeException('Beneficiary not found');
        }

        $user = $pdo->prepare('SELECT kyc_status, status FROM users WHERE id = :id');
        $user->execute(['id' => $userId]);
        $u = $user->fetch();
        if (!$u || $u['status'] !== 'active') {
            throw new \RuntimeException('Account is not active');
        }
        if ($this->settings->getBool('kyc.required_for_transfer', true) && $u['kyc_status'] !== 'approved') {
            throw new \RuntimeException('KYC approval required before transfer');
        }

        $quote = $this->exchange->quote(
            strtoupper($sourceCurrency),
            $beneficiary['currency_code'],
            $sendAmount,
            $beneficiary['country_code']
        );
        if (!$quote) {
            throw new \RuntimeException('Exchange rate unavailable for this corridor');
        }

        $uuid = Security::uuid();
        $reference = $this->generateReference();

        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare(
                'INSERT INTO transactions
                 (uuid, reference_code, sender_user_id, beneficiary_id, source_currency, target_currency,
                  destination_country, send_amount, receive_amount, market_rate, margin, customer_rate,
                  fee_amount, fee_currency, total_debit, status, payment_method)
                 VALUES
                 (:uuid, :ref, :sender, :ben, :src, :tgt, :country, :send, :recv, :market, :margin, :crate,
                  :fee, :fee_cur, :total, \'created\', :pmethod)'
            );
            $stmt->execute([
                'uuid' => $uuid,
                'ref' => $reference,
                'sender' => $userId,
                'ben' => $beneficiaryId,
                'src' => $quote['source_currency'],
                'tgt' => $quote['target_currency'],
                'country' => $beneficiary['country_code'],
                'send' => $quote['send_amount'],
                'recv' => $quote['receive_amount'],
                'market' => $quote['market_rate'],
                'margin' => $quote['margin'],
                'crate' => $quote['customer_rate'],
                'fee' => $quote['fee_amount'],
                'fee_cur' => $quote['fee_currency'],
                'total' => $quote['total_debit'],
                'pmethod' => $paymentMethod,
            ]);
            $txnId = (int) $pdo->lastInsertId();

            $this->logStatus($txnId, null, 'created', 'user', $userId, 'Transfer created');
            $this->audit->log('user', $userId, 'transaction.created', 'transaction', $txnId, null, [
                'reference' => $reference,
                'send_amount' => $quote['send_amount'],
                'total_debit' => $quote['total_debit'],
            ]);

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        return $this->findById($txnId, $userId);
    }

    public function updateStatus(
        int $txnId,
        string $toStatus,
        string $actorType,
        ?int $actorId,
        ?string $note = null
    ): array {
        $pdo = Database::connection();
        $stmt = $pdo->prepare('SELECT * FROM transactions WHERE id = :id');
        $stmt->execute(['id' => $txnId]);
        $txn = $stmt->fetch();
        if (!$txn) {
            throw new \RuntimeException('Transaction not found');
        }

        $from = $txn['status'];
        if (!$this->canTransition($from, $toStatus)) {
            throw new \RuntimeException("Invalid status transition: {$from} → {$toStatus}");
        }

        $extra = '';
        if ($toStatus === 'completed') {
            $extra = ', completed_at = NOW(3)';
        } elseif ($toStatus === 'cancelled') {
            $extra = ', cancelled_at = NOW(3)';
        } elseif ($toStatus === 'refunded') {
            $extra = ', refunded_at = NOW(3)';
        }

        $pdo->prepare("UPDATE transactions SET status = :status {$extra} WHERE id = :id")
            ->execute(['status' => $toStatus, 'id' => $txnId]);

        $this->logStatus($txnId, $from, $toStatus, $actorType, $actorId, $note);
        $this->audit->log($actorType === 'admin' ? 'admin' : ($actorType === 'user' ? 'user' : 'system'), $actorId, 'transaction.status_changed', 'transaction', $txnId, ['status' => $from], ['status' => $toStatus]);

        if (in_array($toStatus, ['completed', 'failed', 'refunded'], true)) {
            $this->notifications->notifyUser(
                (int) $txn['sender_user_id'],
                'transfer_' . $toStatus,
                'Transfer ' . ucfirst(str_replace('_', ' ', $toStatus)),
                "Your transfer {$txn['reference_code']} is now {$toStatus}."
            );
        }

        return $this->findById($txnId);
    }

    public function findById(int $id, ?int $userId = null): array
    {
        $pdo = Database::connection();
        $sql = 'SELECT t.*, b.receiver_name, b.bank_name, b.account_number, b.iban
                FROM transactions t
                JOIN beneficiaries b ON b.id = t.beneficiary_id
                WHERE t.id = :id';
        $params = ['id' => $id];
        if ($userId !== null) {
            $sql .= ' AND t.sender_user_id = :uid';
            $params['uid'] = $userId;
        }
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch();
        if (!$row) {
            throw new \RuntimeException('Transaction not found');
        }
        return $row;
    }

    public function listForUser(int $userId, int $limit = 50, int $offset = 0): array
    {
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT t.id, t.uuid, t.reference_code, t.source_currency, t.target_currency,
                    t.send_amount, t.receive_amount, t.fee_amount, t.total_debit, t.status, t.created_at,
                    b.receiver_name, b.country_code
             FROM transactions t
             JOIN beneficiaries b ON b.id = t.beneficiary_id
             WHERE t.sender_user_id = :uid
             ORDER BY t.id DESC LIMIT :lim OFFSET :off'
        );
        $stmt->bindValue('uid', $userId, \PDO::PARAM_INT);
        $stmt->bindValue('lim', $limit, \PDO::PARAM_INT);
        $stmt->bindValue('off', $offset, \PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    private function logStatus(int $txnId, ?string $from, string $to, string $actorType, ?int $actorId, ?string $note): void
    {
        $pdo = Database::connection();
        $pdo->prepare(
            'INSERT INTO transaction_logs (transaction_id, from_status, to_status, actor_type, actor_id, note, ip_address)
             VALUES (:txn, :from_status, :to_status, :actor_type, :actor_id, :note, :ip)'
        )->execute([
            'txn' => $txnId,
            'from_status' => $from,
            'to_status' => $to,
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'note' => $note,
            'ip' => Security::clientIp(),
        ]);
    }

    private function canTransition(string $from, string $to): bool
    {
        $map = [
            'created' => ['pending_payment', 'cancelled'],
            'pending_payment' => ['processing', 'failed', 'cancelled'],
            'processing' => ['under_review', 'completed', 'failed'],
            'under_review' => ['processing', 'completed', 'failed', 'cancelled'],
            'completed' => ['refunded'],
            'failed' => ['refunded', 'processing'],
            'cancelled' => [],
            'refunded' => [],
        ];
        return in_array($to, $map[$from] ?? [], true);
    }

    private function generateReference(): string
    {
        return 'XM' . date('ymd') . strtoupper(bin2hex(random_bytes(4)));
    }

    private function assertTransferLimits(int $userId, float $sendAmount, string $sourceCurrency): void
    {
        $defaultCurrency = strtoupper((string) $this->settings->get('app.default_source_currency', 'AED'));
        $minKey = 'transfer.min_amount_' . strtolower($defaultCurrency);
        $maxKey = 'transfer.max_amount_' . strtolower($defaultCurrency);

        $min = $this->settings->getNumber($minKey, $this->settings->getNumber('transfer.min_amount_aed', 50));
        $max = $this->settings->getNumber($maxKey, $this->settings->getNumber('transfer.max_amount_aed', 50000));

        if ($sourceCurrency !== $defaultCurrency) {
            $quote = $this->exchange->quote($sourceCurrency, $defaultCurrency, $sendAmount);
            $amountInDefault = $quote ? (float) $quote['receive_amount'] : $sendAmount;
        } else {
            $amountInDefault = $sendAmount;
        }

        if ($amountInDefault < $min) {
            throw new \RuntimeException(sprintf('Minimum transfer amount is %s %s', number_format($min, 2), $defaultCurrency));
        }
        if ($amountInDefault > $max) {
            throw new \RuntimeException(sprintf('Maximum transfer amount is %s %s', number_format($max, 2), $defaultCurrency));
        }

        $pdo = Database::connection();
        $dailyMax = $this->settings->getNumber('transfer.daily_limit_aed', $max * 2);
        $stmt = $pdo->prepare(
            "SELECT COALESCE(SUM(send_amount), 0) FROM transactions
             WHERE sender_user_id = :uid AND DATE(created_at) = CURDATE()
             AND status NOT IN ('cancelled', 'failed', 'refunded')"
        );
        $stmt->execute(['uid' => $userId]);
        $sentToday = (float) $stmt->fetchColumn();
        if (($sentToday + $amountInDefault) > $dailyMax) {
            throw new \RuntimeException(sprintf('Daily transfer limit of %s %s exceeded', number_format($dailyMax, 2), $defaultCurrency));
        }
    }
}
