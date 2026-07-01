import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_id_qr_dialog.dart';
import '../../../../shared/widgets/ciervo_id_qr_scanner_page.dart';
import '../../../../shared/widgets/ciervo_user_id_badge.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../users/domain/entities/user_search_result.dart';
import '../../../users/presentation/pages/user_search_page.dart';
import '../../../wallet/domain/entities/resolved_wallet_user.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';
import '../../data/chat_payments_remote_datasource.dart';

class ChatGiftPage extends StatefulWidget {
  const ChatGiftPage({
    this.conversationId,
    this.initialTargetCiervoCode,
    this.initialTargetUserId,
    super.key,
  });

  final String? conversationId;
  final String? initialTargetCiervoCode;
  final String? initialTargetUserId;

  @override
  State<ChatGiftPage> createState() => _ChatGiftPageState();
}

class _ChatGiftPageState extends State<ChatGiftPage> {
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _giftType = 'Money';
  bool _sending = false;
  String? _targetUserId;
  UserSearchResult? _pickedRecipient;

  static const _giftTypes = <String, String>{
    'Money': 'Dinero',
    'GiftCard': 'Tarjeta regalo',
    'Coupon': 'Cupon',
    'Benefit': 'Beneficio',
    'Event': 'Evento',
  };

  @override
  void initState() {
    super.initState();
    _targetUserId = widget.initialTargetUserId;
    if (widget.initialTargetCiervoCode != null) {
      _codeController.text = widget.initialTargetCiervoCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickRecipientByName() async {
    final user = await Navigator.of(context).push<UserSearchResult>(
      MaterialPageRoute(
        builder: (_) => const UserSearchPage(pickRecipient: true),
      ),
    );
    if (user == null || !mounted) return;
    setState(() {
      _pickedRecipient = user;
      _targetUserId = user.userId;
      if (user.ciervoUserCode != null) {
        _codeController.text = user.ciervoUserCode!;
      }
    });
  }

  Future<void> _scanRecipientQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CiervoIdQrScannerPage()),
    );
    if (code == null || !mounted) return;
    setState(() {
      _codeController.text = code;
      _pickedRecipient = null;
      _targetUserId = null;
    });
    if (mounted) {
      context.read<WalletCubit>().resolveUser(code);
    }
  }

  Future<void> _shareMyIdInChat() async {
    final conversationId = widget.conversationId;
    if (conversationId == null || conversationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abre el regalo desde un chat para enviar tu ID ahí.'),
        ),
      );
      return;
    }
    final code = await resolveCiervoUserCodeForSession();
    if (!mounted) return;
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos cargar tu CIERVO ID.')),
      );
      return;
    }
    final result = await getIt<ChatRepository>().sendText(
      conversationId,
      'Mi CIERVO ID es $code. Escanea mi QR o úsalo para enviarme un regalo.',
    );
    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu CIERVO ID fue enviado al chat.')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(getIt<WalletRepository>()),
      child: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, walletState) {
          final resolved = walletState.resolvedUser;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Enviar regalo'),
              actions: [
                IconButton(
                  tooltip: 'Mostrar mi QR',
                  icon: const Icon(Icons.qr_code_2_outlined),
                  onPressed: () => showMyCiervoIdQrDialog(context),
                ),
                if (widget.conversationId != null)
                  IconButton(
                    tooltip: 'Enviar mi ID al chat',
                    icon: const Icon(Icons.chat_outlined),
                    onPressed: _shareMyIdInChat,
                  ),
              ],
            ),
            body: AbsorbPointer(
              absorbing: _sending,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: CiervoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _giftType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de regalo',
                        ),
                        items: _giftTypes.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: _sending
                            ? null
                            : (value) =>
                                setState(() => _giftType = value ?? 'Money'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Ciervo ID del destinatario',
                          prefixIcon: const Icon(Icons.alternate_email),
                          suffixIcon: IconButton(
                            tooltip: 'Escanear QR',
                            onPressed: _sending ? null : _scanRecipientQr,
                            icon: const Icon(Icons.qr_code_scanner),
                          ),
                        ),
                        onChanged: (_) => setState(() {
                          _pickedRecipient = null;
                          _targetUserId = widget.initialTargetUserId;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: CiervoButton(
                              label: 'Buscar por nombre',
                              icon: Icons.person_search_outlined,
                              variant: CiervoButtonVariant.secondary,
                              onPressed: _sending ? null : _pickRecipientByName,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: CiervoButton(
                              label: 'Escanear QR',
                              icon: Icons.qr_code_scanner,
                              variant: CiervoButtonVariant.secondary,
                              onPressed: _sending ? null : _scanRecipientQr,
                            ),
                          ),
                        ],
                      ),
                      if (_pickedRecipient == null &&
                          _codeController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        CiervoButton(
                          label: 'Validar CIERVO ID',
                          icon: Icons.verified_outlined,
                          variant: CiervoButtonVariant.secondary,
                          onPressed: _sending
                              ? null
                              : () => context.read<WalletCubit>().resolveUser(
                                    _codeController.text.trim(),
                                  ),
                        ),
                      ],
                      if (_pickedRecipient != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(_pickedRecipient!.fullName),
                          subtitle: Text(_pickedRecipient!.ciervoUserCode ?? ''),
                        ),
                      ] else if (resolved != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.verified_outlined),
                          title: Text(resolved.displayName),
                          subtitle: Text(resolved.ciervoUserCode),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monto (COP)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mensaje (opcional)',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CiervoButton(
                        label: _sending ? 'Enviando' : 'Enviar regalo',
                        icon: Icons.card_giftcard_outlined,
                        state: _sending
                            ? CiervoButtonState.loading
                            : CiervoButtonState.normal,
                        onPressed: _sending ? null : () => _submit(resolved),
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

  Future<void> _submit(ResolvedWalletUser? resolved) async {
    final code = _codeController.text.trim();
    final resolvedCode = resolved?.ciervoUserCode;
    final targetCode = code.isNotEmpty
        ? code
        : (resolvedCode != null && resolvedCode.isNotEmpty ? resolvedCode : '');
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final targetUserId = _targetUserId ?? widget.initialTargetUserId;

    if (amount <= 0 || (targetCode.isEmpty && targetUserId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Elige destinatario (nombre o QR) e ingresa un monto válido.',
          ),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await getIt<ChatPaymentsRemoteDataSource>().sendGift(
        chatConversationId: widget.conversationId,
        targetCiervoUserCode: targetCode,
        targetUserId: targetUserId,
        amount: amount,
        giftType: _giftType,
        message: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regalo enviado correctamente.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
