import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_id_qr_scanner_page.dart';
import '../../../../shared/widgets/currency_selector.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../users/domain/entities/user_search_result.dart';
import '../../../users/presentation/pages/user_search_page.dart';
import '../../domain/entities/resolved_wallet_user.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../widgets/ciervo_digital_card.dart';
import '../widgets/transfer_directory_actions.dart';
import '../widgets/transfer_directory_list_sheet.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({this.card, this.initialCiervoCode, super.key});
  final WalletCard? card;
  final String? initialCiervoCode;

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeFocus = FocusNode();
  String _currency = CountryRegistration.currencyForCountry(
    CountryRegistration.defaultCountryCode(),
  );
  TransferDirectoryAction? _selectedAction = TransferDirectoryAction.ciervoId;
  String? _recipientLabel;

  @override
  void initState() {
    super.initState();
    if (widget.initialCiervoCode != null) {
      _codeController.text = widget.initialCiervoCode!;
      _selectedAction = TransferDirectoryAction.ciervoId;
    }
    if (widget.card?.currency.isNotEmpty == true) {
      _currency = widget.card!.currency;
    } else {
      _resolveCurrencyFromProfile();
    }
  }

  Future<void> _resolveCurrencyFromProfile() async {
    final result = await getIt<ProfileRepository>().getMe();
    if (!mounted) return;
    result.when(
      success: (profile) {
        final country = (profile.countryCode ?? '').trim();
        if (country.isEmpty) return;
        setState(() {
          _currency = CountryRegistration.currencyForCountry(country);
        });
      },
      failure: (_) {},
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  String get _lookupHint => switch (_selectedAction) {
    TransferDirectoryAction.username => '@usuario',
    TransferDirectoryAction.search => 'CIERVO ID, @usuario o nombre',
    _ => 'CIERVO-########',
  };

  String get _lookupLabel => switch (_selectedAction) {
    TransferDirectoryAction.username => 'Usuario',
    TransferDirectoryAction.search => 'Buscar destinatario',
    _ => 'CIERVO ID del destinatario',
  };

  Future<void> _onDirectoryAction(
    BuildContext context,
    TransferDirectoryAction action,
  ) async {
    setState(() => _selectedAction = action);
    final cubit = context.read<WalletCubit>();

    switch (action) {
      case TransferDirectoryAction.search:
        final picked = await Navigator.of(context).push<UserSearchResult>(
          MaterialPageRoute(
            builder: (_) => const UserSearchPage(pickRecipient: true),
          ),
        );
        if (!mounted || picked == null) return;
        await _applyLookup(
          cubit,
          picked.ciervoUserCode?.trim().isNotEmpty == true
              ? picked.ciervoUserCode!
              : (picked.username?.trim().isNotEmpty == true
                    ? (picked.username!.startsWith('@')
                          ? picked.username!
                          : '@${picked.username!}')
                    : picked.fullName),
          displayName: picked.fullName,
        );
      case TransferDirectoryAction.ciervoId:
        _codeFocus.requestFocus();
      case TransferDirectoryAction.username:
        if (!_codeController.text.trim().startsWith('@') &&
            _codeController.text.trim().isEmpty) {
          _codeController.text = '@';
          _codeController.selection = const TextSelection.collapsed(offset: 1);
        }
        _codeFocus.requestFocus();
      case TransferDirectoryAction.contacts:
        final entry = await showTransferDirectoryListSheet(
          context,
          title: 'Contactos CIERVO',
          loader: () async {
            final result = await getIt<WalletRepository>().transferContacts();
            return result.when(
              success: (items) => items,
              failure: (error) => throw error,
            );
          },
          showFavoriteToggle: true,
        );
        if (!mounted || entry == null) return;
        await _applyLookup(cubit, entry.lookup, displayName: entry.displayName);
      case TransferDirectoryAction.favorites:
        final entry = await showTransferDirectoryListSheet(
          context,
          title: 'Favoritos',
          loader: () async {
            final result = await getIt<WalletRepository>().transferFavorites();
            return result.when(
              success: (items) => items,
              failure: (error) => throw error,
            );
          },
          showFavoriteToggle: true,
        );
        if (!mounted || entry == null) return;
        await _applyLookup(cubit, entry.lookup, displayName: entry.displayName);
      case TransferDirectoryAction.scanQr:
        final code = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const CiervoIdQrScannerPage()),
        );
        if (!mounted || code == null || code.trim().isEmpty) return;
        await _applyLookup(cubit, code.trim());
      case TransferDirectoryAction.recent:
        final entry = await showTransferDirectoryListSheet(
          context,
          title: 'Transferencias recientes',
          loader: () async {
            final result = await getIt<WalletRepository>().transferRecent();
            return result.when(
              success: (items) => items,
              failure: (error) => throw error,
            );
          },
          showFavoriteToggle: true,
        );
        if (!mounted || entry == null) return;
        await _applyLookup(cubit, entry.lookup, displayName: entry.displayName);
    }
  }

  Future<void> _applyLookup(
    WalletCubit cubit,
    String lookup, {
    String? displayName,
  }) async {
    final normalized = lookup.trim();
    if (normalized.isEmpty) return;
    setState(() {
      _codeController.text = normalized;
      _recipientLabel = displayName;
    });
    await cubit.resolveUser(normalized);
  }

  Future<void> _toggleFavorite(ResolvedWalletUser user) async {
    final repo = getIt<WalletRepository>();
    final result = user.isFavorite
        ? await repo.removeTransferFavorite(user.userId)
        : await repo.addTransferFavorite(
            targetUserId: user.userId,
            targetCiervoUserCode: user.ciervoUserCode,
            targetUsername: user.username,
          );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isFavorite
                  ? 'Quitado de favoritos.'
                  : 'Agregado a favoritos.',
            ),
          ),
        );
        context.read<WalletCubit>().resolveUser(
          user.ciervoUserCode.isNotEmpty ? user.ciervoUserCode : user.handle,
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(getIt<WalletRepository>()),
      child: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) {
          final message = state.errorMessage ?? state.successMessage;
          if (message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
          final user = state.resolvedUser;
          if (user != null) {
            setState(() {
              _recipientLabel = user.displayName;
              if (user.ciervoUserCode.isNotEmpty &&
                  _codeController.text.trim().isEmpty) {
                _codeController.text = user.ciervoUserCode;
              }
            });
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Transferir dinero')),
            body: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: pagePaddingOf(context),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxContentWidthOf(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CiervoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '¿A quién le envías?',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Busca por CIERVO ID, @usuario, contactos, favoritos o QR.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TransferDirectoryActions(
                              selected: _selectedAction,
                              onSelected: (action) =>
                                  _onDirectoryAction(context, action),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CiervoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _codeController,
                              focusNode: _codeFocus,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) => context
                                  .read<WalletCubit>()
                                  .resolveUser(value.trim()),
                              decoration: InputDecoration(
                                labelText: _lookupLabel,
                                hintText: _lookupHint,
                                prefixIcon: Icon(
                                  _selectedAction ==
                                          TransferDirectoryAction.username
                                      ? Icons.alternate_email
                                      : Icons.badge_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            CiervoButton(
                              label: state.isLoading
                                  ? 'Buscando'
                                  : 'Resolver destinatario',
                              icon: Icons.person_search_outlined,
                              variant: CiervoButtonVariant.secondary,
                              state: state.isLoading
                                  ? CiervoButtonState.loading
                                  : CiervoButtonState.normal,
                              onPressed: state.isLoading
                                  ? null
                                  : () =>
                                        context.read<WalletCubit>().resolveUser(
                                          _codeController.text.trim(),
                                        ),
                            ),
                            if (state.resolvedUser != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              _RecipientPreview(
                                user: state.resolvedUser!,
                                fallbackLabel: _recipientLabel,
                                onToggleFavorite: () =>
                                    _toggleFavorite(state.resolvedUser!),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Monto',
                                hintText: '0',
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            CurrencySelector(
                              value: _currency,
                              onChanged: (value) =>
                                  setState(() => _currency = value),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _descriptionController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Mensaje (opcional)',
                                hintText: 'Para el almuerzo',
                                prefixIcon: Icon(Icons.notes_outlined),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            CiervoButton(
                              label: state.isLoading
                                  ? 'Procesando'
                                  : 'Confirmar transferencia',
                              icon: Icons.send_outlined,
                              state: state.isLoading
                                  ? CiervoButtonState.loading
                                  : CiervoButtonState.normal,
                              onPressed: state.isLoading
                                  ? null
                                  : () => _confirmTransfer(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmTransfer(BuildContext context) async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final target = _codeController.text.trim();
    if (target.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa destinatario y un monto válido.'),
        ),
      );
      return;
    }
    final card = widget.card;
    if (card != null && !card.canSpend(amount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo disponible insuficiente (${DisplayFormatters.formatMoney(card.availableBalance, currency: card.currency.isNotEmpty ? card.currency : _currency)}).',
          ),
        ),
      );
      return;
    }
    final resolved = context.read<WalletCubit>().state.resolvedUser;
    final destinationLabel = resolved?.displayName ?? _recipientLabel ?? target;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar transferencia'),
        content: Text(
          'Enviar ${DisplayFormatters.formatMoney(amount, currency: _currency)} a $destinationLabel',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final resolvedCode = resolved?.ciervoUserCode.trim();
    await context.read<WalletCubit>().transfer(
      targetCiervoUserCode: (resolvedCode != null && resolvedCode.isNotEmpty)
          ? resolvedCode
          : target,
      amount: amount,
      description: _descriptionController.text.trim(),
      walletCardId: widget.card?.id,
      currency: _currency,
    );
  }
}

class _RecipientPreview extends StatelessWidget {
  const _RecipientPreview({
    required this.user,
    required this.onToggleFavorite,
    this.fallbackLabel,
  });

  final ResolvedWalletUser user;
  final VoidCallback onToggleFavorite;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = user.displayName.isNotEmpty
        ? user.displayName
        : (fallbackLabel ?? 'Destinatario');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CiervoBrandColors.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: CiervoBrandColors.gold.withValues(alpha: 0.18),
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: CiervoBrandColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: CiervoBrandColors.gold,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    user.handle,
                    if (user.ciervoUserCode.isNotEmpty &&
                        user.handle != user.ciervoUserCode)
                      user.ciervoUserCode,
                    if (user.countryCode != null) user.countryCode!,
                    if (user.localCurrency != null) user.localCurrency!,
                  ].where((s) => s.trim().isNotEmpty).join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: user.isFavorite
                ? 'Quitar de favoritos'
                : 'Agregar a favoritos',
            onPressed: onToggleFavorite,
            icon: Icon(
              user.isFavorite ? Icons.star : Icons.star_outline,
              color: CiervoBrandColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
