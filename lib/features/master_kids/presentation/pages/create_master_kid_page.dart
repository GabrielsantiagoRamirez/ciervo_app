import 'package:flutter/material.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../data/repositories/master_kids_repository.dart';
import '../../domain/models/master_kids_models.dart';

class CreateMasterKidPage extends StatefulWidget {
  const CreateMasterKidPage({required this.repository, super.key});
  final MasterKidsRepository repository;

  @override
  State<CreateMasterKidPage> createState() => _CreateMasterKidPageState();
}

class _CreateMasterKidPageState extends State<CreateMasterKidPage> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _pin = TextEditingController();
  final _repeatPin = TextEditingController();
  DateTime? _birthDate;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pin.clear();
    _repeatPin.clear();
    _name.dispose();
    _username.dispose();
    _pin.dispose();
    _repeatPin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final username = _username.text.trim();
    final pin = _pin.text;
    if (name.isEmpty || username.isEmpty || username.length > 50) {
      return setState(() => _error = 'Completa nombre y usuario.');
    }
    if (pin.length < 4 || pin.length > 12 || pin != _repeatPin.text) {
      return setState(
        () => _error = 'El PIN debe tener entre 4 y 12 dígitos y coincidir.',
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final created = await widget.repository.createKid(
      CreateKidCommand(name: name, birthDate: _birthDate),
    );
    Object? failure;
    int? kidId;
    created.when(
      success: (kid) => kidId = kid.kidId,
      failure: (error) => failure = error,
    );
    if (failure == null && kidId != null) {
      final account = await widget.repository.createKidAccount(
        kidId!,
        CreateKidAccountCommand(username: username, pin: pin),
      );
      account.when(success: (_) {}, failure: (error) => failure = error);
    }
    _pin.clear();
    _repeatPin.clear();
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _busy = false;
        _error = UserErrorMessage.from(failure!);
      });
      return;
    }
    Navigator.pop(context, kidId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear perfil Kids')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fecha de nacimiento'),
          subtitle: Text(
            _birthDate == null
                ? 'Opcional'
                : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
          ),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: _busy
              ? null
              : () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDate: _birthDate ?? DateTime.now(),
                  );
                  if (selected != null) setState(() => _birthDate = selected);
                },
        ),
        TextField(
          controller: _username,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'Usuario Kids'),
        ),
        TextField(
          controller: _pin,
          obscureText: true,
          enableSuggestions: false,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        TextField(
          controller: _repeatPin,
          obscureText: true,
          enableSuggestions: false,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Repetir PIN'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Crear perfil y acceso'),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!),
          ),
      ],
    ),
  );
}
