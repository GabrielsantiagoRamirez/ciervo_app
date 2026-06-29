import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
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
  String? _error;

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

  Future<void> _register() async {
    final card = widget.walletCard;
    if (card == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una tarjeta wallet primero.')),
      );
      return;
    }
    final uidController = TextEditingController();
    final labelController = TextEditingController(text: 'Mi tarjeta CIERVO');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar tarjeta fisica'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: uidController,
              decoration: const InputDecoration(
                labelText: 'UID de la tarjeta',
                hintText: '04A1B2C3D4',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Etiqueta'),
            ),
          ],
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
    );
    if (saved != true || !mounted) return;
    final result = await getIt<WalletRepository>().registerPhysicalNfcCard(
      cardId: card.id,
      cardUid: uidController.text.trim(),
      label: labelController.text.trim(),
    );
    if (!mounted) return;
    await result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarjeta fisica registrada.')),
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
      appBar: AppBar(title: const Text('Tarjetas fisicas CIERVO')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _register,
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('Registrar UID'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const CiervoLoadingState()
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  CiervoCard(child: Text(_error!)),
                  const SizedBox(height: AppSpacing.md),
                  CiervoButton(label: 'Reintentar', onPressed: _load),
                ],
              )
            : _cards.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: const [
                  CiervoEmptyState(
                    title: 'Sin tarjetas fisicas',
                    description:
                        'Registra el UID de tu tarjeta CIERVO Plus. '
                        'El cobro se realiza desde el panel del comercio.',
                    icon: Icons.credit_card_outlined,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _cards.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return CiervoCard(
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
                  );
                },
              ),
      ),
    );
  }
}
