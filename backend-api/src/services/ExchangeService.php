<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\Database;
use XMoney\Providers\Exchange\ExchangeRateProviderInterface;
use XMoney\Providers\Exchange\ManualExchangeProvider;

final class ExchangeService
{
    public function __construct(
        private readonly ExchangeRateProviderInterface $provider = new ManualExchangeProvider()
    ) {
    }

    public function getCustomerRate(string $source, string $target): ?array
    {
        $source = strtoupper($source);
        $target = strtoupper($target);

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT * FROM exchange_rates
             WHERE source_currency = :s AND target_currency = :t
               AND is_active = 1
               AND effective_from <= NOW(3)
               AND (effective_to IS NULL OR effective_to > NOW(3))
             ORDER BY effective_from DESC LIMIT 1'
        );
        $stmt->execute(['s' => $source, 't' => $target]);
        $row = $stmt->fetch();
        if ($row) {
            return [
                'source_currency' => $row['source_currency'],
                'target_currency' => $row['target_currency'],
                'market_rate' => (float) $row['market_rate'],
                'margin' => (float) $row['margin'],
                'customer_rate' => (float) $row['customer_rate'],
                'provider' => $row['provider'],
            ];
        }

        $external = $this->provider->fetchRate($source, $target);
        if (!$external) {
            return null;
        }

        $margin = (float) ($external['margin'] ?? 0.15);
        $market = (float) $external['market_rate'];
        $customer = $this->applyMargin($market, $margin);

        $pdo->prepare(
            'INSERT INTO exchange_rates
             (source_currency, target_currency, market_rate, margin, customer_rate, provider, effective_from, is_active)
             VALUES (:s, :t, :market, :margin, :customer, :provider, NOW(3), 1)'
        )->execute([
            's' => $source,
            't' => $target,
            'market' => $market,
            'margin' => $margin,
            'customer' => $customer,
            'provider' => $external['provider'] ?? 'external',
        ]);

        return [
            'source_currency' => $source,
            'target_currency' => $target,
            'market_rate' => $market,
            'margin' => $margin,
            'customer_rate' => $customer,
            'provider' => $external['provider'] ?? 'external',
        ];
    }

    public function quote(string $source, string $target, float $sendAmount, ?string $country = null): ?array
    {
        $rate = $this->getCustomerRate($source, $target);
        if (!$rate) {
            return null;
        }

        $fee = $this->calculateFee($source, $target, $sendAmount, $country);
        $receive = round($sendAmount * (float) $rate['customer_rate'], 2);
        $totalDebit = round($sendAmount + $fee['fee_amount'], 2);

        return [
            'send_amount' => $sendAmount,
            'source_currency' => $source,
            'target_currency' => $target,
            'destination_country' => $country,
            'market_rate' => $rate['market_rate'],
            'margin' => $rate['margin'],
            'customer_rate' => $rate['customer_rate'],
            'receive_amount' => $receive,
            'fee_amount' => $fee['fee_amount'],
            'fee_currency' => $source,
            'fee_name' => $fee['name'],
            'total_debit' => $totalDebit,
        ];
    }

    public function applyMargin(float $marketRate, float $margin): float
    {
        return round(max(0, $marketRate - $margin), 8);
    }

    private function calculateFee(string $source, string $target, float $amount, ?string $country): array
    {
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT * FROM fees WHERE is_active = 1
             AND (source_currency IS NULL OR source_currency = :s)
             AND (target_currency IS NULL OR target_currency = :t)
             AND (destination_country IS NULL OR destination_country = :c)
             AND min_amount <= :amount
             AND (max_amount IS NULL OR max_amount >= :amount2)
             ORDER BY priority ASC, id ASC LIMIT 1'
        );
        $stmt->execute([
            's' => $source,
            't' => $target,
            'c' => $country,
            'amount' => $amount,
            'amount2' => $amount,
        ]);
        $fee = $stmt->fetch();
        if (!$fee) {
            return ['fee_amount' => 0.0, 'name' => 'No fee'];
        }

        $value = 0.0;
        if ($fee['fee_type'] === 'flat') {
            $value = (float) $fee['flat_amount'];
        } elseif ($fee['fee_type'] === 'percent') {
            $value = $amount * ((float) $fee['percent_value'] / 100);
            if ($fee['min_fee'] !== null) {
                $value = max($value, (float) $fee['min_fee']);
            }
            if ($fee['max_fee'] !== null) {
                $value = min($value, (float) $fee['max_fee']);
            }
        }

        return ['fee_amount' => round($value, 4), 'name' => $fee['name']];
    }
}
