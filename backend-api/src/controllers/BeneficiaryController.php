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
        $query = $request['query'] ?? [];
        $pdo = Database::connection();

        $sql = 'SELECT uuid, receiver_name, nickname, country_code, currency_code, delivery_method,
                       wallet_provider_code, bank_name, branch_name, account_number, iban, swift_bic,
                       mobile_country, mobile_number, email, address_line, receiver_city, receiver_state,
                       postal_code, national_id, purpose_of_transfer, relationship, verification_status,
                       is_favourite, last_used_at, is_active, created_at
                FROM beneficiaries
                WHERE user_id = :uid AND deleted_at IS NULL';
        $params = ['uid' => $userId];

        if (!empty($query['country_code'])) {
            $sql .= ' AND country_code = :cc';
            $params['cc'] = strtoupper((string) $query['country_code']);
        }
        if (!empty($query['currency_code'])) {
            $sql .= ' AND currency_code = :cur';
            $params['cur'] = strtoupper((string) $query['currency_code']);
        }
        if (!empty($query['delivery_method'])) {
            $sql .= ' AND delivery_method = :dm';
            $params['dm'] = strtolower((string) $query['delivery_method']);
        }

        $sql .= ' ORDER BY is_favourite DESC, last_used_at DESC, id DESC';

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
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

        $delivery = strtolower((string) ($body['delivery_method'] ?? 'bank'));
        $isWallet = $delivery === 'wallet';
        if (!$isWallet && empty($body['account_number']) && empty($body['iban']) && empty($body['mobile_number'])) {
            Response::error('Provide account number, IBAN, or mobile number', 422);
        }
        if ($isWallet && empty($body['mobile_number']) && empty($body['account_number'])) {
            Response::error('Provide wallet number or mobile number', 422);
        }

        $uuid = Security::uuid();
        $pdo = Database::connection();
        $pdo->prepare(
            'INSERT INTO beneficiaries
             (uuid, user_id, receiver_name, nickname, country_code, currency_code, delivery_method,
              wallet_provider_code, bank_name, branch_name, account_number, iban, swift_bic,
              mobile_country, mobile_number, email, address_line, receiver_city, receiver_state,
              postal_code, national_id, purpose_of_transfer, relationship, is_favourite, verification_status)
             VALUES
             (:uuid, :uid, :name, :nick, :country, :cur, :dm, :wpc, :bank, :branch, :acc, :iban, :swift,
              :mc, :mn, :email, :addr, :city, :state, :postal, :nid, :purpose, :rel, :fav, \'unverified\')'
        )->execute([
            'uuid' => $uuid,
            'uid' => $userId,
            'name' => trim($body['receiver_name']),
            'nick' => $body['nickname'] ?? null,
            'country' => strtoupper($body['country_code']),
            'cur' => strtoupper($body['currency_code']),
            'dm' => $delivery,
            'wpc' => $body['wallet_provider_code'] ?? null,
            'bank' => $body['bank_name'] ?? null,
            'branch' => $body['branch_name'] ?? null,
            'acc' => $body['account_number'] ?? ($body['wallet_number'] ?? null),
            'iban' => $body['iban'] ?? null,
            'swift' => $body['swift_bic'] ?? null,
            'mc' => $body['mobile_country'] ?? null,
            'mn' => $body['mobile_number'] ?? null,
            'email' => $body['email'] ?? null,
            'addr' => $body['address_line'] ?? null,
            'city' => $body['receiver_city'] ?? null,
            'state' => $body['receiver_state'] ?? null,
            'postal' => $body['postal_code'] ?? null,
            'nid' => $body['national_id'] ?? null,
            'purpose' => $body['purpose_of_transfer'] ?? null,
            'rel' => $body['relationship'] ?? null,
            'fav' => !empty($body['is_favourite']) ? 1 : 0,
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
                nickname = COALESCE(:nick, nickname),
                bank_name = COALESCE(:bank, bank_name),
                branch_name = COALESCE(:branch, branch_name),
                account_number = COALESCE(:acc, account_number),
                iban = COALESCE(:iban, iban),
                swift_bic = COALESCE(:swift, swift_bic),
                mobile_country = COALESCE(:mc, mobile_country),
                mobile_number = COALESCE(:mn, mobile_number),
                email = COALESCE(:email, email),
                address_line = COALESCE(:addr, address_line),
                receiver_city = COALESCE(:city, receiver_city),
                receiver_state = COALESCE(:state, receiver_state),
                postal_code = COALESCE(:postal, postal_code),
                national_id = COALESCE(:nid, national_id),
                purpose_of_transfer = COALESCE(:purpose, purpose_of_transfer),
                relationship = COALESCE(:rel, relationship),
                is_favourite = COALESCE(:fav, is_favourite),
                last_used_at = COALESCE(:last_used, last_used_at)
             WHERE id = :id'
        )->execute([
            'name' => isset($body['receiver_name']) ? trim($body['receiver_name']) : null,
            'nick' => $body['nickname'] ?? null,
            'bank' => $body['bank_name'] ?? null,
            'branch' => $body['branch_name'] ?? null,
            'acc' => $body['account_number'] ?? null,
            'iban' => $body['iban'] ?? null,
            'swift' => $body['swift_bic'] ?? null,
            'mc' => $body['mobile_country'] ?? null,
            'mn' => $body['mobile_number'] ?? null,
            'email' => $body['email'] ?? null,
            'addr' => $body['address_line'] ?? null,
            'city' => $body['receiver_city'] ?? null,
            'state' => $body['receiver_state'] ?? null,
            'postal' => $body['postal_code'] ?? null,
            'nid' => $body['national_id'] ?? null,
            'purpose' => $body['purpose_of_transfer'] ?? null,
            'rel' => $body['relationship'] ?? null,
            'fav' => array_key_exists('is_favourite', $body) ? ($body['is_favourite'] ? 1 : 0) : null,
            'last_used' => $body['last_used_at'] ?? null,
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
