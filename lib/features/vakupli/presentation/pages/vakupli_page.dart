import 'package:flutter/material.dart';

import '../../../chat/domain/entities/chat_button.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/presentation/widgets/chat_buttons_bar.dart';
import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../core/utils/thousands_separator_input_formatter.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../data/vakupli_repository.dart';
import '../../domain/entities/vakupli_plan.dart';
import '../widgets/vakupli_chat_bubble.dart';
import '../widgets/vakupli_friends_group.dart';
import '../widgets/vakupli_plan_card.dart';
import '../widgets/vakupli_split_selector.dart';
import '../widgets/vaku_buy_extra_slots_sheet.dart';
import '../widgets/vaku_insufficient_funds_sheet.dart';
import 'vakupli_contacts_picker_page.dart';

class VakupliPage extends StatefulWidget {
  const VakupliPage({super.key});

  @override
  State<VakupliPage> createState() => _VakupliPageState();
}

class _VakupliPageState extends State<VakupliPage>
    with SingleTickerProviderStateMixin {
  final _repository = getIt<VakupliRepository>();
  late final TabController _tabs;
  List<VakupliPlan> _plans = const [];
  bool _loading = true;
  String? _error;
  bool _apiUnavailable = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
      _apiUnavailable = false;
    });
    final result = await _repository.plans();
    if (!mounted) return;
    result.when(
      success: (plans) => setState(() {
        _plans = plans;
        _loading = false;
      }),
      failure: (error) {
        final message = UserErrorMessage.from(error).toLowerCase();
        setState(() {
          _loading = false;
          _error = UserErrorMessage.from(error);
          _apiUnavailable =
              message.contains('404') || message.contains('not found');
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaku'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Mis planes'),
            Tab(text: 'Crear plan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PlansTab(
            loading: _loading,
            error: _error,
            apiUnavailable: _apiUnavailable,
            plans: _plans,
            onRefresh: _loadPlans,
            onOpenPlan: _openPlanDetail,
          ),
          VakupliCreatePlanTab(
            repository: _repository,
            onCreated: () {
              _tabs.animateTo(0);
              _loadPlans();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openPlanDetail(VakupliPlan plan) async {
    if (plan.id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VakupliPlanDetailPage(plan: plan, repository: _repository),
      ),
    );
    _loadPlans();
  }
}

class _PlansTab extends StatelessWidget {
  const _PlansTab({
    required this.loading,
    required this.error,
    required this.apiUnavailable,
    required this.plans,
    required this.onRefresh,
    required this.onOpenPlan,
  });

  final bool loading;
  final String? error;
  final bool apiUnavailable;
  final List<VakupliPlan> plans;
  final Future<void> Function() onRefresh;
  final void Function(VakupliPlan plan) onOpenPlan;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: loading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [CiervoLoadingState(itemCount: 3)],
            )
          : error != null && plans.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (apiUnavailable)
                  const CiervoEmptyState(
                    title: 'Vaku próximamente',
                    description:
                        'El módulo social estará disponible cuando el backend lo active.',
                    icon: Icons.groups_outlined,
                  )
                else
                  CiervoErrorState(
                    title: 'No pudimos cargar tus planes',
                    description: error!,
                    onRetry: onRefresh,
                  ),
              ],
            )
          : plans.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                CiervoEmptyState(
                  title: 'Sin planes activos',
                  description:
                      'Crea un plan y comparte el link con tus amigos.',
                  icon: Icons.event_outlined,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: plans.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return GestureDetector(
                  onTap: () => onOpenPlan(plan),
                  child: VakupliPlanCard(plan: plan),
                );
              },
            ),
    );
  }
}

class VakupliCreatePlanTab extends StatefulWidget {
  const VakupliCreatePlanTab({
    required this.repository,
    required this.onCreated,
    super.key,
  });

  final VakupliRepository repository;
  final VoidCallback onCreated;

  @override
  State<VakupliCreatePlanTab> createState() => _VakupliCreatePlanTabState();
}

