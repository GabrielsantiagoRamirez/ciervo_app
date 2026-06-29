// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../qr_wallet/presentation/pages/qr_wallet_page.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(getIt<NotificationsRepository>())..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notificaciones'),
      actions: [
        IconButton(
          tooltip: 'Preferencias',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationPreferencesPage(),
            ),
          ),
          icon: const Icon(Icons.tune),
        ),
        IconButton(
          tooltip: 'Marcar todas como leidas',
          onPressed: context.read<NotificationsCubit>().markAllAsRead,
          icon: const Icon(Icons.done_all),
        ),
      ],
    ),
    body: BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: context.read<NotificationsCubit>().load,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: switch (state.status) {
              NotificationsStatus.initial || NotificationsStatus.loading =>
                const CiervoLoadingState(),
              NotificationsStatus.empty => const CiervoEmptyState(
                  title: 'Sin notificaciones',
                  description:
                      'Aqui veras avisos de reservas, QR, tickets, beneficios y seguridad.',
                  icon: Icons.notifications_none,
                ),
              NotificationsStatus.failure => CiervoErrorState(
                  title: 'No pudimos cargar notificaciones',
                  description: state.errorMessage ?? 'Intenta nuevamente.',
                  onRetry: context.read<NotificationsCubit>().load,
                ),
              _ => ListView.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return InkWell(
                      onTap: () => _openNotification(context, item),
                      child: CiervoCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _notificationIcon(item),
                              color: item.isRead
                                  ? Theme.of(context).colorScheme.outline
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      if ((item.type ?? '').isNotEmpty)
                                        Chip(
                                          label: Text(_notificationTypeLabel(item.type!)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if ((item.category ?? '').isNotEmpty)
                                        Chip(
                                          label: Text(_notificationTypeLabel(item.category!)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (!item.isRead)
                                        const Chip(
                                          label: Text('Nuevo'),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(item.message),
                                  if (item.date != null) ...[
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      item.date!
                                          .toLocal()
                                          .toString()
                                          .substring(0, 16),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            },
          ),
        );
      },
    ),
  );
}

Future<void> _openNotification(
  BuildContext context,
  AppNotification item,
) async {
  if (!item.isRead) {
    context.read<NotificationsCubit>().markAsRead(item.id);
  }
  final handled = _openDeepLink(context, item);
  if (!handled && context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _NotificationDetailPage(item: item),
      ),
    );
  }
}

bool _openDeepLink(BuildContext context, AppNotification item) {
  final link = item.deepLink ?? _fallbackDeepLink(item);
  if (link == null || link.isEmpty) return false;
  final normalized = link.startsWith('/') ? link : '/$link';
  if (normalized.startsWith('/bookings/') ||
      normalized.startsWith('/tickets/') ||
      normalized.startsWith('/gift-cards/') ||
      normalized.startsWith('/coupons/') ||
      normalized.startsWith('/rewards/')) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QrWalletPage()),
    );
    return true;
  }
  return false;
}

String? _fallbackDeepLink(AppNotification item) {
  if (item.bookingId != null) return '/bookings/${item.bookingId}';
  if (item.ticketId != null) return '/tickets/${item.ticketId}';
  if (item.giftCardId != null) return '/gift-cards/${item.giftCardId}';
  if (item.couponId != null) return '/coupons/${item.couponId}';
  if (item.rewardId != null) return '/rewards/${item.rewardId}';
  if (item.eventId != null) return '/events/${item.eventId}';
  if (item.businessId != null) return '/businesses/${item.businessId}';
  return null;
}

IconData _notificationIcon(AppNotification item) {
  final type = item.type ?? '';
  if (type.contains('event') || type.contains('ticket')) {
    return Icons.confirmation_number_outlined;
  }
  if (type.contains('booking')) return Icons.event_available_outlined;
  if (type.contains('gift')) return Icons.card_giftcard_outlined;
  if (type.contains('reward') || type.contains('coupon')) {
    return Icons.redeem_outlined;
  }
  if (type.contains('qr')) return Icons.qr_code_2_outlined;
  if (type.contains('delivery')) return Icons.delivery_dining_outlined;
  if (type.contains('kyc') || type.contains('fraud')) {
    return Icons.verified_user_outlined;
  }
  if (type.contains('business')) return Icons.storefront_outlined;
  return Icons.notifications_active_outlined;
}

