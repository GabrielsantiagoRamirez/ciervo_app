import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/family_payment_card.dart';
import '../cubit/family_payment_methods_cubit.dart';

/// Requiere un [FamilyPaymentMethodsCubit] en el árbol (p. ej. vía [BlocProvider.value]).
class MercadoPago3dsPage extends StatelessWidget {
  const MercadoPago3dsPage({
    required this.cardId,
    this.verificationUrl,
    super.key,
  });

  final String cardId;
  final String? verificationUrl;

  @override
  Widget build(BuildContext context) {
    return _MercadoPago3dsView(
      cardId: cardId,
      verificationUrl: verificationUrl,
    );
  }
}

class _MercadoPago3dsView extends StatefulWidget {
  const _MercadoPago3dsView({required this.cardId, this.verificationUrl});

  final String cardId;
  final String? verificationUrl;

  @override
  State<_MercadoPago3dsView> createState() => _MercadoPago3dsViewState();
}

class _MercadoPago3dsViewState extends State<_MercadoPago3dsView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _verifying = false;
  String? _error;

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
    } else {
      _loading = false;
    }
  }

  Future<void> _completeVerification() async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    final cubit = context.read<FamilyPaymentMethodsCubit>();
    final ok = await cubit.verifyCard(widget.cardId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _verifying = false;
      _error =
          cubit.state.errorMessage ??
          'No pudimos validar la tarjeta después de la autenticación.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autenticación 3DS')),
      body: Column(
        children: [
          if (_loading || _verifying)
            const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: _verifying ? null : _completeVerification,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          Expanded(
            child:
                widget.verificationUrl == null ||
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
                            onPressed: _verifying
                                ? null
                                : _completeVerification,
                            child: Text(
                              _verifying
                                  ? 'Validando...'
                                  : 'Ya autentiqué mi tarjeta',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}

/// Requiere un [FamilyPaymentMethodsCubit] en el árbol (p. ej. vía [BlocProvider.value]).
class EditFamilyCardAliasPage extends StatefulWidget {
  const EditFamilyCardAliasPage({required this.card, super.key});

  final FamilyPaymentCard card;

  @override
  State<EditFamilyCardAliasPage> createState() =>
      _EditFamilyCardAliasPageState();
}

class _EditFamilyCardAliasPageState extends State<EditFamilyCardAliasPage> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

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
    setState(() {
      _saving = true;
      _error = null;
    });
    final cubit = context.read<FamilyPaymentMethodsCubit>();
    final ok = await cubit.updateAlias(
      cardId: widget.card.id,
      alias: _controller.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = cubit.state.errorMessage ?? 'No pudimos guardar el alias.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar alias')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
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
    );
  }
}
