import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/receipts/domain/entities/action_confirmation.dart';
import '../../features/wallet/presentation/widgets/ciervo_digital_card.dart';

class CiervoReceiptPalette {
  const CiervoReceiptPalette({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textMuted,
    required this.borderAlpha,
    required this.sidebarGradient,
  });

  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textMuted;
  final double borderAlpha;
  final List<Color> sidebarGradient;

  static CiervoReceiptPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const CiervoReceiptPalette(
        background: Color(0xFF050505),
        surface: Color(0xFF101010),
        textPrimary: Colors.white,
        textMuted: Color(0xFF9A968E),
        borderAlpha: 0.55,
        sidebarGradient: [Color(0xFF14110A), Color(0xFF0A0A0A)],
      );
    }
    return const CiervoReceiptPalette(
      background: AppColors.dayBackground,
      surface: AppColors.daySurface,
      textPrimary: AppColors.dayText,
      textMuted: AppColors.dayTextMuted,
      borderAlpha: 0.5,
      sidebarGradient: [Color(0xFFFFF8E8), Color(0xFFF3EBD6)],
    );
  }
}

class CiervoPaymentReceipt extends StatelessWidget {
  const CiervoPaymentReceipt({
    required this.confirmation,
    super.key,
    this.referenceLabel,
    this.referenceValue,
    this.compact = false,
  });

  final ActionConfirmation confirmation;
  final String? referenceLabel;
  final String? referenceValue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = CiervoReceiptPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 640 && !compact;

    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: CiervoBrandColors.gold.withValues(alpha: palette.borderAlpha),
        ),
        boxShadow: [
          BoxShadow(
            color: CiervoBrandColors.gold.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: horizontal
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _BrandPanel(palette: palette)),
                  Expanded(
                    flex: 6,
                    child: _DetailsPanel(
                      palette: palette,
                      confirmation: confirmation,
                      referenceLabel: referenceLabel,
                      referenceValue: referenceValue,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BrandPanel(palette: palette, compact: true),
                _DetailsPanel(
                  palette: palette,
                  confirmation: confirmation,
                  referenceLabel: referenceLabel,
                  referenceValue: referenceValue,
                ),
              ],
            ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.palette, this.compact = false});

  final CiervoReceiptPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.sidebarGradient,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/notifications/ciervo_logo_gold.png',
            height: compact ? 48 : 64,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'CIERVO',
            style: TextStyle(
              color: CiervoBrandColors.gold,
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: CiervoBrandColors.gold.withValues(alpha: 0.45),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  'ENTRETENIMIENTO SIN LÍMITES',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 9,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: CiervoBrandColors.gold.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          if (!compact) const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadii.input,
              border: Border.all(
                color: CiervoBrandColors.gold.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.workspace_premium, color: CiervoBrandColors.gold, size: 20),
                const SizedBox(height: 4),
                Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: CiervoBrandColors.gold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'EXPERIENCIA SIN LÍMITES',
                  style: TextStyle(color: palette.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.palette,
    required this.confirmation,
    this.referenceLabel,
    this.referenceValue,
  });

  final CiervoReceiptPalette palette;
  final ActionConfirmation confirmation;
  final String? referenceLabel;
  final String? referenceValue;

  @override
  Widget build(BuildContext context) {
    final amountText = _formatAmount(confirmation.amount, confirmation.currency);
    final refLabel = referenceLabel ??
        (confirmation.businessName != null ? 'Comercio' : 'Referencia');
    final refValue = referenceValue ??
        confirmation.businessName ??
        (confirmation.confirmationCode.isNotEmpty
            ? confirmation.confirmationCode
            : null);
    final now = DateTime.now();
    final dateText = _formatDate(confirmation.date) ?? _formatDateTime(now);
    final timeText = _formatTime(confirmation.time) ?? _formatClock(now);
    final statusText = confirmation.status ?? 'Pago realizado con éxito';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECIBO DE PAGO',
                      style: TextStyle(
                        color: CiervoBrandColors.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gracias por elegir CIERVO',
                      style: TextStyle(color: palette.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CiervoBrandColors.gold,
                  border: Border.all(color: palette.background, width: 2),
                ),
                child: Icon(Icons.check_rounded, color: palette.background, size: 22),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (amountText != null)
            _ReceiptRow(
              palette: palette,
              icon: Icons.payments_outlined,
              label: 'Valor pagado',
              value: amountText,
            ),
          if (refValue != null && refValue.isNotEmpty)
            _ReceiptRow(
              palette: palette,
              icon: Icons.storefront_outlined,
              label: refLabel,
              value: refValue,
            ),
          _ReceiptRow(
            palette: palette,
            icon: Icons.schedule_outlined,
            label: 'Hora',
            value: timeText,
          ),
          _ReceiptRow(
            palette: palette,
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: dateText,
          ),
          if (confirmation.confirmationCode.isNotEmpty)
            _ReceiptRow(
              palette: palette,
              icon: Icons.receipt_long_outlined,
              label: 'Código de transacción',
              value: confirmation.confirmationCode,
            ),
          if (confirmation.userCiervoCode != null &&
              confirmation.userCiervoCode!.isNotEmpty)
            _CopyableReceiptRow(
              palette: palette,
              label: 'ID de usuario (token único)',
              value: confirmation.userCiervoCode!,
            ),
          if (confirmation.shareDescription != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              confirmation.shareDescription!,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(color: CiervoBrandColors.gold.withValues(alpha: 0.35)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: CiervoBrandColors.gold, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                'CIERVO APP',
                style: TextStyle(
                  color: CiervoBrandColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset(
                'assets/notifications/ciervo_logo_gold.png',
                width: 14,
                height: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
  });

  final CiervoReceiptPalette palette;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: CiervoBrandColors.gold),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(height: 1, color: CiervoBrandColors.gold.withValues(alpha: 0.2)),
        ],
      ),
    );
  }
}

class _CopyableReceiptRow extends StatelessWidget {
  const _CopyableReceiptRow({
    required this.palette,
    required this.label,
    required this.value,
  });

  final CiervoReceiptPalette palette;
  final String label;
  final String value;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID copiado al portapapeles'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: CiervoBrandColors.gold),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _copy(context),
              borderRadius: AppRadii.input,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.input,
                  border: Border.all(
                    color: CiervoBrandColors.gold.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: CiervoBrandColors.gold.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _formatAmount(num? amount, String? currency) {
  if (amount == null) return null;
  final code = (currency ?? 'COP').toUpperCase();
  return '\$${_groupThousands(amount.round())} $code';
}

String _groupThousands(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    if (i > 0 && fromEnd % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return negative ? '-${buffer.toString()}' : buffer.toString();
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatClock(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String? _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return _formatDateTime(parsed);
  if (raw.length >= 10 && raw[4] == '-') {
    final parts = raw.substring(0, 10).split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
  return raw.length > 16 ? raw.substring(0, 10) : raw;
}

String? _formatTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.contains('T')) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return _formatClock(parsed);
  }
  if (RegExp(r'^\d{2}:\d{2}').hasMatch(raw)) {
    final parts = raw.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return _formatClock(DateTime(2000, 1, 1, hour, minute));
  }
  return raw;
}
