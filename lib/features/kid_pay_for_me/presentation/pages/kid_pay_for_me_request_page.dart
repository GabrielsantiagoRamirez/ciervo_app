import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../kid_me/data/kid_me_repository.dart';
import '../../../kids_v2/data/repositories/kids_v2_repositories.dart'
    as kids_v2;
import '../../../kids_v2/domain/models/kids_v2_models.dart';

class KidPayForMeRequestPage extends StatefulWidget {
  const KidPayForMeRequestPage({
    this.businessId,
    this.businessName,
    this.commerceCiervoId,
    super.key,
  });

  final String? businessId;
  final String? businessName;
  final String? commerceCiervoId;

  @override
  State<KidPayForMeRequestPage> createState() => _KidPayForMeRequestPageState();
}

class _KidPayForMeRequestPageState extends State<KidPayForMeRequestPage> {
  final _repository = getIt<KidMeRepository>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  List<Map<String, dynamic>> _tutors = const [];
  String? _selectedTutorCode;
  String? _familyConversationId;
  final String _idempotencyKey = IdempotencyKey.generate('kid-pinduck');
  String _currency = 'COP';
  String _country = 'CO';
  bool _shareInChat = true;
  bool _loadingMeta = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_onFieldsChanged);
    _description.addListener(_onFieldsChanged);
    _loadMeta();
  }

  void _onFieldsChanged() => setState(() {});

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    final description = _description.text.trim();
    return !_submitting &&
        amount != null &&
        amount > 0 &&
        description.length >= 3 &&
        _selectedTutorCode != null;
  }

  Future<void> _loadMeta() async {
    final profileResult = await _repository.profile();
    final tutorsResult = await _repository.tutors();
    final familyChatResult = await _repository.familyChat();
    if (!mounted) return;
    profileResult.when(
      success: (profile) {
        final code = profile.countryCode.trim().toUpperCase();
        _country = code.isNotEmpty ? code : 'CO';
        _currency = CountryRegistration.currencyForCountry(_country);
      },
      failure: (_) {},
    );
    tutorsResult.when(
      success: (items) => setState(() {
        _tutors = items;
        if (items.isNotEmpty) {
          final primary = items.cast<Map<String, dynamic>>().firstWhere(
            (item) => item['isPrimaryGuardian'] == true,
            orElse: () => items.first,
          );
          final code = '${primary['ciervoUserCode'] ?? ''}'.trim();
          _selectedTutorCode = code.isEmpty ? null : code;
        }
        _loadingMeta = false;
      }),
      failure: (_) => setState(() => _loadingMeta = false),
    );
    familyChatResult.when(
      success: (conversation) =>
          _familyConversationId = conversation.id.toString(),
      failure: (_) {},
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final amount = double.parse(_amount.text.replaceAll(',', '').trim());

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await getIt<kids_v2.KidsRepository>().createPaymentRequest(
      PayForMeCommand(
        businessId: int.tryParse(widget.businessId ?? ''),
        amount: amount,
        idempotencyKey: _idempotencyKey,
        description: _description.text.trim(),
        currency: _currency,
        payerCiervoUserCode: _selectedTutorCode,
        chatConversationId: _shareInChat
            ? int.tryParse(_familyConversationId ?? '')
            : null,
      ),
    );

    if (!mounted) return;
    result.when(
      success: (_) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solicitud enviada. Tu tutor la verá en el chat familiar.',
            ),
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
      appBar: AppBar(title: const Text('Pinduck')),
      body: SafeArea(
        child: ListView(
          padding: pagePaddingOf(context),
          children: [
            CiervoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.businessName != null) ...[
                    Text(
                      widget.businessName!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(
                    'Tu tutor recibirá la solicitud en el chat familiar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Moneda de la solicitud: $_currency '
                    '(${CountryRegistration.countryLabel(_country)}).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (widget.businessId == null ||
                      widget.businessId!.trim().isEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Para pagar en un comercio, ábrelo desde Comercios y '
                      'usa Pinduck allí. Así el tutor ve el lugar exacto.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_loadingMeta)
              const LinearProgressIndicator()
            else if (_tutors.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: _selectedTutorCode,
                decoration: const InputDecoration(
                  labelText: 'Tutor',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
                items: [
                  ..._tutors.map(
                    (tutor) => DropdownMenuItem<String?>(
                      value: '${tutor['ciervoUserCode']}',
                      child: Text(
                        '${tutor['displayName'] ?? tutor['name'] ?? 'Tutor'}',
                      ),
                    ),
                  ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _selectedTutorCode = value),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                suffixText: _currency,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Quiero comprar una hamburguesa',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compartir en chat familiar'),
              subtitle: const Text('Publica un mensaje con el detalle.'),
              value: _shareInChat,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _shareInChat = value),
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
              icon: Icons.send_outlined,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
