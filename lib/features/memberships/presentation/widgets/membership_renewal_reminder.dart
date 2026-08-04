import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/membership_state.dart';
import '../cubit/membership_cubit.dart';
import '../pages/membership_page.dart';

/// Recuerda renovar el plan a 7 / 5 / 3 días del vencimiento.
/// En mora (gracia 10 días) muestra popup hasta que el usuario marque
/// "no volver a mostrar" o termine la gracia. No se muestra en periodo vigente
/// fuera de esos hitos.
Future<void> showMembershipRenewalReminderIfNeeded(BuildContext context) async {
  final cubit = getIt<MembershipCubit>();
  if (!cubit.state.isLoaded) {
    await cubit.load();
  }
  if (!context.mounted) return;

  final me = cubit.state;
  if (!me.shouldPromptRenewalReminder) return;

  final storage = getIt<SecureStorage>();
  final cycleKey = me.renewalCycleKey;
  if (cycleKey == null) return;

  void openMembership() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MembershipPage()));
  }

  if (me.isInGrace) {
    final dismissed = await storage.read(_graceDismissedKey(cycleKey));
    if (dismissed == 'true') return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => _MembershipRenewalDialog(
        kind: _ReminderKind.grace,
        planName: me.planName,
        endsAt: me.endsAt,
        remainingDays: me.remainingDays,
        graceDaysRemaining: me.graceDaysRemaining,
        graceEndsAt: me.graceEndsAt,
        graceDays: me.graceDays,
        onDismissForever: () =>
            storage.write(_graceDismissedKey(cycleKey), 'true'),
        onRenew: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          openMembership();
        },
      ),
    );
    return;
  }

  final day = me.remainingDays;
  if (day == null || !MembershipState.preExpiryReminderDays.contains(day)) {
    return;
  }
  final milestoneKey = _milestoneKey(cycleKey, day);
  if (await storage.read(milestoneKey) == 'true') return;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => _MembershipRenewalDialog(
      kind: _ReminderKind.preExpiry,
      planName: me.planName,
      endsAt: me.endsAt,
      remainingDays: day,
      graceDaysRemaining: null,
      graceEndsAt: null,
      graceDays: me.graceDays,
      onDismissForever: null,
      onShown: () => storage.write(milestoneKey, 'true'),
      onRenew: () {
        Navigator.of(ctx, rootNavigator: true).pop();
        openMembership();
      },
    ),
  );
}

String _graceDismissedKey(String cycleKey) =>
    'membership_grace_dismissed_$cycleKey';

String _milestoneKey(String cycleKey, int day) =>
    'membership_renewal_day_${day}_$cycleKey';

enum _ReminderKind { preExpiry, grace }

class _MembershipRenewalDialog extends StatefulWidget {
  const _MembershipRenewalDialog({
    required this.kind,
    required this.planName,
    required this.endsAt,
    required this.remainingDays,
    required this.graceDaysRemaining,
    required this.graceEndsAt,
    required this.graceDays,
    required this.onRenew,
    this.onDismissForever,
    this.onShown,
  });

  final _ReminderKind kind;
  final String planName;
  final DateTime? endsAt;
  final int? remainingDays;
  final int? graceDaysRemaining;
  final DateTime? graceEndsAt;
  final int graceDays;
  final VoidCallback onRenew;
  final Future<void> Function()? onDismissForever;
  final Future<void> Function()? onShown;

  @override
  State<_MembershipRenewalDialog> createState() =>
      _MembershipRenewalDialogState();
}

class _MembershipRenewalDialogState extends State<_MembershipRenewalDialog> {
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    widget.onShown?.call();
  }

  String get _title => switch (widget.kind) {
    _ReminderKind.grace => 'Plan en mora',
    _ReminderKind.preExpiry => 'Renueva tu plan',
  };

  String get _body {
    final plan = widget.planName;
    final ends = widget.endsAt;
    final endsLabel = ends == null
        ? ''
        : ends.toLocal().toString().substring(0, 10);
    if (widget.kind == _ReminderKind.grace) {
      final left = widget.graceDaysRemaining;
      final graceEnd = widget.graceEndsAt;
      final graceEndLabel = graceEnd == null
          ? ''
          : graceEnd.toLocal().toString().substring(0, 10);
      final leftText = left == null
          ? 'Tienes ${widget.graceDays} días de mora'
          : left <= 0
          ? 'Último día de mora'
          : 'Te quedan $left día${left == 1 ? '' : 's'} de mora';
      return 'Tu plan $plan venció${endsLabel.isEmpty ? '' : ' el $endsLabel'}. '
          '$leftText con beneficios.'
          '${graceEndLabel.isEmpty ? '' : ' Renueva antes del $graceEndLabel'} '
          'o pasarás automáticamente a Free.';
    }
    final days = widget.remainingDays ?? 0;
    return 'Tu plan $plan vence en $days día${days == 1 ? '' : 's'}'
        '${endsLabel.isEmpty ? '' : ' ($endsLabel)'}. '
        'Si no renuevas a tiempo, tendrás ${widget.graceDays} días de mora '
        'y luego se cancelará solo.';
  }

  Future<void> _close() async {
    if (_dontShowAgain && widget.onDismissForever != null) {
      await widget.onDismissForever!();
    }
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_body),
          if (widget.onDismissForever != null) ...[
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _dontShowAgain,
              onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('No volver a mostrar'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _close, child: const Text('Ahora no')),
        FilledButton(onPressed: widget.onRenew, child: const Text('Renovar')),
      ],
    );
  }
}
