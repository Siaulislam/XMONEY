<?php

declare(strict_types=1);

namespace XMoney\Providers\Exchange;

use XMoney\Config\App;

/**
 * External FX API integration (Frankfurter, ExchangeRate-API, or custom URL template).
 *
 * Env:
 *   EXCHANGE_API_URL=https://api.frankfurter.app/latest
 *   EXCHANGE_API_KEY=optional
 */
final class ExternalApiExchangeProvider implements ExchangeRateProviderInterface
{
    public function __construct(
        private readonly ?string $apiUrl = null,
        private readonly ?string $apiKey = null
    ) {
    }

    public function fetchRate(string $sourceCurrency, string $targetCurrency): ?array
    {
        $url = $this->apiUrl ?? App::env('EXCHANGE_API_URL', '');
        if ($url === '') {
            return null;
        }

        $source = strtoupper($sourceCurrency);
        $target = strtoupper($targetCurrency);
        $margin = (float) (App::env('EXCHANGE_DEFAULT_MARGIN', '0.15') ?? '0.15');

        $endpoint = $this->buildEndpoint($url, $source, $target);
        $json = $this->httpGet($endpoint);
        if (!$json) {
            return null;
        }

        $market = $this->extractRate($json, $source, $target);
        if ($market === null || $market <= 0) {
            return null;
        }

        return [
            'market_rate' => $market,
            'margin' => $margin,
            'provider' => 'external_api',
        ];
    }

    private function buildEndpoint(string $base, string $source, string $target): string
    {
        $key = $this->apiKey ?? App::env('EXCHANGE_API_KEY', '');
        $base = rtrim($base, '/');

        if (str_contains($base, '{from}') || str_contains($base, '{to}')) {
            return str_replace(
                ['{from}', '{to}', '{key}'],
                [$source, $target, $key],
                $base
            );
        }

        if (str_contains($base, 'exchangerate.host')) {
            return $base . '?base=' . $source . '&symbols=' . $target . ($key ? '&access_key=' . urlencode($key) : '');
        }

        // Frankfurter / generic: ?from=AED&to=INR
        $sep = str_contains($base, '?') ? '&' : '?';
        return $base . $sep . 'from=' . urlencode($source) . '&to=' . urlencode($target);
    }

    private function extractRate(array $json, string $source, string $target): ?float
    {
        if (isset($json['rates'][$target])) {
            return (float) $json['rates'][$target];
        }
        if (isset($json['result'][$target])) {
            return (float) $json['result'][$target];
        }
        if (isset($json['conversion_rate'])) {
            return (float) $json['conversion_rate'];
        }
        if (isset($json['rate'])) {
            return (float) $json['rate'];
        }
        return null;
    }

    private function httpGet(string $url): ?array
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 10,
            CURLOPT_HTTPHEADER => ['Accept: application/json'],
        ]);
        $raw = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($code !== 200 || !$raw) {
            return null;
        }
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : null;
    }
}
