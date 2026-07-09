import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.router, required this.uuid});
  final AppRouter router;
  final String uuid;

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Map<String, dynamic>? _txn;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.router.api.get('/v1/transfers/${widget.uuid}');
    if (!mounted) return;
    setState(() {
      _txn = res['data'] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel transfer?'),
        content: const Text('This action cannot be undone if processing has started.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _loading = true);
    final res = await widget.router.api.post('/v1/transfers/${widget.uuid}/cancel', {});
    if (!mounted) return;
    if (res['success'] == true) {
      showXmSnack(context, 'Transfer cancelled');
      await _load();
    } else {
      setState(() => _loading = false);
      showXmSnack(context, res['message'] as String? ?? 'Cancel failed', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final t = _txn;
    final history = (t?['history'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(t?['reference_code'] as String? ?? 'Transfer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : t == null
              ? const Center(child: Text('Transfer not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['status'] as String? ?? '', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text('${fmt.format(t['send_amount'])} ${t['source_currency']} → ${fmt.format(t['receive_amount'])} ${t['target_currency']}'),
                            const SizedBox(height: 4),
                            Text('To: ${t['receiver_name']}'),
                            if (t['purpose'] != null) Text('Purpose: ${t['purpose']}'),
                          ],
                        ),
                      ),
                    ),
                    if (['draft', 'quoted', 'pending_payment'].contains(t['status']))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton(onPressed: _cancel, child: const Text('Cancel transfer')),
                      ),
                    const SizedBox(height: 16),
                    const Text('Status history', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...history.map((h) {
                      final m = h as Map<String, dynamic>;
                      return ListTile(
                        dense: true,
                        title: Text('${m['from_status'] ?? '—'} → ${m['to_status']}'),
                        subtitle: Text(m['note'] as String? ?? ''),
                        trailing: Text((m['created_at'] as String? ?? '').replaceFirst('T', ' ').substring(0, 16)),
                      );
                    }),
                  ],
                ),
    );
  }
}
