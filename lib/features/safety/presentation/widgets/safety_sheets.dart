import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/safety_models.dart';
import '../../domain/repositories/safety_repository.dart';
import 'block_user_confirmation_dialog.dart';

Future<void> showReportSheet(
  BuildContext context, {
  required ReportTargetType targetType,
  String? targetId,
  int? reportedUserId,
  String? subjectLabel,
  bool allowBlockUser = false,
  VoidCallback? onCompleted,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (sheetContext) => _ReportSheet(
    targetType: targetType,
    targetId: targetId,
    reportedUserId: reportedUserId,
    subjectLabel: subjectLabel,
    allowBlockUser: allowBlockUser,
    onCompleted: onCompleted,
  ),
);

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.targetType,
    this.targetId,
    this.reportedUserId,
    this.subjectLabel,
    required this.allowBlockUser,
    this.onCompleted,
  });

  final ReportTargetType targetType;
  final String? targetId;
  final int? reportedUserId;
  final String? subjectLabel;
  final bool allowBlockUser;
  final VoidCallback? onCompleted;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool alsoBlock}) async {
    final reason = _selectedReason;
    if (reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un motivo de reporte.')),
      );
      return;
    }

    if (reason == ReportReason.other &&
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe el motivo cuando eliges Otro.')),
      );
      return;
    }

    setState(() => _loading = true);
    final repository = getIt<SafetyRepository>();

    final reportResult = await repository.createReport(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reportedUserId: widget.reportedUserId,
      reason: reason,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    if (!mounted) return;

    await reportResult.when(
      success: (_) async {
        if (alsoBlock && widget.reportedUserId != null) {
          final blockResult = await repository.blockUser(
            widget.reportedUserId!,
          );
          if (!mounted) return;
          blockResult.when(
            success: (_) {
              widget.onCompleted?.call();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte enviado y usuario bloqueado.'),
                ),
              );
            },
            failure: (error) {
              setState(() => _loading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(UserErrorMessage.from(error))),
              );
            },
          );
          return;
        }

        widget.onCompleted?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gracias por ayudarnos a mantener segura la comunidad.',
            ),
          ),
        );
      },
      failure: (error) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Reportar${widget.subjectLabel != null ? ' ${widget.subjectLabel}' : ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Selecciona el motivo del reporte',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ...ReportReason.values.map(
            (reason) => RadioListTile<ReportReason>(
              contentPadding: EdgeInsets.zero,
              value: reason,
              groupValue: _selectedReason,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _selectedReason = value),
              title: Text(reason.label, style: const TextStyle(fontSize: 14)),
            ),
          ),
          if (_selectedReason == ReportReason.other) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Describe el problema',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _submit(alsoBlock: false),
                child: const Text('Reportar'),
              ),
            ),
            if (widget.allowBlockUser && widget.reportedUserId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _submit(alsoBlock: true),
                  child: const Text('Reportar y bloquear'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

Future<void> showBlockUserFlow(
  BuildContext context, {
  required int userId,
  required String displayName,
  VoidCallback? onBlocked,
}) async {
  final confirmed = await showBlockUserConfirmationDialog(
    context,
    displayName: displayName,
  );
  if (confirmed != true || !context.mounted) return;

  final result = await getIt<SafetyRepository>().blockUser(userId);
  if (!context.mounted) return;

  result.when(
    success: (_) {
      onBlocked?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario bloqueado correctamente.')),
      );
    },
    failure: (error) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))),
  );
}

Future<void> showBlockContentFlow(
  BuildContext context, {
  required ReportTargetType targetType,
  required String targetId,
  VoidCallback? onBlocked,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Bloquear contenido'),
      content: const Text(
        'Este contenido dejara de mostrarse en tu experiencia CIERVO.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Bloquear'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final result = await getIt<SafetyRepository>().blockContent(
    targetType: targetType,
    targetId: targetId,
  );
  if (!context.mounted) return;

  result.when(
    success: (_) {
      onBlocked?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contenido bloqueado correctamente.')),
      );
    },
    failure: (error) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))),
  );
}

void showSafetyOptionsSheet(
  BuildContext context, {
  required String title,
  ReportTargetType? contentType,
  String? contentId,
  int? userId,
  String? userDisplayName,
  VoidCallback? onActionCompleted,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (contentType != null && contentId != null) ...[
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Reportar contenido'),
              onTap: () {
                Navigator.pop(sheetContext);
                showReportSheet(
                  context,
                  targetType: contentType,
                  targetId: contentId,
                  onCompleted: onActionCompleted,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Bloquear contenido'),
              onTap: () {
                Navigator.pop(sheetContext);
                showBlockContentFlow(
                  context,
                  targetType: contentType,
                  targetId: contentId,
                  onBlocked: onActionCompleted,
                );
              },
            ),
          ],
          if (userId != null) ...[
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: const Text('Reportar usuario'),
              onTap: () {
                Navigator.pop(sheetContext);
                showReportSheet(
                  context,
                  targetType: ReportTargetType.user,
                  reportedUserId: userId,
                  subjectLabel: userDisplayName,
                  allowBlockUser: true,
                  onCompleted: onActionCompleted,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquear usuario'),
              onTap: () {
                Navigator.pop(sheetContext);
                showBlockUserFlow(
                  context,
                  userId: userId,
                  displayName: userDisplayName ?? 'este usuario',
                  onBlocked: onActionCompleted,
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}
