import '../transfer/country_currency_option.dart';
import '../transfer/local_transfer_repository.dart';
import '../transfer/transfer_delivery_type.dart';
import '../wallets/wallet_provider.dart';

/// Quote + corridor context passed into beneficiary selection.
class InternationalTransferContext {
  const InternationalTransferContext({
    required this.sender,
    required this.receiver,
    required this.sendAmount,
    required this.quote,
    this.payFromWalletId,
    required this.deliveryMethod,
    this.walletProvider,
    this.selectedBank,
  });

  final CountryCurrencyOption sender;
  final CountryCurrencyOption receiver;
  final double sendAmount;
  final Map<String, dynamic>? quote;
  final String? payFromWalletId;
  final TransferDeliveryType deliveryMethod;
  final WalletProvider? walletProvider;
  final LocalBank? selectedBank;

  bool get isWallet => deliveryMethod == TransferDeliveryType.wallet;
  bool get isBank => deliveryMethod == TransferDeliveryType.bank;
}
