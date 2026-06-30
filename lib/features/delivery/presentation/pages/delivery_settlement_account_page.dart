import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../catalogs/data/catalog_repository.dart';
import '../../../catalogs/domain/entities/settlement_catalog.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';

class DeliverySettlementAccountPage extends StatefulWidget {
  const DeliverySettlementAccountPage({super.key, this.profile});

  final DeliveryProfile? profile;

  @override
  State<DeliverySettlementAccountPage> createState() =>
      _DeliverySettlementAccountPageState();
}

class _DeliverySettlementAccountPageState
    extends State<DeliverySettlementAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumber = TextEditingController();
  final _holderName = TextEditingController();
  final _documentNumber = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _walletIdentifier = TextEditingController();

  List<SettlementCountry> _countries = const [];
  List<BankOption> _banks = const [];
  List<SettlementMethodOption> _methods = const [];
  SettlementPolicy _policy = SettlementPolicy.fallback;
  DeliverySettlementAccountDetails? _current;

  String? _countryCode;
  String? _methodCode;
  String? _bankId;
  String? _accountType;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _countryUnsupported = false;

  SettlementMethodOption? get _selectedMethod {
    if (_methodCode == null) return null;
    for (final method in _methods) {
      if (method.code == _methodCode) return method;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _accountNumber.dispose();
    _holderName.dispose();
    _documentNumber.dispose();
    _phoneNumber.dispose();
    _walletIdentifier.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _countryUnsupported = false;
    });

    final catalog = getIt<CatalogRepository>();
    final delivery = getIt<DeliveryRepository>();
    final profileResult = await getIt<ProfileRepository>().getMe();
    final profileCountry = profileResult.when(
      success: (profile) => profile.countryCode,
      failure: (_) => null,
    );

    final countriesResult = await catalog.settlementCountries();
    final accountResult = await delivery.settlementAccount();

    var countryCode = profileCountry?.trim();
    countriesResult.when(
      success: (countries) {
        _countries = countries;
        if ((countryCode ?? '').isEmpty) {
          countryCode = countries.isNotEmpty ? countries.first.code : 'CO';
        }
        if (countries.isNotEmpty &&
            !countries.any((c) => c.code == countryCode)) {
          _countryUnsupported = true;
          _error =
              'Tu país no está disponible para configurar liquidaciones todavía.';
        }
      },
      failure: (error) {
        if ((countryCode ?? '').isEmpty) {
          countryCode = 'CO';
        }
        _error ??= UserErrorMessage.from(error);
      },
    );

    _countryCode = countryCode ?? 'CO';

    if (_countryUnsupported) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final banks = await catalog.banks(country: _countryCode!);
    final methods = await catalog.settlementMethods(country: _countryCode!);
    final policy = await catalog.settlementPolicy(country: _countryCode!);

    if (!mounted) return;

    setState(() {
      accountResult.when(
        success: (value) => _current = value,
        failure: (error) => _error = UserErrorMessage.from(error),
      );

      banks.when(
        success: (value) => _banks = value,
        failure: (error) {
          _banks = const [];
          _error ??= UserErrorMessage.from(error);
        },
      );

      methods.when(
        success: (value) {
          _methods = value;
          _methodCode = _current?.settlementMethod ??
              (value.isNotEmpty ? value.first.code : null);
        },
        failure: (error) {
          _methods = const [];
          _error ??= UserErrorMessage.from(error);
        },
      );

      _policy = policy.when(
        success: (value) => value,
        failure: (_) => SettlementPolicy.fallback,
      );

      _loading = false;
    });
  }

  Future<void> _onCountryChanged(String? code) async {
    if (code == null || code == _countryCode) return;
    setState(() {
      _countryCode = code;
      _loading = true;
      _bankId = null;
      _methodCode = null;
      _methods = const [];
      _banks = const [];
    });
    final catalog = getIt<CatalogRepository>();
    final banks = await catalog.banks(country: code);
    final methods = await catalog.settlementMethods(country: code);
    final policy = await catalog.settlementPolicy(country: code);
    if (!mounted) return;
    setState(() {
      banks.when(
        success: (value) => _banks = value,
        failure: (error) => _error = UserErrorMessage.from(error),
      );
      methods.when(
        success: (value) {
          _methods = value;
          _methodCode = value.isNotEmpty ? value.first.code : null;
        },
        failure: (error) => _error = UserErrorMessage.from(error),
      );
      _policy = policy.when(
        success: (value) => value,
        failure: (_) => SettlementPolicy.fallback,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cuenta de liquidación')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_countryUnsupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cuenta de liquidación')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CiervoErrorState(
            title: 'País no disponible',
            description: _error ?? 'No podemos configurar liquidaciones en tu país.',
            onRetry: _load,
          ),
        ),
      );
    }

    if (_methods.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cuenta de liquidación')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CiervoEmptyState(
            title: 'Sin métodos disponibles',
            description:
                _error ??
                'No hay métodos de liquidación para tu país en este momento.',
            icon: Icons.account_balance_outlined,
            actionLabel: 'Reintentar',
            onAction: _load,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta de liquidación')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_current != null) _StatusCard(details: _current!),
              CiervoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Política de pagos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_policy.policyMessage),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _policy.securityMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_countries.length > 1)
                DropdownButtonFormField<String>(
                  value: _countryCode,
                  decoration: const InputDecoration(labelText: 'País'),
                  items: _countries
                      .map(
                        (country) => DropdownMenuItem(
                          value: country.code,
                          child: Text(
                            country.currency == null
                                ? country.name
                                : '${country.name} (${country.currency})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _onCountryChanged,
                )
              else if (_countryCode != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.public),
                  title: const Text('País'),
                  subtitle: Text(_countryLabel()),
                ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: _methodCode,
                decoration: const InputDecoration(
                  labelText: 'Método de liquidación',
                ),
                items: _methods
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.code,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _methodCode = value;
                  _bankId = null;
                }),
                validator: (value) =>
                    value == null ? 'Selecciona un método' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              ..._buildDynamicFields(),
              const SizedBox(height: AppSpacing.lg),
              CiervoButton(
                label: _saving ? 'Guardando…' : 'Guardar cuenta',
                icon: Icons.account_balance_outlined,
                state: _saving
                    ? CiervoButtonState.loading
                    : CiervoButtonState.normal,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _countryLabel() {
    final match = _countries.where((c) => c.code == _countryCode).firstOrNull;
    if (match != null) {
      return match.currency == null
          ? match.name
          : '${match.name} (${match.currency})';
    }
    return _countryCode ?? '';
  }

  List<Widget> _buildDynamicFields() {
    final method = _selectedMethod;
    if (method == null) return const [];

    final fields = method.requiredFields.isNotEmpty
        ? method.requiredFields
        : _defaultFieldsForMethod(method.code);

    return fields.map(_fieldWidget).whereType<Widget>().toList();
  }

  List<String> _defaultFieldsForMethod(String code) {
    final key = code.toUpperCase().replaceAll(' ', '_');
    if (key.contains('BANK')) {
      return const [
        'bankId',
        'accountType',
        'accountNumber',
        'holderName',
        'documentNumber',
      ];
    }
    return const ['phoneNumber', 'holderName', 'documentNumber'];
  }

  Widget? _fieldWidget(String field) {
    final key = field.toLowerCase();
    switch (key) {
      case 'bankid':
        if (_banks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'No hay bancos disponibles para ${_countryLabel()}.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: DropdownButtonFormField<String>(
            value: _bankId,
            decoration: InputDecoration(
              labelText: DisplayLabels.settlementFieldLabel(field),
            ),
            items: _banks
                .map(
                  (bank) => DropdownMenuItem(
                    value: bank.id,
                    child: Text(bank.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _bankId = value),
            validator: (value) =>
                value == null ? 'Selecciona un banco' : null,
          ),
        );
      case 'accounttype':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: DropdownButtonFormField<String>(
            value: _accountType,
            decoration: InputDecoration(
              labelText: DisplayLabels.settlementFieldLabel(field),
            ),
            items: const [
              DropdownMenuItem(value: 'Savings', child: Text('Ahorros')),
              DropdownMenuItem(value: 'Checking', child: Text('Corriente')),
            ],
            onChanged: (value) => setState(() => _accountType = value),
            validator: (value) =>
                value == null ? 'Selecciona el tipo de cuenta' : null,
          ),
        );
      case 'accountnumber':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TextFormField(
            controller: _accountNumber,
            decoration: InputDecoration(
              labelText: DisplayLabels.settlementFieldLabel(field),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingresa el número de cuenta'
                : null,
          ),
        );
      case 'holdername':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TextFormField(
            controller: _holderName,
            decoration: InputDecoration(
              labelText: DisplayLabels.settlementFieldLabel(field),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingresa el nombre del titular'
                : null,
          ),
        );
      case 'documentnumber':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TextFormField(
            controller: _documentNumber,
            decoration: InputDecoration(
              labelText: DisplayLabels.settlementFieldLabel(field),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingresa el documento'
                : null,
          ),
        );
      case 'phonenumber':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TextFormField(
            controller: _phoneNumber,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: DisplayLabels.settlementFieldLabel(field),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingresa el teléfono'
                : null,
          ),
        );
      case 'walletidentifier':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TextFormField(
            controller: _walletIdentifier,
            decoration: InputDecoration(
              labelText: DisplayLabels.settlementFieldLabel(field),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingresa el identificador de billetera'
                : null,
          ),
        );
      default:
        return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _methodCode == null ||
        _countryCode == null) {
      return;
    }
    setState(() => _saving = true);

    final method = _selectedMethod;
    final fields = method?.requiredFields.isNotEmpty == true
        ? method!.requiredFields
        : _defaultFieldsForMethod(_methodCode!);

    String? pick(String name) {
      if (!fields.any((f) => f.toLowerCase() == name)) return null;
      return switch (name) {
        'bankid' => _bankId,
        'accounttype' => _accountType,
        'accountnumber' => _accountNumber.text.trim(),
        'holdername' => _holderName.text.trim(),
        'documentnumber' => _documentNumber.text.trim(),
        'phonenumber' => _phoneNumber.text.trim(),
        'walletidentifier' => _walletIdentifier.text.trim(),
        _ => null,
      };
    }

    final account = DeliverySettlementAccount(
      countryCode: _countryCode!,
      settlementMethod: _methodCode!,
      bankId: pick('bankid'),
      accountType: pick('accounttype'),
      accountNumber: pick('accountnumber'),
      holderName: pick('holdername'),
      documentNumber: pick('documentnumber'),
      phoneNumber: pick('phonenumber'),
      walletIdentifier: pick('walletidentifier'),
    );

    final result =
        await getIt<DeliveryRepository>().updateSettlementAccount(account);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu cuenta fue enviada a revisión. Te avisaremos cuando sea aprobada.',
            ),
          ),
        );
        _load();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.details});

  final DeliverySettlementAccountDetails details;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DisplayLabels.settlementStatus(details.status),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (details.rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Motivo: ${details.rejectionReason}'),
          ],
          if (details.bankName != null) Text('Banco: ${details.bankName}'),
          if (details.maskedAccountNumber != null)
            Text('Cuenta: ${details.maskedAccountNumber}'),
          if (details.maskedPhone != null)
            Text('Teléfono: ${details.maskedPhone}'),
          if (details.maskedMercadoPago != null)
            Text('Mercado Pago: ${details.maskedMercadoPago}'),
        ],
      ),
    ),
  );
}
