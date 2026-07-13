import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/nfc/nfc_tag_reader.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/repositories/kids_repository.dart';

class GuardianKidNfcAssociatePage extends StatefulWidget {
  const GuardianKidNfcAssociatePage({
    required this.childId,
    required this.childName,
    super.key,
  });

  final String childId;
  final String childName;

  @override
  State<GuardianKidNfcAssociatePage> createState() =>
      _GuardianKidNfcAssociatePageState();
}

class _GuardianKidNfcAssociatePageState
    extends State<GuardianKidNfcAssociatePage> {
  final _repository = getIt<KidsRepository>();
  final _uidController = TextEditingController();
  final _labelController = TextEditingController(text: 'Tarjeta escolar');
  List<Map<String, dynamic>> _cards = const [];
  String? _selectedCardId;
  String? _generatedPublicId;
  bool _loading = true;
  bool _scanning = false;
  bool _submitting = false;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _load();
    _checkNfc();
  }

  @override
  void dispose() {
    _uidController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _checkNfc() async {
    final available = await NfcTagReader.isAvailable();
    if (mounted) setState(() => _nfcAvailable = available);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.childWalletCards(widget.childId);
    if (!mounted) return;
    result.when(
      success: (items) {
        final cards = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        setState(() {
          _cards = cards;
          _selectedCardId = _cardId(cards.firstOrNull);
          _loading = false;
        });
      },
      failure: (error) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  String? _cardId(Map<String, dynamic>? card) {
    if (card == null) return null;
    final raw = card['id'] ?? card['cardId'] ?? card['walletCardId'];
    return raw?.toString();
  }

  String _cardLabel(Map<String, dynamic> card) {
    final name = DisplayFormatters.safeText(
      card['displayName'] ?? card['name'],
      fallback: 'Wallet Kids',
    );
    final balance = card['availableBalance'] ?? card['balance'];
    final currency = DisplayFormatters.safeText(
      card['currency'],
      fallback: 'COP',
    );
    if (balance == null) return name;
    return '$name · ${DisplayFormatters.formatMoney(balance, currency: currency)}';
  }

  Future<void> _scanUid() async {
    if (!_nfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa NFC en tu dispositivo.')),
      );
      return;
    }
    setState(() => _scanning = true);
    final uid = await NfcTagReader.readUid();
    if (!mounted) return;
    setState(() => _scanning = false);
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No pudimos leer el UID.')));
      return;
    }
    setState(() => _uidController.text = uid);
  }

  Future<void> _associate() async {
    final cardId = _selectedCardId;
    final uid = _uidController.text.trim().toUpperCase();
    final label = _labelController.text.trim();
    if (cardId == null || cardId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la wallet del menor.')),
      );
      return;
    }
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escanea o ingresa el UID NFC.')),
      );
      return;
    }
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una etiqueta para la tarjeta.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await _repository.associateChildNfc(
      childId: widget.childId,
      childWalletCardId: cardId,
      cardUid: uid,
      label: label,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarjeta NFC vinculada para ${widget.childName}.'),
          ),
        );
        Navigator.of(context).pop(true);
      },
      failure: (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))),
    );
  }

  Future<void> _generatePublicId() async {
    final cardId = _selectedCardId;
    if (cardId == null || cardId.isEmpty) return;
    final result = await _repository.generateChildNfcPublicId(
      childId: widget.childId,
      cardId: cardId,
    );
    if (!mounted) return;
    result.when(
      success: (value) {
        setState(() => _generatedPublicId = value);
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID público copiado al portapapeles.')),
        );
      },
      failure: (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NFC · ${widget.childName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: pagePaddingOf(context),
              children: [
                CiervoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vincular tarjeta física',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'El menor puede escanear la tarjeta en su app, pero el registro '
                        'oficial lo hace el tutor con este formulario.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_cards.isEmpty)
                  const Text('Este menor aún no tiene wallet activa.')
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCardId,
                    decoration: const InputDecoration(
                      labelText: 'Wallet del menor',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: _cards
                        .map(
                          (card) => DropdownMenuItem(
                            value: _cardId(card),
                            child: Text(_cardLabel(card)),
                          ),
                        )
                        .toList(),
                    onChanged: _submitting
                        ? null
                        : (value) => setState(() => _selectedCardId = value),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _uidController,
                  decoration: const InputDecoration(
                    labelText: 'UID NFC',
                    prefixIcon: Icon(Icons.nfc),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CiervoButton(
                  label: _scanning ? 'Leyendo NFC...' : 'Escanear tarjeta',
                  icon: Icons.sensors,
                  state: _scanning
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: _scanning ? null : _scanUid,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CiervoButton(
                  label: _submitting ? 'Vinculando...' : 'Vincular tarjeta NFC',
                  icon: Icons.link,
                  state: _submitting
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: _submitting ? null : _associate,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _selectedCardId == null ? null : _generatePublicId,
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Generar ID público (KIDS-...)'),
                ),
                if (_generatedPublicId != null &&
                    _generatedPublicId!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  CiervoCard(
                    child: Text(
                      'ID público: $_generatedPublicId',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
