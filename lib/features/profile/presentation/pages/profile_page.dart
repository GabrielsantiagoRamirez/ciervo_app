import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../kids/presentation/pages/kids_page.dart';
import '../../../memberships/presentation/pages/membership_page.dart';
import '../../../transport/presentation/pages/transport_page.dart';
import '../../../kyc/presentation/pages/kyc_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../../../wallet/presentation/pages/payment_requests_page.dart';
import '../../../financial_history/presentation/pages/financial_history_page.dart';
import '../../../receipts/presentation/pages/receipts_page.dart';
import '../../../cashback/presentation/pages/cashback_page.dart';
import '../../../qr_wallet/presentation/pages/qr_wallet_page.dart';
import '../../../reservations/presentation/pages/reservations_page.dart';
import '../../../delivery/presentation/pages/delivery_page.dart';
import '../../../delivery/presentation/pages/customer_orders_page.dart';
import '../../../bonuses/presentation/pages/bonuses_pages.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(getIt<ProfileRepository>())..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Perfil')),
          body: RefreshIndicator(
            onRefresh: context.read<ProfileCubit>().loadProfile,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: switch (state.status) {
                      ProfileStatus.initial || ProfileStatus.loading =>
                        const CiervoLoadingState(itemCount: 4),
                      ProfileStatus.empty => const CiervoEmptyState(
                        title: 'Perfil no disponible',
                        description: 'Sincroniza tu cuenta para continuar.',
                      ),
                      ProfileStatus.failure => CiervoErrorState(
                        title: 'No pudimos cargar tu perfil',
                        description:
                            state.errorMessage ?? 'Intenta nuevamente.',
                        onRetry: context.read<ProfileCubit>().loadProfile,
                      ),
                      _ => _ProfileContent(state: state),
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    if (profile == null) {
      return const CiervoEmptyState(
        title: 'Perfil no disponible',
        description: 'Vuelve a iniciar sesion para sincronizar tus datos.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        _CompleteProfileBanner(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        _FamilyCard(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const KidsPage())),
        ),
        const SizedBox(height: AppSpacing.lg),
        _AccountActions(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        CiervoButton(
          label: 'Cerrar sesion',
          variant: CiervoButtonVariant.secondary,
          icon: Icons.logout,
          onPressed: () {
            context.read<ExperienceModeCubit>().requireSelection();
            getIt<AuthRepository>().logout();
          },
        ),
      ],
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CiervoCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.family_restroom,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ciervo Kids / Familia',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text('Perfiles Kids, permisos y control parental.'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  static const _maxPhotoBytes = 5 * 1024 * 1024;
  static const _extensions = {'jpg', 'jpeg', 'png', 'webp'};

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
    final upload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vista previa'),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.file(File(photo.path), height: 260, fit: BoxFit.cover),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Subir foto'),
          ),
        ],
      ),
    );
    if (upload == true && mounted) {
      await context.read<ProfileCubit>().uploadPhoto(
        path: photo.path,
        fileName: photo.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = widget.profile;

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: colorScheme.primary,
                    child: profile.photoUrl == null
                        ? Text(
                            profile.initials,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : ClipOval(
                            child: AuthenticatedMediaImage(
                              mediaId: profile.photoUrl!,
                              thumbnail: true,
                              width: 68,
                              height: 68,
                              errorWidget: Text(profile.initials),
                            ),
                          ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: IconButton.filledTonal(
                      tooltip: 'Cambiar foto',
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
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
                      profile.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      profile.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                icon: Icons.phone_outlined,
                label: profile.phone.isEmpty
                    ? 'Telefono pendiente'
                    : profile.phone,
              ),
              _InfoChip(
                icon: Icons.badge_outlined,
                label: profile.ciervoUserCode == null
                    ? 'Ciervo ID no disponible'
                    : 'Ciervo ID: ${profile.ciervoUserCode}',
              ),
              _InfoChip(
                icon: Icons.verified_user_outlined,
                label: _profileStatus(profile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _profileStatus(UserProfile profile) {
    final complete =
        profile.firstName.isNotEmpty &&
        profile.lastName.isNotEmpty &&
        profile.email.isNotEmpty &&
        profile.phone.isNotEmpty;
    return complete ? 'Perfil activo' : 'Perfil por completar';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CompleteProfileBanner extends StatelessWidget {
  const _CompleteProfileBanner({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final complete =
        profile.firstName.isNotEmpty &&
        profile.lastName.isNotEmpty &&
        profile.email.isNotEmpty &&
        profile.phone.isNotEmpty;
    if (complete) {
      return const SizedBox.shrink();
    }
    return CiervoCard(
      child: Row(
        children: [
          const Icon(Icons.edit_note_outlined),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Completa tu perfil para mantener tus datos y reservas actualizados.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.verified_user_outlined,
            title: 'Verificacion KYC',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const KycPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.directions_bus_outlined,
            title: 'Transporte',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TransportPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Mi Wallet',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const WalletPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.mark_email_unread_outlined,
            title: 'Solicitudes de pago',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PaymentRequestsPage(),
              ),
            ),
          ),
          _ActionTile(
            icon: Icons.timeline_outlined,
            title: 'Historial financiero',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FinancialHistoryPage(),
              ),
            ),
          ),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            title: 'Recibos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReceiptsPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Mi Membresia',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MembershipPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.favorite_border,
            title: 'Mis Favoritos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FavoritesPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.local_offer_outlined,
            title: 'Bonos y cupones',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BonusesCatalogPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.card_giftcard_outlined,
            title: 'Mis bonos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MyBonusesPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.redeem_outlined,
            title: 'Mis Beneficios',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const QrWalletPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.savings_outlined,
            title: 'Cashback y puntos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CashbackPage()),
            ),
          ),
          const Divider(),
          _ActionTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Cambiar experiencia Dia / Noche',
            onTap: () => context.push(AppRoutePaths.experienceMode),
          ),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            title: 'Mis pedidos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CustomerOrdersPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.edit_outlined,
            title: 'Editar perfil',
            onTap: () => _openEditProfile(context),
          ),
          _ActionTile(
            icon: Icons.event_available_outlined,
            title: 'Mis reservas',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReservationsPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.qr_code_2_outlined,
            title: 'Mis QR',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const QrWalletPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.delivery_dining_outlined,
            title: 'Trabajar como domiciliario',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DeliveryPage()),
            ),
          ),
          _ActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsPage(),
              ),
            ),
          ),
          _ActionTile(
            icon: Icons.settings_outlined,
            title: 'Configuracion',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(profile: profile),
              ),
            ),
          ),
          _ActionTile(
            icon: Icons.help_outline,
            title: 'Ayuda',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HelpPage()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditProfilePage(profile: profile),
      ),
    );
    if (updated == true && context.mounted) {
      context.read<ProfileCubit>().loadProfile();
    }
  }

  // ignore: unused_element
  void _openComingSoon(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CiervoEmptyState(
              title: 'Funcionalidad disponible próximamente',
              description: 'Estamos conectando este módulo con Ciervo.',
              icon: Icons.construction_outlined,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.profile, required this.isSaving});

  final UserProfile profile;
  final bool isSaving;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.profile.firstName,
    );
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);
  }

  @override
  void didUpdateWidget(covariant _ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id ||
        oldWidget.profile.email != widget.profile.email) {
      _firstNameController.text = widget.profile.firstName;
      _lastNameController.text = widget.profile.lastName;
      _emailController.text = widget.profile.email;
      _phoneController.text = widget.profile.phone;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await context.read<ProfileCubit>().updateProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Datos personales',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _firstNameController,
              validator: (value) =>
                  InputValidators.requiredText(value ?? '', 'tu nombre'),
              decoration: const InputDecoration(
                hintText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _lastNameController,
              validator: (value) =>
                  InputValidators.requiredText(value ?? '', 'tu apellido'),
              decoration: const InputDecoration(
                hintText: 'Apellido',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              validator: (value) => InputValidators.email(value ?? ''),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Correo electronico',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              validator: (value) => InputValidators.phone(value ?? ''),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Telefono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: widget.isSaving ? 'Guardando' : 'Guardar cambios',
              icon: Icons.save_outlined,
              state: widget.isSaving
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
