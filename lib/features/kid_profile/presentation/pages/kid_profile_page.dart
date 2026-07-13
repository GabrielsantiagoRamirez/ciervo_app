import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../kid_me/data/kid_me_repository.dart';
import '../../../kid_me/domain/entities/kid_me_profile.dart';
import '../../../kid_nfc/presentation/pages/kid_nfc_device_registration_page.dart';
import '../../../kid_wallet/presentation/pages/kid_wallet_page.dart';

class KidProfilePage extends StatefulWidget {
  const KidProfilePage({super.key});

  @override
  State<KidProfilePage> createState() => _KidProfilePageState();
}

class _KidProfilePageState extends State<KidProfilePage> {
  final _repository = getIt<KidMeRepository>();
  KidMeProfile? _profile;
  bool _loading = true;
  bool _uploadingPhoto = false;
  bool _savingNickname = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.profile();
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _profile = data;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  String? get _nickname {
    final nick = DisplayFormatters.safeText(_profile?.nickname);
    final display = DisplayFormatters.safeText(_profile?.displayName);
    if (nick.isNotEmpty && nick != display) return nick;
    if (display.isNotEmpty &&
        display != _profile?.firstName &&
        display != '${_profile?.firstName} ${_profile?.lastName}'.trim()) {
      return display;
    }
    return null;
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final result = await _repository.uploadPhoto(
      path: photo.path,
      fileName: photo.name,
    );
    if (!mounted) return;
    result.when(
      success: (data) {
        final url = DisplayFormatters.safeText(
          data['photoUrl'] ?? data['imageUrl'],
        );
        setState(() {
          if (_profile != null && url.isNotEmpty) {
            _profile = KidMeProfile(
              firstName: _profile!.firstName,
              lastName: _profile!.lastName,
              displayName: _profile!.displayName,
              nickname: _profile!.nickname,
              username: _profile!.username,
              ciervoUserCode: _profile!.ciervoUserCode,
              role: _profile!.role,
              roleLabel: _profile!.roleLabel,
              photoUrl: url,
              familyName: _profile!.familyName,
              countryCode: _profile!.countryCode,
              childProfileId: _profile!.childProfileId,
              guardians: _profile!.guardians,
            );
          }
          _uploadingPhoto = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto actualizada.')));
      },
      failure: (error) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  Future<void> _editNickname() async {
    final controller = TextEditingController(text: _nickname ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu apodo'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Ej: Josecito',
            helperText: 'Así te verán en tu wallet y tarjeta digital.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;

    setState(() => _savingNickname = true);
    final result = await _repository.updateDisplayName(controller.text);
    if (!mounted) return;
    result.when(
      success: (_) {
        setState(() => _savingNickname = false);
        _load();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Apodo guardado.')));
      },
      failure: (error) {
        setState(() => _savingNickname = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: pagePaddingOf(context),
                children: const [CiervoLoadingState(itemCount: 3)],
              )
            : ListView(
                padding: pagePaddingOf(context),
                children: [
                  if (_error != null)
                    CiervoErrorState(
                      title: 'No pudimos cargar tu perfil',
                      description: _error!,
                      onRetry: _load,
                    ),
                  if (profile != null) ...[
                    CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundImage: profile.photoUrl.isNotEmpty
                                        ? NetworkImage(profile.photoUrl)
                                        : null,
                                    child: profile.photoUrl.isEmpty
                                        ? Text(
                                            profile.firstName.isNotEmpty
                                                ? profile.firstName[0]
                                                      .toUpperCase()
                                                : 'K',
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: IconButton.filledTonal(
                                      icon: _uploadingPhoto
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt,
                                              size: 18,
                                            ),
                                      onPressed: _uploadingPhoto
                                          ? null
                                          : _pickPhoto,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DisplayFormatters.safeDisplayName(
                                        nickname: profile.nickname,
                                        displayName: profile.displayName,
                                        firstName: profile.firstName,
                                        lastName: profile.lastName,
                                        username: profile.username,
                                        ciervoId: profile.ciervoUserCode,
                                        fallback: 'Menor',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(profile.roleLabel),
                                    if (profile.username.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        DisplayFormatters.formatUsername(
                                          profile.username,
                                        ),
                                      ),
                                    ],
                                    if (profile.ciervoUserCode.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(profile.ciervoUserCode),
                                    ],
                                    if (profile.familyName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(profile.familyName),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: _savingNickname ? null : _editNickname,
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(
                              _nickname == null
                                  ? 'Agregar apodo'
                                  : 'Cambiar apodo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (profile.guardians.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      CiervoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis tutores',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...profile.guardians.map(
                              (guardian) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.family_restroom),
                                title: Text(
                                  DisplayFormatters.identityLine(
                                    username: guardian.username,
                                    displayName: guardian.displayName,
                                    ciervoId: guardian.ciervoUserCode,
                                  ),
                                ),
                                subtitle: guardian.isPrimary
                                    ? const Text('Tutor principal')
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.md),
                  CiervoButton(
                    label: 'Ver mi wallet',
                    icon: Icons.account_balance_wallet_outlined,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const KidWalletPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CiervoButton(
                    label: 'Registrar dispositivo NFC',
                    variant: CiervoButtonVariant.secondary,
                    icon: Icons.nfc,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const KidNfcDeviceRegistrationPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CiervoButton(
                    label: 'Cerrar sesión',
                    variant: CiervoButtonVariant.secondary,
                    icon: Icons.logout,
                    onPressed: () => getIt<AuthRepository>().logout(),
                  ),
                ],
              ),
      ),
    );
  }
}
