import 'package:flutter/material.dart';

class CiervoChipTag extends StatelessWidget {
  const CiervoChipTag({
    required this.label,
    super.key,
    this.selected = false,
    this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
    );
  }
}
