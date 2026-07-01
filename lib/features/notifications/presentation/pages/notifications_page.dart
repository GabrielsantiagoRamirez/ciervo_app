// ignore_for_file: unnecessary_underscores

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/notifications/notifications_sync.dart';
import '../../../../core/notifications/notification_deep_link.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../wallet/presentation/widgets/ciervo_digital_card.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
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

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  static const _filters = <String?, String>{
    null: 'Todas',
    'Messages': 'Mensajes',
    'Wallet': 'Wallet',
    'Pagos': 'Pagos',
    'Reservas': 'Reservas',
    'Delivery': 'Delivery',
    'Eventos': 'Eventos',
    'Promociones': 'Promos',
    'Recompensas': 'Recompensas',
    'Seguridad': 'Seguridad',
    'Sistema': 'Sistema',
  };

  String? _category;
  StreamSubscription<void>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _syncSubscription = getIt<NotificationsSync>().onRefresh.listen((_) {
      if (!mounted) return;
      context.read<NotificationsCubit>().load(category: _category);
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: const Text('CIERVO CLUB'),
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
        IconButton(
          tooltip: 'Eliminar todas',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Eliminar todas'),
                content: const Text('Esta accion no se puede deshacer.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              context.read<NotificationsCubit>().deleteAll();
            }
          },
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
    ),
    body: Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            children: _filters.entries.map((entry) {
              final selected = _category == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: FilterChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _category = entry.key);
                    context.read<NotificationsCubit>().load(category: entry.key);
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              return RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                onRefresh: () =>
                    context.read<NotificationsCubit>().load(category: _category),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: switch (state.status) {
                    NotificationsStatus.initial ||
                    NotificationsStatus.loading =>
                      const CiervoLoadingState(),
                    NotificationsStatus.empty => const CiervoEmptyState(
                        title: 'Sin notificaciones',
                        description:
                            'Aqui veras avisos de wallet, chat, delivery, reservas y seguridad.',
                        icon: Icons.notifications_none,
                      ),
                    NotificationsStatus.failure => CiervoErrorState(
                        title: 'No pudimos cargar notificaciones',
                        description: state.errorMessage ?? 'Intenta nuevamente.',
                        onRetry: () => context
                            .read<NotificationsCubit>()
                            .load(category: _category),
                      ),
                    _ => ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: CiervoBrandColors.expense,
                              child: const Icon(Icons.delete_outline),
                            ),
                            onDismissed: (_) => context
                                .read<NotificationsCubit>()
                                .deleteNotification(item.id),
                            child: InkWell(
                              onTap: () => _openNotification(context, item),
                              child: CiervoCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'assets/notifications/ciervo_logo_gold.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight: item.isRead
                                                            ? FontWeight.w500
                                                            : FontWeight.w700,
                                                        color: item.isRead
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                ),
                                              ),
                                              if (!item.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: const EdgeInsets.only(
                                                    left: AppSpacing.xs,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if ((item.category ?? item.type)
                                              ?.isNotEmpty ==
                                              true) ...[
                                            const SizedBox(
                                              height: AppSpacing.xxs,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: CiervoBrandColors.gold
                                                    .withValues(alpha: 0.14),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                DisplayLabels.notificationPreference(
                                                  item.category ?? item.type!,
                                                ),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: AppSpacing.xxs),
                                          Text(
                                            item.message,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              height: 1.35,
                                            ),
                                          ),
                                          if (item.date != null) ...[
                                            const SizedBox(
                                              height: AppSpacing.xxs,
                                            ),
                                            Text(
                                              _formatNotificationDate(item.date!),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
        ),
      ],
    ),
  );
}

String _formatNotificationDate(DateTime date) {
  final local = date.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

Future<void> _openNotification(
  BuildContext context,
  AppNotification item,
) async {
  if (!item.isRead) {
    context.read<NotificationsCubit>().markAsRead(item.id);
  }
  final handled = NotificationDeepLink.open(context, item);
  if (!handled && context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _NotificationDetailPage(item: item),
      ),
    );
  }
}

