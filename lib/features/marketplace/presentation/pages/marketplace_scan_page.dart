import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../domain/repositories/marketplace_repository.dart';

class MarketplaceScanPage extends StatefulWidget {
  const MarketplaceScanPage({super.key});

  @override
  State<MarketplaceScanPage> createState() => _MarketplaceScanPageState();
}

class _MarketplaceScanPageState extends State<MarketplaceScanPage> {
  final _controller = MobileScannerController();
  final _manualController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _handle(String raw) async {
    final code = raw.trim();
    if (code.isEmpty || _busy) return;
    setState(() => _busy = true);
    await _controller.stop();

    double? lat;
    double? lng;
    try {
      final location = await getIt<LocationService>().currentLocation();
      lat = location.latitude;
      lng = location.longitude;
    } catch (_) {}

    final result = await getIt<MarketplaceRepository>().scanQr(
      qrCode: code,
      latitude: lat,
      longitude: lng,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    await result.when(
      success: (store) async {
        if (!mounted) return;
        context.pushReplacement('/marketplace/stores/${store.storeId}');
      },
      failure: (error) async {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
        await _controller.start();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear comercio')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final value = capture.barcodes
                        .map((b) => b.rawValue)
                        .whereType<String>()
                        .firstOrNull;
                    if (value != null) {
                      _handle(value);
                    }
                  },
                ),
                if (_busy)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                TextField(
                  controller: _manualController,
                  decoration: const InputDecoration(
                    labelText: 'CIERVO ID o código',
                    hintText: 'ciervo://business/22',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CiervoButton(
                  label: 'Abrir comercio',
                  icon: Icons.storefront_outlined,
                  onPressed: () => _handle(_manualController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
