import '../transfer/transfer_delivery_type.dart';

/// Saved or draft transfer beneficiary.
class Beneficiary {
  const Beneficiary({
    required this.uuid,
    required this.receiverName,
    required this.countryCode,
    required this.currencyCode,
    this.nickname,
    this.deliveryMethod = TransferDeliveryType.bank,
    this.walletProviderCode,
    this.walletProviderName,
    this.bankName,
    this.branchName,
    this.accountNumber,
    this.iban,
    this.swiftBic,
    this.mobileCountry,
    this.mobileNumber,
    this.email,
    this.addressLine,
    this.receiverCity,
    this.receiverState,
    this.postalCode,
    this.nationalId,
    this.purposeOfTransfer,
    this.relationship,
    this.verificationStatus = 'unverified',
    this.isFavourite = false,
    this.lastUsedAt,
    this.createdAt,
  });

  final String uuid;
  final String receiverName;
  final String? nickname;
  final String countryCode;
  final String currencyCode;
  final TransferDeliveryType deliveryMethod;
  final String? walletProviderCode;
  final String? walletProviderName;
  final String? bankName;
  final String? branchName;
  final String? accountNumber;
  final String? iban;
  final String? swiftBic;
  final String? mobileCountry;
  final String? mobileNumber;
  final String? email;
  final String? addressLine;
  final String? receiverCity;
  final String? receiverState;
  final String? postalCode;
  final String? nationalId;
  final String? purposeOfTransfer;
  final String? relationship;
  final String verificationStatus;
  final bool isFavourite;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  String get displayName => (nickname?.isNotEmpty == true) ? nickname! : receiverName;

  bool get isWallet => deliveryMethod == TransferDeliveryType.wallet;

  static Beneficiary? fromJson(Map<String, dynamic> json) {
    final uuid = json['uuid'] as String?;
    final name = json['receiver_name'] as String?;
    final cc = json['country_code'] as String?;
    final cur = json['currency_code'] as String?;
    if (uuid == null || name == null || cc == null || cur == null) return null;
    return Beneficiary(
      uuid: uuid,
      receiverName: name,
      nickname: json['nickname'] as String?,
      countryCode: cc,
      currencyCode: cur,
      deliveryMethod: TransferDeliveryType.fromString(json['delivery_method'] as String?),
      walletProviderCode: json['wallet_provider_code'] as String?,
      walletProviderName: json['wallet_provider_name'] as String?,
      bankName: json['bank_name'] as String?,
      branchName: json['branch_name'] as String?,
      accountNumber: json['account_number'] as String?,
      iban: json['iban'] as String?,
      swiftBic: json['swift_bic'] as String?,
      mobileCountry: json['mobile_country'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      email: json['email'] as String?,
      addressLine: json['address_line'] as String?,
      receiverCity: json['receiver_city'] as String?,
      receiverState: json['receiver_state'] as String?,
      postalCode: json['postal_code'] as String?,
      nationalId: json['national_id'] as String?,
      purposeOfTransfer: json['purpose_of_transfer'] as String?,
      relationship: json['relationship'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'unverified',
      isFavourite: json['is_favourite'] == true || json['is_favourite'] == 1,
      lastUsedAt: _parseDate(json['last_used_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'receiver_name': receiverName,
      if (nickname != null && nickname!.isNotEmpty) 'nickname': nickname,
      'country_code': countryCode,
      'currency_code': currencyCode,
      'delivery_method': deliveryMethod.apiValue,
      if (walletProviderCode != null) 'wallet_provider_code': walletProviderCode,
      if (bankName != null) 'bank_name': bankName,
      if (branchName != null) 'branch_name': branchName,
      if (accountNumber != null) 'account_number': accountNumber,
      if (iban != null) 'iban': iban,
      if (swiftBic != null) 'swift_bic': swiftBic,
      if (mobileCountry != null) 'mobile_country': mobileCountry,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (email != null) 'email': email,
      if (addressLine != null) 'address_line': addressLine,
      if (receiverCity != null) 'receiver_city': receiverCity,
      if (receiverState != null) 'receiver_state': receiverState,
      if (postalCode != null) 'postal_code': postalCode,
      if (nationalId != null) 'national_id': nationalId,
      if (purposeOfTransfer != null) 'purpose_of_transfer': purposeOfTransfer,
      if (relationship != null) 'relationship': relationship,
      'is_favourite': isFavourite,
    };
  }

  Beneficiary copyWith({bool? isFavourite, DateTime? lastUsedAt}) => Beneficiary(
        uuid: uuid,
        receiverName: receiverName,
        nickname: nickname,
        countryCode: countryCode,
        currencyCode: currencyCode,
        deliveryMethod: deliveryMethod,
        walletProviderCode: walletProviderCode,
        walletProviderName: walletProviderName,
        bankName: bankName,
        branchName: branchName,
        accountNumber: accountNumber,
        iban: iban,
        swiftBic: swiftBic,
        mobileCountry: mobileCountry,
        mobileNumber: mobileNumber,
        email: email,
        addressLine: addressLine,
        receiverCity: receiverCity,
        receiverState: receiverState,
        postalCode: postalCode,
        nationalId: nationalId,
        purposeOfTransfer: purposeOfTransfer,
        relationship: relationship,
        verificationStatus: verificationStatus,
        isFavourite: isFavourite ?? this.isFavourite,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        createdAt: createdAt,
      );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
