<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\Database;
use XMoney\Services\AuditService;
use XMoney\Utils\Response;
use XMoney\Utils\Security;
use XMoney\Utils\Validator;

final class BeneficiaryController
{
    public function index(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT uuid, receiver_name, country_code, currency_code, bank_name, account_number,
                    iban, mobile_country, mobile_number, verification_status, is_active, created_at
             FROM beneficiaries
             WHERE user_id = :uid AND deleted_at IS NULL
             ORDER BY id DESC'
        );
        $stmt->execute(['uid' => $userId]);
        Response::success($stmt->fetchAll());
    }

    public function store(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $body = $request['body'];
        $errors = Validator::validate($body, [
            'receiver_name' => 'required|min:2|max:200',
            'country_code' => 'required|min:2|max:2',
            'currency_code' => 'required|min:3|max:3',
        ]);
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }
        if (empty($body['account_number']) && empty($body['iban']) && empty($body['mobile_number'])) {
            Response::error('Provide account number, IBAN, or mobile number', 422);
        }

        $uuid = Security::uuid();
        $pdo = Database::connection();
        $pdo->prepare(
            'INSERT INTO beneficiaries
             (uuid, user_id, receiver_name, country_code, currency_code, bank_name, account_number,
              iban, swift_bic, mobile_country, mobile_number, relationship, verification_status)
             VALUES
             (:uuid, :uid, :name, :country, :cur, :bank, :acc, :iban, :swift, :mc, :mn, :rel, \'unverified\')'
        )->execute([
            'uuid' => $uuid,
            'uid' => $userId,
            'name' => trim($body['receiver_name']),
            'country' => strtoupper($body['country_code']),
            'cur' => strtoupper($body['currency_code']),
            'bank' => $body['bank_name'] ?? null,
            'acc' => $body['account_number'] ?? null,
            'iban' => $body['iban'] ?? null,
            'swift' => $body['swift_bic'] ?? null,
            'mc' => $body['mobile_country'] ?? null,
            'mn' => $body['mobile_number'] ?? null,
            'rel' => $body['relationship'] ?? null,
        ]);

        (new AuditService())->log('user', $userId, 'beneficiary.created', 'beneficiary', (int) $pdo->lastInsertId());
        Response::success(['uuid' => $uuid], 'Beneficiary added', 201);
    }

    public function update(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $uuid = $request['params']['uuid'] ?? '';
        $body = $request['body'];
        $pdo = Database::connection();

        $stmt = $pdo->prepare('SELECT id FROM beneficiaries WHERE uuid = :uuid AND user_id = :uid AND deleted_at IS NULL');
        $stmt->execute(['uuid' => $uuid, 'uid' => $userId]);
        $row = $stmt->fetch();
        if (!$row) {
            Response::error('Beneficiary not found', 404);
        }

        $pdo->prepare(
            'UPDATE beneficiaries SET
                receiver_name = COALESCE(:name, receiver_name),
                bank_name = COALESCE(:bank, bank_name),
                account_number = COALESCE(:acc, account_number),
                iban = COALESCE(:iban, iban),
                mobile_country = COALESCE(:mc, mobile_country),
                mobile_number = COALESCE(:mn, mobile_number),
                relationship = COALESCE(:rel, relationship)
             WHERE id = :id'
        )->execute([
            'name' => isset($body['receiver_name']) ? trim($body['receiver_name']) : null,
            'bank' => $body['bank_name'] ?? null,
            'acc' => $body['account_number'] ?? null,
            'iban' => $body['iban'] ?? null,
            'mc' => $body['mobile_country'] ?? null,
            'mn' => $body['mobile_number'] ?? null,
            'rel' => $body['relationship'] ?? null,
            'id' => $row['id'],
        ]);

        (new AuditService())->log('user', $userId, 'beneficiary.updated', 'beneficiary', (int) $row['id']);
        Response::success(null, 'Beneficiary updated');
    }

    public function destroy(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $uuid = $request['params']['uuid'] ?? '';
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'UPDATE beneficiaries SET deleted_at = NOW(3), is_active = 0
             WHERE uuid = :uuid AND user_id = :uid AND deleted_at IS NULL'
        );
        $stmt->execute(['uuid' => $uuid, 'uid' => $userId]);
        if ($stmt->rowCount() === 0) {
            Response::error('Beneficiary not found', 404);
        }
        (new AuditService())->log('user', $userId, 'beneficiary.deleted', 'beneficiary', null);
        Response::success(null, 'Beneficiary deleted');
    }

    public function verify(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $uuid = $request['params']['uuid'] ?? '';
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'UPDATE beneficiaries SET verification_status = \'pending\'
             WHERE uuid = :uuid AND user_id = :uid AND deleted_at IS NULL'
        );
        $stmt->execute(['uuid' => $uuid, 'uid' => $userId]);
        if ($stmt->rowCount() === 0) {
            Response::error('Beneficiary not found', 404);
        }
        Response::success(null, 'Beneficiary verification requested');
    }
}
