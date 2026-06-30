import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../users/presentation/pages/user_search_page.dart';
import '../../data/vakupli_repository.dart';
import '../../domain/entities/vakupli_plan.dart';
import '../widgets/vakupli_chat_bubble.dart';
import '../widgets/vakupli_friends_group.dart';
import '../widgets/vakupli_plan_card.dart';
import '../widgets/vakupli_split_selector.dart';

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
        title: const Text('Vakupli'),
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
        builder: (_) => VakupliPlanDetailPage(plan: plan, repository: _repository),
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
                    title: 'Vakupli próximamente',
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
                  description: 'Crea un plan y comparte el link con tus amigos.',
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

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
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
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan creado.')),
        );
        widget.onCreated();
      },
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _submitting = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Monto total (COP)',
            prefixText: '\$ ',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _description,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
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
  final _message = TextEditingController();
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = widget.plan.messages;
    _loadMessages();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final planId = widget.plan.id;
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
    final planId = widget.plan.id;
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

  Future<void> _inviteFriend() async {
    final planId = widget.plan.id;
    if (planId == null) return;
    final userId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const UserSearchPage(selectMode: true)),
    );
    if (userId == null || !mounted) return;
    final result = await widget.repository.inviteToPlan(
      planId: planId,
      userId: userId,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitación enviada.')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  Future<void> _paySplit() async {
    final planId = widget.plan.id;
    if (planId == null) return;
    final result = await widget.repository.paySplit(
      planId: planId,
      amount: widget.plan.totalAmount,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago del plan registrado.')),
        );
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.plan.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                VakupliPlanCard(plan: widget.plan),
                const SizedBox(height: AppSpacing.md),
                VakupliFriendsGroup(friends: widget.plan.friends),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _inviteFriend,
                        icon: const Icon(Icons.link),
                        label: const Text('Invitar'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CiervoButton(
                        label: 'Pagar split',
                        icon: Icons.payments_outlined,
                        onPressed: _paySplit,
                      ),
                    ),
                  ],
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
