import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/ciervo_date_picker.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../media/data/media_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
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
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();
  DateTime? _birthDate;
  String _countryCode = CountryRegistration.defaultCountryCode();
  String? _documentType;
  String _vehicle = 'Bike';
  String? _vehiclePhotoPath;
  String? _vehiclePhotoName;
  bool _confirmsFrontPlate = false;
  bool _loadingProfile = true;
  bool _saving = false;

  bool get _needsPlate => _vehicle == 'Motorcycle' || _vehicle == 'Car';
  bool get _needsBrandModel => _vehicle == 'Motorcycle' || _vehicle == 'Car';

  List<AdultDocumentOption> get _documentOptions =>
      CountryRegistration.adultDocumentOptions(_countryCode);

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  @override
  void dispose() {
    _document.dispose();
    _phone.dispose();
    _plate.dispose();
    _brand.dispose();
    _model.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _prefillFromProfile() async {
    final result = await getIt<ProfileRepository>().getMe();
    if (!mounted) return;
    result.when(
      success: (profile) {
        final country = (profile.countryCode ?? '').trim().toUpperCase();
        final options = CountryRegistration.adultDocumentOptions(
          country.isNotEmpty ? country : _countryCode,
        );
        final savedType = (profile.documentType ?? '').trim().toUpperCase();
        final matchedType = options
            .where((item) => item.code.toUpperCase() == savedType)
            .map((item) => item.code)
            .firstOrNull;

        setState(() {
          _countryCode = country.isNotEmpty ? country : _countryCode;
          if ((profile.identityDocument ?? '').trim().isNotEmpty) {
            _document.text = profile.identityDocument!.trim();
          }
          if (profile.phone.trim().isNotEmpty) {
            _phone.text = profile.phone.trim();
          }
          if (profile.birthDate != null) {
            _birthDate = profile.birthDate;
          }
          _documentType = matchedType ?? options.firstOrNull?.code;
          _loadingProfile = false;
        });
      },
      failure: (_) => setState(() {
        _documentType = _documentOptions.firstOrNull?.code;
        _loadingProfile = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inscripción domiciliario')),
    body: AbsorbPointer(
      absorbing: _saving || _loadingProfile,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const CiervoCard(
            child: Text(
              'Completa tus datos. Revisaremos tu solicitud antes de activar tu perfil.',
            ),
          ),
          if (_loadingProfile) ...[
            const SizedBox(height: AppSpacing.lg),
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cargando tus datos de perfil…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
                  subtitle: _birthDate != null
                      ? const Text('Tomada de tu perfil (puedes cambiarla)')
                      : const Text('Selecciona tu fecha de nacimiento'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickDate,
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('document-$_documentType-$_countryCode'),
                  initialValue: _documentType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de documento',
                  ),
                  items: _documentOptions
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.code,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _documentType = value),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Selecciona el tipo de documento.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _document,
                  decoration: const InputDecoration(
                    labelText: 'Número de documento',
                    helperText: 'Se completa con tu perfil si ya lo tienes',
                  ),
                  validator: (v) =>
                      InputValidators.requiredText(v ?? '', 'tu documento'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    helperText: 'Se completa con tu perfil si ya lo tienes',
                  ),
                  validator: (v) => InputValidators.phone(v ?? ''),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _vehicle,
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
                  onChanged: (v) => setState(() {
                    _vehicle = v ?? 'Bike';
                    if (!_needsBrandModel) {
                      _brand.clear();
                      _model.clear();
                      _plate.clear();
                    }
                  }),
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
                if (_needsBrandModel) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _brand,
                    decoration: const InputDecoration(labelText: 'Marca'),
                    validator: (v) => _needsBrandModel
                        ? InputValidators.requiredText(v ?? '', 'la marca')
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _model,
                    decoration: const InputDecoration(labelText: 'Modelo'),
                    validator: (v) => _needsBrandModel
                        ? InputValidators.requiredText(v ?? '', 'el modelo')
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _color,
                    decoration: const InputDecoration(
                      labelText: 'Color (opcional)',
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Foto frontal del vehículo',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Debe mostrar el frente del vehículo con la placa claramente '
                  'legible para la revisión del Superadmin.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _pickVehiclePhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    _vehiclePhotoPath == null
                        ? 'Tomar / subir foto frontal + placa'
                        : 'Cambiar foto frontal',
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
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmsFrontPlate,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Confirmo que esta foto es el frente del vehículo '
                    'con la placa legible',
                  ),
                  onChanged: (value) =>
                      setState(() => _confirmsFrontPlate = value ?? false),
                ),
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
    final now = DateTime.now();
    final date = await showCiervoDatePicker(
      context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (date != null) setState(() => _birthDate = date);
  }

  Future<void> _pickVehiclePhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (photo == null) {
      final gallery = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (gallery == null) return;
      setState(() {
        _vehiclePhotoPath = gallery.path;
        _vehiclePhotoName = gallery.name;
      });
      return;
    }
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
    if (_documentType == null || _documentType!.trim().isEmpty) {
      _message('Selecciona el tipo de documento.');
      return;
    }
    if (_vehiclePhotoPath == null) {
      _message('Subí la foto frontal del vehículo con la placa legible.');
      return;
    }
    if (!_confirmsFrontPlate) {
      _message(
        'Debés confirmar que la foto muestra el frente con la placa legible.',
      );
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
    final upload = await getIt<MediaRepository>().upload(
      path: _vehiclePhotoPath!,
      fileName: _vehiclePhotoName ?? 'vehicle-front.jpg',
    );
    final failed = upload.when(
      success: (asset) {
        vehicleMediaId = asset.id;
        return false;
      },
      failure: (_) => true,
    );
    if (failed || vehicleMediaId == null) {
      if (mounted) {
        setState(() => _saving = false);
        _message('No pudimos subir la foto del vehículo. Intenta de nuevo.');
      }
      return;
    }

    final mediaId = int.tryParse(vehicleMediaId!);
    final d = _birthDate!;
    final payload = <String, dynamic>{
      'birthDate':
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      'documentType': _documentType,
      'documentNumber': _document.text.trim(),
      'phone': _phone.text.trim(),
      'vehicleType': _vehicle,
      'vehiclePhotoMediaId': mediaId ?? vehicleMediaId,
      'confirmsFrontShowsReadablePlate': true,
      if (_needsPlate) 'vehiclePlate': _plate.text.trim().toUpperCase(),
      if (_needsBrandModel) ...{
        'vehicleBrand': _brand.text.trim(),
        'vehicleModel': _model.text.trim(),
      },
      if (_color.text.trim().isNotEmpty) 'vehicleColor': _color.text.trim(),
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
