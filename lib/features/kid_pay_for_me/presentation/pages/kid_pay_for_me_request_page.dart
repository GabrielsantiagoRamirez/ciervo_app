import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../kid_me/data/kid_me_repository.dart';

class KidPayForMeRequestPage extends StatefulWidget {
  const KidPayForMeRequestPage({
    required this.businessId,
    required this.businessName,
    super.key,
  });

  final String businessId;
  final String businessName;

  @override
  State<KidPayForMeRequestPage> createState() => _KidPayForMeRequestPageState();
}

class _KidPayForMeRequestPageState extends State<KidPayForMeRequestPage> {
  final _repository = getIt<KidMeRepository>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  bool _attachLocation = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    double? latitude;
    double? longitude;
    if (_attachLocation) {
      try {
        final location = await getIt<LocationService>().currentLocation();
        latitude = location.latitude;
        longitude = location.longitude;
      } catch (_) {
        // Ubicación opcional; continuar sin ella.
      }
    }

    final result = await _repository.requestPayForMe(
      businessId: widget.businessId,
      amount: amount,
      description: _description.text.trim(),
      latitude: latitude,
      longitude: longitude,
    );

    if (!mounted) return;
    result.when(
      success: (_) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada a tu familia.')),
        );
      },
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _submitting = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedir a mi familia')),
      body: ListView(
        padding: pagePaddingOf(context),
        children: [
          CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.businessName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tu tutor recibirá la solicitud y podrá aprobar o rechazar el pago.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Monto (COP)',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '¿Para qué lo necesitas?',
              hintText: 'Ej: Quiero comprar una hamburguesa',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Incluir mi ubicación'),
            subtitle: const Text('Ayuda a tu familia a saber dónde estás.'),
            value: _attachLocation,
            onChanged: _submitting
                ? null
                : (value) => setState(() => _attachLocation = value),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          CiervoButton(
            label: _submitting ? 'Enviando...' : 'Enviar solicitud',
            icon: Icons.family_restroom,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
