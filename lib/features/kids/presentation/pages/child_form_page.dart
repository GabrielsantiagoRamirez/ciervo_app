import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/kids_repository.dart';
import '../cubit/kids_cubit.dart';
import '../cubit/kids_state.dart';

class ChildFormPage extends StatelessWidget {
  const ChildFormPage({this.child, super.key});

  final ChildProfile? child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KidsCubit(getIt<KidsRepository>()),
      child: _ChildFormView(child: child),
    );
  }
}

class _ChildFormView extends StatefulWidget {
  const _ChildFormView({this.child});

  final ChildProfile? child;

  @override
  State<_ChildFormView> createState() => _ChildFormViewState();
}

class _ChildFormViewState extends State<_ChildFormView> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _documentNumber = TextEditingController();
  final _medicalNotes = TextEditingController();
  DateTime? _birthDate;
  int _relationshipType = 1;
  bool _isPrimaryGuardian = true;
  String _countryCode = 'CO';
  String? _documentType;

  static const _relationships = <int, String>{
    1: 'Madre',
    2: 'Padre',
    3: 'Tutor legal',
    4: 'Familiar',
    5: 'Otro',
  };

  static const _documents = <String, List<DropdownMenuItem<String>>>{
    'CO': [
      DropdownMenuItem(value: 'RC', child: Text('Registro civil')),
      DropdownMenuItem(value: 'TI', child: Text('Tarjeta de identidad')),
    ],
    'CL': [
      DropdownMenuItem(value: 'TI', child: Text('Tarjeta de identidad')),
      DropdownMenuItem(value: 'RUN', child: Text('RUN')),
    ],
  };

  @override
  void initState() {
    super.initState();
    final child = widget.child;
    if (child != null) {
      _firstName.text = child.firstName;
      _lastName.text = child.lastName;
      _documentNumber.text = child.documentNumber ?? '';
      _medicalNotes.text = child.medicalNotes ?? '';
      _birthDate = child.birthDate;
      _relationshipType = int.tryParse(child.relationshipType) ?? 1;
      final existingDocument = child.documentType;
      if (existingDocument == 'RUN' ||
          existingDocument == 'TI' ||
          existingDocument == 'CERT_NAC') {
        _countryCode = 'CL';
      }
      _documentType =
          _documents[_countryCode]!.any(
            (item) => item.value == existingDocument,
          )
          ? existingDocument
          : null;
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _documentNumber.dispose();
    _medicalNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KidsCubit, KidsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) async {
        if (state.status == KidsStatus.saved) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              icon: const Icon(Icons.check_circle_outline),
              title: Text(
                widget.child == null ? 'Menor creado' : 'Menor actualizado',
              ),
              content: const Text('La información se guardó correctamente.'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          );
          if (!context.mounted) return;
          Navigator.of(context).pop(true);
        }
        if (state.errorMessage != null && state.status == KidsStatus.loaded) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final saving = state.status == KidsStatus.actionLoading;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.child == null ? 'Crear menor' : 'Editar menor'),
          ),
          body: AbsorbPointer(
            absorbing: saving,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CiervoCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _textField(_firstName, 'Nombre', required: true),
                      _textField(_lastName, 'Apellido', required: true),
                      _dateField(context),
                      DropdownButtonFormField<int>(
                        initialValue: _relationshipType,
                        decoration: const InputDecoration(
                          labelText: 'Relación con el menor',
                          prefixIcon: Icon(Icons.family_restroom_outlined),
                        ),
                        items: _relationships.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _relationshipType = value ?? 1),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _countryCode,
                        decoration: const InputDecoration(
                          labelText: 'País del documento',
                          prefixIcon: Icon(Icons.public_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'CO',
                            child: Text('Colombia'),
                          ),
                          DropdownMenuItem(value: 'CL', child: Text('Chile')),
                        ],
                        onChanged: (value) => setState(() {
                          _countryCode = value ?? 'CO';
                          _documentType = null;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_countryCode),
                        initialValue: _documentType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de documento',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: _documents[_countryCode],
                        validator: (value) => value == null
                            ? 'Selecciona el tipo de documento.'
                            : null,
                        onChanged: (value) => _documentType = value,
                      ),
                      _textField(
                        _documentNumber,
                        'Número de documento',
                        required: true,
                        topSpacing: true,
                      ),
                      _textField(
                        _medicalNotes,
                        'Notas médicas (opcional)',
                        topSpacing: true,
                        maxLines: 3,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Soy tutor principal'),
                        subtitle: const Text(
                          'El tutor principal gestiona permisos y cuenta del menor.',
                        ),
                        value: _isPrimaryGuardian,
                        onChanged: (value) =>
                            setState(() => _isPrimaryGuardian = value),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CiervoButton(
                        label: saving ? 'Guardando' : 'Guardar',
                        icon: Icons.save_outlined,
                        state: saving
                            ? CiervoButtonState.loading
                            : CiervoButtonState.normal,
                        onPressed: saving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool topSpacing = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.md,
        top: topSpacing ? AppSpacing.md : 0,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? '$label es requerido.'
                  : null
            : null,
      ),
    );
  }

  Widget _dateField(BuildContext context) {
    final label = _birthDate == null
        ? 'Seleccionar fecha'
        : '${_birthDate!.year.toString().padLeft(4, '0')}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FormField<DateTime>(
        initialValue: _birthDate,
        validator: (_) {
          if (_birthDate == null) {
            return 'Selecciona la fecha de nacimiento.';
          }
          return CountryRegistration.validateKidsAge(_birthDate!);
        },
        builder: (field) => InkWell(
          onTap: () async {
            final selected = await showDatePicker(
              context: context,
              initialDate:
                  _birthDate ??
                  DateTime.now().subtract(const Duration(days: 365 * 12)),
              firstDate: DateTime.now().subtract(const Duration(days: 365 * 26)),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
            );
            if (selected != null) {
              setState(() => _birthDate = selected);
              field.didChange(selected);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Fecha de nacimiento',
              prefixIcon: const Icon(Icons.calendar_month_outlined),
              errorText: field.errorText,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _birthDate == null) return;
    final date = _birthDate!;
    final isoDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    context.read<KidsCubit>().saveChild(
      childId: widget.child?.id,
      data: {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'birthDate': isoDate,
        'relationshipType': _relationshipType,
        'documentType': _documentType,
        'documentNumber': _documentNumber.text.trim(),
        'medicalNotes': _medicalNotes.text.trim(),
        'isPrimaryGuardian': _isPrimaryGuardian,
      },
    );
  }
}
