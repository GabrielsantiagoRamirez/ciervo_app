import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class PaymentSummaryRow extends StatelessWidget {
  const PaymentSummaryRow({
    required this.label,
    required this.value,
    super.key,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized ? AppTextStyles.title : AppTextStyles.body;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
