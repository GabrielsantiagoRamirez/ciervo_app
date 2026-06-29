import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_spacing.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notifications/domain/entities/notification_badges.dart';
import '../../features/notifications/presentation/cubit/notification_badges_cubit.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reservations/presentation/pages/reservations_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/vakupli/presentation/pages/vakupli_page.dart';

class CiervoBottomNavScaffold extends StatefulWidget {
  const CiervoBottomNavScaffold({super.key});

  @override
  State<CiervoBottomNavScaffold> createState() =>
      _CiervoBottomNavScaffoldState();
}

class _CiervoBottomNavScaffoldState extends State<CiervoBottomNavScaffold> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    HomePage(),
    SearchPage(),
    VakupliPage(),
    ReservationsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<NotificationBadgesCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBadgesCubit, NotificationBadges>(
      builder: (context, badges) {
        return Scaffold(
          body: SafeArea(child: _pages[_selectedIndex]),
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
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: NavigationBar(
                  height: 68,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                    context.read<NotificationBadgesCubit>().refresh();
                  },
                  indicatorColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundColor: Colors.transparent,
                  destinations: [
                    NavigationDestination(
                      icon: _badgedIcon(Icons.home_outlined, badges.total),
                      selectedIcon: _badgedIcon(Icons.home_rounded, badges.total),
                      label: 'Inicio',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore_rounded),
                      label: 'Explorar',
                    ),
                    NavigationDestination(
                      icon: _badgedIcon(Icons.forum_outlined, badges.chat),
                      selectedIcon: _badgedIcon(Icons.forum_rounded, badges.chat),
                      label: 'Chat',
                    ),
                    NavigationDestination(
                      icon: _badgedIcon(
                        Icons.event_available_outlined,
                        badges.reservations,
                      ),
                      selectedIcon: _badgedIcon(
                        Icons.event_available_rounded,
                        badges.reservations,
                      ),
                      label: 'Reservas',
                    ),
                    NavigationDestination(
                      icon: _badgedIcon(Icons.person_outline, badges.promos),
                      selectedIcon: _badgedIcon(Icons.person_rounded, badges.promos),
                      label: 'Perfil',
                    ),
                  ],
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
