import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_router.dart';
import '../../core/widgets/xm_ui.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key, required this.router});
  final AppRouter router;

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  List<dynamic> _docs = [];
  String _type = 'passport';
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.router.api.get('/v1/kyc');
    if (!mounted) return;
    setState(() {
      _docs = (res['data'] as List?) ?? [];
      _loading = false;
    });
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() => _uploading = true);
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : 'document.jpg';
    final res = await widget.router.api.uploadKyc(documentType: _type, bytes: bytes, filename: name);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (res['success'] == true) {
      showXmSnack(context, 'Document uploaded');
      await _load();
    } else {
      showXmSnack(context, res['message'] as String? ?? 'Upload failed', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC verification')),
      body: _loading
          ? const XmLoading()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Upload a government-issued ID to verify your identity.'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Document type'),
                  items: const [
                    DropdownMenuItem(value: 'passport', child: Text('Passport')),
                    DropdownMenuItem(value: 'national_id', child: Text('National ID')),
                    DropdownMenuItem(value: 'emirates_id', child: Text('Emirates ID')),
                    DropdownMenuItem(value: 'address_proof', child: Text('Address proof')),
                    DropdownMenuItem(value: 'selfie', child: Text('Selfie')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'passport'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _uploading ? null : _pickAndUpload,
                  child: Text(_uploading ? 'Uploading…' : 'Choose file & upload'),
                ),
                const SizedBox(height: 24),
                const Text('Your documents', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_docs.isEmpty) const Text('No documents uploaded yet.'),
                ..._docs.map((d) {
                  final m = d as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(m['document_type'] as String? ?? ''),
                      subtitle: Text(m['status'] as String? ?? ''),
                      trailing: m['rejection_reason'] != null
                          ? Icon(Icons.info_outline, color: Colors.orange.shade700)
                          : null,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
