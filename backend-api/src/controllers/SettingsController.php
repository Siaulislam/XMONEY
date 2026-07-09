<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Services\SettingsService;
use XMoney\Utils\Response;

final class SettingsController
{
    public function publicSettings(array $request): void
    {
        $settings = new SettingsService();
        Response::success([
            'app_name' => $settings->get('app.name', 'XMONEY'),
            'default_source_currency' => $settings->get('app.default_source_currency', 'AED'),
            'transfer_min_amount' => $settings->getNumber('transfer.min_amount_aed', 50),
            'transfer_max_amount' => $settings->getNumber('transfer.max_amount_aed', 50000),
            'transfer_daily_limit' => $settings->getNumber('transfer.daily_limit_aed', 100000),
            'kyc_required' => $settings->getBool('kyc.required_for_transfer', true),
        ]);
    }
}
