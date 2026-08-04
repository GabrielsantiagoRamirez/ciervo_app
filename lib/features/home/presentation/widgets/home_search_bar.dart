import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../search/presentation/pages/search_page.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({this.initialQuery, super.key});

  final String? initialQuery;

  void _openSearch(BuildContext context, {String? query}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(initialQuery: query ?? initialQuery),
      ),
    );
  }

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
        readOnly: true,
        onTap: () => _openSearch(context),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) => _openSearch(context, query: value),
        decoration: const InputDecoration(
          hintText: 'Busca personas, lugares, productos o eventos',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}
