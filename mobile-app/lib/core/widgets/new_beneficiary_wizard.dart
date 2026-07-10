import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../beneficiaries/beneficiary_validator.dart';
import '../transfer/country_currency_option.dart';
import '../theme/xmoney_theme.dart';
import '../transfer/country_currency_option.dart';
import '../transfer/currency_repository.dart';
import '../transfer/transfer_delivery_type.dart';
import '../wallets/wallet_provider.dart';
import '../wallets/wallet_repository.dart';
import 'country_picker.dart';
import 'xm_country_flag.dart';
import 'wallet_selector.dart';
import '../wallets/country_wallet_mapping.dart';

typedef NewBeneficiarySubmit = void Function(Map<String, dynamic> draft, bool saveBeneficiary);

/// Multi-step new beneficiary wizard with dynamic fields.
class NewBeneficiaryWizard extends StatefulWidget {
  const NewBeneficiaryWizard({
    super.key,
    required this.api,
    required this.initialCountry,
    required this.initialCurrency,
    required this.deliveryMethod,
    this.walletProvider,
    this.initialBankName,
    required this.onSubmit,
  });

  final ApiClient api;
  final CountryCurrencyOption initialCountry;
  final String initialCurrency;
  final TransferDeliveryType deliveryMethod;
  final WalletProvider? walletProvider;
  final String? initialBankName;
  final NewBeneficiarySubmit onSubmit;

  @override
  State<NewBeneficiaryWizard> createState() => _NewBeneficiaryWizardState();
}

class _NewBeneficiaryWizardState extends State<NewBeneficiaryWizard> {
  final _page = PageController();
  int _step = 0;
  bool _saveBeneficiary = true;
  bool _agreed = false;

  late CountryCurrencyOption _country;
  late String _currency;
  WalletProvider? _walletProvider;

  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _bank = TextEditingController();
  final _branch = TextEditingController();
  final _iban = TextEditingController();
  final _account = TextEditingController();
  final _swift = TextEditingController();
  final _walletNumber = TextEditingController();
  final _nationalId = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  String _purpose = '';
  String _relationship = '';

  Map<String, String> _errors = {};
  CountryWalletMapping? _walletMapping;
  late final WalletRepository _walletRepo;

  static const _purposes = ['Family support', 'Education', 'Medical', 'Business', 'Gift', 'Other'];
  static const _relationships = ['Family', 'Friend', 'Self', 'Employee', 'Business partner', 'Other'];

  @override
  void initState() {
    super.initState();
    _country = widget.initialCountry;
    _currency = widget.initialCurrency;
    _walletProvider = widget.walletProvider;
    if (widget.initialBankName?.trim().isNotEmpty == true) {
      _bank.text = widget.initialBankName!.trim();
    }
    _walletRepo = WalletRepository(widget.api);
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final m = await _walletRepo.forCountry(_country.countryCode);
    if (mounted) setState(() => _walletMapping = m);
  }

