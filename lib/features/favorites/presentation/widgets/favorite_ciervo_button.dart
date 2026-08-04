import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/sync/home_feed_refresh.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../core/widgets/membership_upgrade_dialog.dart';
import '../../../memberships/presentation/cubit/membership_cubit.dart';
import '../../domain/entities/favorite_filters.dart';
import '../../domain/repositories/favorites_repository.dart';

/// Favorito con icono ciervo (marca establecimiento como favorito).
class FavoriteCiervoButton extends StatefulWidget {
  const FavoriteCiervoButton({
    required this.businessId,
    this.initialValue = false,
    this.size = 39,
    this.onChanged,
    super.key,
  });

  final String businessId;
  final bool initialValue;
  final double size;
  final ValueChanged<bool>? onChanged;

  @override
  State<FavoriteCiervoButton> createState() => _FavoriteCiervoButtonState();
}

class _FavoriteCiervoButtonState extends State<FavoriteCiervoButton> {
  late bool _favorite;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _favorite = widget.initialValue;
    _syncFromServer();
  }

  @override
  void didUpdateWidget(covariant FavoriteCiervoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId ||
        oldWidget.initialValue != widget.initialValue) {
      _favorite = widget.initialValue;
      _syncFromServer();
    }
  }

  Future<void> _syncFromServer() async {
    if (widget.businessId.isEmpty) return;
    final result = await getIt<FavoritesRepository>().check(widget.businessId);
    if (!mounted) return;
    result.when(
      success: (value) {
        if (_favorite == value) return;
        setState(() => _favorite = value);
        widget.onChanged?.call(value);
      },
      failure: (_) {},
    );
  }

  Future<void> _toggle() async {
    if (_busy || widget.businessId.isEmpty) return;
    if (!_favorite) {
      final membership = context.read<MembershipCubit>().state;
      if (membership.isLoaded) {
        final listResult = await getIt<FavoritesRepository>().list(
          const FavoriteFilters(pageSize: 200),
        );
        final currentCount = listResult.when(
          success: (items) => items.length,
          failure: (_) => 0,
        );
        if (!membership.canAddFavorite(currentCount)) {
          await showMembershipUpgradeDialog(
            context,
            featureLabel: DisplayLabels.membershipFeatureLabel('favorites.max'),
          );
          return;
        }
      }
    }

    setState(() => _busy = true);
    final repository = getIt<FavoritesRepository>();
    final result = _favorite
        ? await repository.remove(widget.businessId)
        : await repository.add(widget.businessId);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        setState(() => _favorite = !_favorite);
        widget.onChanged?.call(_favorite);
        HomeFeedRefresh.instance.favoritesChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _favorite
                  ? 'Establecimiento agregado a favoritos.'
                  : 'Establecimiento quitado de favoritos.',
            ),
          ),
        );
      },
      failure: (error) async {
        if (!await handlePlanLimitError(context, error)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(UserErrorMessage.from(error))),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _busy ? null : _toggle,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: _busy
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _favorite
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.85),
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/branding/ciervo_head_gold.png',
                      width: widget.size * 0.62,
                      height: widget.size * 0.62,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        _favorite ? Icons.pets : Icons.pets_outlined,
                        size: widget.size * 0.5,
                        color: _favorite
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
