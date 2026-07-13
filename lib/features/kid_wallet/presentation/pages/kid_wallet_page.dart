import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../kid_me/data/kid_me_repository.dart';
import '../../../kid_me/domain/entities/kid_me_profile.dart';
import '../widgets/kid_premium_wallet_dashboard.dart';

class KidWalletPage extends StatefulWidget {
  const KidWalletPage({super.key});

  @override
  State<KidWalletPage> createState() => _KidWalletPageState();
}

class _KidWalletPageState extends State<KidWalletPage> {
  final _repository = getIt<KidMeRepository>();
  Map<String, dynamic>? _wallet;
  KidMeProfile? _profile;
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

    final walletResult = await _repository.wallet();
    final profileResult = await _repository.profile();

    if (!mounted) return;

    walletResult.when(
      success: (wallet) {
        profileResult.when(
          success: (profile) => setState(() {
            _wallet = wallet;
            _profile = profile;
            _loading = false;
          }),
          failure: (error) => setState(() {
            _wallet = wallet;
            _profile = null;
            _loading = false;
            _error = UserErrorMessage.from(error);
          }),
        );
      },
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  List<Map<String, dynamic>> _movements() {
    final raw = _wallet?['lastMovements'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String get _userName => _profile?.greetingName ?? 'amigo';

  double get _availableBalance {
    final available = _num(_wallet?['availableBalance']);
    if (available > 0) return available;
    final balance = _num(_wallet?['balance']);
    final held = _num(_wallet?['heldBalance']);
    return balance - held;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi wallet')),
      body: _loading
          ? const CiervoBrandLoader(message: 'Cargando tu wallet')
          : _error != null && _wallet == null
          ? CiervoErrorState(
              title: 'No pudimos cargar tu wallet',
              description: _error!,
              onRetry: _load,
            )
          : KidPremiumWalletDashboard(
              userName: _userName,
              balance: _availableBalance,
              heldBalance: _num(_wallet?['heldBalance']),
              currency: '${_wallet?['currency'] ?? 'COP'}',
              movements: _movements(),
              onRefresh: _load,
            ),
    );
  }
}
