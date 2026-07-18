import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/device/device_installation_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../kid_me/data/kid_me_repository.dart';
import '../../../kid_me/domain/entities/kid_me_profile.dart';
import '../../../kids_v2/data/repositories/kids_v2_repositories.dart'
    as kids_v2;
import '../../../kids_v2/domain/models/kids_v2_models.dart' as kids_v2_models;
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
  String? _typedName;
  kids_v2_models.KidNfcStatus? _nfcStatus;
  String? _deviceId;
  String? _firebaseUid;
  bool _showRegistrationIds = false;
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
    final typedRepository = getIt<kids_v2.KidsRepository>();
    final typedSettingsResult = await typedRepository.settings();
    final typedProfileResult = await typedRepository.profile();
    final typedNfcResult = await typedRepository.nfcStatus();
    final deviceId = await getIt<DeviceInstallationService>().deviceId();
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final legacySettingsResult = await _repository.settings();

    if (!mounted) return;

    Map<String, dynamic>? settings;
    typedSettingsResult.when(
      success: (value) => settings = {
        'wallet': value.rawWallet,
        'spendingLimits': value.rawLimits,
        'schedule': value.rawSchedule,
        'categories': value.categories,
        'geofences': value.geofences,
      },
      failure: (_) {
        legacySettingsResult.when(
          success: (value) => settings = value,
          failure: (_) {},
        );
      },
    );
    typedProfileResult.when(
      success: (value) => _typedName = value.name,
      failure: (_) {},
    );
    typedNfcResult.when(
      success: (value) => _nfcStatus = value,
      failure: (error) => _error ??= UserErrorMessage.from(error),
    );
    _deviceId = deviceId;
    _firebaseUid = firebaseUid;

    walletResult.when(
      success: (wallet) {
        final mergedWallet = Map<String, dynamic>.from(wallet);
        final settingsWallet = settings?['wallet'];
        if (settingsWallet is Map) {
          for (final entry in settingsWallet.entries) {
            mergedWallet.putIfAbsent('${entry.key}', () => entry.value);
          }
        }
        mergedWallet.putIfAbsent(
          'spendingLimits',
          () => settings?['spendingLimits'] ?? settings?['limits'],
        );
        mergedWallet.putIfAbsent(
          'securityStatus',
          () => settings?['securityStatus'] ?? settings?['shield'],
        );
        profileResult.when(
          success: (profile) => setState(() {
            _wallet = mergedWallet;
            _profile = profile;
            _loading = false;
          }),
          failure: (error) => setState(() {
            _wallet = mergedWallet;
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

  String get _userName => _typedName?.trim().isNotEmpty == true
      ? _typedName!
      : _profile?.greetingName ?? 'amigo';

  double get _availableBalance {
    final available = _num(_wallet?['availableBalance']);
    if (available > 0) return available;
    final balance = _num(_wallet?['balance']);
    final held = _num(_wallet?['heldBalance']);
    return balance - held;
  }

  double get _monthlyLimit {
    final limits = _wallet?['spendingLimits'];
    return _num(
      _wallet?['monthlyLimit'] ??
          _wallet?['monthlySpendingLimit'] ??
          (limits is Map ? limits['monthlyLimit'] ?? limits['monthly'] : null),
    );
  }

  double get _monthlySpent {
    return _num(
      _wallet?['monthlySpent'] ??
          _wallet?['spentThisMonth'] ??
          _wallet?['monthSpent'],
    );
  }

  bool? get _shieldLocked {
    final security = _wallet?['securityStatus'];
    final raw =
        _wallet?['status'] ??
        _wallet?['securityState'] ??
        (security is Map ? security['status'] : null);
    if (raw == null || '$raw'.trim().isEmpty) return null;
    final status = '$raw'.toLowerCase();
    if (status.contains('lock') || status.contains('block')) return true;
    if (status.contains('active') ||
        status.contains('unlock') ||
        status.contains('enabled')) {
      return false;
    }
    return null;
  }

  bool get _needsNfcPreregistration {
    final nfc = _nfcStatus;
    if (nfc == null || nfc.enabled) return false;
    final status = nfc.status?.toLowerCase() ?? '';
    return status.isEmpty ||
        status.contains('pending') ||
        status.contains('pendiente') ||
        status.contains('not_approved') ||
        status.contains('no aprobado') ||
        status.contains('reject');
  }

  String _masked(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'No disponible';
    if (_showRegistrationIds || text.length <= 8) return text;
    return '${text.substring(0, 4)}••••${text.substring(text.length - 4)}';
  }

  Future<void> _copyId(String? value, String label) async {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copiado de forma segura.')));
  }

  String get _cardLast4 {
    final card = _wallet?['card'];
    final raw =
        _wallet?['cardLast4'] ??
        _wallet?['last4'] ??
        (card is Map ? card['last4'] ?? card['lastFour'] : null);
    final digits = '$raw'.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 4 ? digits.substring(digits.length - 4) : '••••';
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
          : Column(
              children: [
                if (_nfcStatus != null)
                  ListTile(
                    key: const Key('kidNfcStatus'),
                    leading: const Icon(Icons.nfc),
                    title: Text(
                      _nfcStatus!.enabled ? 'NFC habilitado' : 'NFC pendiente',
                    ),
                    subtitle: Text(
                      _nfcStatus!.status ?? 'Esperando aprobación',
                    ),
                  ),
                if (_needsNfcPreregistration)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datos para prerregistro',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Text(
                            'Compártelos solo con tu tutor o soporte oficial.',
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Device ID'),
                            subtitle: Text(_masked(_deviceId)),
                            trailing: IconButton(
                              tooltip: 'Copiar Device ID',
                              onPressed: _deviceId == null
                                  ? null
                                  : () => _copyId(_deviceId, 'Device ID'),
                              icon: const Icon(Icons.copy),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Firebase UID'),
                            subtitle: Text(_masked(_firebaseUid)),
                            trailing: IconButton(
                              tooltip: 'Copiar Firebase UID',
                              onPressed: _firebaseUid == null
                                  ? null
                                  : () => _copyId(_firebaseUid, 'Firebase UID'),
                              icon: const Icon(Icons.copy),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(
                              () =>
                                  _showRegistrationIds = !_showRegistrationIds,
                            ),
                            icon: Icon(
                              _showRegistrationIds
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            label: Text(
                              _showRegistrationIds
                                  ? 'Ocultar identificadores'
                                  : 'Mostrar identificadores',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: KidPremiumWalletDashboard(
                    userName: _userName,
                    balance: _availableBalance,
                    heldBalance: _num(_wallet?['heldBalance']),
                    currency: '${_wallet?['currency'] ?? 'COP'}',
                    movements: _movements(),
                    monthlySpent: _monthlySpent,
                    monthlyLimit: _monthlyLimit,
                    shieldLocked: _shieldLocked,
                    cardLast4: _cardLast4,
                    photoUrl: _profile?.photoUrl ?? '',
                    onRefresh: _load,
                  ),
                ),
              ],
            ),
    );
  }
}
