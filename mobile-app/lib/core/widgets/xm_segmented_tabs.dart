import 'package:flutter/material.dart';
import '../theme/xmoney_theme.dart';

/// Premium two-option segmented control.
class XmSegmentedTabs extends StatelessWidget {
  const XmSegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F0)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Material(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                elevation: selected ? 1 : 0,
                shadowColor: Colors.black26,
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: selected ? XmoneyTheme.navyDeep : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
