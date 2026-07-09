<?php

declare(strict_types=1);

namespace XMoney\Providers\Payment;

interface PaymentProviderInterface
{
    public function code(): string;

    /**
     * @return array{status:string,provider_ref:?string,payload?:array}
     */
    public function initiate(array $payment): array;

    /**
     * @return array{status:string,provider_ref:?string,payload?:array}
     */
    public function capture(string $providerRef): array;

    /**
     * @return array{status:string,provider_ref:?string,payload?:array}
     */
    public function refund(string $providerRef, float $amount): array;
}
