import 'package:flutter/material.dart';

import 'favorite_ciervo_button.dart';

/// Compatibilidad: cualquier “favorito corazón” ahora usa el ciervo.
class FavoriteHeartButton extends StatelessWidget {
  const FavoriteHeartButton({
    required this.businessId,
    this.initialValue = false,
    this.compact = false,
    this.onChanged,
    super.key,
  });

  final String businessId;
  final bool initialValue;
  final bool compact;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FavoriteCiervoButton(
      businessId: businessId,
      initialValue: initialValue,
      size: compact ? 39 : 44,
      onChanged: onChanged,
    );
  }
}
