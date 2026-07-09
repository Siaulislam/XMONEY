<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Services\PaymentService;
use XMoney\Utils\Response;

final class PaymentController
{
    public function show(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $uuid = $request['params']['uuid'] ?? '';
        try {
            $payment = PaymentService::resolve()->findByUuid($uuid, $userId);
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 404);
        }
        Response::success($payment);
    }

    public function simulateCapture(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $uuid = $request['params']['uuid'] ?? '';
        try {
            PaymentService::resolve()->findByUuid($uuid, $userId);
            $payment = PaymentService::resolve()->simulateCaptureForDevelopment($uuid);
        } catch (\RuntimeException $e) {
            Response::error($e->getMessage(), 400);
        }
        Response::success($payment, 'Payment captured (development simulation)');
    }
}
