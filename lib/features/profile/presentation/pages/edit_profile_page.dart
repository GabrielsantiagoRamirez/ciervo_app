import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../widgets/profile_photo_image.dart';
import '../widgets/email_verification_sheet.dart';
import '../../domain/entities/user_profile.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(
        getIt<ProfileRepository>(),
        getIt<WalletRepository>(),
      ),
      child: _EditProfileView(profile: profile),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView({required this.profile});

  final UserProfile profile;

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  static const _maxPhotoBytes = 5 * 1024 * 1024;
  static const _extensions = {'jpg', 'jpeg', 'png', 'webp'};

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.profile.firstName);
    _lastName = TextEditingController(text: widget.profile.lastName);
    _email = TextEditingController(text: widget.profile.email);
    _phone = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.profile?.photoUrl != current.profile?.photoUrl,
      listener: (context, state) async {
        if (state.status == ProfileStatus.saved) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              icon: const Icon(Icons.check_circle_outline),
              title: const Text('Perfil actualizado'),
              content: const Text('Tus datos se guardaron correctamente.'),
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
        if (state.status == ProfileStatus.loaded &&
            state.profile?.photoUrl != widget.profile.photoUrl) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto actualizada correctamente.')),
          );
        }
        if (state.status == ProfileStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final saving = state.isSaving || state.status == ProfileStatus.uploadingPhoto;
        final profile = state.profile ?? widget.profile;
        return Scaffold(
          appBar: AppBar(title: const Text('Editar perfil')),
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
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: profile.hasPhoto
                                  ? ClipOval(
                                      child: ProfilePhotoImage(
                                        key: ValueKey(profile.photoUrl),
                                        photoRef: profile.photoUrl,
                                        width: 84,
                                        height: 84,
                                        fallback: Text(profile.initials),
                                      ),
                                    )
                                  : Text(
                                      profile.initials,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: IconButton.filledTonal(
                                tooltip: 'Cambiar foto',
                                onPressed: saving ? null : _pickPhoto,
                                icon: const Icon(Icons.camera_alt_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _field(
                        controller: _firstName,
                        label: 'Nombre',
                        icon: Icons.person_outline,
                        validator: (value) => InputValidators.requiredText(
                          value ?? '',
                          'tu nombre',
                        ),
                      ),
                      _field(
                        controller: _lastName,
                        label: 'Apellido',
                        icon: Icons.person_outline,
                        validator: (value) => InputValidators.requiredText(
                          value ?? '',
                          'tu apellido',
                        ),
                      ),
                      _field(
                        controller: _email,
                        label: 'Correo electrónico',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: widget.profile.emailVerified,
                        helperText: widget.profile.emailVerified
                            ? 'Verificado. Para cambiarlo debes volver a confirmarlo.'
                            : null,
                        onTap: widget.profile.emailVerified
                            ? () => _promptVerifiedFieldChange(context, 'correo')
                            : null,
                        validator: (value) =>
                            InputValidators.email(value ?? ''),
                      ),
                      _field(
                        controller: _phone,
                        label: 'Teléfono',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        readOnly: widget.profile.phoneVerified,
                        helperText: widget.profile.phoneVerified
                            ? 'Verificado. Para cambiarlo debes volver a confirmarlo.'
                            : null,
                        onTap: widget.profile.phoneVerified
                            ? () => _promptVerifiedFieldChange(context, 'teléfono')
                            : null,
                        validator: (value) =>
                            InputValidators.phone(value ?? ''),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CiervoButton(
                        label: saving ? 'Guardando' : 'Guardar cambios',
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

  Future<void> _promptVerifiedFieldChange(
    BuildContext context,
    String fieldLabel,
  ) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cambiar $fieldLabel'),
        content: Text(
          'Tu $fieldLabel está verificado. Si lo cambias, deberás confirmarlo nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cambiar y verificar'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    if (fieldLabel == 'correo') {
      setState(() => _email.clear());
      await showEmailVerificationSheet(context, email: _email.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Edita el teléfono, guarda y confirma el código SMS en inicio de sesión.',
          ),
        ),
      );
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? helperText,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helperText,
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (photo == null || !mounted) return;
    final extension = photo.name.split('.').last.toLowerCase();
    final length = await photo.length();
    if (!_extensions.contains(extension) || length > _maxPhotoBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Usa JPG, JPEG, PNG o WEBP de máximo 5 MB.'),
        ));
      }
      return;
    }
    if (!mounted) return;
    await context.read<ProfileCubit>().uploadPhoto(
      path: photo.path,
      fileName: photo.name,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileCubit>().updateProfile(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
    );
  }
}
