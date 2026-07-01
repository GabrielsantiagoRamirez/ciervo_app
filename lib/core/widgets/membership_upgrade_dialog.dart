import 'package:flutter/material.dart';

import '../errors/app_exception.dart';
import '../utils/display_labels.dart';
import '../../features/memberships/presentation/pages/membership_page.dart';

class PlanLimitErrorDetails {
  const PlanLimitErrorDetails({
    this.featureKey,
    this.requiredPlan,
    required this.featureLabel,
  });

  final String? featureKey;
  final String? requiredPlan;
  final String featureLabel;
}

String featureLabelFromKey(String? featureKey) {
  if (featureKey == null || featureKey.isEmpty) {
    return 'esta función';
  }
  return DisplayLabels.membershipFeatureLabel(featureKey);
}

PlanLimitErrorDetails? parsePlanLimitError(Object error) {
  String? code;
  var message = error.toString();
  if (error is AppException) {
    code = error.code;
    message = error.message;
  }
  final text = message.toUpperCase();
  if (code?.toUpperCase() == 'PLAN_LIMIT_REACHED' ||
      text.contains('PLAN_LIMIT_REACHED')) {
    final feature = _extractField(text, 'feature');
    final requiredPlan = _extractField(text, 'requiredPlan');
    return PlanLimitErrorDetails(
      featureKey: feature,
      requiredPlan: requiredPlan,
      featureLabel: featureLabelFromKey(feature),
    );
  }
  return null;
}

String? _extractField(String text, String key) {
  final pattern = RegExp('$key=([^|]+)', caseSensitive: false);
  final match = pattern.firstMatch(text);
  return match?.group(1)?.trim();
}

Future<bool?> showMembershipUpgradeDialog(
  BuildContext context, {
  required String featureLabel,
  String? requiredPlan,
}) {
  final planHint = requiredPlan != null && requiredPlan.isNotEmpty
      ? ' El plan ${DisplayLabels.planName(code: requiredPlan)} lo incluye.'
      : '';
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Mejora tu plan CIERVO'),
      content: Text(
        'Tu plan actual no incluye $featureLabel.$planHint',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Ver planes'),
        ),
      ],
    ),
  ).then((upgrade) async {
    if (upgrade == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MembershipPage()),
      );
    }
    return upgrade;
  });
}

Future<bool> handlePlanLimitError(
  BuildContext context,
  Object error,
) async {
  final details = parsePlanLimitError(error);
  if (details == null) return false;
  await showMembershipUpgradeDialog(
    context,
    featureLabel: details.featureLabel,
    requiredPlan: details.requiredPlan,
  );
  return true;
}

Future<bool> showApiErrorOrUpgrade(
  BuildContext context,
  Object error, {
  required String fallbackMessage,
}) async {
  if (await handlePlanLimitError(context, error)) return true;
  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(fallbackMessage)),
  );
  return false;
}
