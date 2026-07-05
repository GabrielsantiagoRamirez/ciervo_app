import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shared/widgets/ciervo_button.dart';

class OpenSettingsButton extends StatelessWidget {
  const OpenSettingsButton({
    this.label = 'Abrir configuración',
    super.key,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return CiervoButton(
      label: label,
      icon: Icons.settings_outlined,
      variant: CiervoButtonVariant.secondary,
      onPressed: openAppSettings,
    );
  }
}
