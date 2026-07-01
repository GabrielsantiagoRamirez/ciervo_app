import 'package:flutter/material.dart';

import '../../domain/entities/family_payment_record.dart';
import 'family_payment_detail_page.dart';
import 'family_payment_methods_page.dart';
import 'parent_payment_approval_page.dart';
import 'parent_payment_history_page.dart';

/// Navegación centralizada para deep links y push de Family Payments.
abstract final class FamilyPaymentNavigation {
  static bool openFromPayload(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final type = _combinedType(data);
    final paymentId = _paymentId(data);
    final kidId = data['kidId']?.toString() ?? data['childProfileId']?.toString();

    if (_matches(type, 'payment.pending_parent') && paymentId != null) {
      _push(context, ParentPaymentApprovalPage(paymentId: paymentId));
      return true;
    }
    if (_matches(type, 'payment.requested') && paymentId != null) {
      _push(context, ParentPaymentApprovalPage(paymentId: paymentId));
      return true;
    }
    if (_matches(type, 'payment.approved') && paymentId != null) {
      _push(context, FamilyPaymentDetailPage(paymentId: paymentId));
      return true;
    }
    if (_matches(type, 'payment.rejected') && paymentId != null) {
      _push(context, FamilyPaymentDetailPage(paymentId: paymentId));
      return true;
    }
    if (_matches(type, 'payment.completed') && paymentId != null) {
      _push(context, FamilyPaymentDetailPage(paymentId: paymentId));
      return true;
    }
    if (_matches(type, 'payment.refunded') && paymentId != null) {
      _push(context, FamilyPaymentDetailPage(paymentId: paymentId));
      return true;
    }
    if (_matches(type, 'card.added') || _matches(type, 'card.removed')) {
      _push(context, const FamilyPaymentMethodsPage());
      return true;
    }
    if (_matches(type, 'limits.updated') ||
        _matches(type, 'rules.updated')) {
      if (kidId != null && kidId.isNotEmpty) {
        // El hub se abre desde Kids; aquí llevamos al historial familiar.
        _push(context, const ParentPaymentHistoryPage());
        return true;
      }
    }
    if (paymentId != null && paymentId.isNotEmpty) {
      _push(context, FamilyPaymentDetailPage(paymentId: paymentId));
      return true;
    }
    return false;
  }

  static bool openFromDeepLink(BuildContext context, String link) {
    final lower = link.toLowerCase();
    if (lower.contains('family/payment-methods') ||
        lower.contains('payment-methods')) {
      _push(context, const FamilyPaymentMethodsPage());
      return true;
    }
    if (lower.contains('family/payments/history') ||
        lower.contains('family/payments')) {
      _push(context, const ParentPaymentHistoryPage());
      return true;
    }
    final paymentId = _segmentAfter(link, 'payments');
    if (lower.contains('/approve') && paymentId != null) {
      _push(context, ParentPaymentApprovalPage(paymentId: paymentId));
      return true;
    }
    if (paymentId != null) {
      _push(context, FamilyPaymentDetailPage(paymentId: paymentId));
      return true;
    }
    return false;
  }

  static String _combinedType(Map<String, dynamic> data) {
    return [
      data['type'],
      data['event'],
      data['category'],
      data['notificationType'],
    ].whereType<String>().join(' ').toLowerCase();
  }

  static String? _paymentId(Map<String, dynamic> data) {
    return data['paymentId']?.toString() ??
        data['resourceId']?.toString() ??
        data['id']?.toString();
  }

  static bool _matches(String text, String token) =>
      text.contains(token.replaceAll('.', '').replaceAll('_', '')) ||
      text.contains(token) ||
      text.contains(token.replaceAll('.', '_'));

  static String? _segmentAfter(String path, String marker) {
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    final index = parts.indexWhere((part) => part.toLowerCase() == marker);
    if (index == -1 || index + 1 >= parts.length) return null;
    return parts[index + 1];
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

Future<void> showFamilyPaymentResultDialog(
  BuildContext context, {
  required FamilyPaymentDetail payment,
}) {
  final usedParentCard = payment.usedParentCard ||
      (payment.fundingSource ?? '').toLowerCase().contains('parent');
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: Icon(
        usedParentCard ? Icons.verified_user_outlined : Icons.check_circle_outline,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(usedParentCard ? 'Pago autorizado por tu tutor' : 'Pago realizado'),
      content: Text(
        usedParentCard
            ? 'Tu compra en ${payment.merchantName} fue autorizada. No mostramos información bancaria.'
            : 'Tu pago en ${payment.merchantName} se completó correctamente.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
