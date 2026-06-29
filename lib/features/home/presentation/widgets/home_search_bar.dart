import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({required this.onSubmitted, super.key});

  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadii.input,
        boxShadow: AppShadows.button,
      ),
      child: TextField(
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        decoration: const InputDecoration(
          hintText: 'Busca lugares, promos o planes',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}
