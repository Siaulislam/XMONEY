<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Services\AuditService;
use XMoney\Services\PaymentService;
use XMoney\Utils\Response;

/**
 * Webhook entry points for payment providers.
 * Each provider posts to POST /v1/webhooks/payments/{provider}
 */
final class WebhookController
{
    public function payment(array $request): void
    {
        $provider = strtolower($request['params']['provider'] ?? '');
        if ($provider === '') {
            Response::error('Provider required', 400);
        }

        $body = $request['body'];
        if ($provider === 'stub' && empty($body['provider_ref']) && !empty($body['payment_uuid'])) {
            try {
                $payment = PaymentService::resolve('stub')->simulateCaptureForDevelopment((string) $body['payment_uuid']);
            } catch (\RuntimeException $e) {
                Response::error($e->getMessage(), 400);
            }
            Response::success($payment, 'Stub webhook processed');
        }

        try {
            $payment = PaymentService::resolve($provider)->handleWebhook($provider, $body);
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 400);
        }

        (new AuditService())->log('system', null, 'payment.webhook', 'payment', null, null, [
            'provider' => $provider,
            'payment_uuid' => $payment['uuid'] ?? null,
        ]);

        Response::success($payment, 'Webhook processed');
    }
}
