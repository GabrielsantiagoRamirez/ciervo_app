// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/ciervo_qr_item.dart';

class CiervoQrCard extends StatelessWidget {
  const CiervoQrCard({
    required this.item,
    this.onRefresh,
    this.onTap,
    super.key,
  });

  final CiervoQrItem item;
  final VoidCallback? onRefresh;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, item.status);
    return CiervoCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_icon(item.type)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _typeLabel(item.type),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    label: Text(_statusLabel(item.status, item.rawStatus)),
                    backgroundColor: statusColor.withOpacity(0.14),
                    side: BorderSide(color: statusColor.withOpacity(0.35)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Center(child: _QrVisual(item: item)),
              const SizedBox(height: AppSpacing.md),
              Text(
                item.title ?? _typeLabel(item.type),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if ((item.subtitle ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(item.subtitle!),
              ],
              const SizedBox(height: AppSpacing.sm),
              _InfoLine(label: 'Referencia', value: item.reference),
              _InfoLine(label: 'Expira', value: _date(item.expiresAt)),
              if (item.eventDate != null)
                _InfoLine(label: 'Fecha', value: _date(item.eventDate)),
              if ((item.pin ?? '').isNotEmpty)
                _InfoLine(label: 'PIN', value: item.pin!),
              if (item.points != null)
                _InfoLine(label: 'Puntos', value: '${item.points}'),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refrescar estado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrVisual extends StatelessWidget {
  const _QrVisual({required this.item});

  final CiervoQrItem item;

  @override
  Widget build(BuildContext context) {
    final payload = item.qrPayload;
    if (payload == null || payload.isEmpty) {
      return Container(
        width: 220,
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            item.qrId == null
                ? 'QR no generado para este elemento'
                : 'Toca refrescar para cargar el QR',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: QrImageView(
          data: payload,
          size: 220,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xxs),
    child: Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(child: Text(value.isEmpty ? 'No disponible' : value)),
      ],
    ),
  );
}

IconData _icon(CiervoQrType type) => switch (type) {
  CiervoQrType.booking => Icons.event_available_outlined,
  CiervoQrType.ticket => Icons.confirmation_number_outlined,
  CiervoQrType.giftCard => Icons.card_giftcard_outlined,
  CiervoQrType.benefit => Icons.workspace_premium_outlined,
};

String _typeLabel(CiervoQrType type) => switch (type) {
  CiervoQrType.booking => 'Reserva',
  CiervoQrType.ticket => 'Entrada',
  CiervoQrType.giftCard => 'Tarjeta regalo',
  CiervoQrType.benefit => 'Beneficio',
};

String _statusLabel(CiervoQrStatus status, String? rawStatus) => switch (status) {
  CiervoQrStatus.active => _translatedStatus(rawStatus) ?? 'Activo',
  CiervoQrStatus.used => _translatedStatus(rawStatus) ?? 'Usado',
  CiervoQrStatus.expired => _translatedStatus(rawStatus) ?? 'Vencido',
  CiervoQrStatus.cancelled => _translatedStatus(rawStatus) ?? 'Cancelado',
  CiervoQrStatus.unknown => _translatedStatus(rawStatus) ?? 'Sin estado',
};

String? _translatedStatus(String? value) {
  final text = value?.toLowerCase();
  return switch (text) {
    'active' => 'Activo',
    'used' || 'redeemed' => 'Usado',
    'expired' => 'Vencido',
    'cancelled' || 'canceled' => 'Cancelado',
    'pending' => 'Pendiente',
    'confirmed' => 'Confirmado',
    'rejected' => 'Rechazado',
    'attended' => 'Asistio',
    'noshow' || 'no_show' || 'no show' => 'No asistio',
    _ => value,
  };
}

Color _statusColor(BuildContext context, CiervoQrStatus status) => switch (status) {
  CiervoQrStatus.active => Colors.green,
  CiervoQrStatus.used => Theme.of(context).colorScheme.primary,
  CiervoQrStatus.expired => Colors.orange,
  CiervoQrStatus.cancelled => Theme.of(context).colorScheme.error,
  CiervoQrStatus.unknown => Theme.of(context).colorScheme.outline,
};

String _date(DateTime? value) =>
    value == null ? 'No disponible' : value.toLocal().toString().substring(0, 16);
