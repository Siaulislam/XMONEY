import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../core/l10n/xm_strings.dart';
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
  final _s = XmStrings.instance;

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
      showXmSnack(context, _s.t('mobile.profile.updated', 'Profile updated'));
      Navigator.pop(context, res['data']);
    } else {
      showXmSnack(context, res['message'] as String? ?? _s.t('mobile.profile.updateFailed', 'Update failed'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_s.t('mobile.profile.editTitle', 'Edit profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: InputDecoration(labelText: _s.t('auth.fullName', 'Full name'))),
          TextField(controller: _country, decoration: InputDecoration(labelText: _s.t('auth.country', 'Country'))),
          TextField(controller: _city, decoration: InputDecoration(labelText: _s.t('mobile.profile.city', 'City'))),
          TextField(controller: _address1, decoration: InputDecoration(labelText: _s.t('mobile.profile.address', 'Address'))),
          TextField(controller: _postal, decoration: InputDecoration(labelText: _s.t('mobile.profile.postal', 'Postal code'))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_s.t('common.save', 'Save')),
          ),
        ],
      ),
    );
  }
}
