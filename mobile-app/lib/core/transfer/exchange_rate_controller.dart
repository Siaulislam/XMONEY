import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';

/// Live FX quote state for international transfer (debounced API calls).
class ExchangeRateController extends ChangeNotifier {
  ExchangeRateController(this.api);

  final ApiClient api;

  Map<String, dynamic>? quote;
  bool loading = false;
  String? error;
  Timer? _debounce;

  void disposeController() {
    _debounce?.cancel();
  }

  void refresh({
    required String sourceCurrency,
    required String targetCurrency,
    required double sendAmount,
    String? destinationCountry,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetch(
        sourceCurrency: sourceCurrency,
        targetCurrency: targetCurrency,
        sendAmount: sendAmount,
        destinationCountry: destinationCountry,
      );
    });
  }

  Future<void> _fetch({
    required String sourceCurrency,
    required String targetCurrency,
    required double sendAmount,
    String? destinationCountry,
  }) async {
    if (sendAmount <= 0) {
      quote = null;
      error = null;
      loading = false;
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    final res = await api.post('/v1/transfers/quote', {
      'source_currency': sourceCurrency,
      'target_currency': targetCurrency,
      'send_amount': sendAmount,
      if (destinationCountry != null) 'destination_country': destinationCountry,
    });

    if (res['success'] == true && res['data'] != null) {
      quote = res['data'] as Map<String, dynamic>;
      error = null;
    } else if (api.previewBypassAuth) {
      quote = _previewQuote(sourceCurrency, targetCurrency, sendAmount);
      error = null;
    } else {
      quote = null;
      error = res['message'] as String? ?? 'Exchange rate unavailable';
    }

    loading = false;
    notifyListeners();
  }

  Map<String, dynamic> _previewQuote(String src, String tgt, double amount) {
    final rate = _previewRate(src, tgt);
    final fee = (amount * 0.02).clamp(1.0, 25.0);
    final receive = (amount * rate * 100).round() / 100;
    return {
      'send_amount': amount,
      'source_currency': src,
      'target_currency': tgt,
      'customer_rate': rate,
      'receive_amount': receive,
      'fee_amount': double.parse(fee.toStringAsFixed(2)),
      'fee_currency': src,
      'total_debit': double.parse((amount + fee).toStringAsFixed(2)),
    };
  }

  double _previewRate(String src, String tgt) {
    const table = {
      'AED_PKR': 75.67,
      'AED_INR': 22.85,
      'AED_USD': 0.272,
      'AED_EUR': 0.25,
      'AED_GBP': 0.215,
      'USD_PKR': 278.0,
      'USD_INR': 83.5,
      'EUR_GBP': 0.86,
    };
    final key = '${src}_$tgt';
    final inv = '${tgt}_$src';
    if (table.containsKey(key)) return table[key]!;
    if (table.containsKey(inv)) return 1 / table[inv]!;
    return 1.0;
  }
}
