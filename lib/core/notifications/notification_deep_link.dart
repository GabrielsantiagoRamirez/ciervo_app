import 'package:flutter/material.dart';

import '../../features/bonuses/presentation/pages/bonus_detail_page.dart';
import '../../features/bonuses/presentation/pages/bonuses_pages.dart';
import '../../features/chat/presentation/pages/chat_conversation_page.dart';
import '../../features/chat/presentation/pages/chat_inbox_page.dart';
import '../../features/delivery/presentation/pages/customer_order_detail_page.dart';
import '../../features/delivery/presentation/pages/customer_orders_page.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/qr_wallet/presentation/pages/qr_wallet_page.dart';
import '../../features/reservations/presentation/pages/reservations_page.dart';
import '../../features/vakupli/presentation/pages/vakupli_page.dart';
import '../../features/secure_shipment/presentation/pages/secure_shipment_detail_page.dart';
import '../../features/secure_shipment/presentation/pages/secure_shipment_list_page.dart';
import '../../features/wallet/presentation/pages/payment_requests_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';

/// Navega desde una notificacion (in-app o push) a la pantalla correspondiente.
class NotificationDeepLink {
  const NotificationDeepLink._();

  static bool open(BuildContext context, AppNotification item) {
    final link = item.deepLink ?? _fallback(item);
    if (link != null && link.isNotEmpty) {
      return _openPath(context, link, item);
    }
    return _openByType(context, item);
  }

  static bool openFromPayload(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final deepLink = data['deepLink']?.toString();
    if (deepLink != null && deepLink.isNotEmpty) {
      return _openPath(context, deepLink, null);
    }
    final type = data['type']?.toString() ?? '';
    final category = data['category']?.toString() ?? '';
    return _openByCategory(context, type, category, data);
  }

  static String? _fallback(AppNotification item) {
    if (item.bookingId != null) return '/reservations/${item.bookingId}';
    if (item.ticketId != null) return '/events/tickets/${item.ticketId}';
    if (item.eventId != null) return '/events/${item.eventId}';
    if (item.businessId != null) return '/businesses/${item.businessId}';
    if (item.couponId != null) return '/promotions/coupons/${item.couponId}';
    if (item.rewardId != null) return '/rewards/${item.rewardId}';
    if (item.giftCardId != null) return '/wallet/gift-cards/${item.giftCardId}';
    return null;
  }

  static bool _openPath(
    BuildContext context,
    String link,
    AppNotification? item,
  ) {
    final path = link.startsWith('/') ? link : '/$link';
    final lower = path.toLowerCase();

    if (lower.contains('/chat') || lower.contains('/conversations/')) {
      final id = _segmentId(path);
      if (id != null) {
        _push(context, ChatConversationPage(conversationId: id));
        return true;
      }
      _push(context, const ChatInboxPage());
      return true;
    }
    if (lower.contains('/payment-request') || lower.contains('/payment_request')) {
      _push(context, const PaymentRequestsPage());
      return true;
    }
    if (lower.contains('/vakupli')) {
      _push(context, const VakupliPage());
      return true;
    }
    if (lower.contains('/bonus') || lower.contains('/bonuses')) {
      final id = _segmentId(path);
      if (id != null) {
        _push(context, BonusDetailPage(bonusId: id));
        return true;
      }
      _push(context, const MyBonusesPage());
      return true;
    }
    if (lower.contains('/campaign') || lower.contains('/ads')) {
      _push(context, const BonusesCatalogPage());
      return true;
    }
    if (lower.contains('/secure-shipment') || lower.contains('/secure_shipment')) {
      final id = _segmentId(path);
      if (id != null) {
        _push(context, SecureShipmentDetailPage(publicId: id));
        return true;
      }
      return false;
    }
    if (lower.contains('/wallet') || lower.contains('/nfc')) {
      _push(context, const WalletPage());
      return true;
    }
    if (lower.contains('/delivery') || lower.contains('/orders/')) {
      final id = _segmentId(path);
      if (id != null) {
        _push(context, CustomerOrderDetailPage(orderId: id));
        return true;
      }
      _push(context, const CustomerOrdersPage());
      return true;
    }
    if (lower.contains('/reserv') || lower.contains('/booking')) {
      _push(context, const ReservationsPage());
      return true;
    }
    if (lower.contains('/event') ||
        lower.contains('/ticket') ||
        lower.contains('/promo') ||
        lower.contains('/coupon') ||
        lower.contains('/reward') ||
        lower.contains('/qr')) {
      _push(context, const QrWalletPage());
      return true;
    }
    if (lower.contains('/profile') ||
        lower.contains('/security') ||
        lower.contains('/settings')) {
      _push(context, const ProfilePage());
      return true;
    }
    return false;
  }

