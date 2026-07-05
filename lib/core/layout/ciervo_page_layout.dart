import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'responsive_layout.dart';

/// Espaciado y padding estandar para pantallas con listas de tarjetas.
abstract final class CiervoPageLayout {
  static const double cardGap = AppSpacing.md;
  static const EdgeInsets compactCardPadding = EdgeInsets.all(AppSpacing.md);

  static EdgeInsets pagePadding(BuildContext context) => pagePaddingOf(context);

  static Widget paddedList({
    required BuildContext context,
    required List<Widget> children,
    bool scrollable = true,
  }) {
    final padding = pagePadding(context);
    final list = ListView.separated(
      padding: padding,
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: cardGap),
      itemBuilder: (_, index) => children[index],
    );
    return scrollable ? list : Column(children: children);
  }
}
