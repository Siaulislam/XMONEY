import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  List<dynamic> _beneficiaries = [];
  String? _selectedBen;
  final _amount = TextEditingController();
  Map<String, dynamic>? _quote;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.router.api.get('/v1/beneficiaries');
    setState(() {
      _beneficiaries = (res['data'] as List?) ?? [];
      _loading = false;
    });
  }

  Future<void> _quote() async {
    final ben = _beneficiaries.cast<Map<String, dynamic>>().firstWhere((b) => b['uuid'] == _selectedBen);
    final res = await widget.router.api.post('/v1/transfers/quote', {
      'source_currency': 'AED',
      'target_currency': ben['currency_code'],
      'send_amount': double.parse(_amount.text),
      'destination_country': ben['country_code'],
    });
    setState(() => _quote = res['data'] as Map<String, dynamic>?);
  }

  Future<void> _send() async {
    if (_quote == null || _selectedBen == null) return;
    final create = await widget.router.api.post('/v1/transfers', {
      'beneficiary_uuid': _selectedBen,
      'send_amount': _quote!['send_amount'],
      'source_currency': _quote!['source_currency'],
      'payment_method': 'wallet',
    });
    if (create['success'] != true) return;
    final uuid = (create['data'] as Map)['uuid'];
    await widget.router.api.post('/v1/transfers/$uuid/confirm', {'payment_method': 'wallet'});
    if (!mounted) return;
    showXmSnack(context, 'Transfer submitted');
    _amount.clear();
    setState(() => _quote = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send money')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedBen,
                    decoration: const InputDecoration(labelText: 'Beneficiary'),
                    items: _beneficiaries.map((b) {
                      final m = b as Map<String, dynamic>;
                      return DropdownMenuItem(value: m['uuid'] as String, child: Text(m['receiver_name'] as String));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedBen = v),
                  ),
                  TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (AED)')),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _quote, child: const Text('Get quote')),
                  if (_quote != null) ...[
                    const SizedBox(height: 12),
                    Text('Receive: ${_quote!['receive_amount']} ${_quote!['target_currency']}'),
                    Text('Fee: ${_quote!['fee_amount']}'),
                  ],
                  const Spacer(),
                  ElevatedButton(onPressed: _quote != null ? _send : null, child: const Text('Confirm & pay')),
                ],
              ),
            ),
    );
  }
}
