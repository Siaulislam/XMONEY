import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.router.api.get('/v1/transfers?limit=50');
    final d = res['data'];
    setState(() {
      _rows = d is List ? d : (d is Map ? (d['rows'] as List? ?? []) : []);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (_, i) {
                  final t = _rows[i] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(t['reference_code'] as String? ?? ''),
                    subtitle: Text('${t['receiver_name']} · ${t['status']}'),
                    trailing: Text('${fmt.format(t['send_amount'])} ${t['source_currency']}'),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.transactionDetail,
                      arguments: {'uuid': t['uuid']},
                    ),
                  );
                },
              ),
            ),
    );
  }
}
