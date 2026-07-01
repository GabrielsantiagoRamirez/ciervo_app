// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/widgets/email_verification_sheet.dart';
import '../../../media/data/media_repository.dart';
import '../../data/kyc_repository.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  late Future<_KycPageData> _data;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = _fetch();
  }

  Future<_KycPageData> _fetch() async {
    final kycResult = await getIt<KycRepository>().me();
    final profileResult = await getIt<ProfileRepository>().getMe();
    return _KycPageData(
      kyc: kycResult.when(success: (v) => v, failure: (e) => throw e),
      profile: profileResult.when(success: (v) => v, failure: (_) => null),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Verificación de identidad')),
        body: FutureBuilder<_KycPageData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CiervoLoadingState();
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: CiervoErrorState(
                  title: 'No pudimos cargar tu verificación',
                  description: UserErrorMessage.from(snapshot.error!),
                  onRetry: () => setState(_reload),
                ),
              );
            }
            final payload = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => setState(_reload),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _KycStatusCard(kyc: payload.kyc),
                  const SizedBox(height: AppSpacing.lg),
                  if (payload.profile != null)
                    _ContactVerificationCard(
                      profile: payload.profile!,
                      onChanged: () => setState(_reload),
                    ),
                  if (payload.profile != null) const SizedBox(height: AppSpacing.lg),
                  if (_canSubmitDocument(payload.kyc, payload.profile))
                    _KycSubmitForm(
                      countryCode: payload.profile?.countryCode ?? 'CO',
                      onSubmitted: () => setState(_reload),
                    ),
                ],
              ),
            );
          },
        ),
      );
}

class _KycPageData {
  const _KycPageData({required this.kyc, required this.profile});

  final KycSubmission? kyc;
  final UserProfile? profile;
}

class _ContactVerificationCard extends StatefulWidget {
  const _ContactVerificationCard({
    required this.profile,
    required this.onChanged,
  });

  final UserProfile profile;
  final VoidCallback onChanged;

  @override
  State<_ContactVerificationCard> createState() =>
      _ContactVerificationCardState();
}

class _ContactVerificationCardState extends State<_ContactVerificationCard> {
  bool _syncingPhone = false;

