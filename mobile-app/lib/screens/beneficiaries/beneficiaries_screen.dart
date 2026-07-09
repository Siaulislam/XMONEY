import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class BeneficiariesScreen extends StatefulWidget {
  const BeneficiariesScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  List<dynamic> _rows = [];
  bool _loading = true;
  bool _showForm = false;
  final _name = TextEditingController();
  final _country = TextEditingController(text: 'PK');
  final _currency = TextEditingController(text: 'PKR');
  final _bank = TextEditingController();
  final _account = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.router.api.get('/v1/beneficiaries');
    if (!mounted) return;
    setState(() {
      _rows = (res['data'] as List?) ?? [];
      _loading = false;
    });
  }

  Future<void> _create() async {
    final res = await widget.router.api.post('/v1/beneficiaries', {
      'receiver_name': _name.text.trim(),
      'country_code': _country.text.trim().toUpperCase(),
      'currency_code': _currency.text.trim().toUpperCase(),
      'bank_name': _bank.text.trim(),
      'account_number': _account.text.trim(),
    });
    if (!mounted) return;
    if (res['success'] == true) {
      showXmSnack(context, 'Beneficiary added');
      setState(() => _showForm = false);
      _name.clear(); _bank.clear(); _account.clear();
      await _load();
    } else {
      showXmSnack(context, res['message'] as String? ?? 'Failed to add beneficiary', error: true);
    }
  }

  Future<void> _remove(String uuid) async {
    final res = await widget.router.api.delete('/v1/beneficiaries/$uuid');
    if (!mounted) return;
    if (res['success'] == true) {
      showXmSnack(context, 'Beneficiary removed');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiaries'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close : Icons.add),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: _loading
          ? const XmLoading()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_showForm) ...[
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Receiver name')),
                  TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country (ISO)')),
                  TextField(controller: _currency, decoration: const InputDecoration(labelText: 'Currency')),
                  TextField(controller: _bank, decoration: const InputDecoration(labelText: 'Bank name')),
                  TextField(controller: _account, decoration: const InputDecoration(labelText: 'Account number')),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _create, child: const Text('Save beneficiary')),
                  const Divider(height: 32),
                ],
                if (_rows.isEmpty) const Text('No beneficiaries yet.'),
                ..._rows.map((b) {
                  final m = b as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(m['receiver_name'] as String? ?? ''),
                      subtitle: Text('${m['bank_name']} · ${m['currency_code']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(m['uuid'] as String),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
