<?php

declare(strict_types=1);

namespace XMoney\Services;

use XMoney\Config\Database;

final class DigitalWalletService
{
    /**
     * Full catalog + country mappings for mobile app bootstrap.
     *
     * @return array{providers: list<array>, mappings: list<array>}
     */
    public function catalog(): array
    {
        $pdo = Database::connection();
        if (!$this->tablesExist($pdo)) {
            return $this->fallbackCatalog();
        }

        $providers = $pdo->query(
            'SELECT code, name, description, logo_url, brand_color
             FROM digital_wallet_providers
             WHERE is_active = 1
             ORDER BY name'
        )->fetchAll();

        $mappings = [];
        $rows = $pdo->query(
            'SELECT cdw.country_code,
                    GROUP_CONCAT(dwp.code ORDER BY cdw.sort_order, dwp.name SEPARATOR ",") AS provider_codes
             FROM country_digital_wallets cdw
             INNER JOIN digital_wallet_providers dwp ON dwp.id = cdw.provider_id
             WHERE cdw.is_active = 1 AND dwp.is_active = 1
             GROUP BY cdw.country_code
             ORDER BY cdw.country_code'
        )->fetchAll();

        foreach ($rows as $row) {
            $codes = array_values(array_filter(explode(',', (string) $row['provider_codes'])));
            $mappings[] = [
                'countryCode' => strtoupper((string) $row['country_code']),
                'providerCodes' => $codes,
            ];
        }

        return [
            'providers' => array_map(static fn (array $p) => [
                'code' => $p['code'],
                'name' => $p['name'],
                'description' => $p['description'],
                'logo_url' => $p['logo_url'],
                'brand_color' => $p['brand_color'],
            ], $providers),
            'mappings' => $mappings,
        ];
    }

    /**
     * Providers available for a destination country.
     *
     * @return list<array>
     */
    public function forCountry(string $countryCode): array
    {
        $countryCode = strtoupper($countryCode);
        $pdo = Database::connection();
        if (!$this->tablesExist($pdo)) {
            $catalog = $this->fallbackCatalog();
            $codes = [];
            foreach ($catalog['mappings'] as $m) {
                if (($m['countryCode'] ?? '') === $countryCode) {
                    $codes = $m['providerCodes'] ?? [];
                    break;
                }
            }
            $byCode = [];
            foreach ($catalog['providers'] as $p) {
                $byCode[$p['code']] = $p;
            }
            $out = [];
            foreach ($codes as $code) {
                if (isset($byCode[$code])) {
                    $out[] = $byCode[$code];
                }
            }
            return $out;
        }

        $stmt = $pdo->prepare(
            'SELECT dwp.code, dwp.name, dwp.description, dwp.logo_url, dwp.brand_color, cdw.sort_order
             FROM country_digital_wallets cdw
             INNER JOIN digital_wallet_providers dwp ON dwp.id = cdw.provider_id
             WHERE cdw.country_code = :cc AND cdw.is_active = 1 AND dwp.is_active = 1
             ORDER BY cdw.sort_order, dwp.name'
        );
        $stmt->execute(['cc' => $countryCode]);
        return array_map(static fn (array $p) => [
            'code' => $p['code'],
            'name' => $p['name'],
            'description' => $p['description'],
            'logo_url' => $p['logo_url'],
            'brand_color' => $p['brand_color'],
            'sort_order' => (int) $p['sort_order'],
        ], $stmt->fetchAll());
    }

    private function tablesExist(\PDO $pdo): bool
    {
        try {
            $pdo->query('SELECT 1 FROM digital_wallet_providers LIMIT 1');
            return true;
        } catch (\Throwable) {
            return false;
        }
    }

    /** @return array{providers: list<array>, mappings: list<array>} */
    private function fallbackCatalog(): array
    {
        $path = dirname(__DIR__, 3) . '/mobile-app/assets/data/country_wallet_providers.json';
        if (!is_readable($path)) {
            return ['providers' => [], 'mappings' => []];
        }
        $json = json_decode((string) file_get_contents($path), true);
        return is_array($json) ? $json : ['providers' => [], 'mappings' => []];
    }
}
