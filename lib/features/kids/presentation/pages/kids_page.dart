// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../family_chat/presentation/pages/family_chat_page.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/kids_repository.dart';
import '../cubit/kids_cubit.dart';
import '../cubit/kids_state.dart';
import 'allowed_businesses_page.dart';
import 'allowed_categories_page.dart';
import 'child_spending_limits_page.dart';
import 'child_wallet_page.dart';
import 'child_business_payment_page.dart';
import 'child_form_page.dart';

class KidsPage extends StatelessWidget {
  const KidsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KidsCubit(getIt<KidsRepository>())..loadChildren(),
      child: const _KidsView(),
    );
  }
}

class _KidsView extends StatelessWidget {
  const _KidsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KidsCubit, KidsState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor:
              isDark ? AppColors.background : AppColors.dayBackground,
          appBar: AppBar(title: const Text('Ciervo Kids')),
          body: RefreshIndicator(
            onRefresh: context.read<KidsCubit>().loadChildren,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Administra la experiencia de tus niños en Ciervo.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.status == KidsStatus.initial ||
                    state.status == KidsStatus.loading)
                  const CiervoLoadingState(itemCount: 3)
                else if (state.status == KidsStatus.failure)
                  CiervoErrorState(
                    title: 'No pudimos cargar Ciervo Kids',
                    description: state.errorMessage ?? 'Intenta nuevamente.',
                    onRetry: context.read<KidsCubit>().loadChildren,
                  )
                else if (state.children.isEmpty)
                  _KidsEmptyPanel(
                    onAdd: () => _openChildForm(context),
                  )
                else ...[
                  ...state.children.map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ChildCard(child: child),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CiervoButton(
                    label: 'Agregar menor',
                    icon: Icons.add,
                    onPressed: () => _openChildForm(context),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KidsEmptyPanel extends StatelessWidget {
  const _KidsEmptyPanel({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppColors.surface, AppColors.backgroundAlt]
              : const [Color(0xFFFFFBF0), Color(0xFFF1E5C8)],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(isDark ? 0.16 : 0.22),
                border: Border.all(color: AppColors.primary.withOpacity(0.55)),
              ),
              child: Icon(
                Icons.child_care_outlined,
                size: 38,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aún no tienes niños agregados',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Crea un perfil para administrar permisos, comercios, categorías y experiencia familiar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            CiervoButton(
              label: 'Agregar menor',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});
  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final document = [
      child.documentType,
      child.documentNumber,
    ].where((value) => value != null && value.isNotEmpty).join(' ');
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.child_care_outlined)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  child.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Chip(label: Text(child.isActive ? 'Activo' : 'Inactivo')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${child.age == null ? 'Edad no registrada' : '${child.age} años'}${document.isEmpty ? '' : ' · $document'}',
          ),
          Text('Comercios permitidos: ${child.allowedBusinessesCount}'),
          Text('Categorías permitidas: ${child.allowedCategoriesCount}'),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => KidsDetailPage(childId: child.id),
                ),
              ),
              child: const Text('Gestionar'),
            ),
          ),
        ],
      ),
    );
  }
}

class KidsDetailPage extends StatelessWidget {
  const KidsDetailPage({required this.childId, super.key});
  final String childId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KidsCubit(getIt<KidsRepository>())..loadChild(childId),
      child: BlocBuilder<KidsCubit, KidsState>(
        builder: (context, state) {
          final child = state.selectedChild;
          return Scaffold(
            appBar: AppBar(title: Text(child?.fullName ?? 'Detalle del menor')),
            body: state.status == KidsStatus.loading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CiervoLoadingState(itemCount: 4),
                  )
                : child == null
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: CiervoErrorState(
                      title: 'No pudimos cargar el menor',
                      description: state.errorMessage ?? 'Intenta nuevamente.',
                      onRetry: () =>
                          context.read<KidsCubit>().loadChild(childId),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _DetailsCard(child: child),
                      const SizedBox(height: AppSpacing.md),
                      _PermissionCard(
                        title: 'Categorías permitidas',
                        value: state.overview['allowedCategories'],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PermissionCard(
                        title: 'Comercios permitidos',
                        value: state.overview['allowedBusinesses'],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.family_restroom),
                        label: const Text('Chat entre tutores'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FamilyChatPage(childId: childId),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CiervoButton(
                        label: 'Editar menor',
                        icon: Icons.edit_outlined,
                        onPressed: () async {
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => ChildFormPage(child: child),
                                ),
                              );
                          if (updated == true && context.mounted) {
                            context.read<KidsCubit>().loadChild(childId);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.point_of_sale_outlined),
                        label: const Text('Pagar en comercio'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChildBusinessPaymentPage(
                              childId: childId,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: const Text('Wallet del menor'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChildWalletPage(childId: childId),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.speed_outlined),
                        label: const Text('Límites de gasto'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ChildSpendingLimitsPage(childId: childId),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Gestionar comercios permitidos'),
                        onPressed: () async {
                          final updated = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AllowedBusinessesPage(childId: childId),
                            ),
                          );
                          if (updated == true && context.mounted) {
                            context.read<KidsCubit>().loadChild(childId);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.category_outlined),
                        label: const Text('Gestionar categorías permitidas'),
                        onPressed: () async {
                          final updated = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AllowedCategoriesPage(childId: childId),
                            ),
                          );
                          if (updated == true && context.mounted) {
                            context.read<KidsCubit>().loadChild(childId);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Navegar como este menor'),
                        onPressed: () {
                          getIt<SelectedKidContext>().select(
                            childId,
                            name: child.fullName,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Modo menor activado para ${child.fullName}.',
                              ),
                            ),
                          );
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar menor'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Eliminar menor'),
                              content: Text(
                                '¿Seguro que deseas eliminar el perfil de ${child.fullName}? '
                                'Esta acción no se puede deshacer.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !context.mounted) return;
                          await context.read<KidsCubit>().deleteChild(childId);
                          if (!context.mounted) return;
                          final kidContext = getIt<SelectedKidContext>();
                          if (kidContext.kidId == childId) {
                            kidContext.clear();
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.child});
  final ChildProfile child;
  @override
  Widget build(BuildContext context) => CiervoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Datos básicos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text('Nombre: ${child.fullName}'),
        Text('Edad: ${child.age ?? 'No registrada'}'),
        Text('Relación: ${child.relationshipType}'),
        Text(
          'Documento: ${child.documentType ?? ''} ${child.documentNumber ?? 'No registrado'}',
        ),
        Text('Estado del perfil: ${child.isActive ? 'Activo' : 'Inactivo'}'),
        Text('Comercios permitidos: ${child.allowedBusinessesCount}'),
        Text('Categorías permitidas: ${child.allowedCategoriesCount}'),
      ],
    ),
  );
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.title, required this.value});
  final String title;
  final dynamic value;
  @override
  Widget build(BuildContext context) {
    final items = value is List ? value : const [];
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            const Text('Sin elementos configurados.')
          else
            ...items.map((item) {
              if (item is Map) {
                return Text(
                  '• ${item['name'] ?? item['displayName'] ?? item['category'] ?? 'Permitido'}',
                );
              }
              return Text('• $item');
            }),
        ],
      ),
    );
  }
}

Future<void> _openChildForm(BuildContext context) async {
  final updated = await Navigator.of(
    context,
  ).push<bool>(MaterialPageRoute(builder: (_) => const ChildFormPage()));
  if (updated == true && context.mounted) {
    context.read<KidsCubit>().loadChildren();
  }
}
