import 'package:flutter/material.dart';

import '../../../family_payments/domain/entities/family_payment_card.dart';
import '../../../family_payments/presentation/pages/add_family_card_page.dart';
import '../../../family_payments/presentation/pages/family_payment_methods_page.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/repositories/kids_repository.dart';
import '../utils/child_wallet_card_view.dart';

/// Configuración de medios de pago del menor según contrato §6.6 y §10.
class ChildPaymentMethodsPage extends StatefulWidget {
  const ChildPaymentMethodsPage({
    required this.childId,
    required this.childName,
    super.key,
  });

  final String childId;
  final String childName;

  @override
  State<ChildPaymentMethodsPage> createState() =>
      _ChildPaymentMethodsPageState();
}

class _ChildPaymentMethodsPageState extends State<ChildPaymentMethodsPage> {
  final _kidsRepository = getIt<KidsRepository>();

  Map<String, dynamic>? _status;
  List<ChildWalletCardView> _virtualCards = const [];
  List<FamilyPaymentCard> _backupCards = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _selectedCardId;
  bool _usePrimary = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final methods = await _kidsRepository.childPaymentMethods(widget.childId);
    final cards = await _kidsRepository.childWalletCards(widget.childId);

    if (!mounted) return;
    String? error;
    Map<String, dynamic>? status;
    methods.when(
      success: (data) => status = data,
      failure: (e) => error = UserErrorMessage.from(e),
    );

    var virtual = <ChildWalletCardView>[];
    cards.when(
      success: (items) => virtual = ChildWalletCardView.listFrom(items),
      failure: (e) => error ??= UserErrorMessage.from(e),
    );

    final backupRaw = status?['parentBackupCards'] ??
        status?['backupCards'] ??
        status?['familyCards'];
    final backup = _parseFamilyCards(backupRaw);

    final linkedId = status?['linkedCardId'] ??
        status?['paymentSourceCardId'] ??
        status?['cardId'];
    final usePrimary = status?['usePrimaryCard'] != false;

    setState(() {
      _status = status;
      _virtualCards = virtual;
      _backupCards = backup;
      _selectedCardId = linkedId?.toString();
      _usePrimary = usePrimary;
      _loading = false;
      _error = error;
    });
  }

  List<FamilyPaymentCard> _parseFamilyCards(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          return FamilyPaymentCard(
            id: '${map['id'] ?? map['cardId'] ?? ''}',
            brand: '${map['brand'] ?? ''}',
            lastFour: '${map['lastFour'] ?? map['last4'] ?? ''}',
            status: '${map['status'] ?? 'active'}',
            isPrimary: map['isPrimary'] == true,
            isBackup: map['isBackup'] == true,
            expirationMonth: '${map['expirationMonth'] ?? ''}',
            expirationYear: '${map['expirationYear'] ?? ''}',
            alias: '${map['alias'] ?? map['displayName'] ?? ''}',
            isFrozen: map['isFrozen'] == true,
          );
        })
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  String? get _hint {
    final hint = _status?['hint'] ??
        _status?['setupHint'] ??
        _status?['message'];
    return hint?.toString();
  }

  Future<void> _saveSource() async {
    setState(() => _saving = true);
    final result = await _kidsRepository.saveChildPaymentSource(
      childId: widget.childId,
      cardId: _usePrimary ? null : _selectedCardId,
      usePrimaryCard: _usePrimary,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarjeta del tutor vinculada.')),
        );
        _load();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _openAddFamilyCard() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddFamilyCardPage()),
    );
    if (added == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primary : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Medios de pago Kids')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 4),
            )
          : _error != null && _status == null
              ? Padding(
                  padding: pagePaddingOf(context),
                  child: CiervoErrorState(
                    title: 'No pudimos cargar la configuración',
                    description: _error!,
                    onRetry: _load,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: pagePaddingOf(context),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidthOf(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CiervoCard(
                                showGradientOverlay: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pagos de ${widget.childName}',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Las tarjetas Kids son virtuales (saldo prepago). '
                                      'Visa/Mastercard del tutor se tokenizan por separado '
                                      'y se usan como respaldo.',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              if (_hint != null && _hint!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withValues(alpha: isDark ? 0.2 : 0.45),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline, color: accent),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          _hint!,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Tarjetas Kids (virtuales)',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (_virtualCards.isEmpty)
                                const CiervoCard(
                                  child: Text(
                                    'Aún no hay tarjetas virtuales. Créalas desde la wallet del menor.',
                                  ),
                                )
                              else
                                ..._virtualCards.map(
                                  (card) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: CiervoCard(
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: accent.withValues(
                                            alpha: isDark ? 0.2 : 0.12,
                                          ),
                                          child: Icon(
                                            Icons.credit_card,
                                            color: accent,
                                          ),
                                        ),
                                        title: Text(card.displayName),
                                        subtitle: Text(
                                          'Saldo: ${card.currency} ${card.balance.toStringAsFixed(0)}',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Respaldo del tutor (Visa/Mastercard)',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (_backupCards.isEmpty) ...[
                                CiervoCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Agrega una tarjeta del tutor para pagos cuando no haya saldo Kids.',
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      CiervoButton(
                                        label: 'Tokenizar tarjeta del tutor',
                                        icon: Icons.add_card_outlined,
                                        onPressed: _openAddFamilyCard,
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Usar tarjeta principal'),
                                  value: _usePrimary,
                                  onChanged: (value) =>
                                      setState(() => _usePrimary = value),
                                ),
                                if (!_usePrimary)
                                  CiervoCard(
                                    child: Column(
                                      children: _backupCards
                                          .map(
                                            (card) => RadioListTile<String>(
                                              value: card.id,
                                              groupValue: _selectedCardId,
                                              onChanged: (value) => setState(
                                                () => _selectedCardId = value,
                                              ),
                                              title: Text(
                                                card.alias.isNotEmpty
                                                    ? card.alias
                                                    : card.maskedNumber,
                                              ),
                                              subtitle: Text(
                                                '${card.brand} · ${card.maskedNumber}',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.sm),
                                CiervoButton(
                                  label: _saving
                                      ? 'Guardando...'
                                      : 'Vincular al menor',
                                  icon: Icons.link,
                                  state: _saving
                                      ? CiervoButtonState.loading
                                      : CiervoButtonState.normal,
                                  onPressed: _saving ? null : _saveSource,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const FamilyPaymentMethodsPage(),
                                    ),
                                  ),
                                  icon: const Icon(Icons.settings_outlined),
                                  label: const Text('Gestionar tarjetas del tutor'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
