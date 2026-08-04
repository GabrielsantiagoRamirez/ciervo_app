import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../../core/experience/experience_mode.dart';
import '../../core/experience/experience_mode_cubit.dart';
import '../../core/experience/operational_session_id.dart';
import '../../core/kids/selected_kid_context.dart';
import '../../core/result/result.dart';
import '../../core/session/auth_token_claims.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ciervo_share.dart';
import '../../features/kid_me/data/kid_me_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/presentation/widgets/ciervo_digital_card.dart';
import 'ciervo_logo_mark.dart';

Future<void> shareCiervoId(String id, {String? label}) async {
  if (id.trim().isEmpty) return;
  await CiervoShare.shareText(
    '${label ?? 'CIERVO ID'}: ${id.trim()}',
    subject: 'CIERVO CLUB',
  );
}

Future<void> copyCiervoId(BuildContext context, String id) async {
  if (id.trim().isEmpty) return;
  await Clipboard.setData(ClipboardData(text: id.trim()));
  HapticFeedback.lightImpact();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('ID copiado al portapapeles'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );
}

Future<void> copyCiervoUsername(BuildContext context, String username) async {
  if (username.trim().isEmpty) return;
  await Clipboard.setData(ClipboardData(text: username.trim()));
  HapticFeedback.lightImpact();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Usuario copiado al portapapeles'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );
}

Future<String?> resolveCiervoUserCodeForSession() async {
  final session = getIt<SessionManager>();
  if (!session.state.isAuthenticated) return null;
  final token = await session.accessToken();
  if (token == null || token.isEmpty) return null;
  final claims = AuthTokenClaims.fromJwt(token);
  if (claims.routeKind == 'Kid') {
    final result = await getIt<KidMeRepository>().profile();
    return result.when(
      success: (profile) =>
          profile.ciervoUserCode.isNotEmpty ? profile.ciervoUserCode : null,
      failure: (_) => null,
    );
  }
  final kidContext = getIt<SelectedKidContext>();
  if (kidContext.isActive) return kidContext.kidId;
  final walletId = await getIt<WalletRepository>().myCiervoId();
  if (walletId case Success(value: final identity)) {
    return identity.ciervoUserCode;
  }
  final profile = await getIt<ProfileRepository>().getMe();
  return profile.when(
    success: (user) => user.ciervoUserCode,
    failure: (_) => null,
  );
}

Future<String?> resolveUsernameForSession() async {
  final session = getIt<SessionManager>();
  if (!session.state.isAuthenticated) return null;
  final token = await session.accessToken();
  if (token == null || token.isEmpty) return null;
  final claims = AuthTokenClaims.fromJwt(token);
  if (claims.routeKind == 'Kid') {
    final result = await getIt<KidMeRepository>().profile();
    return result.when(
      success: (profile) {
        final user = profile.username.trim();
        if (user.isEmpty) return null;
        return user.startsWith('@') ? user : '@$user';
      },
      failure: (_) => null,
    );
  }
  final profile = await getIt<ProfileRepository>().getMe();
  return profile.when(
    success: (user) {
      final raw = user.username?.trim();
      if (raw == null || raw.isEmpty) return null;
      return raw.startsWith('@') ? raw : '@$raw';
    },
    failure: (_) => null,
  );
}

/// Logo CIERVO en círculo. Al tocar abre chips de ID y username; se cierra a los 5 s.
class CiervoUserIdBadge extends StatefulWidget {
  const CiervoUserIdBadge({
    super.key,
    this.compact = false,
    this.codeOverride,
    this.labelOverride,
  });

  final bool compact;
  final String? codeOverride;
  final String? labelOverride;

  @override
  State<CiervoUserIdBadge> createState() => _CiervoUserIdBadgeState();
}

