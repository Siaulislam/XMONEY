<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Services\DigitalWalletService;
use XMoney\Utils\Response;

final class DigitalWalletController
{
    public function __construct(
        private readonly DigitalWalletService $wallets = new DigitalWalletService()
    ) {
    }

    /** GET /v1/digital-wallets — full catalog or ?country=PK */
    public function index(array $request): void
    {
        $country = isset($request['query']['country'])
            ? strtoupper((string) $request['query']['country'])
            : null;

        if ($country !== null && $country !== '') {
            Response::success([
                'country_code' => $country,
                'providers' => $this->wallets->forCountry($country),
            ]);
            return;
        }

        Response::success($this->wallets->catalog());
    }
}
