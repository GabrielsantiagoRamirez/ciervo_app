import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/errors/user_error_message.dart';
import '../../../core/nfc/nfc_tag_reader.dart';
import '../../../core/permissions/permission_kind.dart';
import '../../../core/permissions/permission_manager.dart';
import '../../../core/utils/idempotency_key.dart';
import '../data/business_nfc_repository.dart';
import '../domain/business_nfc_models.dart';

class BusinessNfcChargePage extends StatefulWidget {
  const BusinessNfcChargePage({required this.repository, super.key});
  final BusinessNfcRepository repository;

  @override
  State<BusinessNfcChargePage> createState() => _BusinessNfcChargePageState();
}

class _BusinessNfcChargePageState extends State<BusinessNfcChargePage> {
  final _payload = TextEditingController();
  BusinessNfcCredential? _credential;
  BusinessNfcValidation? _validation;
  String _idempotencyKey = IdempotencyKey.generate('wallet-nfc-charge');
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _clearSecret();
    _payload.dispose();
    super.dispose();
  }

  void _clearSecret() {
    _payload.clear();
    _credential = null;
  }

  Future<void> _readNfc() async {
    final available = await PermissionManager.instance.ensure(
      context,
      AppPermissionKind.nfc,
    );
    if (!available || !mounted) {
      setState(() => _message = 'NFC no está disponible o está desactivado.');
      return;
    }
    setState(() {
      _busy = true;
      _message = 'Acerca el dispositivo o tarjeta NFC.';
    });
    final payload = await NfcTagReader.readPayload();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (payload == null || payload.isEmpty) {
        _message = 'No encontramos una credencial NFC válida.';
      } else {
        _payload.text = payload;
        _message = 'Credencial NFC leída. Valídala antes de cobrar.';
      }
    });
  }

  BusinessNfcCredential _readCredential() {
    final decoded = jsonDecode(_payload.text.trim());
    if (decoded is! Map) throw const FormatException('Payload NFC inválido.');
    final credential = BusinessNfcCredential.fromPayload(
      Map<String, dynamic>.from(decoded),
    );
    if (credential.sessionId <= 0 || credential.token.isEmpty) {
      throw const FormatException('El payload no contiene sesión y token.');
    }
    return credential;
  }

  Future<void> _validate() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final credential = _readCredential();
      final result = await widget.repository.validate(
        BusinessNfcValidateCommand(
          sessionId: credential.sessionId,
          token: credential.token,
        ),
      );
      if (!mounted) return;
      result.when(
        success: (value) => setState(() {
          _credential = credential;
          _validation = value;
          _message = value.valid
              ? 'Credencial válida.'
              : value.reason ?? 'Credencial rechazada.';
        }),
        failure: (error) =>
            setState(() => _message = UserErrorMessage.from(error)),
      );
    } catch (error) {
      if (mounted) setState(() => _message = UserErrorMessage.from(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _charge() async {
    final credential = _credential;
    final validation = _validation;
    if (credential == null || validation?.valid != true) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar cobro NFC'),
            content: Text(
              'Cobrar ${validation!.currency ?? ''} '
              '${validation.amount?.toStringAsFixed(2) ?? ''}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cobrar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await widget.repository.charge(
      BusinessNfcChargeCommand(
        sessionId: credential.sessionId,
        token: credential.token,
        idempotencyKey: _idempotencyKey,
      ),
    );
    if (!mounted) return;
    result.when(
      success: (charge) {
        _clearSecret();
        _validation = null;
        _idempotencyKey = IdempotencyKey.generate('wallet-nfc-charge');
        _message =
            'Cobro ${charge.status}: ${charge.currency ?? ''} '
            '${charge.amount?.toStringAsFixed(2) ?? ''}.';
      },
      failure: (error) => _message = UserErrorMessage.from(error),
    );
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final validation = _validation;
    return Scaffold(
      appBar: AppBar(title: const Text('Cobro NFC')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Acerca el lector o pega el payload recibido. La credencial se '
            'mantiene solo en memoria y se borra al cobrar o salir.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _readNfc,
            icon: const Icon(Icons.nfc),
            label: const Text('Leer NFC'),
          ),
          TextField(
            controller: _payload,
            minLines: 2,
            maxLines: 4,
            autocorrect: false,
            enableSuggestions: false,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Payload NFC'),
          ),
          FilledButton(
            onPressed: _busy ? null : _validate,
            child: const Text('Validar'),
          ),
          if (validation?.valid == true)
            Card(
              child: ListTile(
                title: Text(
                  '${validation?.currency ?? ''} '
                  '${validation?.amount?.toStringAsFixed(2) ?? ''}',
                ),
                subtitle: Text(
                  validation?.customerName ??
                      validation?.description ??
                      'Sesión validada',
                ),
              ),
            ),
          if (validation?.valid == true)
            FilledButton.icon(
              onPressed: _busy ? null : _charge,
              icon: const Icon(Icons.contactless_outlined),
              label: const Text('Confirmar cobro'),
            ),
          if (_busy) const LinearProgressIndicator(),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
        ],
      ),
    );
  }
}
