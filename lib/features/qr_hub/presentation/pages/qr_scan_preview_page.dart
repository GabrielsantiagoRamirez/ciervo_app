import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../qr_wallet/presentation/pages/qr_wallet_page.dart';
import '../../data/qr_scan_repository.dart';
import '../../domain/entities/qr_scan_models.dart';

class QrScanPreviewPage extends StatefulWidget {
  const QrScanPreviewPage({
    required this.preview,
    required this.rawToken,
    super.key,
  });

  final QrValidatePreview preview;
  final String rawToken;

  @override
  State<QrScanPreviewPage> createState() => _QrScanPreviewPageState();
}

class _QrScanPreviewPageState extends State<QrScanPreviewPage> {
  bool _redeeming = false;

  String get _title =>
      widget.preview.title ??
      widget.preview.couponTitle ??
      widget.preview.benefitTitle ??
      'QR detectado';

  String? get _description =>
      widget.preview.message ??
      widget.preview.couponDescription ??
      widget.preview.benefitDescription;

  Future<void> _redeemCoupon() async {
    final couponId = _couponIdFromPreview();
    if (couponId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos identificar el cupon.')),
      );
      return;
    }

    setState(() => _redeeming = true);
    final result = await getIt<QrScanRepository>().redeemCoupon(couponId);
    if (!mounted) return;
    await result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cupon redimido correctamente.')),
        );
        Navigator.of(context).pop(true);
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
    if (mounted) setState(() => _redeeming = false);
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;

    return Scaffold(
      appBar: AppBar(title: const Text('QR detectado')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_iconForType(preview.type)),
                title: Text(_title),
                subtitle: Text(_typeLabel(preview.type)),
              ),
              if (_description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_description!),
              ],
              if (preview.ownerName != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Titular: ${preview.ownerName}'),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (preview.isCoupon)
                CiervoButton(
                  label: _redeeming ? 'Redimiendo' : 'Redimir cupon',
                  icon: Icons.redeem_outlined,
                  state: _redeeming
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: _redeeming ? null : _redeemCoupon,
                )
              else if (preview.isBenefit)
                const Text(
                  'Muestra este beneficio al personal del comercio para que lo '
                  'validen en mostrador.',
                )
              else
                const Text(
                  'Este QR es para mostrarlo a quien deba validarlo. '
                  'Usa Mi QR si te van a escanear a ti.',
                ),
              if (!preview.isCoupon) ...[
                const SizedBox(height: AppSpacing.md),
                CiervoButton(
                  label: 'Ver mis accesos',
                  icon: Icons.qr_code_2_outlined,
                  variant: CiervoButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const QrWalletPage(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    final text = type.toLowerCase();
    if (text.contains('coupon')) return Icons.local_offer_outlined;
    if (text.contains('benefit')) return Icons.workspace_premium_outlined;
    if (text.contains('ticket')) return Icons.confirmation_number_outlined;
    if (text.contains('booking')) return Icons.event_available_outlined;
    return Icons.qr_code_2_outlined;
  }

  String _typeLabel(String type) {
    final text = type.toLowerCase();
    if (text.contains('coupon')) return 'Cupon';
    if (text.contains('benefit')) return 'Beneficio';
    if (text.contains('ticket')) return 'Entrada';
    if (text.contains('booking')) return 'Reserva';
    return type;
  }

  int? _couponIdFromPreview() {
    final preview = widget.preview;
    if (preview.ownerId != null) return preview.ownerId;

    final endpoint = preview.recommendedRedeemEndpoint;
    if (endpoint == null || endpoint.isEmpty) return null;
    final match = RegExp(r'/coupons/(\d+)/redeem').firstMatch(endpoint);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
