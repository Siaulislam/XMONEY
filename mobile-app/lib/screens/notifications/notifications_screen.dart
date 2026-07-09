import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _rows = [];
  int _unread = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.router.api.get('/v1/notifications?limit=50');
    if (!mounted) return;
    final data = res['data'];
    setState(() {
      if (data is Map) {
        _rows = (data['rows'] as List?) ?? [];
        _unread = data['unread_count'] as int? ?? 0;
      } else {
        _rows = (data as List?) ?? [];
      }
      _loading = false;
    });
  }

  Future<void> _markRead(String uuid) async {
    await widget.router.api.post('/v1/notifications/$uuid/read');
    await _load();
  }

  Future<void> _markAll() async {
    await widget.router.api.post('/v1/notifications/read-all');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unread > 0)
            TextButton(onPressed: _markAll, child: const Text('Mark all read')),
        ],
      ),
      body: _loading
          ? const XmLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _rows.isEmpty
                  ? ListView(children: const [SizedBox(height: 120), Center(child: Text('No notifications'))])
                  : ListView.builder(
                      itemCount: _rows.length,
                      itemBuilder: (_, i) {
                        final m = _rows[i] as Map<String, dynamic>;
                        final read = m['read_at'] != null;
                        return ListTile(
                          leading: Icon(read ? Icons.notifications_none : Icons.notifications_active,
                              color: read ? null : Colors.amber),
                          title: Text(m['title'] as String? ?? ''),
                          subtitle: Text(m['body'] as String? ?? ''),
                          onTap: () => _markRead(m['uuid'] as String),
                        );
                      },
                    ),
            ),
    );
  }
}