class _CiervoUserIdBadgeState extends State<CiervoUserIdBadge>
    with SingleTickerProviderStateMixin {
  static const _autoCollapse = Duration(seconds: 5);

  late final AnimationController _expand;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _collapseTimer;

  String? _id;
  String? _username;
  String _label = 'CIERVO ID';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _expand, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _expand, curve: Curves.easeOutCubic));
    _applyOverrideOrLoad();
    getIt<SelectedKidContext>().addListener(_onKidChanged);
  }

  @override
  void didUpdateWidget(covariant CiervoUserIdBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.codeOverride != widget.codeOverride ||
        oldWidget.labelOverride != widget.labelOverride) {
      _applyOverrideOrLoad();
    }
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _expand.dispose();
    getIt<SelectedKidContext>().removeListener(_onKidChanged);
    super.dispose();
  }

  void _onKidChanged() => _applyOverrideOrLoad();

  void _applyOverrideOrLoad() {
    final override = widget.codeOverride?.trim();
    if (override != null && override.isNotEmpty) {
      setState(() {
        _id = override;
        _label = widget.labelOverride ?? 'CIERVO ID';
        _loading = false;
      });
      unawaited(_loadUsernameOnly());
      return;
    }
    _load();
  }

  Future<void> _loadUsernameOnly() async {
    final username = await resolveUsernameForSession();
    if (!mounted) return;
    setState(() => _username = username);
  }

  Future<void> _load() async {
    if (widget.codeOverride != null && widget.codeOverride!.isNotEmpty) return;
    setState(() => _loading = true);
    final code = await resolveCiervoUserCodeForSession();
    final username = await resolveUsernameForSession();
    if (!mounted) return;
    if (code == null || code.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final kidContext = getIt<SelectedKidContext>();
    setState(() {
      _id = code;
      _username = username;
      _label =
          widget.labelOverride ??
          (kidContext.isActive
              ? (kidContext.kidName == null
                    ? 'ID MENOR'
                    : 'ID ${kidContext.kidName!.toUpperCase()}')
              : 'CIERVO ID');
      _loading = false;
    });
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    if (_expand.isCompleted || _expand.value > 0.5) {
      _collapse();
    } else {
      _open();
    }
  }

  void _open() {
    _collapseTimer?.cancel();
    _expand.forward();
    _collapseTimer = Timer(_autoCollapse, _collapse);
  }

  void _collapse() {
    _collapseTimer?.cancel();
    _collapseTimer = null;
    if (mounted) _expand.reverse();
  }

  void _onIdTap() {
    final id = _id;
    if (id == null) return;
    _collapseTimer?.cancel();
    _collapseTimer = Timer(_autoCollapse, _collapse);
    copyCiervoId(context, id);
  }

  void _onUsernameTap() {
    final user = _username;
    if (user == null || user.isEmpty) return;
    _collapseTimer?.cancel();
    _collapseTimer = Timer(_autoCollapse, _collapse);
    copyCiervoUsername(context, user);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _id == null || _id!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoSize = widget.compact ? 40.0 : 48.0;
    final mode = context.watch<ExperienceModeCubit>().state.mode;
    final hasUsername = _username != null && _username!.isNotEmpty;

    return AnimatedBuilder(
      animation: _expand,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _LogoButton(
              size: logoSize,
              isDark: isDark,
              expanded: _expand.value > 0.05,
              onTap: _toggleExpanded,
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _fade.value,
                child: Opacity(
                  opacity: _fade.value.clamp(0.0, 1.0),
                  child: SlideTransition(
                    position: _slide,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _IdChip(
                            label: _label,
                            id: _id!,
                            modeLabel: mode.label,
                            modeIcon: OperationalSessionId.iconFor(mode: mode),
                            compact: widget.compact,
                            isDark: isDark,
                            onTap: _onIdTap,
                          ),
                          if (hasUsername) ...[
                            const SizedBox(height: 6),
                            _UsernameChip(
                              username: _username!,
                              compact: widget.compact,
                              isDark: isDark,
                              onTap: _onUsernameTap,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LogoButton extends StatelessWidget {
  const _LogoButton({
    required this.size,
    required this.isDark,
    required this.expanded,
    required this.onTap,
  });

  final double size;
  final bool isDark;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = CiervoBrandColors.gold;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.black.withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.94),
            border: Border.all(
              color: gold.withValues(alpha: expanded ? 0.95 : 0.7),
              width: expanded ? 1.6 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: CiervoLogoMark(size: size * 0.62)),
        ),
      ),
    );
  }
}

class _IdChip extends StatelessWidget {
  const _IdChip({
    required this.label,
    required this.id,
    required this.modeLabel,
    required this.modeIcon,
    required this.compact,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String id;
  final String modeLabel;
  final IconData modeIcon;
  final bool compact;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.dayText;
    final gold = CiervoBrandColors.gold;
    final maxW = MediaQuery.sizeOf(context).width * 0.78;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: gold.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,
              minHeight: compact ? 18 : 20,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(modeIcon, size: compact ? 13 : 14, color: gold),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$label · $id · $modeLabel',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.copy_rounded,
                  size: compact ? 12 : 13,
                  color: gold.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsernameChip extends StatelessWidget {
  const _UsernameChip({
    required this.username,
    required this.compact,
    required this.isDark,
    required this.onTap,
  });

  final String username;
  final bool compact;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.dayText;
    final gold = CiervoBrandColors.gold;
    final maxW = MediaQuery.sizeOf(context).width * 0.78;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: gold.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,
              minHeight: compact ? 18 : 20,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.alternate_email_rounded,
                  size: compact ? 13 : 14,
                  color: gold.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    username,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.copy_rounded,
                  size: compact ? 12 : 13,
                  color: gold.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CiervoUserIdOverlay extends StatelessWidget {
  const CiervoUserIdOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: const Center(child: CiervoUserIdBadge(compact: true)),
            ),
          ),
        ),
      ],
    );
  }
}
