<?php

declare(strict_types=1);

namespace XMoney\Providers\Exchange;

/**
 * Manual / DB-backed provider stub.
 * Replace with live API provider (e.g. Open Exchange Rates, Fixer) later.
 */
final class ManualExchangeProvider implements ExchangeRateProviderInterface
{
    public function fetchRate(string $sourceCurrency, string $targetCurrency): ?array
    {
        // No live fetch — rates must exist in exchange_rates table for local/dev.
        return null;
    }
}