  bool get _isWallet => widget.deliveryMethod == TransferDeliveryType.wallet;
  bool get _needsSwift => !['PK', 'IN', 'BD', 'AE', 'SA'].contains(_country.countryCode);

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    _nickname.dispose();
    _mobile.dispose();
    _email.dispose();
    _bank.dispose();
    _branch.dispose();
    _iban.dispose();
    _account.dispose();
    _swift.dispose();
    _walletNumber.dispose();
    _nationalId.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await CountryPicker.show(context, title: 'Receiver country', selectedCode: _country.countryCode);
    if (picked == null) return;
    final cur = CurrencyRepository.instance.defaultCurrencyForCountry(picked.countryCode);
    setState(() {
      _country = picked;
      _currency = cur?.currencyCode ?? picked.currencyCode;
    });
    await _loadWallets();
  }

  void _validateAndNext() {
    if (_step < 2) {
      setState(() {
        _step++;
        _page.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
      });
      return;
    }
    final result = BeneficiaryValidator.validate(
      method: widget.deliveryMethod,
      receiverName: _name.text,
      countryCode: _country.countryCode,
      currencyCode: _currency,
      mobileNumber: _mobile.text,
      email: _email.text,
      bankName: _bank.text,
      branchName: _branch.text,
      accountNumber: _account.text,
      iban: _iban.text,
      swiftBic: _swift.text,
      walletNumber: _walletNumber.text,
      walletProviderCode: _walletProvider?.code,
      addressLine: _address.text,
      receiverCity: _city.text,
      purpose: _purpose,
      relationship: _relationship,
      requireSwift: _needsSwift,
    );
    if (!result.isValid) {
      setState(() => _errors = result.fieldErrors);
      return;
    }
    if (!_agreed) {
      setState(() => _errors = {'terms': 'Please confirm Key Facts Statement'});
      return;
    }
    widget.onSubmit({
      'receiver_name': _name.text.trim(),
      'nickname': _nickname.text.trim(),
      'country_code': _country.countryCode,
      'currency_code': _currency,
      'delivery_method': widget.deliveryMethod.apiValue,
      'wallet_provider_code': _walletProvider?.code,
      'wallet_provider_name': _walletProvider?.name,
      'bank_name': _bank.text.trim(),
      'branch_name': _branch.text.trim(),
      'account_number': _account.text.trim(),
      'iban': _iban.text.trim(),
      'swift_bic': _swift.text.trim(),
      'mobile_number': _mobile.text.trim(),
      'email': _email.text.trim(),
      'address_line': _address.text.trim(),
      'receiver_city': _city.text.trim(),
      'receiver_state': _state.text.trim(),
      'postal_code': _postal.text.trim(),
      'national_id': _nationalId.text.trim(),
      'purpose_of_transfer': _purpose,
      'relationship': _relationship,
      'wallet_number': _walletNumber.text.trim(),
    }, _saveBeneficiary);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIndicator(step: _step, labels: const ['Receiver', 'Details', 'Review']),
        const SizedBox(height: 16),
        SizedBox(
          height: 520,
          child: PageView(
            controller: _page,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _stepReceiver(),
              _stepDetails(),
              _stepReview(),
            ],
          ),
        ),
        if (_errors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_errors.values.first, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _step--);
                    _page.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
                  },
                  child: const Text('Back'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _validateAndNext,
                style: FilledButton.styleFrom(backgroundColor: XmoneyTheme.blue, minimumSize: const Size(0, 52)),
                child: Text(_step == 2 ? 'Continue' : 'Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepReceiver() => ListView(
        children: [
          _fieldTile(
            'Receiver country',
            '${_country.countryName} · ${_country.currencyCode}',
            onTap: _pickCountry,
            leadingWidget: XmCountryFlag(countryCode: _country.countryCode),
          ),
          _tf('Currency', _currency, readOnly: true),
          _tf('Transfer method', widget.deliveryMethod.label, readOnly: true),
          if (_isWallet && _walletMapping != null) ...[
            const SizedBox(height: 8),
            WalletSelector(
              mapping: _walletMapping!,
              repository: _walletRepo,
              selected: _walletProvider,
              compact: true,
              onSelected: (p) => setState(() => _walletProvider = p),
            ),
            if (_errors['wallet_provider'] != null) _err(_errors['wallet_provider']!),
          ],
        ],
      );

  Widget _stepDetails() => ListView(
        children: [
          _tf('Full name', '', controller: _name, error: _errors['receiver_name']),
          _tf('Nickname (optional)', '', controller: _nickname),
          _tf('Mobile number', '', controller: _mobile, keyboard: TextInputType.phone, error: _errors['mobile_number']),
          _tf('Email (optional)', '', controller: _email, error: _errors['email']),
          if (!_isWallet) ...[
            _tf('Bank name', '', controller: _bank, error: _errors['bank_name']),
            _tf('Branch', '', controller: _branch),
            _tf('IBAN', '', controller: _iban, error: _errors['iban']),
            _tf('Account number', '', controller: _account, error: _errors['account_number']),
            if (_needsSwift) _tf('SWIFT / BIC', '', controller: _swift, error: _errors['swift_bic']),
          ] else ...[
            _tf('Wallet number', '', controller: _walletNumber, error: _errors['wallet_number']),
          ],
          _tf('Receiver address', '', controller: _address, error: _errors['address_line']),
          _tf('Receiver city', '', controller: _city, error: _errors['receiver_city']),
          _tf('State / province', '', controller: _state),
          _tf('Postal code', '', controller: _postal),
          _dropdown('Purpose of transfer', _purposes, _purpose, (v) => setState(() => _purpose = v), error: _errors['purpose_of_transfer']),
          _dropdown('Relationship', _relationships, _relationship, (v) => setState(() => _relationship = v), error: _errors['relationship']),
        ],
      );

  Widget _stepReview() => ListView(
        children: [
          _reviewRow('Receiver', _name.text),
          _reviewRow('Country', _country.countryName),
          _reviewRow('Currency', _currency),
          _reviewRow('Method', widget.deliveryMethod.label),
          if (_isWallet) _reviewRow('Wallet', _walletProvider?.name ?? '—'),
          if (!_isWallet) _reviewRow('Bank', _bank.text),
          SwitchListTile(
            value: _saveBeneficiary,
            onChanged: (v) => setState(() => _saveBeneficiary = v),
            title: const Text('Save this beneficiary', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Quick access for future transfers'),
          ),
          CheckboxListTile(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            title: const Text('I have read & understood Key Facts Statement'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      );

  Widget _fieldTile(String label, String value, {VoidCallback? onTap, Widget? leadingWidget}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (leadingWidget != null) ...[leadingWidget, const SizedBox(width: 10)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (onTap != null) Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _tf(String label, String hint, {TextEditingController? controller, bool readOnly = false, TextInputType? keyboard, String? error}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller ?? TextEditingController(text: hint),
          readOnly: readOnly,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
            filled: true,
            fillColor: const Color(0xFFF6F8FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _dropdown(String label, List<String> items, String value, ValueChanged<String> onChanged, {String? error}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
            filled: true,
            fillColor: const Color(0xFFF6F8FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );

  Widget _reviewRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(k, style: TextStyle(color: Colors.grey.shade600))),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _err(String m) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(m, style: const TextStyle(color: Colors.red, fontSize: 12)));
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.labels});
  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= step;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0) Expanded(child: Container(height: 2, color: active ? XmoneyTheme.teal : Colors.grey.shade300)),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: active ? XmoneyTheme.teal : Colors.grey.shade300,
                    child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : Colors.grey.shade700)),
                  ),
                  if (i < labels.length - 1) Expanded(child: Container(height: 2, color: i < step ? XmoneyTheme.teal : Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 6),
              Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? XmoneyTheme.navyDeep : Colors.grey.shade500)),
            ],
          ),
        );
      }),
    );
  }
}
