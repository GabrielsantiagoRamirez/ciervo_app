import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../media/data/media_repository.dart';
import '../../domain/repositories/delivery_repository.dart';

const _vehicles = <String, String>{
  'Bike': 'Bicicleta',
  'Motorcycle': 'Moto',
  'Car': 'Carro',
};

class DeliveryApplyPage extends StatefulWidget {
  const DeliveryApplyPage({super.key});
  @override
  State<DeliveryApplyPage> createState() => _DeliveryApplyPageState();
}

class _DeliveryApplyPageState extends State<DeliveryApplyPage> {
  final _key = GlobalKey<FormState>();
  final _document = TextEditingController();
  final _phone = TextEditingController();
  final _plate = TextEditingController();
  DateTime? _birthDate;
  String _vehicle = 'Bike';
  String? _vehiclePhotoPath;
  String? _vehiclePhotoName;
  bool _saving = false;

  bool get _needsPlate => _vehicle == 'Motorcycle' || _vehicle == 'Car';
  bool get _needsVehiclePhoto => true;

  @override
  void dispose() {
    _document.dispose();
    _phone.dispose();
    _plate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inscripción domiciliario')),
    body: AbsorbPointer(
      absorbing: _saving,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const CiervoCard(
            child: Text(
              'Completa tus datos. Revisaremos tu solicitud antes de activar tu perfil.',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Form(
            key: _key,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake_outlined),
                  title: Text(
                    _birthDate == null
                        ? 'Fecha de nacimiento'
                        : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickDate,
                ),
                TextFormField(
                  controller: _document,
                  decoration: const InputDecoration(
                    labelText: 'Número de documento',
                  ),
                  validator: (v) =>
                      InputValidators.requiredText(v ?? '', 'tu documento'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  validator: (v) => InputValidators.phone(v ?? ''),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _vehicle,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de vehículo',
                  ),
                  items: _vehicles.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _vehicle = v ?? 'Bike'),
                ),
                if (_needsPlate) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _plate,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText:
                          'Placa de la ${DisplayLabels.vehicleType(_vehicle).toLowerCase()}',
                    ),
                    validator: (v) => _needsPlate
                        ? InputValidators.requiredText(v ?? '', 'la placa')
                        : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _pickVehiclePhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    _vehiclePhotoPath == null
                        ? 'Foto del vehículo'
                        : 'Cambiar foto del vehículo',
                  ),
                ),
                if (_vehiclePhotoPath != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_vehiclePhotoPath!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                CiervoButton(
                  label: _saving ? 'Enviando…' : 'Enviar solicitud',
                  icon: Icons.send_outlined,
                  state: _saving
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _birthDate = date);
  }

  Future<void> _pickVehiclePhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (photo == null) return;
    setState(() {
      _vehiclePhotoPath = photo.path;
      _vehiclePhotoName = photo.name;
    });
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    if (_birthDate == null) {
      _message('Selecciona tu fecha de nacimiento.');
      return;
    }
    if (_needsVehiclePhoto && _vehiclePhotoPath == null) {
      _message('Sube una foto de tu vehículo.');
      return;
    }
    final today = DateTime.now();
    final adultDate = DateTime(today.year - 18, today.month, today.day);
    if (_birthDate!.isAfter(adultDate)) {
      _message('Debes ser mayor de edad para inscribirte.');
      return;
    }

    setState(() => _saving = true);
    String? vehicleMediaId;
    if (_vehiclePhotoPath != null && _vehiclePhotoName != null) {
      final upload = await getIt<MediaRepository>().upload(
        path: _vehiclePhotoPath!,
        fileName: _vehiclePhotoName!,
      );
      final failed = upload.when(
        success: (asset) {
          vehicleMediaId = asset.id;
          return false;
        },
        failure: (_) => true,
      );
      if (failed) {
        if (mounted) {
          setState(() => _saving = false);
          _message('No pudimos subir la foto del vehículo. Intenta de nuevo.');
        }
        return;
      }
    }

    final d = _birthDate!;
    final payload = <String, dynamic>{
      'birthDate':
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      'documentNumber': _document.text.trim(),
      'phone': _phone.text.trim(),
      'vehicleType': _vehicle,
      if (_needsPlate) 'vehiclePlate': _plate.text.trim().toUpperCase(),
      if (vehicleMediaId != null) 'vehiclePhotoMediaId': vehicleMediaId,
    };

    final result = await getIt<DeliveryRepository>().apply(payload);
    if (!mounted) return;
    result.when(
      success: (_) {
        _message('Solicitud enviada correctamente.');
        Navigator.of(context).pop();
      },
      failure: (e) {
        setState(() => _saving = false);
        _message(UserErrorMessage.from(e));
      },
    );
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
