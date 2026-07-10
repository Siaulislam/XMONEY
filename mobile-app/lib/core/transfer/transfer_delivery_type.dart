/// Transfer delivery channel for beneficiaries.
enum TransferDeliveryType {
  international,
  bank,
  wallet,
  local,
  cnic,
  qr;

  static TransferDeliveryType fromString(String? v) {
    switch (v?.toLowerCase()) {
      case 'wallet':
        return TransferDeliveryType.wallet;
      case 'cnic':
        return TransferDeliveryType.cnic;
      case 'local':
        return TransferDeliveryType.local;
      case 'qr':
        return TransferDeliveryType.qr;
      case 'international':
        return TransferDeliveryType.international;
      default:
        return TransferDeliveryType.bank;
    }
  }

  String get apiValue {
    switch (this) {
      case TransferDeliveryType.wallet:
        return 'wallet';
      case TransferDeliveryType.cnic:
        return 'cnic';
      case TransferDeliveryType.local:
        return 'local';
      case TransferDeliveryType.qr:
        return 'qr';
      case TransferDeliveryType.international:
        return 'international';
      case TransferDeliveryType.bank:
        return 'bank';
    }
  }

  String get label {
    switch (this) {
      case TransferDeliveryType.wallet:
        return 'Wallet';
      case TransferDeliveryType.cnic:
        return 'CNIC';
      case TransferDeliveryType.local:
        return 'Local';
      case TransferDeliveryType.qr:
        return 'QR';
      case TransferDeliveryType.international:
        return 'International';
      case TransferDeliveryType.bank:
        return 'Bank';
    }
  }
}
