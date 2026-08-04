import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/keyboard_utils.dart';
import '../../features/chat/presentation/pages/chat_inbox_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notifications/domain/entities/notification_badges.dart';
import '../../features/notifications/presentation/cubit/notification_badges_cubit.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/qr_hub/presentation/pages/qr_hub_page.dart';
import '../../features/reservations/presentation/pages/reservations_page.dart';
import 'ciervo_logo_mark.dart';

class CiervoBottomNavScaffold extends StatefulWidget {
  const CiervoBottomNavScaffold({super.key});

  @override
  State<CiervoBottomNavScaffold> createState() =>
      _CiervoBottomNavScaffoldState();
}

class _CiervoBottomNavScaffoldState extends State<CiervoBottomNavScaffold> {
  final _homeKey = GlobalKey<HomePageState>();
  final List<int> _tabHistory = [0];
  final Set<int> _activatedTabs = {0};
  int _selectedIndex = 0;

  /// 0 Inicio · 1 Chat · 2 QR Ciervo · 3 Reservas · 4 Perfil
  late final List<Widget> _pages = [
    HomePage(key: _homeKey),
    const ChatInboxPage(),
    const QrHubPage(),
    const ReservationsPage(),
    const ProfilePage(),
  ];

  static const int _chatIndex = 1;
  static const int _qrIndex = 2;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBadgesCubit>().refresh();
  }

  void _selectTab(int index) {
    dismissKeyboard();
    if (index == _selectedIndex) {
      if (index == 0) {
        _homeKey.currentState?.scrollToTopAndRefresh();
      }
      return;
    }
    setState(() {
      _activatedTabs.add(index);
      _tabHistory.add(index);
      _selectedIndex = index;
    });
    context.read<NotificationBadgesCubit>().refresh(force: index == _chatIndex);
  }

  bool get _canPopTabHistory => _tabHistory.length > 1 || _selectedIndex != 0;

  void _popTabHistory() {
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _selectedIndex = _tabHistory.last;
        _activatedTabs.add(_selectedIndex);
      });
      return;
    }
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        _tabHistory
          ..clear()
          ..add(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBadgesCubit, NotificationBadges>(
      builder: (context, badges) {
        return PopScope(
          canPop: !_canPopTabHistory,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_canPopTabHistory) _popTabHistory();
          },
          child: Scaffold(
            body: SafeArea(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    _activatedTabs.contains(i)
                        ? _pages[i]
                        : const SizedBox.shrink(),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black38,
                  color: Theme.of(context).colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  borderRadius: AppRadii.card,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        _CiervoNavItem(
                          label: 'Inicio',
                          selected: _selectedIndex == 0,
                          onTap: () => _selectTab(0),
                          icon: _badgedIcon(Icons.home_outlined, badges.total),
                          selectedIcon: _badgedIcon(
                            Icons.home_rounded,
                            badges.total,
                          ),
                        ),
                        _CiervoNavItem(
                          label: 'Chat',
                          selected: _selectedIndex == 1,
                          onTap: () => _selectTab(1),
                          icon: _badgedIcon(Icons.forum_outlined, badges.chat),
                          selectedIcon: _badgedIcon(
                            Icons.forum_rounded,
                            badges.chat,
                          ),
                        ),
                        _CiervoNavItem(
                          label: 'QR',
                          selected: _selectedIndex == _qrIndex,
                          isQr: true,
                          onTap: () => _selectTab(_qrIndex),
                          icon: const CiervoLogoMark(size: 24),
                          selectedIcon: const CiervoLogoMark(size: 26),
                        ),
                        _CiervoNavItem(
                          label: 'Reservas',
                          selected: _selectedIndex == 3,
                          onTap: () => _selectTab(3),
                          icon: _badgedIcon(
                            Icons.event_available_outlined,
                            badges.reservations,
                          ),
                          selectedIcon: _badgedIcon(
                            Icons.event_available_rounded,
                            badges.reservations,
                          ),
                        ),
                        _CiervoNavItem(
                          label: 'Perfil',
                          selected: _selectedIndex == 4,
                          onTap: () => _selectTab(4),
                          icon: _badgedIcon(
                            Icons.person_outline,
                            badges.promos,
                          ),
                          selectedIcon: _badgedIcon(
                            Icons.person_rounded,
                            badges.promos,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badgedIcon(IconData icon, int count) {
    if (count <= 0) return Icon(icon);
    return Badge(label: Text('$count'), child: Icon(icon));
  }
}

class _CiervoNavItem extends StatelessWidget {
  const _CiervoNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.selectedIcon,
    this.isQr = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget icon;
  final Widget selectedIcon;
  final bool isQr;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = !selected
        ? Colors.transparent
        : isQr
        ? Colors.black
        : scheme.primaryContainer;
    final foregroundColor = !selected
        ? scheme.onSurfaceVariant
        : isQr
        ? Colors.white
        : scheme.onPrimaryContainer;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: scheme.primary.withValues(alpha: 0.12),
          highlightColor: scheme.primary.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 10 : 4,
              vertical: selected ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(color: foregroundColor, size: 24),
                  child: selected ? selectedIcon : icon,
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foregroundColor,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
