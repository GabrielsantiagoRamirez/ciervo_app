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
          title: const Text('Registrar tarjeta física'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: uidController,
                  decoration: const InputDecoration(
                    labelText: 'UID de la tarjeta',
                    hintText: '04A1B2C3D4',
                    helperText:
                        'Cada lectura NFC genera un UID único para pagos e historial.',
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
        const SnackBar(content: Text('No pudimos leer el UID. Intenta de nuevo.')),
      );
      return;
    }
    await _register(presetUid: uid);
  }

  Future<void> _block(PhysicalNfcCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear tarjeta'),
        content: Text('Bloquear ${card.label} (${card.cardUid})?'),
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
    final result = await getIt<WalletRepository>().blockPhysicalNfcCard(card.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarjeta bloqueada.')),
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
            label: const Text('Registrar UID'),
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
                          'Cada registro NFC genera un UID propio. '
                          'Úsalo para pagos e historial sin reutilizar el mismo identificador.',
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
                          'Escanea tu tarjeta CIERVO Plus o registra el UID manualmente. '
                          'El cobro se realiza desde el panel del comercio.',
                      icon: Icons.credit_card_outlined,
                    )
                  else
                    ..._cards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CiervoCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.nfc),
                            title: Text(card.label),
                            subtitle: Text('UID: ${card.cardUid} · ${card.status}'),
                            trailing: card.isBlocked
                                ? null
                                : IconButton(
                                    tooltip: 'Bloquear',
                                    onPressed: () => _block(card),
                                    icon: const Icon(Icons.block_outlined),
                                  ),
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