class _VakupliCreatePlanTabState extends State<VakupliCreatePlanTab> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  VakupliSplitOption _split = VakupliSplitOption.equal;
  bool _submitting = false;
  String? _error;
  String _currency = 'COP';
  String _countryCode = 'CO';

  @override
  void initState() {
    super.initState();
    _loadCountryCurrency();
  }

  Future<void> _loadCountryCurrency() async {
    final result = await getIt<ProfileRepository>().getMe();
    if (!mounted) return;
    result.when(
      success: (profile) {
        final country = (profile.countryCode ?? '').trim().toUpperCase();
        final resolved = country.isNotEmpty
            ? country
            : CountryRegistration.defaultCountryCode();
        setState(() {
          _countryCode = resolved;
          _currency = CountryRegistration.currencyForCountry(resolved);
        });
      },
      failure: (_) {
        final resolved = CountryRegistration.defaultCountryCode();
        setState(() {
          _countryCode = resolved;
          _currency = CountryRegistration.currencyForCountry(resolved);
        });
      },
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = DisplayFormatters.parseMoneyInput(_amount.text);
    if (_title.text.trim().isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Completa título y monto.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await widget.repository.createPlan(
      title: _title.text.trim(),
      totalAmount: amount,
      splitOption: _split,
      description: _description.text.trim(),
      currency: _currency,
    );
    if (!mounted) return;
    result.when(
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _submitting = false;
      }),
      success: (_) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plan creado.')));
        widget.onCreated();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final countryLabel = CountryRegistration.countryLabel(_countryCode);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Título del plan'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [ThousandsSeparatorInputFormatter()],
          decoration: InputDecoration(
            labelText: 'Monto total ($_currency)',
            hintText: _currency == 'CLP' ? '20.000' : '20.000',
            prefixText: '\$ ',
            helperText: 'Moneda según tu país de cuenta: $countryLabel',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _description,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        VakupliSplitSelector(
          selected: _split,
          onChanged: (value) => setState(() => _split = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        CiervoButton(
          label: _submitting ? 'Creando...' : 'Crear plan',
          icon: Icons.add,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

class VakupliPlanDetailPage extends StatefulWidget {
  const VakupliPlanDetailPage({
    required this.plan,
    required this.repository,
    super.key,
  });

  final VakupliPlan plan;
  final VakupliRepository repository;

  @override
  State<VakupliPlanDetailPage> createState() => _VakupliPlanDetailPageState();
}

class _VakupliPlanDetailPageState extends State<VakupliPlanDetailPage> {
  List<VakupliMessage> _messages = const [];
  List<VakupliFriend> _friends = const [];
  List<ChatButton> _chatButtons = const [];
  late VakupliPlan _plan;
  final _message = TextEditingController();
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _messages = widget.plan.messages;
    _friends = widget.plan.friends;
    _loadMessages();
    _loadParticipants();
    _loadButtons();
  }

  Future<void> _loadButtons() async {
    final chatId = _plan.chatId;
    if (chatId == null) return;
    final result = await getIt<ChatRepository>().buttons();
    if (!mounted) return;
    result.when(
      success: (buttons) => setState(() => _chatButtons = buttons),
      failure: (_) {},
    );
  }

  Future<void> _loadParticipants() async {
    final groupId = _plan.id;
    if (groupId == null) return;
    final result = await widget.repository.participants(groupId);
    if (!mounted) return;
    result.when(
      success: (friends) => setState(() {
        _friends = friends;
        final paid = friends.where((f) => f.hasPaid).length;
        final used = friends.length;
        final remaining = ((_plan.maxTotal ?? _plan.maxParticipants) - used)
            .clamp(0, _plan.maxTotal ?? _plan.maxParticipants);
        _plan = _plan.copyWith(
          friends: friends,
          paidContributions: paid,
          totalContributions: used > 0 ? used : _plan.totalContributions,
          participantCount: used,
          usedSlots: used,
          remainingSlots: remaining,
        );
      }),
      failure: (_) {},
    );
  }

  Future<void> _inviteFriend() async {
    final planId = _plan.id;
    if (planId == null) return;
    if (!_plan.hasCapacity) {
      final bought = await _offerExtraSlots(
        reason:
            'Sin cupos. ${_plan.planCapacityHint}. '
            'Puedes comprar packs de +${_plan.extraSlotPackSize} invitados '
            'o mejorar tu membresía.',
      );
      if (!bought || !_plan.hasCapacity) return;
    }
    if (!mounted) return;

    final userId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const VakupliContactsPickerPage(),
      ),
    );
    if (userId == null || !mounted) return;

    final divisor = (_plan.maxTotal ?? _plan.maxParticipants) > 0
        ? (_plan.maxTotal ?? _plan.maxParticipants)
        : (_plan.participantCount > 0 ? _plan.participantCount : 1);
    final perPerson = _plan.totalAmount > 0
        ? (_plan.totalAmount / divisor)
        : 10000.0;

    final result = await widget.repository.inviteToPlan(
      planId: planId,
      userId: userId,
      amount: perPerson,
    );
    if (!mounted) return;
    result.when(
      success: (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitación enviada.')),
        );
        await _loadParticipants();
      },
      failure: (error) async {
        final message = UserErrorMessage.from(error);
        final upper = message.toUpperCase();
        final raw = error.toString().toUpperCase();
        if (upper.contains('CAPACITY_EXCEEDED') ||
            raw.contains('CAPACITY_EXCEEDED') ||
            message.toLowerCase().contains('cupo')) {
          await _offerExtraSlots(reason: message);
          return;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  Future<bool> _offerExtraSlots({required String reason}) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sin cupos'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'buy'),
            child: const Text('Comprar cupos'),
          ),
        ],
      ),
    );
    if (action != 'buy' || !mounted) return false;
    return _buyExtraSlots();
  }

  Future<bool> _buyExtraSlots() async {
    final purchase = await showVakuBuyExtraSlotsSheet(context, plan: _plan);
    if (purchase == null || !mounted) return false;
    setState(() {
      _plan = _plan.copyWith(
        maxGuests: purchase.maxGuests,
        maxTotal: purchase.maxGuests + 1,
        maxParticipants: purchase.maxGuests + 1,
        purchasedExtraGuests: purchase.purchasedExtraGuests,
        remainingSlots: purchase.remainingSlots,
        extraSlotsPeriodEndsAt: purchase.periodEndsAt,
        extraSlotsPeriodActive: true,
        nextPackPriceUsd: _plan.nextPackPriceUsd ?? purchase.priceUsd,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Listo: +${purchase.guestsAdded} invitados. '
          'Quedan ${purchase.remainingSlots} cupos.',
        ),
      ),
    );
    return true;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final planId = _plan.id;
    if (planId == null) {
      setState(() => _loading = false);
      return;
    }
    final result = await widget.repository.messages(planId);
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _messages = items;
        _loading = false;
      }),
      failure: (_) => setState(() => _loading = false),
    );
  }

  Future<void> _sendMessage() async {
    final planId = _plan.id;
    if (planId == null || _message.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final result = await widget.repository.sendMessage(
      planId: planId,
      text: _message.text.trim(),
    );
    if (!mounted) return;
    result.when(
      success: (msg) {
        _message.clear();
        setState(() {
          _messages = [..._messages, msg];
          _sending = false;
        });
      },
      failure: (_) => setState(() => _sending = false),
    );
  }

  Future<void> _paySplit() async {
    final planId = _plan.id;
    if (planId == null) return;

    final dueResult = await widget.repository.pendingContributionDue(planId);
    if (!mounted) return;
    final due = dueResult.when(
      success: (value) => value,
      failure: (_) => (
        amount: _pendingAmountFallback(),
        currency: 'COP',
      ),
    );

    final cards = await loadWalletCards();
    if (!mounted) return;
    final available = cards.fold<double>(
      0,
      (sum, card) => sum + card.availableBalance,
    );

    int? walletCardId;
    final hasPayableCard = cards.any((card) => card.canSpend(due.amount));
    if (!hasPayableCard || available < due.amount) {
      final resolution = await showVakuInsufficientFundsSheet(
        context,
        amountDue: due.amount,
        availableBalance: available,
        currency: due.currency,
        cards: cards,
      );
      if (!mounted || resolution == null) return;
      if (resolution.action == VakuFundsAction.pickCard &&
          resolution.card != null) {
        walletCardId = int.tryParse(resolution.card!.id);
      } else {
        await openVakuFundsAction(context, resolution, cards: cards);
        return;
      }
    } else {
      final primary =
          cards.where((c) => c.isPrimary && c.canSpend(due.amount)).firstOrNull ??
          cards.where((c) => c.canSpend(due.amount)).firstOrNull;
      walletCardId = int.tryParse(primary?.id ?? '');
    }

    final result = await widget.repository.paySplit(
      planId: planId,
      amount: due.amount,
      walletCardId: walletCardId,
    );
    if (!mounted) return;
    result.when(
      success: (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pago de ${DisplayFormatters.formatMoney(due.amount, currency: due.currency)} registrado.',
            ),
          ),
        );
        await _loadParticipants();
      },
      failure: (error) async {
        final message = UserErrorMessage.from(error);
        final raw = error.toString().toUpperCase();
        if (raw.contains('INSUFFICIENT') ||
            message.toLowerCase().contains('saldo')) {
          final resolution = await showVakuInsufficientFundsSheet(
            context,
            amountDue: due.amount,
            availableBalance: available,
            currency: due.currency,
            cards: cards,
          );
          if (!mounted || resolution == null) return;
          if (resolution.action == VakuFundsAction.pickCard &&
              resolution.card != null) {
            final retry = await widget.repository.paySplit(
              planId: planId,
              amount: due.amount,
              walletCardId: int.tryParse(resolution.card!.id),
            );
            if (!mounted) return;
            retry.when(
              success: (_) async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pago del plan registrado.')),
                );
                await _loadParticipants();
              },
              failure: (retryError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(UserErrorMessage.from(retryError)),
                  ),
                );
              },
            );
            return;
          }
          await openVakuFundsAction(context, resolution, cards: cards);
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  double _pendingAmountFallback() {
    final unpaid = _friends.where((f) => !f.hasPaid && f.amount != null);
    if (unpaid.isNotEmpty) return unpaid.first.amount!;
    final max = _plan.maxTotal ?? _plan.maxParticipants;
    if (_plan.totalAmount > 0 && max > 0) {
      return _plan.totalAmount / max;
    }
    return _plan.totalAmount;
  }

  Future<void> _onGroupAction(String action) async {
    final groupId = _plan.id;
    if (groupId == null) return;
    switch (action) {
      case 'edit':
        await _editGroup();
      case 'cancel':
        await _confirmGroupAction(
          title: 'Cancelar plan',
          body: 'El plan quedará cancelado. ¿Continuar?',
          confirmLabel: 'Cancelar plan',
          run: () => widget.repository.cancelGroup(groupId),
        );
      case 'leave':
        await _confirmGroupAction(
          title: 'Salir del grupo',
          body: 'Dejarás de ser miembro de este plan.',
          confirmLabel: 'Salir',
          run: () => widget.repository.leaveGroup(groupId),
          popOnSuccess: true,
        );
      case 'delete':
        await _confirmGroupAction(
          title: 'Eliminar plan',
          body:
              'Solo el creador puede eliminar. Esta acción no se puede deshacer.',
          confirmLabel: 'Eliminar',
          run: () => widget.repository.deleteGroup(groupId),
          popOnSuccess: true,
        );
    }
  }

  Future<void> _editGroup() async {
    final groupId = _plan.id;
    if (groupId == null) return;
    final controller = TextEditingController(text: _plan.title);
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar plan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
              rootNavigator: true,
            ).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    final result = await widget.repository.updateGroup(
      groupId: groupId,
      name: name,
    );
    if (!mounted) return;
    result.when(
      success: (plan) {
        setState(
          () => _plan = plan.copyWith(friends: _friends, messages: _messages),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan actualizado.')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  Future<void> _confirmGroupAction({
    required String title,
    required String body,
    required String confirmLabel,
    required Future<Result<void>> Function() run,
    bool popOnSuccess = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await run();
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$confirmLabel listo.')));
        if (popOnSuccess) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _plan = _plan.copyWith(statusLabel: 'Cancelado');
          });
        }
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomplete = !_plan.statusLabel.toLowerCase().contains('complet');
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan.title),
        actions: [
          if (_plan.id != null && incomplete)
            PopupMenuButton<String>(
              onSelected: _onGroupAction,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'cancel', child: Text('Cancelar plan')),
                PopupMenuItem(value: 'leave', child: Text('Salir del grupo')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                VakupliPlanCard(plan: _plan),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Cupos del grupo: ${_plan.participantsLabel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                VakupliFriendsGroup(friends: _friends),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _inviteFriend,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: Text(
                          _plan.hasCapacity
                              ? 'Invitar'
                              : 'Sin cupos',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CiervoButton(
                        label: 'Pagar mi parte',
                        icon: Icons.payments_outlined,
                        onPressed: _paySplit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _buyExtraSlots,
                  icon: const Icon(Icons.add_box_outlined),
                  label: Text(
                    _plan.nextPackPriceLabel.isNotEmpty
                        ? 'Más cupos (${_plan.nextPackPriceLabel})'
                        : 'Comprar cupos extra (+${_plan.extraSlotPackSize})',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Chat temporal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_loading)
                  const CiervoLoadingState(itemCount: 2)
                else if (_messages.isEmpty)
                  const Text('Aún no hay mensajes en este plan.')
                else
                  ..._messages.map(
                    (msg) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: VakupliChatBubble(message: msg),
                    ),
                  ),
              ],
            ),
          ),
          if (_plan.chatId != null && _chatButtons.isNotEmpty)
            ChatButtonsBar(
              buttons: _chatButtons,
              conversationId: '${_plan.chatId}',
              enabled: !_sending,
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
