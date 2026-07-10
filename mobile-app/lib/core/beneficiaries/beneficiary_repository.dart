import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../transfer/transfer_delivery_type.dart';
import 'beneficiary.dart';

/// CRUD for transfer beneficiaries with preview-local fallback.
class BeneficiaryRepository {
  BeneficiaryRepository(this.api);

  final ApiClient api;
  static const _previewKey = 'xm_preview_beneficiaries';

  Future<List<Beneficiary>> list({
    String? countryCode,
    String? currencyCode,
    TransferDeliveryType? deliveryMethod,
  }) async {
    var path = '/v1/beneficiaries';
    final q = <String>[];
    if (countryCode != null) q.add('country_code=${countryCode.toUpperCase()}');
    if (currencyCode != null) q.add('currency_code=${currencyCode.toUpperCase()}');
    if (deliveryMethod != null) q.add('delivery_method=${deliveryMethod.apiValue}');
    if (q.isNotEmpty) path += '?${q.join('&')}';

    final res = await api.get(path);
    if (res['success'] == true) {
      return ((res['data'] as List?) ?? [])
          .map((e) => Beneficiary.fromJson(e as Map<String, dynamic>))
          .whereType<Beneficiary>()
          .toList();
    }
    if (api.previewBypassAuth) return _loadPreview();
    return [];
  }

  Future<Beneficiary?> create(Beneficiary draft) async {
    final payload = draft.toCreatePayload();
    if (draft.deliveryMethod == TransferDeliveryType.wallet && draft.accountNumber != null) {
      payload['wallet_number'] = draft.accountNumber;
    }
    final res = await api.post('/v1/beneficiaries', payload);
    if (res['success'] == true) {
      final uuid = (res['data'] as Map?)?['uuid'] as String? ?? const Uuid().v4();
      return Beneficiary(
        uuid: uuid,
        receiverName: draft.receiverName,
        nickname: draft.nickname,
        countryCode: draft.countryCode,
        currencyCode: draft.currencyCode,
        deliveryMethod: draft.deliveryMethod,
        walletProviderCode: draft.walletProviderCode,
        walletProviderName: draft.walletProviderName,
        bankName: draft.bankName,
        branchName: draft.branchName,
        accountNumber: draft.accountNumber,
        iban: draft.iban,
        swiftBic: draft.swiftBic,
        mobileCountry: draft.mobileCountry,
        mobileNumber: draft.mobileNumber,
        email: draft.email,
        addressLine: draft.addressLine,
        receiverCity: draft.receiverCity,
        receiverState: draft.receiverState,
        postalCode: draft.postalCode,
        nationalId: draft.nationalId,
        purposeOfTransfer: draft.purposeOfTransfer,
        relationship: draft.relationship,
        isFavourite: draft.isFavourite,
        lastUsedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }
    if (api.previewBypassAuth) {
      final list = await _loadPreview();
      final b = Beneficiary(
        uuid: const Uuid().v4(),
        receiverName: draft.receiverName,
        nickname: draft.nickname,
        countryCode: draft.countryCode,
        currencyCode: draft.currencyCode,
        deliveryMethod: draft.deliveryMethod,
        walletProviderCode: draft.walletProviderCode,
        walletProviderName: draft.walletProviderName,
        bankName: draft.bankName,
        branchName: draft.branchName,
        accountNumber: draft.accountNumber ?? draft.mobileNumber,
        iban: draft.iban,
        swiftBic: draft.swiftBic,
        mobileCountry: draft.mobileCountry,
        mobileNumber: draft.mobileNumber,
        email: draft.email,
        addressLine: draft.addressLine,
        receiverCity: draft.receiverCity,
        receiverState: draft.receiverState,
        postalCode: draft.postalCode,
        nationalId: draft.nationalId,
        purposeOfTransfer: draft.purposeOfTransfer,
        relationship: draft.relationship,
        isFavourite: draft.isFavourite,
        lastUsedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      list.insert(0, b);
      await _savePreview(list);
      return b;
    }
    return null;
  }

  Future<bool> delete(String uuid) async {
    final res = await api.delete('/v1/beneficiaries/$uuid');
    if (res['success'] == true) return true;
    if (api.previewBypassAuth) {
      final list = await _loadPreview();
      list.removeWhere((b) => b.uuid == uuid);
      await _savePreview(list);
      return true;
    }
    return false;
  }

  Future<bool> update(String uuid, Map<String, dynamic> body) async {
    final res = await api.put('/v1/beneficiaries/$uuid', body);
    return res['success'] == true;
  }

  Future<void> touchLastUsed(String uuid) async {
    await update(uuid, {'last_used_at': DateTime.now().toUtc().toIso8601String()});
  }

  Future<List<Beneficiary>> _loadPreview() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_previewKey);
    if (raw == null) return _seedPreview();
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Beneficiary.fromJson(e as Map<String, dynamic>))
          .whereType<Beneficiary>()
          .toList();
      return list.isEmpty ? _seedPreview() : list;
    } catch (_) {
      return _seedPreview();
    }
  }

  Future<void> _savePreview(List<Beneficiary> list) async {
    final prefs = await SharedPreferences.getInstance();
    final data = list.map((b) {
      final m = b.toCreatePayload();
      m['uuid'] = b.uuid;
      m['receiver_name'] = b.receiverName;
      m['verification_status'] = b.verificationStatus;
      m['is_favourite'] = b.isFavourite;
      if (b.lastUsedAt != null) m['last_used_at'] = b.lastUsedAt!.toIso8601String();
      if (b.createdAt != null) m['created_at'] = b.createdAt!.toIso8601String();
      return m;
    }).toList();
    await prefs.setString(_previewKey, jsonEncode(data));
  }

  List<Beneficiary> _seedPreview() {
    final seed = [
        Beneficiary(
          uuid: 'preview-1',
          receiverName: 'Saif Ul Islam',
          nickname: 'Saif',
          countryCode: 'PK',
          currencyCode: 'PKR',
          deliveryMethod: TransferDeliveryType.bank,
          bankName: 'HBL',
          accountNumber: '****4521',
          isFavourite: true,
          lastUsedAt: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
        ),
        Beneficiary(
          uuid: 'preview-2',
          receiverName: 'Sabreena Bibi',
          countryCode: 'PK',
          currencyCode: 'PKR',
          deliveryMethod: TransferDeliveryType.wallet,
          walletProviderCode: 'easypaisa',
          walletProviderName: 'Easypaisa',
          mobileNumber: '03001234567',
          lastUsedAt: DateTime.now().subtract(const Duration(days: 14)),
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
      ];
    return seed;
  }
}
