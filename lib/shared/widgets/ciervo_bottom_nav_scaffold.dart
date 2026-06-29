import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../features/home/presentation/pages/home_page.dart';
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
  Widget build(BuildContext context) {
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
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              indicatorColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundColor: Colors.transparent,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Explorar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum_rounded),
                  label: 'Chat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_available_outlined),
                  selectedIcon: Icon(Icons.event_available_rounded),
                  label: 'Reservas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
