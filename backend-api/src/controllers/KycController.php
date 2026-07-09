<?php

declare(strict_types=1);

namespace XMoney\Controllers;

use XMoney\Config\App;
use XMoney\Config\Database;
use XMoney\Services\AuditService;
use XMoney\Utils\Response;
use XMoney\Utils\Security;
use XMoney\Utils\Validator;

final class KycController
{
    public function listMine(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT uuid, document_type, document_number, country_code, status, expires_on,
                    reviewed_at, rejection_reason, created_at
             FROM kyc_documents WHERE user_id = :uid ORDER BY id DESC'
        );
        $stmt->execute(['uid' => $userId]);
        Response::success($stmt->fetchAll());
    }

    public function upload(array $request): void
    {
        $userId = (int) $request['user']['id'];
        $type = $_POST['document_type'] ?? $request['body']['document_type'] ?? null;
        $errors = Validator::validate(
            ['document_type' => $type],
            ['document_type' => 'required|in:passport,national_id,emirates_id,address_proof,selfie']
        );
        if ($errors) {
            Response::error('Validation failed', 422, $errors);
        }

        if (empty($_FILES['document']['tmp_name'])) {
            Response::error('Document file is required', 422);
        }

        $file = $_FILES['document'];
        $maxMb = (int) (App::env('UPLOAD_MAX_MB', '10') ?? '10');
        if ($file['size'] > $maxMb * 1024 * 1024) {
            Response::error("File exceeds {$maxMb}MB limit", 422);
        }

        $allowed = ['image/jpeg', 'image/png', 'application/pdf'];
        $finfo = new \finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($file['tmp_name']) ?: '';
        if (!in_array($mime, $allowed, true)) {
            Response::error('Only JPEG, PNG, or PDF allowed', 422);
        }

        $ext = match ($mime) {
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            default => 'pdf',
        };

        $uuid = Security::uuid();
        $relDir = 'kyc/' . $userId;
        $uploadRoot = realpath(App::basePath(App::env('UPLOAD_PATH', '../uploads') ?? '../uploads'));
        if ($uploadRoot === false) {
            $uploadRoot = App::basePath('../uploads');
            @mkdir($uploadRoot, 0755, true);
        }
        $destDir = $uploadRoot . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $relDir);
        if (!is_dir($destDir)) {
            mkdir($destDir, 0755, true);
        }
        $filename = $uuid . '.' . $ext;
        $destPath = $destDir . DIRECTORY_SEPARATOR . $filename;
        if (!move_uploaded_file($file['tmp_name'], $destPath)) {
            Response::error('Upload failed', 500);
        }

        $pdo = Database::connection();
        $pdo->prepare(
            'INSERT INTO kyc_documents
             (uuid, user_id, document_type, document_number, country_code, file_path, file_mime, file_size, status)
             VALUES (:uuid, :uid, :type, :num, :country, :path, :mime, :size, \'pending\')'
        )->execute([
            'uuid' => $uuid,
            'uid' => $userId,
            'type' => $type,
            'num' => $_POST['document_number'] ?? null,
            'country' => isset($_POST['country_code']) ? strtoupper($_POST['country_code']) : null,
            'path' => $relDir . '/' . $filename,
            'mime' => $mime,
            'size' => (int) $file['size'],
        ]);

        $pdo->prepare('UPDATE users SET kyc_status = \'pending\' WHERE id = :id AND kyc_status IN (\'none\',\'rejected\',\'expired\')')
            ->execute(['id' => $userId]);

        (new AuditService())->log('user', $userId, 'kyc.uploaded', 'kyc_document', (int) $pdo->lastInsertId());

        Response::success(['document_uuid' => $uuid, 'status' => 'pending'], 'KYC document uploaded', 201);
    }
}
