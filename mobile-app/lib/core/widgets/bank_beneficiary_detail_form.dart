import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';

/// Professional bank-transfer beneficiary detail fields (International Bank Transfer only).
class BankBeneficiaryDetailForm extends StatelessWidget {
  const BankBeneficiaryDetailForm({
    super.key,
    required this.transferMethodLabel,
    required this.currencyCode,
    required this.nameController,
    required this.mobileController,
    required this.emailController,
    required this.bankController,
    required this.branchController,
    required this.accountController,
    required this.ibanController,
    required this.swiftController,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.postalController,
    required this.purposes,
    required this.purpose,
    required this.onPurposeChanged,
    required this.relationships,
    required this.relationship,
    required this.onRelationshipChanged,
    required this.saveBeneficiary,
    required this.onSaveBeneficiaryChanged,
    required this.agreed,
    required this.onAgreedChanged,
    required this.bankReadOnly,
    required this.showSwift,
    this.errors = const {},
  });

  final String transferMethodLabel;
  final String currencyCode;
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController bankController;
  final TextEditingController branchController;
  final TextEditingController accountController;
  final TextEditingController ibanController;
  final TextEditingController swiftController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalController;
  final List<String> purposes;
  final String purpose;
  final ValueChanged<String> onPurposeChanged;
  final List<String> relationships;
  final String relationship;
  final ValueChanged<String> onRelationshipChanged;
  final bool saveBeneficiary;
  final ValueChanged<bool> onSaveBeneficiaryChanged;
  final bool agreed;
  final ValueChanged<bool> onAgreedChanged;
  final bool bankReadOnly;
  final bool showSwift;
  final Map<String, String> errors;

  static const _fieldFill = Color(0xFFF6F8FC);
  static const _border = Color(0xFFE8ECF3);
  static const _text = Color(0xFF071526);
  static const _label = Color(0xFF4B5563);
  static const _hint = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _infoTile(
          icon: Icons.swap_horiz_rounded,
          label: 'Transfer Method',
          value: transferMethodLabel,
          trailing: const Icon(Icons.chevron_right_rounded, color: _label, size: 22),
        ),
        _infoTile(
          icon: Icons.payments_outlined,
          label: 'Currency',
          value: currencyCode,
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                hint: 'Enter full name',
                controller: nameController,
                error: errors['receiver_name'],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                icon: Icons.smartphone_outlined,
                label: 'Mobile Number',
                hint: 'Enter mobile number',
                controller: mobileController,
                keyboard: TextInputType.phone,
                error: errors['mobile_number'],
              ),
            ),
          ],
        ),
        _field(
          icon: Icons.mail_outline_rounded,
          label: 'Email Address (Optional)',
          hint: 'Enter email address',
          controller: emailController,
          error: errors['email'],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                icon: Icons.account_balance_outlined,
                label: 'Bank Name',
                hint: 'Enter bank name',
                controller: bankController,
                readOnly: bankReadOnly,
                error: errors['bank_name'],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                icon: Icons.location_on_outlined,
                label: 'Branch',
                hint: 'Enter branch name',
                controller: branchController,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                icon: Icons.credit_card_outlined,
                label: 'Account Number / IBAN',
                hint: 'Enter account or IBAN',
                controller: accountController,
                error: errors['account_number'] ?? errors['iban'],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                icon: Icons.badge_outlined,
                label: 'SWIFT / BIC Code',
                hint: showSwift ? 'Enter SWIFT code (if any)' : 'Not required',
                controller: swiftController,
                error: errors['swift_bic'],
                readOnly: !showSwift,
              ),
            ),
          ],
        ),
        _field(
          icon: Icons.home_outlined,
          label: "Receiver's Address",
          hint: 'Enter complete address',
          controller: addressController,
          error: errors['address_line'],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                icon: Icons.location_city_outlined,
                label: 'City',
                hint: 'Enter city',
                controller: cityController,
                error: errors['receiver_city'],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                icon: Icons.map_outlined,
                label: 'State / Province (Optional)',
                hint: 'Enter state or province',
                controller: stateController,
              ),
            ),
          ],
        ),
        _field(
          icon: Icons.local_post_office_outlined,
          label: 'Postal Code (Optional)',
          hint: 'Enter postal code',
          controller: postalController,
        ),
        _picker(
          icon: Icons.description_outlined,
          label: 'Purpose of Transfer',
          hint: 'Select purpose',
          value: purpose,
          items: purposes,
          onChanged: onPurposeChanged,
          error: errors['purpose_of_transfer'],
        ),
        _picker(
          icon: Icons.people_outline_rounded,
          label: 'Relationship',
          hint: 'Select relationship',
          value: relationship,
          items: relationships,
          onChanged: onRelationshipChanged,
          error: errors['relationship'],
        ),
        const SizedBox(height: 4),
        _toggleTile(
          icon: Icons.bookmark_outline_rounded,
          title: 'Save Beneficiary',
          subtitle: 'Save this beneficiary for future transfers',
          value: saveBeneficiary,
          onChanged: onSaveBeneficiaryChanged,
        ),
        _termsTile(
          value: agreed,
          onChanged: onAgreedChanged,
          error: errors['terms'],
        ),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: XmoneyTheme.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _label)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _field({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboard,
    String? error,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: _fieldFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: error != null ? Colors.red.shade300 : _border),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: XmoneyTheme.teal),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _text)),
                  ],
                ),
                TextField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: keyboard,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _text),
                  cursorColor: XmoneyTheme.teal,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: _hint, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error, style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _picker({
    required IconData icon,
    required String label,
    required String hint,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: error != null ? Colors.red.shade300 : _border),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: XmoneyTheme.teal),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _text)),
              ],
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value.isEmpty ? null : value,
                hint: Text(hint, style: const TextStyle(color: _hint, fontSize: 14)),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.chevron_right_rounded, color: _label),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: XmoneyTheme.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: _label)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: XmoneyTheme.teal.withOpacity(0.45),
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _termsTile({required bool value, required ValueChanged<bool> onChanged, String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: XmoneyTheme.teal,
              side: const BorderSide(color: _label, width: 1.5),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: _text, height: 1.4),
                    children: [
                      TextSpan(text: 'I have read & understood '),
                      TextSpan(
                        text: 'Key Facts Statements',
                        style: TextStyle(color: XmoneyTheme.teal, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),
      ],
    );
  }
}