  Future<void> _syncPhone() async {
    setState(() => _syncingPhone = true);
    try {
      final token = await getIt<FirebaseAuthService>().freshIdToken();
      final result = await getIt<AuthRepository>().firebaseSyncVerification(
        firebaseIdToken: token,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teléfono sincronizado con tu cuenta.')),
          );
          widget.onChanged();
        },
        failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      );
    } finally {
      if (mounted) setState(() => _syncingPhone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verifica tu contacto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Confirma tu teléfono o correo para poder enviar tu documento de identidad.',
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              profile.phoneVerified
                  ? Icons.verified_outlined
                  : Icons.phone_iphone_outlined,
              color: profile.phoneVerified ? Colors.green : null,
            ),
            title: Text(profile.phone.isEmpty ? 'Teléfono sin registrar' : profile.phone),
            subtitle: Text(
              profile.phoneVerified ? 'Verificado' : 'Pendiente de verificación',
            ),
            trailing: profile.phoneVerified
                ? null
                : FilledButton.tonal(
                    onPressed: _syncingPhone ? null : _syncPhone,
                    child: Text(_syncingPhone ? 'Sincronizando…' : 'Confirmar'),
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              profile.emailVerified
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
              color: profile.emailVerified ? Colors.green : null,
            ),
            title: Text(
              profile.email.isEmpty ? 'Correo sin registrar' : profile.email,
            ),
            subtitle: Text(
              profile.emailVerified ? 'Verificado' : 'Pendiente de verificación',
            ),
            trailing: profile.emailVerified
                ? null
                : FilledButton.tonal(
                    onPressed: profile.email.isEmpty
                        ? null
                        : () => showEmailVerificationSheet(
                              context,
                              email: profile.email,
                            ).then((_) => widget.onChanged()),
                    child: const Text('Confirmar'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KycStatusCard extends StatelessWidget {
  const _KycStatusCard({required this.kyc});

  final KycSubmission? kyc;

  @override
  Widget build(BuildContext context) {
    final rawStatus = kyc?.status ?? 'No enviado';
    final status = DisplayLabels.kycStatus(rawStatus);
    final color = _color(rawStatus);
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon(rawStatus), color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _statusDescription(rawStatus, kyc),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (kyc != null &&
              (kyc!.documentNumber ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            _infoRow(
              context,
              'Documento',
              '${DisplayLabels.documentType(kyc!.documentType ?? '-')} ${kyc!.documentNumber ?? ''}',
            ),
            if (kyc!.submittedAt != null)
              _infoRow(
                context,
                'Enviado',
                kyc!.submittedAt!.toLocal().toString().substring(0, 16),
              ),
          ],
          if ((kyc?.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Motivo de rechazo: ${kyc!.rejectionReason}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  String _statusDescription(String status, KycSubmission? kyc) {
    final key = status.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    if (kyc == null ||
        key.contains('notsubmitted') ||
        key.contains('noenviado') ||
        key.contains('sinenviar')) {
      return 'Verifica tu teléfono o correo y luego envía tu documento.';
    }
    if (key.contains('approve')) {
      return 'Tu identidad fue verificada correctamente.';
    }
    if (key.contains('reject')) {
      return 'Tu solicitud fue rechazada. Puedes corregir los datos y reenviar.';
    }
    if (key.contains('pending') || key.contains('review')) {
      return 'Estamos validando tu información. Te notificaremos cuando sea aprobada.';
    }
    return 'Revisa el estado de tu solicitud.';
  }
}

class _KycSubmitForm extends StatefulWidget {
  const _KycSubmitForm({
    required this.countryCode,
    required this.onSubmitted,
  });

  final String countryCode;
  final VoidCallback onSubmitted;

  @override
  State<_KycSubmitForm> createState() => _KycSubmitFormState();
}

class _KycSubmitFormState extends State<_KycSubmitForm> {
  final _documentController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();
  String _documentType = 'CC';
  bool _saving = false;
  String? _frontPath;
  String? _backPath;
  String? _selfiePath;

  @override
  void dispose() {
    _documentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(String slot) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      switch (slot) {
        case 'front':
          _frontPath = file.path;
        case 'back':
          _backPath = file.path;
        case 'selfie':
          _selfiePath = file.path;
      }
    });
  }

  Widget _photoTile({
    required String label,
    required String? path,
    required VoidCallback onPick,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: path == null
          ? const CircleAvatar(child: Icon(Icons.image_outlined))
          : CircleAvatar(
              backgroundImage: FileImage(File(path)),
            ),
      title: Text(label),
      subtitle: Text(path == null ? 'Sin foto' : 'Lista para enviar'),
      trailing: OutlinedButton(
        onPressed: onPick,
        child: const Text('Tomar foto'),
      ),
    );
  }

  Future<int?> _upload(String path, String label) async {
    final file = File(path);
    final result = await getIt<MediaRepository>().upload(
      path: path,
      fileName: file.uri.pathSegments.last,
    );
    return result.when(
      success: (asset) => int.tryParse(asset.id),
      failure: (error) {
        throw error;
      },
    );
  }

  @override
  Widget build(BuildContext context) => CiervoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agregar documento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Sube fotos del documento (frente obligatorio) y opcionalmente reverso y selfie.',
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _documentType,
              items: const [
                DropdownMenuItem(value: 'CC', child: Text('Cédula')),
                DropdownMenuItem(value: 'CE', child: Text('Cédula de extranjería')),
                DropdownMenuItem(value: 'PASSPORT', child: Text('Pasaporte')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _documentType = value);
              },
              decoration: const InputDecoration(labelText: 'Tipo de documento'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _documentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número de documento'),
            ),
            const SizedBox(height: AppSpacing.md),
            _photoTile(
              label: 'Frente del documento *',
              path: _frontPath,
              onPick: () => _pickPhoto('front'),
            ),
            _photoTile(
              label: 'Reverso (opcional)',
              path: _backPath,
              onPick: () => _pickPhoto('back'),
            ),
            _photoTile(
              label: 'Selfie (opcional)',
              path: _selfiePath,
              onPick: () => _pickPhoto('selfie'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notas opcionales'),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(_saving ? 'Enviando…' : 'Enviar documento'),
            ),
          ],
        ),
      );

  Future<void> _submit() async {
    if (_documentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el número de documento.')),
      );
      return;
    }
    if (_frontPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La foto del frente del documento es obligatoria.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final frontId = await _upload(_frontPath!, 'front');
      if (frontId == null) throw Exception('No pudimos subir el frente del documento.');
      int? backId;
      int? selfieId;
      if (_backPath != null) backId = await _upload(_backPath!, 'back');
      if (_selfiePath != null) selfieId = await _upload(_selfiePath!, 'selfie');

      final result = await getIt<KycRepository>().submit(
        documentType: _documentType,
        documentNumber: _documentController.text.trim(),
        country: widget.countryCode,
        frontDocumentMediaId: frontId,
        backDocumentMediaId: backId,
        selfieMediaId: selfieId,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento enviado para revisión.')),
          );
          widget.onSubmitted();
        },
        failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      );
    }
  }
}

bool _canSubmitDocument(KycSubmission? kyc, UserProfile? profile) {
  final approved = (kyc?.status.toLowerCase() ?? '').contains('approve');
  if (approved) return false;
  final contactVerified =
      profile?.phoneVerified == true || profile?.emailVerified == true;
  if (!contactVerified) return false;
  final status = kyc?.status.toLowerCase() ?? '';
  return kyc == null ||
      status.contains('reject') ||
      status.contains('rechazado') ||
      (kyc.documentNumber ?? '').isEmpty;
}

IconData _icon(String status) {
  final text = status.toLowerCase();
  if (text.contains('approve')) return Icons.verified_outlined;
  if (text.contains('reject')) return Icons.cancel_outlined;
  return Icons.hourglass_top_outlined;
}

Color _color(String status) {
  final text = status.toLowerCase();
  if (text.contains('approve')) return Colors.green;
  if (text.contains('reject')) return Colors.red;
  return Colors.orange;
}
