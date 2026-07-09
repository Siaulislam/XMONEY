import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.router, required this.profile});
  final AppRouter router;
  final Map<String, dynamic> profile;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _address1;
  late final TextEditingController _postal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p['full_name'] as String? ?? '');
    _country = TextEditingController(text: p['country_code'] as String? ?? 'AE');
    _city = TextEditingController(text: p['city'] as String? ?? '');
    _address1 = TextEditingController(text: p['address_line1'] as String? ?? '');
    _postal = TextEditingController(text: p['postal_code'] as String? ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _country.dispose();
    _city.dispose();
    _address1.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final res = await widget.router.api.put('/v1/me', {
      'full_name': _name.text.trim(),
      'country_code': _country.text.trim().toUpperCase(),
      'city': _city.text.trim(),
      'address_line1': _address1.text.trim(),
      'postal_code': _postal.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['success'] == true) {
      showXmSnack(context, 'Profile updated');
      Navigator.pop(context, res['data']);
    } else {
      showXmSnack(context, res['message'] as String? ?? 'Update failed', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
          TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country (ISO 2)')),
          TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
          TextField(controller: _address1, decoration: const InputDecoration(labelText: 'Address')),
          TextField(controller: _postal, decoration: const InputDecoration(labelText: 'Postal code')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
