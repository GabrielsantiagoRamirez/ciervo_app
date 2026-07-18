import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/permissions/app_permission_service.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../data/repositories/master_kids_repository.dart';
import '../../domain/models/master_kids_models.dart';

class BusinessKidsPaymentPage extends StatefulWidget {
  const BusinessKidsPaymentPage({required this.repository, super.key});

  final MasterKidsRepository repository;

  @override
  State<BusinessKidsPaymentPage> createState() =>
      _BusinessKidsPaymentPageState();
}

class _BusinessKidsPaymentPageState extends State<BusinessKidsPaymentPage> {
  final _token = TextEditingController();
  final _pin = TextEditingController();
  String _executeKey = IdempotencyKey.generate('kids-execute');
  PaymentTokenValidation? _validation;
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _token.clear();
    _pin.clear();
    _token.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    if (_token.text.trim().isEmpty || _pin.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await widget.repository.validatePaymentToken(
      PaymentTokenValidateCommand(
        token: _token.text.trim(),
        pin: _pin.text.trim(),
      ),
    );
    if (!mounted) return;
    result.when(
      success: (value) => setState(() {
        _validation = value;
        _loading = false;
        _message = value.valid
            ? 'Credencial válida para ${value.currency} ${value.amount?.toStringAsFixed(0)}.'
            : value.reason ?? 'La credencial no es válida.';
      }),
      failure: (error) => setState(() {
        _loading = false;
        _message = UserErrorMessage.from(error);
      }),
    );
  }

  Future<void> _execute() async {
    if (_validation?.valid != true) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    final granted = await getIt<AppPermissionService>()
        .requestLocationIfNeeded();
    if (!granted) {
      setState(() {
        _loading = false;
        _message =
            'La ubicación es obligatoria para ejecutar pagos protegidos por geocerca.';
      });
      return;
    }
    try {
      final location = await getIt<LocationService>().currentLocation();
      final result = await widget.repository.executePayment(
        PaymentExecuteCommand(
          token: _token.text.trim(),
          pin: _pin.text.trim(),
          idempotencyKey: _executeKey,
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
      if (!mounted) return;
      result.when(
        success: (payment) => setState(() {
          _loading = false;
          _message =
              'Pago ejecutado: ${payment.currency} ${payment.amount.toStringAsFixed(0)}.';
          _validation = null;
          _executeKey = IdempotencyKey.generate('kids-execute');
          _token.clear();
          _pin.clear();
        }),
        failure: (error) => setState(() {
          _loading = false;
          _message = UserErrorMessage.from(error);
        }),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = UserErrorMessage.from(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cobro autorizado Kids')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'El token y PIN solo se mantienen en esta pantalla y se eliminan al cerrarla.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _token,
          autocorrect: false,
          enableSuggestions: false,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Token'),
        ),
        TextField(
          controller: _pin,
          autocorrect: false,
          enableSuggestions: false,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _validate,
          child: const Text('Validar credencial'),
        ),
        if (_validation?.valid == true)
          FilledButton.icon(
            icon: const Icon(Icons.point_of_sale_outlined),
            onPressed: _loading ? null : _execute,
            label: const Text('Ejecutar pago'),
          ),
        if (_loading) const LinearProgressIndicator(),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_message!),
          ),
      ],
    ),
  );
}
