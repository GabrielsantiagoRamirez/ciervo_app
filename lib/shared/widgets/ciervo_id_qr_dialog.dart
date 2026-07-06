import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/ciervo_id_qr.dart';
import '../../core/utils/ciervo_share.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import 'ciervo_qr_view.dart';
import 'ciervo_user_id_badge.dart';

Future<void> showCiervoIdQrDialog(
  BuildContext context, {
  required String ciervoUserCode,
  String? displayName,
  String? qrPayload,
}) async {
  final code = ciervoUserCode.trim().toUpperCase();
  if (code.isEmpty) return;
  final payload = qrPayload ?? CiervoIdQr.payloadForCode(code);

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(displayName == null ? 'Mi CIERVO ID' : 'QR de $displayName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CiervoQrView(data: payload, size: 200),
          const SizedBox(height: AppSpacing.md),
          SelectableText(
            code,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pide que escaneen este codigo para pagarte o enviarte un regalo.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => copyCiervoId(context, code),
          child: const Text('Copiar ID'),
        ),
        TextButton(
          onPressed: () => CiervoShare.shareText(
            'Mi CIERVO ID: $code\n$payload',
            subject: 'CIERVO CLUB',
          ),
          child: const Text('Compartir'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

Future<void> showMyCiervoIdQrDialog(BuildContext context) async {
  final identityResult = await getIt<WalletRepository>().myCiervoId();
  if (!context.mounted) return;
  final identity = identityResult.when(
    success: (value) => value,
    failure: (_) => null,
  );
  if (identity == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No pudimos cargar tu CIERVO ID.')),
    );
    return;
  }
  await showCiervoIdQrDialog(
    context,
    ciervoUserCode: identity.ciervoUserCode,
    qrPayload: identity.qrPayload,
  );
}
