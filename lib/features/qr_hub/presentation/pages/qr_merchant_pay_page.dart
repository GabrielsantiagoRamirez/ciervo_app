import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/insufficient_balance_dialog.dart';
import '../../../loyalty/loyalty_purchase_helper.dart';
import '../../../receipts/presentation/pages/receipts_page.dart';
import '../../../wallet/domain/entities/wallet_card.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../data/qr_scan_repository.dart';
import '../../domain/entities/qr_scan_models.dart';

class QrMerchantPayPage extends StatefulWidget {
  const QrMerchantPayPage({required this.token, super.key});

  final String token;

  @override
  State<QrMerchantPayPage> createState() => _QrMerchantPayPageState();
}

class _QrMerchantPayPageState extends State<QrMerchantPayPage> {
  late Future<QrPaymentDetails> _details;
  List<WalletCard> _cards = const [];
  WalletCard? _selectedCard;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _details = _loadDetails();
    _loadCards();
  }

  Future<QrPaymentDetails> _loadDetails() async {
    final result = await getIt<QrScanRepository>().paymentDetails(widget.token);
    return result.when(
      success: (value) => value,
      failure: (error) => throw error,
    );
  }

  Future<void> _loadCards() async {
    final result = await getIt<WalletRepository>().cards();
    if (!mounted) return;
    result.when(
      success: (items) {
        final selected =
            items.where((c) => c.isPrimary).firstOrNull ?? items.firstOrNull;
        setState(() {
          _cards = items;
          _selectedCard = selected;
        });
      },
      failure: (_) {},
    );
  }

  Future<void> _pay() async {
    final card = _selectedCard;
    if (card == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una tarjeta wallet.')),
      );
      return;
    }

    setState(() => _paying = true);
    final key =
        'qr-pay-${widget.token}-${DateTime.now().microsecondsSinceEpoch}';
    final result = await getIt<QrScanRepository>().payWithWallet(
      token: widget.token,
      walletCardId: card.id,
      idempotencyKey: key,
    );

    if (!mounted) return;
    await result.when(
      success: (payment) async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago realizado correctamente.')),
        );
        final details = await _details;
        if (!mounted) return;
        await processLoyaltyAfterPurchase(
          context,
          amount: payment.amount ?? details.amount,
          businessId: details.businessId,
          paymentIntentId: payment.paymentIntentId,
        );
        final receiptId = payment.receiptLookupId;
        if (receiptId != null && receiptId.isNotEmpty && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReceiptDetailPage(id: receiptId),
            ),
          );
        }
        if (mounted) Navigator.of(context).pop(true);
      },
      failure: (error) async {
        final message = UserErrorMessage.from(error);
        if (message.toLowerCase().contains('saldo')) {
          await showInsufficientBalanceDialog(context);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );
    if (mounted) setState(() => _paying = false);
  }

  Future<void> _payWithMercadoPago(QrPaymentDetails details) async {
    setState(() => _paying = true);
    final key =
        'qr-mp-${widget.token}-${DateTime.now().microsecondsSinceEpoch}';
    final result = await getIt<QrScanRepository>().payWithMercadoPago(
      token: widget.token,
      idempotencyKey: key,
    );
    if (!mounted) return;
    await result.when(
      success: (payment) async {
        final url = payment.checkoutUrl;
        if (url != null && url.isNotEmpty) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        if (mounted) Navigator.of(context).pop(true);
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
    if (mounted) setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar comercio')),
      body: FutureBuilder<QrPaymentDetails>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(UserErrorMessage.from(snapshot.error!)),
              ),
            );
          }

          final details = snapshot.data!;
          if (!details.canPay) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  details.isExpired
                      ? 'Este QR de pago expiro.'
                      : 'Este QR ya fue utilizado o no esta disponible.',
                ),
              ),
            );
          }

          return AbsorbPointer(
            absorbing: _paying,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CiervoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(details.businessName),
                      subtitle: Text(details.description ?? 'Pago en comercio'),
                    ),
                    const Divider(),
                    Text(
                      '${details.amount.toStringAsFixed(0)} ${details.currency}',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    if (details.expiresAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Expira: ${details.expiresAt!.toLocal().toString().substring(0, 16)}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<WalletCard>(
                      value: _selectedCard,
                      decoration: const InputDecoration(
                        labelText: 'Tarjeta wallet',
                      ),
                      items: _cards
                          .map(
                            (card) => DropdownMenuItem(
                              value: card,
                              child: Text(
                                '${card.name} · ${card.balance.toStringAsFixed(0)} ${card.currency}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _paying
                          ? null
                          : (value) => setState(() => _selectedCard = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CiervoButton(
                      label: _paying ? 'Procesando' : 'Pagar con wallet',
                      icon: Icons.payments_outlined,
                      state: _paying
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: _pay,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoButton(
                      label: 'Pagar con Mercado Pago',
                      icon: Icons.account_balance_wallet_outlined,
                      variant: CiervoButtonVariant.secondary,
                      onPressed: _paying
                          ? null
                          : () => _payWithMercadoPago(details),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
