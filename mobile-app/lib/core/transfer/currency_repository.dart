import '../transfer/country_currency_option.dart';
import '../transfer/country_repository.dart';

/// Currency lookups derived from the worldwide ISO dataset.
class CurrencyRepository {
  CurrencyRepository._();
  static final CurrencyRepository instance = CurrencyRepository._();

  final _countries = CountryRepository.instance;

  Future<void> ensureLoaded() => _countries.ensureLoaded();

  List<CountryCurrencyOption> currenciesForCountry(String countryCode) {
    return _countries.all.where((e) => e.countryCode == countryCode.toUpperCase()).toList();
  }

  CountryCurrencyOption? defaultCurrencyForCountry(String countryCode) {
    return _countries.defaultForCountry(countryCode.toUpperCase());
  }
}
