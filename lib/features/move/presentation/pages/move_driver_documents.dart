import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/ciervo_date_picker.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../media/data/media_repository.dart';
import '../cubit/move_driver_cubit.dart';

const _documentTypes = <String, String>{
  'DriverLicense': 'Licencia de conducir',
  'IdCard': 'Documento de identidad',
  'VehicleRegistration': 'Tarjeta de propiedad',
  'Insurance': 'Seguro (SOAT/póliza)',
  'CriminalRecord': 'Antecedentes',
};

/// Muestra el formulario para subir un documento del conductor.
Future<void> showMoveDocumentForm(
  BuildContext context,
  MoveDriverCubit cubit,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MoveDocumentForm(cubit: cubit),
  );
}

class _MoveDocumentForm extends StatefulWidget {
  const _MoveDocumentForm({required this.cubit});

  final MoveDriverCubit cubit;

  @override
  State<_MoveDocumentForm> createState() => _MoveDocumentFormState();
}

class _MoveDocumentFormState extends State<_MoveDocumentForm> {
  final _numberController = TextEditingController();
  String _documentType = _documentTypes.keys.first;
  String? _photoPath;
  String? _photoName;
  DateTime? _expiresAt;
  bool _saving = false;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (photo == null) return;
    setState(() {
      _photoPath = photo.path;
      _photoName = photo.name;
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showCiervoDatePicker(
      context,
      initialDate: _expiresAt ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      helpText: 'Fecha de vencimiento',
    );
    if (date != null) setState(() => _expiresAt = date);
  }

  void _message(String text) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _submit() async {
    if (_photoPath == null || _photoName == null) {
      _message('Sube una foto o archivo del documento.');
      return;
    }
    setState(() => _saving = true);
    final upload = await getIt<MediaRepository>().upload(
      path: _photoPath!,
      fileName: _photoName!,
      mediaType: 'Document',
    );
    final mediaId = upload.when(
      success: (asset) => asset.id,
      failure: (_) => null,
    );
    if (mediaId == null || mediaId.isEmpty) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('No pudimos subir el archivo. Intenta de nuevo.');
      return;
    }
    final baseUrl = getIt<AppConfig>().apiBaseUrl;
    final fileUrl = '$baseUrl/api/media/$mediaId/download';
    final ok = await widget.cubit.addDocument(
      documentType: _documentType,
      fileUrl: fileUrl,
      documentNumber: _numberController.text.trim().isEmpty
          ? null
          : _numberController.text.trim(),
      expiresAt: _expiresAt,
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subir documento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _documentType,
              decoration: const InputDecoration(labelText: 'Tipo de documento'),
              items: _documentTypes.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _documentType = value ?? _documentType),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Número (opcional)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                _expiresAt == null
                    ? 'Fecha de vencimiento (opcional)'
                    : '${_expiresAt!.day.toString().padLeft(2, '0')}/'
                          '${_expiresAt!.month.toString().padLeft(2, '0')}/'
                          '${_expiresAt!.year}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickExpiry,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(
                _photoPath == null ? 'Adjuntar archivo' : 'Cambiar archivo',
              ),
            ),
            if (_photoPath != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_photoPath!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: 'Enviar documento',
              icon: Icons.upload_file,
              state: _saving
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
