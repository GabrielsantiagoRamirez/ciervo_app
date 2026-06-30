// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../data/qr_wallet_repository.dart';
import '../../domain/entities/ciervo_qr_item.dart';
import '../widgets/ciervo_qr_card.dart';

class QrWalletPage extends StatefulWidget {
  const QrWalletPage({this.initialTabIndex = 0, super.key});

  final int initialTabIndex;

  @override
  State<QrWalletPage> createState() => _QrWalletPageState();
}

class _QrWalletPageState extends State<QrWalletPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<_QrWalletState> _state;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    _state = _fetch();
  }

  Future<_QrWalletState> _fetch() async {
    final repository = getIt<QrWalletRepository>();
    final bookingsFuture = repository.bookings();
    final ticketsFuture = repository.tickets();
    final giftCardsFuture = repository.giftCards();
    final rewardHistoryFuture = repository.rewardHistory();
    final rewardsCatalogFuture = repository.rewardsCatalog();
    final couponsCatalogFuture = repository.couponsCatalog();
    final pointsFuture = repository.rewardPoints();

    final bookingsResult = await bookingsFuture;
    final ticketsResult = await ticketsFuture;
    final giftCardsResult = await giftCardsFuture;
    final rewardHistoryResult = await rewardHistoryFuture;
    final rewardsCatalogResult = await rewardsCatalogFuture;
    final couponsCatalogResult = await couponsCatalogFuture;
    final pointsResult = await pointsFuture;

    final errors = <String>[];
    final bookings = _items(bookingsResult, errors, 'Reservas');
    final tickets = _items(ticketsResult, errors, 'Entradas');
    final giftCards = _items(giftCardsResult, errors, 'Tarjetas regalo');
    final benefits = [
      ..._items(rewardHistoryResult, errors, 'Mis beneficios'),
      ..._items(rewardsCatalogResult, errors, 'Catalogo de recompensas'),
      ..._items(couponsCatalogResult, errors, 'Catalogo de cupones'),
    ];
    final points = _points(pointsResult, errors);

    return _QrWalletState(
      bookings: bookings,
      tickets: tickets,
      giftCards: giftCards,
      benefits: benefits,
      points: points,
      errors: errors,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mis QR'),
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Activos'),
          Tab(text: 'Entradas'),
          Tab(text: 'Regalo'),
          Tab(text: 'Beneficios'),
        ],
      ),
    ),
    body: FutureBuilder<_QrWalletState>(
      future: _state,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CiervoLoadingState(itemCount: 4);
        }
        if (snapshot.hasError) {
          return CiervoErrorState(
            title: 'No pudimos cargar tus QR',
            description: UserErrorMessage.from(snapshot.error!),
            onRetry: () => setState(_load),
          );
        }
        final state = snapshot.data ?? _QrWalletState.empty();
        return RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: TabBarView(
            controller: _tabController,
            children: [
              _QrList(
                items: state.activeItems,
                errors: state.errors,
                emptyTitle: 'Sin QR activos',
                emptyDescription:
                    'Tus reservas, entradas, tarjetas regalo y beneficios activos apareceran aqui.',
                onRefreshItem: _refreshItem,
                onRedeemItem: _redeemItem,
              ),
              _QrList(
                items: state.tickets,
                errors: state.errors,
                emptyTitle: 'Sin entradas',
                emptyDescription:
                    'Tus entradas de eventos apareceran aqui cuando existan.',
                onRefreshItem: _refreshItem,
                onRedeemItem: _redeemItem,
              ),
              _QrList(
                items: state.giftCards,
                errors: state.errors,
                emptyTitle: 'Sin tarjetas regalo',
                emptyDescription:
                    'Tus tarjetas regalo y su historial apareceran aqui.',
                onRefreshItem: _refreshItem,
                onRedeemItem: _redeemItem,
              ),
              _QrList(
                items: state.benefits,
                errors: state.errors,
                header: _PointsHeader(points: state.points),
                emptyTitle: 'Sin beneficios',
                emptyDescription:
                    'Tu catalogo, puntos e historial de redenciones apareceran aqui.',
                onRefreshItem: _refreshItem,
                onRedeemItem: _redeemItem,
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _refreshItem(CiervoQrItem item) async {
    if (item.type == CiervoQrType.ticket && item.id.isNotEmpty) {
      final ticketResult = await getIt<QrWalletRepository>().ticket(item.id);
      if (!mounted) return;
      final handled = ticketResult.when(
        success: (ticket) {
          _showQrDetail(ticket);
          return true;
        },
        failure: (_) => false,
      );
      if (handled) return;
    }
    if ((item.qrId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR no generado para este elemento.')),
      );
      return;
    }
    final result = await getIt<QrWalletRepository>().getQr(item.qrId!);
    if (!mounted) return;
    result.when(
      success: (qr) => _showQrDetail(qr),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _redeemItem(CiervoQrItem item) async {
    final result = await getIt<QrWalletRepository>().redeem(item);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beneficio redimido.')),
        );
        setState(_load);
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  void _showQrDetail(CiervoQrItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CiervoQrCard(
            item: item,
            onRefresh: () {
              Navigator.pop(context);
              _refreshItem(item);
            },
          ),
        ),
      ),
    );
  }
}

class _QrList extends StatelessWidget {
  const _QrList({
    required this.items,
    required this.errors,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.onRefreshItem,
    required this.onRedeemItem,
    this.header,
  });

  final List<CiervoQrItem> items;
  final List<String> errors;
  final String emptyTitle;
  final String emptyDescription;
  final ValueChanged<CiervoQrItem> onRefreshItem;
  final ValueChanged<CiervoQrItem> onRedeemItem;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: AppSpacing.md),
          ],
          if (errors.isNotEmpty) _Warnings(errors: errors),
          CiervoEmptyState(
            title: emptyTitle,
            description: emptyDescription,
            icon: Icons.qr_code_2_outlined,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount:
          items.length + (errors.isEmpty ? 0 : 1) + (header == null ? 0 : 1),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (header != null && index == 0) return header!;
        if (errors.isNotEmpty && index == 0) {
          return _Warnings(errors: errors);
        }
        final offset = (errors.isEmpty ? 0 : 1) + (header == null ? 0 : 1);
        if (errors.isNotEmpty && header != null && index == 1) {
          return _Warnings(errors: errors);
        }
        final item = items[index - offset];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CiervoQrCard(
              item: item,
              onRefresh: () => onRefreshItem(item),
              onTap: () => onRefreshItem(item),
            ),
            if (item.canRedeemFromCatalog) ...[
              const SizedBox(height: AppSpacing.xs),
              FilledButton.icon(
                onPressed: () => onRedeemItem(item),
                icon: const Icon(Icons.redeem_outlined),
                label: const Text('Redimir beneficio'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PointsHeader extends StatelessWidget {
  const _PointsHeader({required this.points});

  final int? points;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.stars_outlined),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              points == null ? 'Puntos no disponibles' : 'Mis puntos: $points',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Warnings extends StatelessWidget {
  const _Warnings({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notas de integracion',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...errors.map((error) => Text('- $error')),
        ],
      ),
    ),
  );
}

class _QrWalletState {
  const _QrWalletState({
    required this.bookings,
    required this.tickets,
    required this.giftCards,
    required this.benefits,
    required this.points,
    required this.errors,
  });

  factory _QrWalletState.empty() => const _QrWalletState(
    bookings: [],
    tickets: [],
    giftCards: [],
    benefits: [],
    points: null,
    errors: [],
  );

  final List<CiervoQrItem> bookings;
  final List<CiervoQrItem> tickets;
  final List<CiervoQrItem> giftCards;
  final List<CiervoQrItem> benefits;
  final int? points;
  final List<String> errors;

  List<CiervoQrItem> get activeItems => [
    ...bookings,
    ...tickets,
    ...giftCards,
    ...benefits,
  ].where((item) => item.status == CiervoQrStatus.active).toList();
}

List<CiervoQrItem> _items(
  Result<List<CiervoQrItem>> result,
  List<String> errors,
  String label,
) =>
    result.when(
      success: (value) => value,
      failure: (error) {
        errors.add('$label: ${UserErrorMessage.from(error)}');
        return const [];
      },
    );

int? _points(Result<int?> result, List<String> errors) => result.when(
  success: (value) => value is int ? value : null,
  failure: (error) {
    errors.add('Mis puntos: ${UserErrorMessage.from(error)}');
    return null;
  },
);
