import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/ciervo_id_qr.dart';
import '../../core/utils/ciervo_share.dart';
import 'ciervo_user_id_badge.dart';

Future<void> showCiervoIdQrDialog(
  BuildContext context, {
  required String ciervoUserCode,
  String? displayName,
}) async {
  final code = ciervoUserCode.trim().toUpperCase();
  if (code.isEmpty) return;

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(displayName == null ? 'Mi CIERVO ID' : 'QR de $displayName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: CiervoIdQr.payloadForCode(code),
              version: QrVersions.auto,
              size: 200,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
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
            'Pide que escaneen este código para pagarte o enviarte un regalo.',
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
            'Mi CIERVO ID: $code\n${CiervoIdQr.payloadForCode(code)}',
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
  final code = await resolveCiervoUserCodeForSession();
  if (!context.mounted) return;
  if (code == null || code.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No pudimos cargar tu CIERVO ID.')),
    );
    return;
  }
  await showCiervoIdQrDialog(context, ciervoUserCode: code);
}
