import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/family_payment_card.dart';
import '../../domain/repositories/family_payments_repository.dart';
import '../cubit/family_payment_methods_cubit.dart';

class MercadoPago3dsPage extends StatefulWidget {
  const MercadoPago3dsPage({
    required this.cardId,
    this.verificationUrl,
    super.key,
  });

  final String cardId;
  final String? verificationUrl;

  @override
  State<MercadoPago3dsPage> createState() => _MercadoPago3dsPageState();
}

class _MercadoPago3dsPageState extends State<MercadoPago3dsPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            if (url.contains('success') ||
                url.contains('approved') ||
                url.contains('verified')) {
              _completeVerification();
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    final url = widget.verificationUrl;
    if (url != null && url.isNotEmpty) {
      _controller.loadRequest(Uri.parse(url));
    }
  }

  Future<void> _completeVerification() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    final cubit = context.read<FamilyPaymentMethodsCubit>();
    final ok = await cubit.verifyCard(widget.cardId);
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FamilyPaymentMethodsCubit(getIt<FamilyPaymentsRepository>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Autenticación 3DS')),
        body: Column(
          children: [
            if (_loading || _verifying)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: widget.verificationUrl == null ||
                      widget.verificationUrl!.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Confirma la autenticación cuando hayas completado el proceso con tu banco.',
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _completeVerification,
                              child: const Text('Ya autentiqué mi tarjeta'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

class EditFamilyCardAliasPage extends StatefulWidget {
  const EditFamilyCardAliasPage({required this.card, super.key});

  final FamilyPaymentCard card;

  @override
  State<EditFamilyCardAliasPage> createState() => _EditFamilyCardAliasPageState();
}

class _EditFamilyCardAliasPageState extends State<EditFamilyCardAliasPage> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.card.alias);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<FamilyPaymentMethodsCubit>().updateAlias(
          cardId: widget.card.id,
          alias: _controller.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FamilyPaymentMethodsCubit(getIt<FamilyPaymentsRepository>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar alias')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Alias',
                  helperText: widget.card.maskedNumber,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando...' : 'Guardar alias'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
