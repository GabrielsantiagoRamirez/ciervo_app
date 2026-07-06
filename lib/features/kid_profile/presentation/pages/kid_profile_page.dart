import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../kid_me/data/kid_me_repository.dart';
import '../../../kid_wallet/presentation/pages/kid_wallet_page.dart';

class KidProfilePage extends StatefulWidget {
  const KidProfilePage({super.key});

  @override
  State<KidProfilePage> createState() => _KidProfilePageState();
}

class _KidProfilePageState extends State<KidProfilePage> {
  final _repository = getIt<KidMeRepository>();
  Map<String, dynamic>? _profile;
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

  String get _legalName => '${_profile?['name'] ?? 'Menor'}'.trim();

  String? get _nickname {
    final value = _profile?['displayName'] ?? _profile?['nickname'];
    final text = '$value'.trim();
    if (text.isEmpty || text.toLowerCase() == 'apodo') return null;
    return text;
  }

  String? get _photoUrl {
    final url = _profile?['photoUrl'] ?? _profile?['avatarUrl'];
    final text = '$url'.trim();
    return text.isEmpty ? null : text;
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
        final url = data['photoUrl'] ?? data['imageUrl'];
        setState(() {
          _profile = {
            ...?_profile,
            if (url != null) 'photoUrl': url,
          };
          _uploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada.')),
        );
      },
      failure: (error) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
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
      success: (data) {
        setState(() {
          _profile = {...?_profile, ...data};
          _savingNickname = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apodo guardado.')),
        );
      },
      failure: (error) {
        setState(() => _savingNickname = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  if (_error != null) Text(_error!, textAlign: TextAlign.center),
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
                                  backgroundImage: _photoUrl != null
                                      ? NetworkImage(_photoUrl!)
                                      : null,
                                  child: _photoUrl == null
                                      ? Text(
                                          (_legalName.isNotEmpty
                                                  ? _legalName[0]
                                                  : 'K')
                                              .toUpperCase(),
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
                                        : const Icon(Icons.camera_alt, size: 18),
                                    onPressed:
                                        _uploadingPhoto ? null : _pickPhoto,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_nickname != null) ...[
                                    Text(
                                      _nickname!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    _legalName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  if (_profile?['familyName'] != null)
                                    Text('${_profile?['familyName']}'),
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
                            _nickname == null ? 'Agregar apodo' : 'Cambiar apodo',
                          ),
                        ),
                      ],
                    ),
                  ),
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
