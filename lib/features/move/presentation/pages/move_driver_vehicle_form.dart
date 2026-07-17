import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../domain/entities/move_enums.dart';
import '../../domain/repositories/move_repository.dart';
import '../cubit/move_driver_cubit.dart';
import '../utils/move_labels.dart';

/// Muestra el formulario para registrar un vehículo del conductor.
Future<void> showMoveVehicleForm(
  BuildContext context,
  MoveDriverCubit cubit,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MoveVehicleForm(cubit: cubit),
  );
}

class _MoveVehicleForm extends StatefulWidget {
  const _MoveVehicleForm({required this.cubit});

  final MoveDriverCubit cubit;

  @override
  State<_MoveVehicleForm> createState() => _MoveVehicleFormState();
}

class _MoveVehicleFormState extends State<_MoveVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();
  final _seats = TextEditingController(text: '4');
  MoveVehicleCategory _category = MoveVehicleCategory.standard;
  bool _saving = false;

  @override
  void dispose() {
    _plate.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    _seats.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await widget.cubit.addVehicle(
      MoveVehicleInput(
        category: _category,
        plate: _plate.text.trim().toUpperCase(),
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        model: _model.text.trim().isEmpty ? null : _model.text.trim(),
        year: int.tryParse(_year.text.trim()),
        color: _color.text.trim().isEmpty ? null : _color.text.trim(),
        seats: int.tryParse(_seats.text.trim()),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrar vehículo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<MoveVehicleCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: MoveVehicleCategory.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(MoveLabels.vehicleCategory(c)),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _plate,
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    InputValidators.requiredText(v ?? '', 'la placa'),
                decoration: const InputDecoration(labelText: 'Placa'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brand,
                      decoration: const InputDecoration(labelText: 'Marca'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _model,
                      decoration: const InputDecoration(labelText: 'Modelo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _year,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Año'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _color,
                      decoration: const InputDecoration(labelText: 'Color'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _seats,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Asientos'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              CiervoButton(
                label: 'Guardar vehículo',
                icon: Icons.save_outlined,
                state: _saving
                    ? CiervoButtonState.loading
                    : CiervoButtonState.normal,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
