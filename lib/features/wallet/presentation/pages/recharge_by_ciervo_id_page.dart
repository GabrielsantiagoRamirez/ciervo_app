import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';

class RechargeByCiervoIdPage extends StatefulWidget {
  const RechargeByCiervoIdPage({this.initialCiervoCode, super.key});

  final String? initialCiervoCode;

  @override
  State<RechargeByCiervoIdPage> createState() => _RechargeByCiervoIdPageState();
}

class _RechargeByCiervoIdPageState extends State<RechargeByCiervoIdPage> {
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _lastIntentId;

  @override
  void initState() {
    super.initState();
    if (widget.initialCiervoCode != null) {
      _codeController.text = widget.initialCiervoCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(getIt<WalletRepository>()),
      child: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) async {
          final message = state.errorMessage ?? state.successMessage;
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
          final url = state.rechargeIntent?.checkoutUrl;
          final intentId = state.rechargeIntent?.id;
          if (url != null && url.isNotEmpty && intentId != _lastIntentId) {
            _lastIntentId = intentId;
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          }
        },
        builder: (context, state) {
          final intentId = state.rechargeIntent?.id ?? _lastIntentId;
          return Scaffold(
            appBar: AppBar(title: const Text('Recargar por ID Ciervo')),
            body: Stack(
              children: [
                AbsorbPointer(
                  absorbing: state.isLoading,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _codeController,
                            decoration: const InputDecoration(
                              hintText: 'Ciervo ID del destinatario',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Monto',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              hintText: 'Descripcion (opcional)',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          CiervoButton(
                            label: state.isLoading
                                ? 'Procesando'
                                : 'Recargar cuenta',
                            icon: Icons.add_card_outlined,
                            state: state.isLoading
                                ? CiervoButtonState.loading
                                : CiervoButtonState.normal,
                            onPressed: state.isLoading ? null : () => _submit(context),
                          ),
                          if (intentId != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            CiervoButton(
                              label: 'Verificar pago',
                              icon: Icons.refresh,
                              variant: CiervoButtonVariant.secondary,
                              onPressed: state.isLoading
                                  ? null
                                  : () => context
                                      .read<WalletCubit>()
                                      .pollRechargeIntent(intentId),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x55000000),
                      child: Center(child: CiervoBrandLoader()),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submit(BuildContext context) {
    final code = _codeController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (code.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un Ciervo ID valido y un monto mayor a cero.'),
        ),
      );
      return;
    }
    context.read<WalletCubit>().rechargeByCiervoId(
      targetCiervoUserCode: code,
      amount: amount,
      description: _descriptionController.text.trim().isEmpty
          ? 'Recarga CIERVO'
          : _descriptionController.text.trim(),
    );
  }
}
