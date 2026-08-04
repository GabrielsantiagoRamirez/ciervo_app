import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/device/device_installation_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/permissions/app_permission_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/realtime/kids_realtime_controller.dart';
import '../../data/repositories/kids_v2_repositories.dart';
import '../../domain/models/kids_v2_models.dart';
import '../controllers/kids_shield_controller.dart';

class KidsQrBootstrapPage extends StatelessWidget {
  const KidsQrBootstrapPage({
    required this.repository,
    required this.installation,
    required this.realtime,
    required this.kidId,
    this.cursorStore,
    super.key,
  });

  final KidsRepository repository;
  final DeviceInstallationService installation;
  final KidsRealtimeRepository realtime;
  final int kidId;
  final KidsRealtimeCursorStore? cursorStore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: installation.deviceId(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('No se pudo identificar el dispositivo.')),
          );
        }
        final deviceId = snapshot.data;
        if (deviceId == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return KidsQrPage(
          repository: repository,
          realtime: realtime,
          kidId: kidId,
          deviceId: deviceId,
          cursorStore: cursorStore,
        );
      },
    );
  }
}

class KidsQrPage extends StatefulWidget {
  const KidsQrPage({
    required this.repository,
    required this.kidId,
    required this.deviceId,
    required this.realtime,
    this.cursorStore,
    super.key,
  });

  final KidsRepository repository;
  final int kidId;
  final String deviceId;
  final KidsRealtimeRepository realtime;
  final KidsRealtimeCursorStore? cursorStore;

  @override
  State<KidsQrPage> createState() => _KidsQrPageState();
}

class _KidsQrPageState extends State<KidsQrPage> with WidgetsBindingObserver {
  final _qr = TextEditingController();
  final _amount = TextEditingController();
  final _scanner = MobileScannerController();
  late final KidsShieldController _shieldController;
  late final KidsRealtimeController _realtimeController;
  StreamSubscription<KidsRealtimeState>? _stateSubscription;
  StreamSubscription<KidsRealtimeEvent>? _eventSubscription;

