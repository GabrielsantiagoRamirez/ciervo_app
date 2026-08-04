import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/utils/display_formatters.dart';
import '../../chat/domain/repositories/chat_repository.dart';
import '../../chat/presentation/pages/chat_conversation_page.dart';
import '../../chat_payments/presentation/pages/chat_gift_page.dart';
import '../../chat_payments/presentation/pages/chat_pay_page.dart';
import '../../home/domain/entities/home_place.dart';
import '../../place_detail/presentation/pages/place_detail_page.dart';
import '../../users/domain/entities/user_search_result.dart';
import '../../wallet/presentation/pages/recharge_by_ciervo_id_page.dart';
import '../../wallet/presentation/pages/request_money_page.dart';
import '../domain/entities/global_search_models.dart';

/// Navegación tipada según `item.type` del GET /api/search.
abstract final class GlobalSearchNavigation {
  static Future<void> open(BuildContext context, GlobalSearchItem item) {
    return switch (item.type) {
      GlobalSearchItemType.person => _openPerson(context, item),
      GlobalSearchItemType.business => _openBusiness(context, item),
      GlobalSearchItemType.product ||
      GlobalSearchItemType.service ||
      GlobalSearchItemType.event =>
        _openBusinessLinked(context, item),
      GlobalSearchItemType.promotion => _openPromotion(context, item),
      GlobalSearchItemType.unknown => _openBusinessLinked(context, item),
    };
  }

  static Future<void> _openPerson(
    BuildContext context,
    GlobalSearchItem item,
  ) async {
    final user = UserSearchResult(
      userId: item.id,
      fullName: item.title,
      username: item.username,
      ciervoUserCode: item.ciervoUserCode,
      photoUrl: item.imageUrl,
      distanceKm: item.distanceKm,
      city: item.city,
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: item.imageUrl != null
                    ? NetworkImage(item.imageUrl!)
                    : null,
                child: item.imageUrl == null
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              title: Text(item.title),
              subtitle: Text(
                DisplayFormatters.identityLine(
                  username: item.username,
                  displayName: item.title,
                  ciervoId: item.ciervoUserCode,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Abrir chat'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openDirectChat(context, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Pagar'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatPayPage(
                      initialTargetCiervoCode: user.ciervoUserCode,
                      initialTargetUserId: user.userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard_outlined),
              title: const Text('Enviar regalo'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatGiftPage(
                      initialTargetCiervoCode: user.ciervoUserCode,
                      initialTargetUserId: user.userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.request_page_outlined),
              title: const Text('Pinduck'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RequestMoneyPage(
                      initialPayerCiervoCode: user.ciervoUserCode,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_card_outlined),
              title: const Text('Recargar por CIERVO ID'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RechargeByCiervoIdPage(
                      initialCiervoCode: user.ciervoUserCode,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openDirectChat(
    BuildContext context,
    UserSearchResult user,
  ) async {
    final result = await getIt<ChatRepository>().createDirectConversation(
      targetUserId: user.userId,
    );
    if (!context.mounted) return;
    result.when(
      success: (conversation) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatConversationPage(
              conversationId: conversation.id,
              title: user.fullName,
            ),
          ),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  static Future<void> _openBusiness(
    BuildContext context,
    GlobalSearchItem item,
  ) {
    final place = HomePlace(
      id: item.businessId ?? item.id,
      name: item.title,
      category: item.subtitle ?? item.city ?? 'Comercio',
      rating: 0,
      priceLevel: '',
      distanceKm: item.distanceKm ?? 0,
      matchPercent: 0,
      imageUrl: item.imageUrl ?? '',
      city: item.city,
    );
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlaceDetailPage(place: place)),
    );
  }

  static Future<void> _openBusinessLinked(
    BuildContext context,
    GlobalSearchItem item,
  ) async {
    final businessId = item.businessId ?? item.id;
    if (businessId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.type.chipLabel}: ${item.title}')),
      );
      return;
    }
    final place = HomePlace(
      id: businessId,
      name: item.businessName ?? item.title,
      category: item.type.chipLabel,
      rating: 0,
      priceLevel: item.priceLabel,
      distanceKm: item.distanceKm ?? 0,
      matchPercent: 0,
      imageUrl: item.imageUrl ?? '',
      city: item.city,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlaceDetailPage(place: place)),
    );
  }

  static Future<void> _openPromotion(
    BuildContext context,
    GlobalSearchItem item,
  ) async {
    final promoId = int.tryParse(item.id);
    if (promoId != null) {
      context.push('/marketplace/promos/$promoId');
      return;
    }
    await _openBusinessLinked(context, item);
  }
}

IconData iconForSearchType(GlobalSearchItemType type) => switch (type) {
  GlobalSearchItemType.person => Icons.person_outline,
  GlobalSearchItemType.business => Icons.storefront_outlined,
  GlobalSearchItemType.product => Icons.fastfood_outlined,
  GlobalSearchItemType.promotion => Icons.local_offer_outlined,
  GlobalSearchItemType.service => Icons.spa_outlined,
  GlobalSearchItemType.event => Icons.event_available_outlined,
  GlobalSearchItemType.unknown => Icons.search,
};
