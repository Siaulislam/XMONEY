import '../api/api_client.dart';

/// Transfer quote, create, and confirm API calls.
class TransferRepository {
  TransferRepository(this.api);

  final ApiClient api;

  Future<Map<String, dynamic>?> quote({
    required String sourceCurrency,
    required String targetCurrency,
    required double sendAmount,
    String? destinationCountry,
  }) async {
    final res = await api.post('/v1/transfers/quote', {
      'source_currency': sourceCurrency,
      'target_currency': targetCurrency,
      'send_amount': sendAmount,
      if (destinationCountry != null) 'destination_country': destinationCountry,
    });
    if (res['success'] == true) return res['data'] as Map<String, dynamic>?;
    return null;
  }

  Future<String?> createTransfer({
    required String beneficiaryUuid,
    required double sendAmount,
    required String sourceCurrency,
    String paymentMethod = 'wallet',
  }) async {
    final res = await api.post('/v1/transfers', {
      'beneficiary_uuid': beneficiaryUuid,
      'send_amount': sendAmount,
      'source_currency': sourceCurrency,
      'payment_method': paymentMethod,
    });
    if (res['success'] == true) {
      return (res['data'] as Map?)?['uuid'] as String?;
    }
    return null;
  }

  Future<bool> confirmTransfer(String transferUuid, {String paymentMethod = 'wallet'}) async {
    final res = await api.post('/v1/transfers/$transferUuid/confirm', {
      'payment_method': paymentMethod,
    });
    return res['success'] == true;
  }
}