  KidsQrScanResponse? _session;
  KidsShieldState? _shield;
  KidsPaymentStatusSnapshot? _tracking;
  KidsPaymentStatusSnapshot? _approval;
  String? _error;
  bool _loading = false;
  bool _refreshingProgress = false;
  String? _confirmKey;
  bool _cameraReady = false;
  KidsRealtimeState _realtimeState = const KidsRealtimeState(
    phase: KidsRealtimePhase.stopped,
    cursor: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shieldController = KidsShieldController(widget.repository);
    _realtimeController = KidsRealtimeController(
      repository: widget.realtime,
      cursorStore:
          widget.cursorStore ??
          SecureStorageKidsRealtimeCursorStore(getIt<SecureStorage>()),
    );
    _stateSubscription = _realtimeController.states.listen((state) {
      if (!mounted) return;
      setState(() => _realtimeState = state);
    });
    _eventSubscription = _realtimeController.events.listen((_) {
      unawaited(_refreshProgress());
    });
    _requestCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_realtimeController.resume());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_realtimeController.pause());
    }
  }

  Future<void> _requestCamera() async {
    final granted = await getIt<AppPermissionService>().requestCameraIfNeeded();
    if (mounted) setState(() => _cameraReady = granted);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_loading || _session != null) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .firstOrNull;
    if (value == null) return;
    await _scanner.stop();
    _qr.text = value;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _qr.dispose();
    _amount.dispose();
    unawaited(_stateSubscription?.cancel());
    unawaited(_eventSubscription?.cancel());
    unawaited(_realtimeController.dispose());
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (_qr.text.trim().isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un QR y un monto válido.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _shield = null;
      _tracking = null;
      _approval = null;
    });
    final permissionGranted = await getIt<AppPermissionService>()
        .requestLocationIfNeeded();
    if (!permissionGranted) {
      _finishWithError(
        'La ubicación es obligatoria para validar geocercas de forma segura.',
      );
      return;
    }
    late final AppLocation location;
    try {
      location = await getIt<LocationService>().currentLocation();
    } catch (error) {
      _finishWithError(UserErrorMessage.from(error));
      return;
    }
    final result = await widget.repository.scanQr(
      KidsQrScanRequest(
        kidId: widget.kidId,
        deviceId: widget.deviceId,
        merchantQr: _normalizeMerchantQr(_qr.text),
        amount: amount,
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    );
    if (!mounted) return;
    await result.when(
      success: _handleScannedSession,
      failure: (error) async => _finishWithError(UserErrorMessage.from(error)),
    );
  }

  Future<void> _handleScannedSession(KidsQrScanResponse value) async {
    if (!mounted) return;
    setState(() {
      _session = value;
      _confirmKey =
          'kids-qr-${widget.deviceId}-${DateTime.now().microsecondsSinceEpoch}';
    });
    final shieldResult = await _shieldController.validate(
      value.paymentSessionId,
    );
    if (!mounted) return;
    await shieldResult.when(
      success: (shield) async {
        setState(() {
          _shield = shield;
          _loading = false;
          _error = shield.message;
        });
        await _refreshProgress();
        if (!shield.rejected &&
            !(_tracking?.terminal == true || _approval?.terminal == true)) {
          await _realtimeController.start(value.paymentSessionId);
        }
      },
      failure: (error) async {
        setState(() {
          _loading = false;
          _error = UserErrorMessage.from(error);
        });
      },
    );
  }

  void _finishWithError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
    if (_cameraReady) unawaited(_scanner.start());
  }

  Future<void> _refreshProgress() async {
    final session = _session;
    if (session == null || _refreshingProgress) return;
    _refreshingProgress = true;
    final tracking = await widget.repository.tracking(session.paymentSessionId);
    final approval =
        session.approvalRequired || _shield?.decision.requiresApproval == true
        ? await widget.repository.approval(session.paymentSessionId)
        : null;
    _refreshingProgress = false;
    if (!mounted) return;
    tracking.when(
      success: (value) => _tracking = value,
      failure: (error) => _error = UserErrorMessage.from(error),
    );
    approval?.when(
      success: (value) => _approval = value,
      failure: (error) => _error = UserErrorMessage.from(error),
    );
    setState(() {});
    if (_tracking?.terminal == true || _approval?.terminal == true) {
      await _realtimeController.stop();
    }
  }

  bool get _approvalGranted {
    final approval = _approval;
    if (approval == null) return false;
    final label = approval.statusLabel.toLowerCase();
    return approval.approved == true ||
        label.contains('approved') ||
        label.contains('aprob');
  }

  bool get _canConfirm {
    final shield = _shield;
    if (shield == null || shield.rejected) return false;
    if (shield.decision.requiresApproval) return _approvalGranted;
    return shield.decision.allowed;
  }

  Future<void> _confirm() async {
    final session = _session;
    final key = _confirmKey;
    if (session == null || key == null || !_canConfirm) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.repository.confirmQr(
      KidsQrConfirmRequest(
        paymentSessionId: session.paymentSessionId,
        idempotencyKey: key,
      ),
    );
    if (!mounted) return;
    await result.when(
      success: (value) async {
        setState(() {
          _loading = false;
          _error = 'Pago enviado. Estado: ${value.status}';
        });
        await _refreshProgress();
      },
      failure: (error) async => setState(() {
        _loading = false;
        _error = UserErrorMessage.from(error);
      }),
    );
  }

  void _reset() {
    unawaited(_realtimeController.stop());
    _qr.clear();
    _amount.clear();
    setState(() {
      _session = null;
      _shield = null;
      _tracking = null;
      _approval = null;
      _error = null;
      _confirmKey = null;
    });
    if (_cameraReady) unawaited(_scanner.start());
  }

  String _phaseLabel(KidsRealtimePhase phase) => switch (phase) {
    KidsRealtimePhase.stopped => 'detenido',
    KidsRealtimePhase.catchingUp => 'recuperando eventos',
    KidsRealtimePhase.live => 'en vivo',
    KidsRealtimePhase.pollingFallback => 'respaldo por consultas',
    KidsRealtimePhase.reconnecting => 'reconectando',
    KidsRealtimePhase.paused => 'pausado',
  };

  /// Convierte Ciervo ID de comercio (CV000022) al formato que entiende el API.
  String _normalizeMerchantQr(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;
    final upper = value.toUpperCase();
    if (upper.startsWith('CIERVO://') ||
        upper.startsWith('CIERVO-QR-') ||
        upper.startsWith('CIERVO-MERCHANT-')) {
      return value;
    }
    // CV000022 / CV22 → CIERVO-MERCHANT-{idNumérico}
    final cv = RegExp(r'^CV0*(\d+)$', caseSensitive: false).firstMatch(value);
    if (cv != null) {
      return 'CIERVO-MERCHANT-${cv.group(1)}';
    }
    // Solo dígitos → merchant id numérico
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return 'CIERVO-MERCHANT-$value';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final shield = _shield;
    return Scaffold(
      appBar: AppBar(title: const Text('QR Kids')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 230,
            child: _cameraReady && session == null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      controller: _scanner,
                      onDetect: _onDetect,
                    ),
                  )
                : Center(
                    child: session == null
                        ? OutlinedButton.icon(
                            onPressed: _requestCamera,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Habilitar cámara'),
                          )
                        : const Icon(Icons.qr_code_scanner, size: 72),
                  ),
          ),
          if (_qr.text.isNotEmpty && session == null)
            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('QR leído correctamente'),
            ),
          TextField(
            controller: _qr,
            enabled: !_loading && session == null,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'QR o Ciervo ID del comercio',
              hintText: 'Escanea o escribe CV000022 / CIERVO-MERCHANT-…',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            enabled: !_loading && session == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto'),
          ),
          const SizedBox(height: 16),
          if (session == null)
            FilledButton(
              onPressed: _loading ? null : _scan,
              child: const Text('Validar QR'),
            )
          else ...[
            ListTile(
              title: Text('${session.amount} ${session.currency}'),
              subtitle: Text(
                session.approvalRequired
                    ? 'Requiere aprobación del tutor'
                    : 'Sesión de pago creada',
              ),
            ),
            if (shield != null)
              Card(
                key: const Key('kidsShieldDecision'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shield.rejected
                            ? 'Shield: rejected'
                            : shield.decision.requiresApproval
                            ? 'Shield: requiresApproval'
                            : 'Shield: allowed',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('allowed: ${shield.decision.allowed}'),
                      Text(
                        'requiresApproval: ${shield.decision.requiresApproval}',
                      ),
                      Text('rejected: ${shield.rejected}'),
                      if (shield.decision.ruleMatched != null)
                        Text('ruleMatched: ${shield.decision.ruleMatched}'),
                      if (shield.decision.reason != null)
                        Text('reason: ${shield.decision.reason}'),
                      if (shield.attemptRegistered)
                        const Text('Intento de seguridad registrado'),
                    ],
                  ),
                ),
              ),
            _StatusTile(label: 'Tracking', value: _tracking),
            if (session.approvalRequired ||
                shield?.decision.requiresApproval == true)
              _StatusTile(label: 'Aprobación', value: _approval),
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text('Tiempo real: ${_phaseLabel(_realtimeState.phase)}'),
              subtitle: Text(
                _realtimeState.lastEvent == null
                    ? 'Cursor ${_realtimeState.cursor}'
                    : 'Último evento: ${_realtimeState.lastEvent!.type} · '
                          'cursor ${_realtimeState.cursor}',
              ),
            ),
            FilledButton(
              onPressed: _loading || !_canConfirm ? null : _confirm,
              child: const Text('Confirmar pago'),
            ),
            TextButton(
              onPressed: _reset,
              child: const Text('Escanear otro QR'),
            ),
          ],
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, key: const Key('kidsQrMessage')),
            ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.value});

  final String label;
  final KidsPaymentStatusSnapshot? value;

  @override
  Widget build(BuildContext context) {
    final snapshot = value;
    return ListTile(
      leading: Icon(snapshot?.terminal == true ? Icons.flag : Icons.schedule),
      title: Text(label),
      subtitle: Text(
        snapshot == null
            ? 'Consultando…'
            : '${snapshot.statusLabel}'
                  '${snapshot.reason == null ? '' : ' · ${snapshot.reason}'}',
      ),
    );
  }
}
