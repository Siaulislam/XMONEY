import 'package:flutter/material.dart';
import '../../core/theme/xmoney_theme.dart';
import '../../core/transfer/country_currency_option.dart';
import '../../core/transfer/country_repository.dart';
import '../../core/transfer/customer_country_service.dart';
import '../../core/transfer/local_transfer_repository.dart';
import '../../core/widgets/xm_country_flag.dart';
import '../../routes/app_router.dart';

/// Resolved customer country for local wallet/bank transfers.
class LocalTransferCountryContext {
  const LocalTransferCountryContext({
    required this.countryCode,
    required this.countryName,
    required this.currency,
  });

  final String countryCode;
  final String countryName;
  final CountryCurrencyOption? currency;
}

Future<LocalTransferCountryContext> resolveLocalTransferCountry(AppRouter router) async {
  await LocalTransferRepository.instance.ensureLoaded();
  await CountryRepository.instance.ensureLoaded();

  final countryService = CustomerCountryService(router.api);
  final code = await countryService.resolveCountryCode();
  final name = await countryService.resolveCountryName(code);
  final currency = CountryRepository.instance.defaultForCountry(code) ??
      CountryRepository.instance.tryFindById('${code}_${_guessCurrency(code)}');

  return LocalTransferCountryContext(
    countryCode: code,
    countryName: name,
    currency: currency,
  );
}

String _guessCurrency(String code) {
  const map = {'PK': 'PKR', 'AE': 'AED', 'IN': 'INR', 'BD': 'BDT'};
  return map[code.toUpperCase()] ?? 'USD';
}

/// Shows the customer's registered country — no country picker on local transfers.
class LocalTransferCountryBanner extends StatelessWidget {
  const LocalTransferCountryBanner({
    super.key,
    required this.countryCode,
    required this.countryName,
    this.currencyCode,
  });

  final String countryCode;
  final String countryName;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Row(
        children: [
          XmCountryFlag(countryCode: countryCode, width: 40, height: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your country', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                Text(
                  currencyCode != null ? '$countryName · $currencyCode' : countryName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: XmoneyTheme.listRowText),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Local transfers use your registered location',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, color: XmoneyTheme.teal),
        ],
      ),
    );
  }
}
