import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../kid_businesses/presentation/pages/kid_businesses_page.dart';
import '../../../kid_family_chat/presentation/pages/kid_family_page.dart';
import '../../../kid_me/data/kid_me_repository.dart';
import '../../../kid_profile/presentation/pages/kid_profile_page.dart';
import '../../../kid_wallet/presentation/pages/kid_wallet_page.dart';

class KidShellPage extends StatefulWidget {
  const KidShellPage({super.key});

  @override
  State<KidShellPage> createState() => _KidShellPageState();
}

class _KidShellPageState extends State<KidShellPage> {
  int _index = 0;

  Widget _pageForIndex(int index) => switch (index) {
        0 => const KidHomePage(),
        1 => const KidBusinessesPage(),
        2 => const KidFamilyPage(),
        3 => const KidProfilePage(),
        _ => const KidHomePage(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pageForIndex(_index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Comercios',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(Icons.family_restroom),
            label: 'Familia',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Yo',
          ),
        ],
      ),
    );
  }
}

class KidHomePage extends StatefulWidget {
  const KidHomePage({super.key});

  @override
  State<KidHomePage> createState() => _KidHomePageState();
}

class _KidHomePageState extends State<KidHomePage> {
  final _repository = getIt<KidMeRepository>();
  Map<String, dynamic>? _home;
  bool _loading = true;
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
    final result = await _repository.home();
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _home = data;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    final name = (_home?['name'] ?? 'amigo').toString();
    final wallet = _home?['wallet'];
    final balance = wallet is Map
        ? _num(wallet['balance'] ?? wallet['availableBalance'])
        : 0.0;
    final businesses = _home?['allowedBusinessesCount'] ?? 0;
    final unread = _home?['unreadFamilyMessages'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Ciervo Kids')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: pagePaddingOf(context),
                children: const [CiervoLoadingState(itemCount: 3)],
              )
            : _error != null
            ? ListView(
                padding: pagePaddingOf(context),
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              )
            : ListView(
                padding: pagePaddingOf(context),
                children: [
                  Text(
                    'Hola, $name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo disponible',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'COP ${balance.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuickTile(
                    icon: Icons.storefront_outlined,
                    title: 'Comercios permitidos',
                    subtitle: '$businesses disponibles',
                  ),
                  _QuickTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Mensajes de familia',
                    subtitle: unread == 0
                        ? 'Sin mensajes nuevos'
                        : '$unread sin leer',
                  ),
                ],
              ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CiervoCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}
