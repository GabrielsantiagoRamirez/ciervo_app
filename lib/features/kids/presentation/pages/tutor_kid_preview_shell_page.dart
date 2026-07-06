import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../family_chat/presentation/pages/family_chat_page.dart';
import '../../../kid_businesses/presentation/pages/kid_businesses_page.dart';
import '../../../kid_wallet/presentation/pages/kid_wallet_page.dart';
import '../../domain/repositories/kids_repository.dart';
import 'allowed_businesses_page.dart';
import 'child_wallet_page.dart';

/// Vista del tutor que replica la experiencia del menor.
class TutorKidPreviewShellPage extends StatefulWidget {
  const TutorKidPreviewShellPage({
    required this.childId,
    required this.childName,
    super.key,
  });

  final String childId;
  final String childName;

  @override
  State<TutorKidPreviewShellPage> createState() =>
      _TutorKidPreviewShellPageState();
}

class _TutorKidPreviewShellPageState extends State<TutorKidPreviewShellPage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    getIt<SelectedKidContext>().select(widget.childId, name: widget.childName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Material(
            color: AppColors.primary.withValues(alpha: 0.14),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Vista previa: ${widget.childName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        getIt<SelectedKidContext>().clear();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _pageForIndex(_index)),
        ],
      ),
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
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }

  Widget _pageForIndex(int index) => switch (index) {
        0 => _TutorKidPreviewHome(
            childId: widget.childId,
            childName: widget.childName,
          ),
        1 => AllowedBusinessesPage(childId: widget.childId),
        2 => FamilyChatPage(childId: widget.childId),
        3 => ChildWalletPage(childId: widget.childId),
        _ => _TutorKidPreviewHome(
            childId: widget.childId,
            childName: widget.childName,
          ),
      };
}

class _TutorKidPreviewHome extends StatefulWidget {
  const _TutorKidPreviewHome({
    required this.childId,
    required this.childName,
  });

  final String childId;
  final String childName;

  @override
  State<_TutorKidPreviewHome> createState() => _TutorKidPreviewHomeState();
}

class _TutorKidPreviewHomeState extends State<_TutorKidPreviewHome> {
  final _repository = getIt<KidsRepository>();
  Map<String, dynamic>? _wallet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.childWallet(widget.childId);
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _wallet = data;
        _loading = false;
      }),
      failure: (_) => setState(() => _loading = false),
    );
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    final balance = _num(
      _wallet?['availableBalance'] ?? _wallet?['balance'],
    );
    final currency = '${_wallet?['currency'] ?? 'COP'}';

    return Scaffold(
      appBar: AppBar(title: Text('Hola, ${widget.childName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo disponible',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '$currency ${balance.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Comercios permitidos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          AllowedBusinessesPage(childId: widget.childId),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Wallet del menor'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChildWalletPage(childId: widget.childId),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: const Text('Vista comercios Kids'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const KidBusinessesPage(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Vista wallet Kids (app menor)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const KidWalletPage(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
