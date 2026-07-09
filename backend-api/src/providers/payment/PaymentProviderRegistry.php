<?php

declare(strict_types=1);

namespace XMoney\Providers\Payment;

use XMoney\Config\App;

/**
 * Resolves payment providers from configuration only.
 *
 * PAYMENT_DEFAULT_PROVIDER=stub|stripe|checkout|wise|uae_bank
 */
final class PaymentProviderRegistry
{
    /** @var array<string, class-string<PaymentProviderInterface>> */
    private const MAP = [
        'stub' => StubPaymentProvider::class,
        'stripe' => StripePaymentProvider::class,
        'checkout' => CheckoutPaymentProvider::class,
        'checkout.com' => CheckoutPaymentProvider::class,
        'wise' => WisePaymentProvider::class,
        'uae_bank' => UaeBankPaymentProvider::class,
        'uae-bank' => UaeBankPaymentProvider::class,
    ];

    public static function codes(): array
    {
        return array_keys(self::MAP);
    }

    public static function create(?string $code = null): PaymentProviderInterface
    {
        $code = strtolower(trim($code ?: (string) (App::env('PAYMENT_DEFAULT_PROVIDER', 'stub') ?? 'stub')));
        $class = self::MAP[$code] ?? StubPaymentProvider::class;
        return new $class();
    }
}
