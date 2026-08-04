import 'package:flutter/material.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/nfc/nfc_tag_reader.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/nfc_models.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../utils/nfc_navigation.dart';

class NfcPhysicalCardsPage extends StatefulWidget {
  const NfcPhysicalCardsPage({this.walletCard, super.key});

  final WalletCard? walletCard;

  @override
  State<NfcPhysicalCardsPage> createState() => _NfcPhysicalCardsPageState();
}

class _NfcPhysicalCardsPageState extends State<NfcPhysicalCardsPage> {
  List<PhysicalNfcCard> _cards = const [];
  bool _loading = true;
  bool _nfcAvailable = false;
  bool _scanning = false;
  String? _error;
  String _countryCode = CountryRegistration.defaultCountryCode();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _nfcAvailable = await NfcTagReader.isAvailable();
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await getIt<WalletRepository>().physicalNfcCards();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _cards = items;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _register({String? presetUid}) async {
    final card = widget.walletCard;
    if (card == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una tarjeta wallet primero.')),
      );
      return;
    }

    final uidController = TextEditingController(text: presetUid ?? '');
    final labelController = TextEditingController(text: 'Mi tarjeta CIERVO');
    var country = _countryCode;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar tarjeta física'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: uidController,
                  readOnly: presetUid != null && presetUid.isNotEmpty,
                  decoration: InputDecoration(
                    labelText: 'UID de la tarjeta',
                    hintText: '04A1B2C3D4',
                    helperText: presetUid != null && presetUid.isNotEmpty
                        ? 'UID leído por NFC. No se podrá editar después.'
                        : 'Puedes registrar varias tarjetas; cada UID debe ser único.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: 'Etiqueta'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: country,
                  decoration: const InputDecoration(
                    labelText: 'País de registro',
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CO', child: Text('Colombia')),
                    DropdownMenuItem(value: 'CL', child: Text('Chile')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => country = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;

    final uid = uidController.text.trim().toUpperCase();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa o escanea un UID válido.')),
      );
      return;
    }

    final result = await getIt<WalletRepository>().registerPhysicalNfcCard(
      cardId: card.id,
      cardUid: uid,
      label: labelController.text.trim(),
      countryCode: country,
    );
    if (!mounted) return;
    await result.when(
      success: (_) {
        setState(() => _countryCode = country);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarjeta física registrada.')),
        );
        _load();
      },
      failure: (error) => handleNfcError(context, error),
    );
  }

  Future<void> _scanAndRegister() async {
    if (!_nfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa NFC en tu dispositivo para escanear.'),
        ),
      );
      return;
    }
    setState(() => _scanning = true);
    final uid = await NfcTagReader.readUid();
    if (!mounted) return;
    setState(() => _scanning = false);
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos leer el UID. Intenta de nuevo.'),
        ),
      );
      return;
    }
    await _register(presetUid: uid);
  }

  Future<void> _editLabel(PhysicalNfcCard card) async {
    final controller = TextEditingController(text: card.label);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar etiqueta'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Etiqueta',
            helperText: 'El UID no se puede cambiar.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final label = controller.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La etiqueta no puede estar vacía.')),
      );
      return;
    }
    final result = await getIt<WalletRepository>().updatePhysicalNfcCard(
      id: card.id,
      label: label,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etiqueta actualizada.')),
        );
        _load();
      },
      failure: (error) => handleNfcError(context, error),
    );
  }

  Future<void> _block(PhysicalNfcCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear tarjeta'),
        content: Text('¿Bloquear ${card.label} (${card.maskedUid})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final result = await getIt<WalletRepository>().blockPhysicalNfcCard(
      card.id,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarjeta bloqueada.')));
        _load();
      },
      failure: (error) => handleNfcError(context, error),
    );
  }

  Future<void> _unblock(PhysicalNfcCard card) async {
    final result = await getIt<WalletRepository>().unblockPhysicalNfcCard(
      card.id,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarjeta desbloqueada.')));
        _load();
      },
      failure: (error) => handleNfcError(context, error),
    );
  }

  Future<void> _revoke(PhysicalNfcCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarjeta física'),
        content: Text(
          '¿Revocar ${card.label}?\n\n'
          'Se podrá volver a registrar este UID en otra tarjeta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final result = await getIt<WalletRepository>().revokePhysicalNfcCard(
      card.id,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarjeta revocada. El UID quedó libre.')),
        );
        _load();
      },
      failure: (error) => handleNfcError(context, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarjetas físicas CIERVO')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scan-nfc',
            onPressed: _scanning ? null : _scanAndRegister,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.nfc),
            label: Text(_scanning ? 'Leyendo NFC...' : 'Escanear NFC'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'register-uid',
            onPressed: () => _register(),
            icon: const Icon(Icons.add_card_outlined),
            label: const Text('Agregar tarjeta física'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const CiervoLoadingState()
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _nfcAvailable ? Icons.nfc : Icons.nfc_outlined,
                              color: _nfcAvailable
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _nfcAvailable
                                    ? 'NFC activo en este dispositivo'
                                    : 'NFC no disponible — puedes ingresar el UID manualmente',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Puedes registrar varias tarjetas físicas. '
                          'El UID de cada chip es único y no se edita; '
                          'para liberarlo, revoca la tarjeta.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_error != null) ...[
                    CiervoCard(child: Text(_error!)),
                    const SizedBox(height: AppSpacing.md),
                    CiervoButton(label: 'Reintentar', onPressed: _load),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_cards.isEmpty && _error == null)
                    const CiervoEmptyState(
                      title: 'Sin tarjetas físicas',
                      description:
                          'Escanea tu tarjeta CIERVO o registra el UID manualmente. '
                          'Puedes agregar más de una.',
                      icon: Icons.credit_card_outlined,
                    )
                  else
                    ..._cards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CiervoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  card.isBlocked
                                      ? Icons.block
                                      : Icons.nfc,
                                ),
                                title: Text(card.label),
                                subtitle: Text(
                                  [
                                    if (card.identifier != null &&
                                        card.identifier!.isNotEmpty)
                                      card.identifier!,
                                    'UID: ${card.maskedUid}',
                                    card.status,
                                  ].join(' · '),
                                ),
                              ),
                              Wrap(
                                spacing: AppSpacing.xs,
                                children: [
                                  if (card.canEdit)
                                    TextButton.icon(
                                      onPressed: () => _editLabel(card),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Editar'),
                                    ),
                                  if (card.canBlock)
                                    TextButton.icon(
                                      onPressed: () => _block(card),
                                      icon: const Icon(Icons.block_outlined),
                                      label: const Text('Bloquear'),
                                    ),
                                  if (card.canUnblock)
                                    TextButton.icon(
                                      onPressed: () => _unblock(card),
                                      icon: const Icon(Icons.lock_open_outlined),
                                      label: const Text('Desbloquear'),
                                    ),
                                  if (card.canRevoke)
                                    TextButton.icon(
                                      onPressed: () => _revoke(card),
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Revocar'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 96),
                ],
              ),
      ),
    );
  }
}
