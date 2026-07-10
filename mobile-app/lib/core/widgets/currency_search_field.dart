import 'package:flutter/material.dart';

class CurrencySearchField extends StatelessWidget {
  const CurrencySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search by country or currency',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF3F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
      ),
    );
  }
}
