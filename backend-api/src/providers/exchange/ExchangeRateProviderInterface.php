<?php

declare(strict_types=1);

namespace XMoney\Providers\Exchange;

interface ExchangeRateProviderInterface
{
    /**
     * @return array{market_rate:float,margin?:float,provider?:string}|null
     */
    public function fetchRate(string $sourceCurrency, string $targetCurrency): ?array;
}
