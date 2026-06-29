import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 360) return ScreenSize.compact;
  if (width < 600) return ScreenSize.medium;
  return ScreenSize.expanded;
}

EdgeInsets pagePaddingOf(BuildContext context) {
  final size = screenSizeOf(context);
  return EdgeInsets.symmetric(
    horizontal: switch (size) {
      ScreenSize.compact => AppSpacing.md,
      ScreenSize.medium => AppSpacing.lg,
      ScreenSize.expanded => AppSpacing.xl,
    },
    vertical: AppSpacing.lg,
  );
}

double maxContentWidthOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width.clamp(320, 720);
}

Widget responsivePage({
  required BuildContext context,
  required Widget child,
  bool scrollable = true,
}) {
  final padding = pagePaddingOf(context);
  final content = Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
      child: child,
    ),
  );
  if (!scrollable) {
    return Padding(padding: padding, child: content);
  }
  return SingleChildScrollView(
    padding: padding,
    child: content,
  );
}
