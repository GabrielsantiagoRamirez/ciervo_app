import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/utils/ciervo_id_qr.dart';
import '../../reservations/data/booking_repository.dart';
import '../../wallet/domain/repositories/wallet_repository.dart';
import '../data/qr_scan_repository.dart';
import '../domain/entities/qr_scan_models.dart';
import 'pages/qr_merchant_pay_page.dart';
import 'pages/qr_scan_preview_page.dart';
import 'pages/qr_user_action_page.dart';

/// Enruta un QR escaneado según POST /api/qr/resolve y contratos del backend.
class QrScanRouter {
  const QrScanRouter._();

  static Future<void> handle(
    BuildContext context,
    String raw, {
    String? chatConversationId,
  }) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final repo = getIt<QrScanRepository>();
    final resolveResult = await repo.resolve(trimmed);

    if (context.mounted) Navigator.of(context).pop();

    await resolveResult.when(
      success: (resolved) async {
        if (!context.mounted) return;
        await _routeResolved(
          context,
          raw: trimmed,
          resolved: resolved,
          chatConversationId: chatConversationId,
        );
      },
      failure: (error) async {
        if (!context.mounted) return;
        await _fallbackLocalParse(context, trimmed, chatConversationId, error);
      },
    );
  }

  static Future<void> _routeResolved(
    BuildContext context, {
    required String raw,
    required QrResolveResult resolved,
    String? chatConversationId,
  }) async {
    if (resolved.isPayment) {
      final token = resolved.token ?? _extractPaymentToken(raw);
      if (token == null || token.isEmpty) {
        _showError(context, 'No pudimos leer el QR de pago.');
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => QrMerchantPayPage(token: token),
        ),
      );
      return;
    }

    if (resolved.isCiervoUser) {
      final code = resolved.code ?? CiervoIdQr.parse(raw);
      if (code == null) {
        _showError(context, 'CIERVO ID no reconocido.');
        return;
      }
      await _openCiervoUser(context, code, chatConversationId);
      return;
    }

    if (resolved.isUniversal) {
      await _openUniversalPreview(context, raw);
      return;
    }

    if (resolved.isBookingCode) {
      final code = resolved.code ?? raw.trim().toUpperCase();
      await _openBookingPreview(context, code);
      return;
    }

    if (resolved.isTicketCode) {
      _showError(
        context,
        'Este codigo es una entrada. Usa Mi QR para mostrarla al personal del evento.',
      );
      return;
    }

    if (resolved.isGiftCardCode) {
      _showError(
        context,
        'Las tarjetas regalo se validan con codigo y PIN desde Mis accesos.',
      );
      return;
    }

    if (resolved.isUnknown) {
      await _fallbackLocalParse(context, raw, chatConversationId, null);
      return;
    }

    _showError(
      context,
      resolved.description ?? 'Tipo de QR no soportado (${resolved.channel}).',
    );
  }

  static Future<void> _openUniversalPreview(
    BuildContext context,
    String raw,
  ) async {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final repo = getIt<QrScanRepository>();
    final result = await repo.validate(
      token: raw,
      deviceInfo: 'CiervoApp ${Platform.operatingSystem}',
    );

    if (context.mounted) Navigator.of(context).pop();

    await result.when(
      success: (preview) async {
        if (!context.mounted) return;
        if (!preview.valid) {
          _showError(context, preview.message ?? 'QR no valido o expirado.');
          return;
        }
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => QrScanPreviewPage(preview: preview, rawToken: raw),
          ),
        );
      },
      failure: (error) {
        if (!context.mounted) return;
        _showError(context, UserErrorMessage.from(error));
      },
    );
  }

  static Future<void> _openBookingPreview(
    BuildContext context,
    String code,
  ) async {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await getIt<BookingRepository>().getByCode(code);
    if (context.mounted) Navigator.of(context).pop();

    await result.when(
      success: (booking) async {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Reserva encontrada'),
            content: Text(
              '${booking.businessName ?? 'Negocio'}\n'
              'Codigo: ${booking.publicCode}\n'
              'Estado: ${booking.status}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
      failure: (error) {
        if (!context.mounted) return;
        _showError(context, UserErrorMessage.from(error));
      },
    );
  }

  static Future<void> _openCiervoUser(
    BuildContext context,
    String code,
    String? chatConversationId,
  ) async {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await getIt<WalletRepository>().resolveUser(code);
    if (context.mounted) Navigator.of(context).pop();

    await result.when(
      success: (user) async {
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => QrUserActionPage(
              ciervoUserCode: user.ciervoUserCode,
              displayName: user.displayName,
              userId: user.userId,
              chatConversationId: chatConversationId,
            ),
          ),
        );
      },
      failure: (error) {
        if (!context.mounted) return;
        _showError(context, UserErrorMessage.from(error));
      },
    );
  }

  static Future<void> _fallbackLocalParse(
    BuildContext context,
    String raw,
    String? chatConversationId,
    Object? resolveError,
  ) async {
    final code = CiervoIdQr.parse(raw);
    if (code != null) {
      await _openCiervoUser(context, code, chatConversationId);
      return;
    }

    if (!context.mounted) return;
    final message = resolveError == null
        ? 'QR no reconocido. Verifica que sea un codigo Ciervo valido.'
        : UserErrorMessage.from(resolveError);
    _showError(context, message);
  }

  static String? _extractPaymentToken(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    if (raw.startsWith('CIERVO-QR-')) return raw;
    return null;
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
