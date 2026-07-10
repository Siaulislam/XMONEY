import 'wallet_provider.dart';

/// Maps a destination country to its supported digital wallet providers.
class CountryWalletMapping {
  const CountryWalletMapping({
    required this.countryCode,
    required this.providers,
    this.countryName,
  });

  final String countryCode;
  final String? countryName;
  final List<WalletProvider> providers;

  bool get hasWallets => providers.isNotEmpty;

  static CountryWalletMapping empty(String countryCode, {String? countryName}) {
    return CountryWalletMapping(countryCode: countryCode, countryName: countryName, providers: const []);
  }
}