  static bool _openByType(BuildContext context, AppNotification item) {
    final type = (item.type ?? item.category ?? '').toLowerCase();
    return _openByCategory(context, type, item.category ?? '', {});
  }

  static bool _openByCategory(
    BuildContext context,
    String type,
    String category,
    Map<String, dynamic> data,
  ) {
    final text = '$type $category'.toLowerCase();
    final publicId = data['resourceId']?.toString() ??
        data['publicId']?.toString();
    if (text.contains('secure_shipment') ||
        text.contains('secure shipment') ||
        text.startsWith('secure_')) {
      if (publicId != null && publicId.isNotEmpty) {
        _push(context, SecureShipmentDetailPage(publicId: publicId));
      } else {
        _push(context, const SecureShipmentListPage());
      }
      return true;
    }
    if (text.contains('chat.message') ||
        text.contains('message.received') ||
        (text.contains('message') && text.contains('chat'))) {
      final conversationId = data['conversationId']?.toString() ??
          data['chatConversationId']?.toString() ??
          data['resourceId']?.toString();
      if (conversationId != null && conversationId.isNotEmpty) {
        _push(context, ChatConversationPage(conversationId: conversationId));
      } else {
        _push(context, const ChatInboxPage());
      }
      return true;
    }
    if (text.contains('payment_request') ||
        text.contains('pay_for_me') ||
        text.contains('paga por mi')) {
      _push(context, const PaymentRequestsPage());
      return true;
    }
    if (text.contains('approval.requested') ||
        text.contains('payment_approval')) {
      _push(context, const PaymentRequestsPage());
      return true;
    }
    if (text.contains('vakupli')) {
      _push(context, const VakupliPage());
      return true;
    }
    if (text.contains('bonus_claimed') ||
        text.contains('bonus_redeemed') ||
        text.contains('bonus claimed') ||
        text.contains('bonus redeemed') ||
        text.contains('bono reclam') ||
        text.contains('bono redim')) {
      final bonusId = data['bonusId']?.toString();
      if (bonusId != null && bonusId.isNotEmpty) {
        _push(context, BonusDetailPage(bonusId: bonusId));
      } else {
        _push(context, const MyBonusesPage());
      }
      return true;
    }
    if (text.contains('ads_campaign_published') ||
        text.contains('campaign_published') ||
        text.contains('campana publicada') ||
        text.contains('nueva campana')) {
      _push(context, const BonusesCatalogPage());
      return true;
    }
    if (text.contains('wallet') ||
        text.contains('payment') ||
        text.contains('pago') ||
        text.contains('transfer') ||
        text.contains('nfc') ||
        text.contains('recharge') ||
        text.contains('recarga')) {
      _push(context, const WalletPage());
      return true;
    }
    if (text.contains('delivery') || text.contains('pedido') || text.contains('order')) {
      final orderId = data['orderId']?.toString();
      if (orderId != null && orderId.isNotEmpty) {
        _push(context, CustomerOrderDetailPage(orderId: orderId));
      } else {
        _push(context, const CustomerOrdersPage());
      }
      return true;
    }
    if (text.contains('booking') ||
        text.contains('reserv') ||
        text.contains('reservation')) {
      _push(context, const ReservationsPage());
      return true;
    }
    if (text.contains('event') ||
        text.contains('ticket') ||
        text.contains('promo') ||
        text.contains('coupon') ||
        text.contains('reward')) {
      _push(context, const QrWalletPage());
      return true;
    }
    if (text.contains('security') ||
        text.contains('seguridad') ||
        text.contains('login') ||
        text.contains('kyc')) {
      _push(context, const ProfilePage());
      return true;
    }
    return false;
  }

  static String? _segmentId(String path) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.last;
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
