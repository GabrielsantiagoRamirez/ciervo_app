import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../users/presentation/pages/user_search_page.dart';
import '../../data/secure_shipment_repository.dart';
import 'secure_shipment_detail_page.dart';

class SecureShipmentCreatePage extends StatefulWidget {
  const SecureShipmentCreatePage({super.key});

  @override
  State<SecureShipmentCreatePage> createState() =>
      _SecureShipmentCreatePageState();
}

class _SecureShipmentCreatePageState extends State<SecureShipmentCreatePage> {
  final _repository = getIt<SecureShipmentRepository>();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _product = TextEditingController();
  final _shipping = TextEditingController();
  final _insurance = TextEditingController();
  final _tax = TextEditingController();
  final _commission = TextEditingController();
  final _total = TextEditingController();
  final _tracking = TextEditingController();
  final _carrier = TextEditingController();
  final _notes = TextEditingController();
  String? _receiverUserId;
  String? _receiverName;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    _product.dispose();
    _shipping.dispose();
    _insurance.dispose();
    _tax.dispose();
    _commission.dispose();
    _total.dispose();
    _tracking.dispose();
    _carrier.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? _parse(String text) {
    final v = double.tryParse(text.replaceAll(',', '').trim());
    return v != null && v > 0 ? v : null;
  }

  void _recalculateTotal() {
    final parts = [
      _parse(_product.text),
      _parse(_shipping.text),
      _parse(_insurance.text),
      _parse(_tax.text),
      _parse(_commission.text),
    ].whereType<double>();
    final sum = parts.fold<double>(0, (a, b) => a + b);
    if (sum > 0) {
      _total.text = sum.toStringAsFixed(0);
    }
  }

  Future<void> _pickReceiver() async {
    final userId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const UserSearchPage(selectMode: true)),
    );
    if (userId == null || !mounted) return;
    setState(() {
      _receiverUserId = userId;
      _receiverName = 'Contacto CIERVO';
    });
  }

  Future<void> _submit() async {
    final total = _parse(_total.text);
    if (_origin.text.trim().isEmpty ||
        _destination.text.trim().isEmpty ||
        total == null) {
      setState(() => _error = 'Completa origen, destino y monto total.');
      return;
    }
    if (_receiverUserId == null) {
      setState(() => _error = 'Selecciona quién recibirá el envío.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await _repository.createShipment(
      originAddress: _origin.text.trim(),
      destinationAddress: _destination.text.trim(),
      totalAmount: total,
      receiverUserId: _receiverUserId,
      receiverName: _receiverName,
      productValue: _parse(_product.text),
      shippingValue: _parse(_shipping.text),
      insuranceValue: _parse(_insurance.text),
      taxValue: _parse(_tax.text),
      commissionValue: _parse(_commission.text),
      logisticsCompany: _carrier.text.trim(),
      trackingNumber: _tracking.text.trim(),
      observations: _notes.text.trim(),
    );

    if (!mounted) return;
    result.when(
      success: (shipment) {
        Navigator.of(context).pop(true);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SecureShipmentDetailPage(publicId: shipment.publicId),
          ),
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
      appBar: AppBar(title: const Text('Nuevo envío seguro')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protege tu venta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'El comprador retiene el pago en su wallet hasta confirmar la entrega con PIN dual.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Comprador / receptor'),
            subtitle: Text(
              _receiverName ?? 'Busca un contacto en CIERVO',
            ),
            trailing: const Icon(Icons.person_search_outlined),
            onTap: _pickReceiver,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _origin,
            decoration: const InputDecoration(labelText: 'Dirección de origen'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _destination,
            decoration: const InputDecoration(labelText: 'Dirección de destino'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Desglose del monto', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _MoneyField(controller: _product, label: 'Valor producto', onChanged: _recalculateTotal),
          _MoneyField(controller: _shipping, label: 'Envío', onChanged: _recalculateTotal),
          _MoneyField(controller: _insurance, label: 'Seguro', onChanged: _recalculateTotal),
          _MoneyField(controller: _tax, label: 'Impuestos', onChanged: _recalculateTotal),
          _MoneyField(controller: _commission, label: 'Comisión', onChanged: _recalculateTotal),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _total,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Total (COP)',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _carrier,
            decoration: const InputDecoration(labelText: 'Transportadora (opcional)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _tracking,
            decoration: const InputDecoration(labelText: 'Guía / tracking (opcional)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notas (opcional)'),
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
            label: _submitting ? 'Creando envío...' : 'Crear envío seguro',
            icon: Icons.verified_user_outlined,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, prefixText: '\$ '),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
