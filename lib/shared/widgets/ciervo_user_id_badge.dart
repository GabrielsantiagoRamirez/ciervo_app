import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di/service_locator.dart';
import '../../core/kids/selected_kid_context.dart';
import '../../core/session/auth_token_claims.dart';
import '../../core/session/session_manager.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../features/kid_me/data/kid_me_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/presentation/widgets/ciervo_digital_card.dart';

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

Future<String?> resolveCiervoUserCodeForSession() async {
  final session = getIt<SessionManager>();
  if (!session.state.isAuthenticated) return null;
  final token = await session.accessToken();
  if (token == null || token.isEmpty) return null;
  final claims = AuthTokenClaims.fromJwt(token);
  if (claims.routeKind == 'Kid') {
    final result = await getIt<KidMeRepository>().profile();
    return result.when(
      success: (profile) => _pickIdFromMap(profile),
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

String? _pickIdFromMap(Map<String, dynamic> profile) {
  for (final key in const [
    'ciervoUserCode',
    'publicCode',
    'userPublicCode',
    'childPublicCode',
    'id',
  ]) {
    final value = profile[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

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

class _CiervoUserIdBadgeState extends State<CiervoUserIdBadge> {
  String? _id;
  String _label = 'CIERVO ID';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
      return;
    }
    _load();
  }

  Future<void> _load() async {
    if (widget.codeOverride != null && widget.codeOverride!.isNotEmpty) return;
    setState(() => _loading = true);
    final code = await resolveCiervoUserCodeForSession();
    if (!mounted) return;
    if (code == null || code.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final kidContext = getIt<SelectedKidContext>();
    setState(() {
      _id = code;
      _label = widget.labelOverride ??
          (kidContext.isActive
              ? (kidContext.kidName == null
                  ? 'ID MENOR'
                  : 'ID ${kidContext.kidName!.toUpperCase()}')
              : 'CIERVO ID');
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _id == null || _id!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? Colors.black.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor =
        CiervoBrandColors.gold.withValues(alpha: isDark ? 0.5 : 0.65);
    final textColor = isDark ? Colors.white : AppColors.dayText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => copyCiervoId(context, _id!),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: widget.compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.badge_outlined,
                size: widget.compact ? 14 : 16,
                color: CiervoBrandColors.gold,
              ),
              const SizedBox(width: 6),
              Text(
                '$_label · ',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.75),
                  fontSize: widget.compact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                _id!,
                style: TextStyle(
                  color: textColor,
                  fontSize: widget.compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.copy_rounded,
                size: widget.compact ? 12 : 14,
                color: CiervoBrandColors.gold.withValues(alpha: 0.85),
              ),
            ],
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
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: CiervoUserIdBadge(compact: true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
