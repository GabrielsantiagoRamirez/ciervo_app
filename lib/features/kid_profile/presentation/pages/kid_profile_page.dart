import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../kid_me/data/kid_me_repository.dart';
import '../../../kid_wallet/presentation/pages/kid_wallet_page.dart';

class KidProfilePage extends StatefulWidget {
  const KidProfilePage({super.key});

  @override
  State<KidProfilePage> createState() => _KidProfilePageState();
}

class _KidProfilePageState extends State<KidProfilePage> {
  final _repository = getIt<KidMeRepository>();
  Map<String, dynamic>? _profile;
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
    final result = await _repository.profile();
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _profile = data;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: pagePaddingOf(context),
                children: const [CiervoLoadingState(itemCount: 3)],
              )
            : ListView(
                padding: pagePaddingOf(context),
                children: [
                  if (_error != null) Text(_error!, textAlign: TextAlign.center),
                  CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          child: Text(
                            ((_profile?['name'] ?? 'K').toString().isNotEmpty
                                    ? (_profile?['name'] ?? 'K')
                                        .toString()[0]
                                    : 'K')
                                .toUpperCase(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '${_profile?['name'] ?? 'Menor'}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CiervoButton(
                    label: 'Ver mi wallet',
                    icon: Icons.account_balance_wallet_outlined,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const KidWalletPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CiervoButton(
                    label: 'Cerrar sesión',
                    variant: CiervoButtonVariant.secondary,
                    icon: Icons.logout,
                    onPressed: () => getIt<AuthRepository>().logout(),
                  ),
                ],
              ),
      ),
    );
  }
}
