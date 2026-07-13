import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/widgets/ciervo_qr_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/ciervo_id_qr.dart';
import '../../../../core/utils/ciervo_qr_share.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../wallet/domain/entities/ciervo_wallet_identity.dart';

class MyCiervoIdentityCard extends StatelessWidget {
  const MyCiervoIdentityCard({required this.identity, super.key});

  final CiervoWalletIdentity identity;

  @override
  Widget build(BuildContext context) {
    final payload =
        identity.qrPayload ??
        CiervoIdQr.payloadForCode(identity.ciervoUserCode);

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mi QR Ciervo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Presenta este codigo para identificarte o recibir pagos.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(child: CiervoQrView(data: payload)),
          const SizedBox(height: AppSpacing.md),
          SelectableText(
            identity.ciervoUserCode,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: identity.ciervoUserCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CIERVO ID copiado.')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => CiervoQrShare.shareIdentity(
                    ciervoUserCode: identity.ciervoUserCode,
                    qrPayload: payload,
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