class _NotificationDetailPage extends StatelessWidget {
  const _NotificationDetailPage({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(item.message),
              const SizedBox(height: AppSpacing.md),
              _detail('Tipo', item.type),
              _detail('Categoria', item.category),
              _detail('Ruta interna', item.deepLink),
              _detail('Datos adicionales', item.metadataJson),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _detail(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text('$label: $value'),
    );
  }
}

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  late Future<Map<String, dynamic>> _preferences;
  final _values = <String, bool>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _preferences = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final result = await getIt<NotificationsRepository>().preferences();
    return result.when(
      success: (value) {
        _values
          ..clear()
          ..addAll(_boolMap(value));
        return value;
      },
      failure: (error) => throw error,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preferencias')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _preferences,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CiervoLoadingState();
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CiervoErrorState(
              title: 'No pudimos cargar preferencias',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: () => setState(() => _preferences = _load()),
            ),
          );
        }
        if (_values.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CiervoEmptyState(
              title: 'Sin preferencias disponibles',
              description: 'Backend aun no devolvio canales configurables.',
              icon: Icons.tune,
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ..._groupedPreferenceKeys(_values.keys).entries.map(
              (entry) => CiervoCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...entry.value.map(
                      (key) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_label(key)),
                        value: _values[key] ?? false,
                        onChanged: (value) =>
                            setState(() => _values[key] = value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando' : 'Guardar preferencias'),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    final result =
        await getIt<NotificationsRepository>().updatePreferences(_values);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferencias actualizadas.')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}

Map<String, bool> _boolMap(Map<String, dynamic> source) {
  final result = <String, bool>{};
  for (final entry in source.entries) {
    final value = entry.value;
    if (value is bool) result[entry.key] = value;
  }
  return result;
}

String _label(String key) {
  final spaced = key.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced.replaceAll('_', ' ');
}

Map<String, List<String>> _groupedPreferenceKeys(Iterable<String> keys) {
  final groups = <String, List<String>>{
    'Descubrimiento': [],
    'Favoritos': [],
    'Familia': [],
    'Reservas/Eventos': [],
    'Entregas': [],
    'Seguridad': [],
  };
  for (final key in keys) {
    groups[_groupFor(key)]!.add(key);
  }
  groups.removeWhere((_, value) => value.isEmpty);
  return groups;
}

String _groupFor(String key) {
  final text = key.toLowerCase();
  if (text.contains('favorite')) return 'Favoritos';
  if (text.contains('kid') || text.contains('family')) return 'Familia';
  if (text.contains('booking') ||
      text.contains('event') ||
      text.contains('ticket') ||
      text.contains('qr')) {
    return 'Reservas/Eventos';
  }
  if (text.contains('delivery') || text.contains('order')) return 'Entregas';
  if (text.contains('kyc') ||
      text.contains('fraud') ||
      text.contains('security') ||
      text.contains('otp')) {
    return 'Seguridad';
  }
  return 'Descubrimiento';
}

String _notificationTypeLabel(String value) {
  final text = value.toLowerCase();
  return switch (text) {
    'new_business' => 'Nuevo negocio',
    'new_event' => 'Nuevo evento',
    'new_product' => 'Nuevo producto',
    'new_service' => 'Nuevo servicio',
    'new_promotion' => 'Nueva promocion',
    'new_discount' => 'Nuevo descuento',
    'new_gift_card' => 'Nueva tarjeta regalo',
    'new_benefit' => 'Nuevo beneficio',
    'new_coupon' => 'Nuevo cupon',
    'favorite_business_activity' => 'Actividad de favorito',
    'nearby_activity' => 'Actividad cercana',
    'booking_created' => 'Reserva creada',
    'booking_confirmed' => 'Reserva confirmada',
    'ticket_generated' => 'Entrada generada',
    'ticket_used' => 'Entrada usada',
    'qr_redeemed' => 'QR redimido',
    'reward_redeemed' => 'Recompensa redimida',
    'coupon_redeemed' => 'Cupon redimido',
    'gift_card_created' => 'Tarjeta regalo creada',
    'gift_card_redeemed' => 'Tarjeta regalo redimida',
    'delivery_assigned' => 'Entrega asignada',
    'delivery_delivered' => 'Entrega completada',
    'kyc_approved' => 'Identidad aprobada',
    'kyc_rejected' => 'Identidad rechazada',
    'fraud_alert' => 'Alerta de seguridad',
    'delivery' => 'Entregas',
    'security' => 'Seguridad',
    'booking' => 'Reservas',
    'ticket' => 'Entradas',
    'reward' => 'Recompensas',
    'coupon' => 'Cupones',
    _ => value.replaceAll('_', ' '),
  };
}
