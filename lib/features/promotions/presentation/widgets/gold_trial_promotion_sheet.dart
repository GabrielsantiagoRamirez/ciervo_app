import 'package:flutter/material.dart';

import '../../../../core/config/ciervo_legal_urls.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../memberships/presentation/cubit/membership_cubit.dart';
import '../../data/promotions_repository.dart';
import 'package:url_launcher/url_launcher.dart';

/// Muestra la promoción Gold 60 días si el usuario es elegible y no la ha visto.
Future<void> showGoldTrialPromotionIfEligible(BuildContext context) async {
  final repo = getIt<PromotionsRepository>();
  if (await repo.wasDismissed()) return;

  final result = await repo.current();
  if (!context.mounted) return;

  final promotion = result.when(
    success: (value) => value,
    failure: (_) => null,
  );
  if (promotion == null || !promotion.eligible) return;
  if (promotion.slotsRemaining == 0) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    builder: (ctx) => _GoldTrialPromotionSheet(promotion: promotion),
  );
}

class _GoldTrialPromotionSheet extends StatefulWidget {
  const _GoldTrialPromotionSheet({required this.promotion});

  final CurrentPromotion promotion;

  @override
  State<_GoldTrialPromotionSheet> createState() =>
      _GoldTrialPromotionSheetState();
}

class _GoldTrialPromotionSheetState extends State<_GoldTrialPromotionSheet> {
  bool _acceptedTerms = false;
  bool _claiming = false;

  Future<void> _claim() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos para continuar.'),
        ),
      );
      return;
    }
    setState(() => _claiming = true);
    final result = await getIt<PromotionsRepository>().claimGoldTrial(
      acceptedTerms: true,
    );
    if (!mounted) return;
    setState(() => _claiming = false);
    await result.when(
      success: (claim) async {
        await getIt<PromotionsRepository>().markDismissed();
        await getIt<MembershipCubit>().loadFresh();
        if (!mounted) return;
        Navigator.pop(context);
        final expires = claim.expiresAt;
        final expiryLabel = expires == null
            ? ''
            : ' Válido hasta ${expires.toLocal().toString().substring(0, 10)}.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${claim.message}$expiryLabel'),
          ),
        );
      },
      failure: (error) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  Future<void> _dismiss() async {
    await getIt<PromotionsRepository>().markDismissed();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promotion;
    final termsUrl = promo.termsUrl ?? CiervoLegalUrls.terms;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              promo.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (promo.slotsRemaining != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Quedan ${promo.slotsRemaining} cupos',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              promo.description.isNotEmpty
                  ? promo.description
                  : 'Las primeras 200 personas reciben Plan Gold gratis por 60 días. '
                      'Después de ese periodo podrán continuar con su plan pagando la suscripción correspondiente. '
                      'Las transacciones realizadas dentro de la plataforma podrán tener una comisión del 1%.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Al continuar aceptas los términos. Las transacciones en la plataforma '
              'podrán tener una comisión del 1%.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acceptedTerms,
              onChanged: _claiming
                  ? null
                  : (value) => setState(() => _acceptedTerms = value == true),
              title: const Text('Acepto los términos de la promoción'),
              subtitle: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(termsUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'Ver términos y condiciones',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CiervoButton(
              label: _claiming ? 'Activando...' : 'Activar Plan Gold',
              icon: Icons.workspace_premium_outlined,
              state: _claiming
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: _claiming ? null : _claim,
            ),
            TextButton(
              onPressed: _claiming ? null : _dismiss,
              child: const Text('Ahora no'),
            ),
          ],
        ),
      ),
    );
  }
}