class _NotificationDetailPage extends StatelessWidget {
  const _NotificationDetailPage({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CiervoBrandColors.background,
    appBar: AppBar(
      backgroundColor: CiervoBrandColors.background,
      foregroundColor: CiervoBrandColors.gold,
      title: const Text('Detalle'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/notifications/ciervo_logo_gold.png',
                    width: 44,
                    height: 44,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                item.message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                    ),
              ),
              if (item.date != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _formatNotificationDate(item.date!),
                  style: const TextStyle(color: CiervoBrandColors.textMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _detail('Tipo', item.type),
              _detail('Categoría', item.category),
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
  late Future<List<_NotificationChannelPref>> _preferences;
  final _channels = <_NotificationChannelPref>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _preferences = _load();
  }

  Future<List<_NotificationChannelPref>> _load() async {
    final result = await getIt<NotificationsRepository>().preferences();
    return result.when(
      success: (value) {
        _channels
          ..clear()
          ..addAll(_parseChannels(value));
        return List<_NotificationChannelPref>.from(_channels);
      },
      failure: (error) => throw error,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preferencias')),
    body: FutureBuilder<List<_NotificationChannelPref>>(
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
        if (_channels.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CiervoEmptyState(
              title: 'Sin preferencias disponibles',
              description:
                  'Aún no hay canales de notificación configurados para tu cuenta.',
              icon: Icons.tune,
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ..._channels.map(
              (channel) => CiervoCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(channel.name),
                  subtitle: channel.description == null
                      ? null
                      : Text(channel.description!),
                  value: channel.enabled,
                  onChanged: channel.configurable
                      ? (value) => setState(() => channel.enabled = value)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando…' : 'Guardar preferencias'),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = {
      'channels': _channels
          .map((channel) => {'code': channel.code, 'enabled': channel.enabled})
          .toList(),
    };
    final result =
        await getIt<NotificationsRepository>().updatePreferences(payload);
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

class _NotificationChannelPref {
  _NotificationChannelPref({
    required this.code,
    required this.name,
    required this.enabled,
    this.description,
    this.configurable = true,
  });

  final String code;
  final String name;
  bool enabled;
  final String? description;
  final bool configurable;
}

List<_NotificationChannelPref> _parseChannels(Map<String, dynamic> source) {
  final raw = source['channels'];
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(
          (item) => _NotificationChannelPref(
            code: '${item['code'] ?? ''}',
            name: '${item['name'] ?? item['code'] ?? 'Canal'}',
            enabled: item['enabled'] == true,
            description: item['description']?.toString(),
            configurable: item['configurable'] != false,
          ),
        )
        .where((channel) => channel.code.isNotEmpty)
        .toList();
  }
  return _boolMap(source)
      .entries
      .map(
        (entry) => _NotificationChannelPref(
          code: entry.key,
          name: DisplayLabels.notificationPreference(entry.key),
          enabled: entry.value,
        ),
      )
      .toList();
}

Map<String, bool> _boolMap(Map<String, dynamic> source) {
  final result = <String, bool>{};
  for (final entry in source.entries) {
    final value = entry.value;
    if (value is bool) result[entry.key] = value;
  }
  return result;
}

Map<String, List<String>> _groupedPreferenceKeys(Iterable<String> keys) {
  final groups = <String, List<String>>{
    'Mensajes': [],
    'Wallet': [],
    'Pagos': [],
    'Reservas': [],
    'Delivery': [],
    'Eventos': [],
    'Promociones': [],
    'Recompensas': [],
    'Seguridad': [],
    'Sistema': [],
  };
  for (final key in keys) {
    groups[_groupFor(key)]!.add(key);
  }
  groups.removeWhere((_, value) => value.isEmpty);
  return groups;
}

String _groupFor(String key) {
  final text = key.toLowerCase();
  if (text.contains('message') || text.contains('chat')) return 'Mensajes';
  if (text.contains('wallet')) return 'Wallet';
  if (text.contains('pago') || text.contains('payment')) return 'Pagos';
  if (text.contains('booking') || text.contains('reserv')) return 'Reservas';
  if (text.contains('delivery') || text.contains('order')) return 'Delivery';
  if (text.contains('event') || text.contains('ticket')) return 'Eventos';
  if (text.contains('promo') || text.contains('coupon')) return 'Promociones';
  if (text.contains('reward') || text.contains('recompensa')) {
    return 'Recompensas';
  }
  if (text.contains('security') ||
      text.contains('seguridad') ||
      text.contains('kyc') ||
      text.contains('fraud')) {
    return 'Seguridad';
  }
  return 'Sistema';
}
