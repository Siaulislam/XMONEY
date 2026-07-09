<?php

declare(strict_types=1);

namespace XMoney\Providers\Exchange;

/**
 * Placeholder for future external FX API integration.
 * Configure EXCHANGE_API_URL + EXCHANGE_API_KEY when ready.
 */
final class ExternalApiExchangeProvider implements ExchangeRateProviderInterface
{
    public function __construct(
        private readonly string $apiUrl,
        private readonly string $apiKey
    ) {
    }

    public function fetchRate(string $sourceCurrency, string $targetCurrency): ?array
    {
        if ($this->apiUrl === '' || $this->apiKey === '') {
            return null;
        }

        // Provider-agnostic hook — implement HTTP call when credentials are supplied.
        // Expected response mapping: market mid rate for source->target.
        return null;
    }
}
