/// ISO country + currency pair for picker lists.
class CountryCurrencyOption {
  const CountryCurrencyOption({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencyName,
  });

  final String countryCode;
  final String countryName;
  final String currencyCode;
  final String currencyName;

  String get id => '${countryCode}_$currencyCode';

  static CountryCurrencyOption? tryParse(Map<String, dynamic> json) {
    final cc = json['countryCode'] as String?;
    final cn = json['countryName'] as String?;
    final cur = json['currencyCode'] as String?;
    final curName = json['currencyName'] as String?;
    if (cc == null || cn == null || cur == null || curName == null) return null;
    return CountryCurrencyOption(
      countryCode: cc,
      countryName: cn,
      currencyCode: cur,
      currencyName: curName,
    );
  }
}

String countryFlagEmoji(String countryCode) {
  if (countryCode.length != 2) return '🏳️';
  final upper = countryCode.toUpperCase();
  final base = 0x1F1E6 - 'A'.codeUnitAt(0);
  return String.fromCharCodes([
    base + upper.codeUnitAt(0),
    base + upper.codeUnitAt(1),
  ]);
}
