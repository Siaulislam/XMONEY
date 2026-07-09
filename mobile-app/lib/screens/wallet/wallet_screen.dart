import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _history = [];
  final _amount = TextEditingController(text: '100');
  final _devAmount = TextEditingController(text: '500');
  bool _loading = true;
  bool _devMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await widget.router.api.get('/v1/wallet');
    final h = await widget.router.api.get('/v1/wallet/history?limit=20');
    final pub = await widget.router.api.get('/v1/settings/public');
    if (!mounted) return;
    setState(() {
      _wallet = w['data'] as Map<String, dynamic>?;
      final hd = h['data'];
      _history = hd is Map ? (hd['rows'] as List? ?? []) : (hd as List? ?? []);
      _devMode = (pub['data'] as Map?)?['development_mode'] == true;
      _loading = false;
    });
  }

  Future<void> _devDeposit() async {
    final amount = double.tryParse(_devAmount.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final res = await widget.router.api.post('/v1/wallet/deposit', {
      'amount': amount,
      'currency': _wallet?['currency'] ?? 'AED',
    });
    if (!mounted) return;
    if (res['success'] == true) {
      showXmSnack(context, 'Test funds added');
      await _load();
    } else {
      setState(() => _loading = false);
      showXmSnack(context, res['message'] as String? ?? 'Deposit failed', error: true);
    }
  }

  Future<void> _topUp() async {
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final res = await widget.router.api.post('/v1/wallet/top-up', {
      'amount': amount,
      'currency': _wallet?['currency'] ?? 'AED',
      'payment_method': 'card',
    });
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet topped up')));
      await _load();
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] as String? ?? 'Top-up failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available'),
                        Text(
                          _wallet != null ? '${fmt.format(_wallet!['available_balance'])} ${_wallet!['currency']}' : '—',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Top up', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _topUp, child: const Text('Top up now')),
                      ],
                    ),
                  ),
                ),
                if (_devMode) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Development deposit', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(controller: _devAmount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _devDeposit, child: const Text('Add test funds')),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._history.map((r) {
                  final m = r as Map<String, dynamic>;
                  return ListTile(
                    title: Text(m['type'] as String? ?? ''),
                    subtitle: Text(m['description'] as String? ?? ''),
                    trailing: Text(fmt.format(m['amount'])),
                  );
                }),
              ],
            ),
    );
  }
}
