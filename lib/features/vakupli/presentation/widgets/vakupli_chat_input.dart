import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_text_input.dart';

class VakupliChatInput extends StatelessWidget {
  const VakupliChatInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: CiervoTextInput(
            hintText: 'Escribe un mensaje...',
            prefixIcon: Icons.chat_bubble_outline,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadii.input,
          ),
          child: IconButton(
            tooltip: 'Envio disponible proximamente',
            onPressed: null,
            icon: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
