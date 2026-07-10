/// International send-money product line (no duplicate modules).
enum InternationalTransferMode {
  wallet,
  bank;

  String get screenTitle {
    switch (this) {
      case InternationalTransferMode.wallet:
        return 'International Wallet Transfer';
      case InternationalTransferMode.bank:
        return 'International Bank Transfer';
    }
  }
}
