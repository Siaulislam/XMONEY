import '../transfer/transfer_delivery_type.dart';

class BeneficiaryValidationResult {
  const BeneficiaryValidationResult({this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;
  bool get isValid => fieldErrors.isEmpty;
  String? operator [](String key) => fieldErrors[key];
}

class BeneficiaryValidator {
  static BeneficiaryValidationResult validate({
    required TransferDeliveryType method,
    required String receiverName,
    required String countryCode,
    required String currencyCode,
    String? mobileNumber,
    String? email,
    String? bankName,
    String? branchName,
    String? accountNumber,
    String? iban,
    String? swiftBic,
    String? walletNumber,
    String? walletProviderCode,
    String? addressLine,
    String? receiverCity,
    String? purpose,
    String? relationship,
    bool requireSwift = false,
  }) {
    final errors = <String, String>{};

    if (receiverName.trim().length < 2) {
      errors['receiver_name'] = 'Enter the full receiver name';
    }
    if (countryCode.length != 2) {
      errors['country_code'] = 'Select a valid country';
    }
    if (currencyCode.length != 3) {
      errors['currency_code'] = 'Select a valid currency';
    }
    if (email != null && email.isNotEmpty && !email.contains('@')) {
      errors['email'] = 'Enter a valid email address';
    }
    if (mobileNumber != null && mobileNumber.isNotEmpty && mobileNumber.replaceAll(RegExp(r'\D'), '').length < 8) {
      errors['mobile_number'] = 'Enter a valid mobile number';
    }

    switch (method) {
      case TransferDeliveryType.wallet:
        if (walletProviderCode == null || walletProviderCode.isEmpty) {
          errors['wallet_provider'] = 'Select a wallet provider';
        }
        if (walletNumber == null || walletNumber.trim().length < 5) {
          errors['wallet_number'] = 'Enter a valid wallet number';
        }
        break;
      case TransferDeliveryType.bank:
      case TransferDeliveryType.international:
        if ((bankName ?? '').trim().isEmpty) {
          errors['bank_name'] = 'Bank name is required';
        }
        final hasIban = (iban ?? '').trim().length >= 15;
        final hasAcc = (accountNumber ?? '').trim().length >= 6;
        if (!hasIban && !hasAcc) {
          errors['account_number'] = 'Enter IBAN or account number';
        }
        if (hasIban && !_isValidIban(iban!.trim())) {
          errors['iban'] = 'IBAN format looks invalid';
        }
        if (requireSwift && (swiftBic ?? '').trim().length < 8) {
          errors['swift_bic'] = 'SWIFT/BIC is required for this corridor';
        } else if ((swiftBic ?? '').isNotEmpty && !_isValidSwift(swiftBic!.trim())) {
          errors['swift_bic'] = 'SWIFT/BIC format looks invalid';
        }
        if ((addressLine ?? '').trim().length < 5) {
          errors['address_line'] = 'Receiver address is required';
        }
        if ((receiverCity ?? '').trim().length < 2) {
          errors['receiver_city'] = 'Receiver city is required';
        }
        break;
      case TransferDeliveryType.cnic:
        if ((accountNumber ?? '').trim().length < 5) {
          errors['national_id'] = 'CNIC number is required';
        }
        break;
      case TransferDeliveryType.local:
      case TransferDeliveryType.qr:
        if ((mobileNumber ?? '').trim().length < 8) {
          errors['mobile_number'] = 'Mobile number is required';
        }
        break;
    }

    if ((purpose ?? '').trim().isEmpty) {
      errors['purpose_of_transfer'] = 'Select purpose of transfer';
    }
    if ((relationship ?? '').trim().isEmpty) {
      errors['relationship'] = 'Select your relationship';
    }

    return BeneficiaryValidationResult(fieldErrors: errors);
  }

  static bool _isValidIban(String iban) {
    final clean = iban.replaceAll(' ', '').toUpperCase();
    return RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$').hasMatch(clean);
  }

  static bool _isValidSwift(String swift) {
    return RegExp(r'^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$').hasMatch(swift.toUpperCase());
  }
}
