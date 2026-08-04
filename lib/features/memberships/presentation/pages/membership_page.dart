import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../core/widgets/vaku_extra_slots_upgrade_ack_dialog.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../payments/domain/repositories/payments_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../cubit/membership_cubit.dart';
import '../../data/memberships_repository.dart';
import '../../domain/entities/membership_plan.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<_MembershipData> _data;
  String? _subscribingPlanId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    final repo = getIt<MembershipsRepository>();
    _data = () async {
      final profileResult = await getIt<ProfileRepository>().getMe();
      final countryCode = profileResult.when(
        success: (profile) =>
            (profile.countryCode ?? '').trim().isNotEmpty
            ? profile.countryCode!.trim().toUpperCase()
            : CountryRegistration.defaultCountryCode(),
        failure: (_) => CountryRegistration.defaultCountryCode(),
      );
      final plansResult = await repo.clientPlans(countryCode: countryCode);
      final meResult = await repo.myMembership();
      final benefitsResult = await repo.benefits();
      final invoicesResult = await repo.invoices();
      return _MembershipData(
        plans: plansResult.when(success: (v) => v, failure: (e) => throw e),
        membership: meResult.when(success: (v) => v, failure: (_) => const {}),
        benefits: benefitsResult.when(
          success: (v) => v,
          failure: (_) => const {},
        ),
        invoices: invoicesResult.when(
          success: (v) => v,
          failure: (_) => const [],
        ),
      );
    }();
  }

  String? _currentPlanCode(_MembershipData data) {
    final code = data.membership['planCode'] ?? data.membership['code'];
    if (code != null && '$code'.isNotEmpty) return '$code'.toLowerCase();
    final current = data.plans.where((plan) => plan.isCurrent).firstOrNull;
    return current?.code.toLowerCase();
  }

  bool _isCurrentPlan(MembershipPlan plan, _MembershipData data) {
    final currentCode = _currentPlanCode(data);
    if (currentCode != null &&
        plan.code.toLowerCase() == currentCode.toLowerCase()) {
      return true;
    }
    final currentId = '${data.membership['planId'] ?? data.membership['id']}';
    return currentId.isNotEmpty && currentId == plan.id;
  }

  Future<void> _subscribe(MembershipPlan plan) async {
    if (_subscribingPlanId != null) return;
    if (plan.requiresCustomQuote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este plan requiere cotizacion comercial.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar suscripcion'),
        content: Text(
          plan.isFree
              ? 'Activar plan ${plan.name}?'
              : 'Suscribirte a ${plan.name} por ${plan.displayPrice}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final canContinueUpgrade =
        await acknowledgeVakuExtraSlotsBeforeUpgrade(context);
    if (!canContinueUpgrade || !mounted) return;

    setState(() => _subscribingPlanId = plan.id);
    final membershipsRepo = getIt<MembershipsRepository>();
    final paymentsRepo = getIt<PaymentsRepository>();

    if (plan.isFree) {
      final result = await membershipsRepo.subscribeFree(planId: plan.id);
      if (!mounted) return;
      setState(() => _subscribingPlanId = null);
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Plan ${plan.name} activado.')),
          );
          context.read<MembershipCubit>().load();
          setState(_load);
        },
        failure: (error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
        },
      );
      return;
    }

    if (!plan.supportsCheckout) {
      setState(() => _subscribingPlanId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este plan no admite checkout automatico.'),
        ),
      );
      return;
    }

    final key =
        'membership-${plan.id}-${DateTime.now().microsecondsSinceEpoch}';
    final intentResult = await paymentsRepo.createMembershipSubscribeIntent(
      membershipPlanId: plan.id,
      idempotencyKey: key,
    );
    if (!mounted) return;

    await intentResult.when(
      success: (intent) async {
        if (intent.checkoutUrl.isNotEmpty) {
          await launchUrl(
            Uri.parse(intent.checkoutUrl),
            mode: LaunchMode.externalApplication,
          );
        }
        final poll = await paymentsRepo.pollIntent(intent.id);
        if (!mounted) return;
        setState(() => _subscribingPlanId = null);
        poll.when(
          success: (finalIntent) {
            if (finalIntent.isApproved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Plan ${plan.name} activado.')),
              );
              context.read<MembershipCubit>().load();
              setState(_load);
            } else if (finalIntent.isRejected) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pago rechazado. Intenta nuevamente.'),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pago ${finalIntent.statusLabel.toLowerCase()}. Consulta tu historial.',
                  ),
                ),
              );
            }
          },
          failure: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(UserErrorMessage.from(error))),
            );
          },
        );
      },
      failure: (error) {
        setState(() => _subscribingPlanId = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  Future<void> _cancelMembership() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar plan'),
        content: const Text(
          'Se cancelará tu plan de pago y pasarás al plan Free. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar plan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await getIt<MembershipsRepository>().cancel();
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan cancelado. Ahora estás en Free.')),
        );
        context.read<MembershipCubit>().load();
        setState(_load);
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Membresia'),
      bottom: TabBar(
        controller: _tabController,
        isScrollable: false,
        tabs: const [
          Tab(text: 'Mi plan'),
          Tab(text: 'Planes'),
          Tab(text: 'Beneficios'),
          Tab(text: 'Facturas'),
        ],
      ),
    ),
    body: FutureBuilder<_MembershipData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CiervoLoadingState(itemCount: 4);
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CiervoErrorState(
              title: 'No pudimos cargar membresias',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: () => setState(_load),
            ),
          );
        }
        final payload = snapshot.data!;
        final plans = payload.plans;
        if (plans.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CiervoEmptyState(
              title: 'Sin planes disponibles',
              description:
                  'Por ahora no hay planes de membresía disponibles en tu país.',
              icon: Icons.workspace_premium_outlined,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: TabBarView(
            controller: _tabController,
            children: [
              _MyMembership(
                plans: plans,
                membership: payload.membership,
                isCurrentPlan: (plan) => _isCurrentPlan(plan, payload),
                renewing: _subscribingPlanId != null,
                onRenew: () {
                  final current =
                      plans
                          .where((p) => _isCurrentPlan(p, payload))
                          .firstOrNull ??
                      plans.first;
                  return _subscribe(current);
                },
                onCancel: _cancelMembership,
              ),
              _PlansList(
                plans: plans,
                isCurrentPlan: (plan) => _isCurrentPlan(plan, payload),
                subscribingPlanId: _subscribingPlanId,
                onSubscribe: _subscribe,
              ),
              _BenefitsView(benefits: payload.benefits),
              _InvoicesView(invoices: payload.invoices),
            ],
          ),
        );
      },
    ),
  );
}

class _MembershipData {
  const _MembershipData({
    required this.plans,
    required this.membership,
    required this.benefits,
    required this.invoices,
  });
  final List<MembershipPlan> plans;
  final Map<String, dynamic> membership;
  final Map<String, dynamic> benefits;
  final List<Map<String, dynamic>> invoices;
}

class _MyMembership extends StatelessWidget {
  const _MyMembership({
    required this.plans,
    required this.membership,
    required this.isCurrentPlan,
    required this.onRenew,
    required this.onCancel,
    this.renewing = false,
  });

  final List<MembershipPlan> plans;
  final Map<String, dynamic> membership;
  final bool Function(MembershipPlan plan) isCurrentPlan;
  final Future<void> Function() onRenew;
  final Future<void> Function() onCancel;
  final bool renewing;

  @override
  Widget build(BuildContext context) {
    final current =
        plans.where(isCurrentPlan).firstOrNull ??
        plans.where((plan) => plan.code.toLowerCase() == 'free').firstOrNull ??
        plans.first;
    final next = plans
        .where((plan) => plan.sortOrder > current.sortOrder)
        .firstOrNull;
    final endsAt = DateTime.tryParse('${membership['endsAt'] ?? ''}');
    final remainingDays = membership['remainingDays'];
    final needsRenewal = membership['needsRenewal'] == true;
    final canCancel = membership['canCancel'] == true;
    final canRenew = membership['canRenew'] == true;
    final billingPeriod =
        '${membership['billingPeriod'] ?? ''}'.trim().isNotEmpty
        ? '${membership['billingPeriod']}'
        : (membership['billingPeriodMonths'] != null
              ? 'Bimensual (${membership['billingPeriodMonths']} meses)'
              : '');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _PlanCard(plan: current, highlighted: true),
        const SizedBox(height: AppSpacing.md),
        if (needsRenewal || membership['isInGrace'] == true) ...[
          CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membership['isInGrace'] == true
                      ? 'En mora — renueva tu plan'
                      : 'Renovación pendiente',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  membership['isInGrace'] == true
                      ? _graceMessage(membership, endsAt)
                      : endsAt != null
                      ? 'Tu plan vence el ${_date(endsAt)}'
                            '${remainingDays != null ? ' (en $remainingDays días)' : ''}. '
                            '¿Renovar o cancelar?'
                      : 'Tu plan necesita renovación. ¿Renovar o cancelar?',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estado', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              _line('Plan actual', current.name),
              _line(
                'Estado',
                DisplayLabels.membershipStatus(
                  '${membership['status'] ?? current.status ?? 'Activo'}',
                ),
              ),
              _line('Vence', _date(endsAt ?? current.expiresAt)),
              if (remainingDays != null)
                _line(
                  (_asInt(remainingDays) != null &&
                              _asInt(remainingDays)! < 0) ||
                          membership['isInGrace'] == true
                      ? 'Días (mora)'
                      : 'Te quedan',
                  () {
                    final n = _asInt(remainingDays);
                    if (n == null) return '$remainingDays';
                    final abs = n.abs();
                    return '$abs día${abs == 1 ? '' : 's'}';
                  }(),
                ),
              if (membership['isInGrace'] == true) ...[
                _line(
                  'Mora',
                  membership['graceDaysRemaining'] != null
                      ? '${membership['graceDaysRemaining']} día(s) para renovar'
                      : 'Activa (${membership['graceDays'] ?? 10} días)',
                ),
                if (membership['graceEndsAt'] != null)
                  _line(
                    'Fin de mora',
                    _date(DateTime.tryParse('${membership['graceEndsAt']}')),
                  ),
              ],
              if (billingPeriod.isNotEmpty)
                _line('Periodo', billingPeriod),
              _line(
                'Multiplicador cashback',
                '${current.cashbackMultiplier.toStringAsFixed(2)}x',
              ),
              _line('Proximo nivel', next?.name ?? 'Nivel maximo'),
              if (canRenew || canCancel) ...[
                const SizedBox(height: AppSpacing.md),
                if (canRenew)
                  CiervoButton(
                    label: renewing ? 'Procesando...' : 'Renovar plan',
                    icon: Icons.autorenew,
                    state: renewing
                        ? CiervoButtonState.loading
                        : CiervoButtonState.normal,
                    onPressed: renewing ? null : () => onRenew(),
                  ),
                if (canCancel) ...[
                  if (canRenew) const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: renewing ? null : () => onCancel(),
                    child: const Text('Cancelar plan'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _graceMessage(Map<String, dynamic> membership, DateTime? endsAt) {
    final left = membership['graceDaysRemaining'];
    final graceEnd = DateTime.tryParse('${membership['graceEndsAt'] ?? ''}');
    final parts = <String>[
      if (endsAt != null) 'Venció el ${_date(endsAt)}.',
      if (left != null) 'Te quedan $left día(s) de mora con beneficios.',
      if (graceEnd != null) 'Renueva antes del ${_date(graceEnd)}.',
      'Si no pagas, el plan pasa a Free automáticamente.',
    ];
    return parts.join(' ');
  }
}

class _PlansList extends StatelessWidget {
  const _PlansList({
    required this.plans,
    required this.isCurrentPlan,
    required this.subscribingPlanId,
    required this.onSubscribe,
  });

  final List<MembershipPlan> plans;
  final bool Function(MembershipPlan plan) isCurrentPlan;
  final String? subscribingPlanId;
  final Future<void> Function(MembershipPlan plan) onSubscribe;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(AppSpacing.lg),
    itemCount: plans.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
    itemBuilder: (context, index) {
      final plan = plans[index];
      final current = isCurrentPlan(plan);
      return _PlanCard(
        plan: plan,
        highlighted: current,
        actionLabel: current
            ? 'Plan actual'
            : plan.requiresCustomQuote
            ? 'Cotizacion requerida'
            : subscribingPlanId == plan.id
            ? 'Procesando...'
            : plan.isFree
            ? 'Activar gratis'
            : 'Pagar con Mercado Pago',
        actionLoading: subscribingPlanId == plan.id,
        onAction: current || plan.requiresCustomQuote
            ? null
            : () => onSubscribe(plan),
      );
    },
  );
}

class _BenefitsView extends StatelessWidget {
  const _BenefitsView({required this.benefits});

  final Map<String, dynamic> benefits;

  @override
  Widget build(BuildContext context) {
    final limits = benefits['limits'] is Map
        ? Map<String, dynamic>.from(benefits['limits'] as Map)
        : const <String, dynamic>{};
    final items = benefits['benefits'] is List
        ? benefits['benefits'] as List
        : benefits['features'] is List
        ? benefits['features'] as List
        : const [];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Beneficios de tu plan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (items.isEmpty && limits.isEmpty)
                const Text('No hay beneficios configurados para tu plan.')
              else ...[
                if (items.isNotEmpty) ...[
                  Text(
                    'Incluidos',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ...items.map((item) => Text('- $item')),
                ],
                if (limits.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Límites',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ...limits.entries.map(
                    (e) => Text(
                      '${DisplayLabels.membershipLimitLabel(e.key)}: '
                      '${DisplayLabels.membershipLimitDisplay(e.key, e.value)}',
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InvoicesView extends StatelessWidget {
  const _InvoicesView({required this.invoices});

  final List<Map<String, dynamic>> invoices;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: CiervoEmptyState(
          title: 'Sin facturas',
          description: 'Aun no tienes facturas de membresia.',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: invoices.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return CiervoCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${invoice['planName'] ?? invoice['description'] ?? 'Factura membresia'}',
            ),
            subtitle: Text(
              '${invoice['createdAt'] ?? invoice['issuedAt'] ?? ''}',
            ),
            trailing: Text(
              DisplayFormatters.formatMoney(
                num.tryParse('${invoice['amount'] ?? invoice['total'] ?? 0}') ??
                    0,
                currency: '${invoice['currency'] ?? 'COP'}',
              ),
            ),
          ),
        );
      },
    );
  }

  String _amount(dynamic value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return parsed?.toStringAsFixed(0) ?? '0';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    this.highlighted = false,
    this.actionLabel,
    this.actionLoading = false,
    this.onAction,
  });

  final MembershipPlan plan;
  final bool highlighted;
  final String? actionLabel;
  final bool actionLoading;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => CiervoCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                plan.name.isEmpty ? plan.code : plan.name,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        if (highlighted || plan.isCurrent || plan.isRecommended) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              if (highlighted || plan.isCurrent)
                const Chip(label: Text('Actual'), visualDensity: VisualDensity.compact),
              if (plan.isRecommended)
                Chip(
                  label: const Text('Recomendado'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(plan.displayPrice),
        if (plan.displayUsdReference.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            plan.displayUsdReference,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (plan.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(plan.description),
        ],
        if (plan.paymentProvider != null &&
            plan.paymentProvider!.isNotEmpty &&
            plan.paymentProvider!.toLowerCase() != 'mercadopago') ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Proveedor: ${plan.paymentProvider}'),
        ],
        const SizedBox(height: AppSpacing.sm),
        _line(
          'Cashback',
          plan.limits['cashbackPercent'] != null
              ? '${plan.limits['cashbackPercent']}%'
              : '${plan.cashbackMultiplier.toStringAsFixed(2)}x',
        ),
        if (plan.benefits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Beneficios', style: Theme.of(context).textTheme.titleSmall),
          ...plan.benefits.map((item) => Text('- $item')),
        ],
        if (plan.limits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Límites', style: Theme.of(context).textTheme.titleSmall),
          ...plan.limits.entries.map(
            (entry) => Text(
              '${DisplayLabels.membershipLimitLabel(entry.key)}: '
              '${DisplayLabels.membershipLimitDisplay(entry.key, entry.value)}',
            ),
          ),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: AppSpacing.md),
          CiervoButton(
            label: actionLabel!,
            icon: Icons.workspace_premium_outlined,
            state: actionLoading
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            variant: highlighted
                ? CiervoButtonVariant.secondary
                : CiervoButtonVariant.primary,
            onPressed: actionLoading ? null : onAction,
          ),
        ],
      ],
    ),
  );
}

Widget _line(String label, String value) => Padding(
  padding: const EdgeInsets.only(top: AppSpacing.xxs),
  child: Text('$label: $value'),
);

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

String _date(DateTime? value) => value == null
    ? 'Sin vencimiento'
    : value.toLocal().toString().substring(0, 10);
