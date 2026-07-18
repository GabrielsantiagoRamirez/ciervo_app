import 'package:flutter/material.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/pay_for_me_labels.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../exchange/data/exchange_rate_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/kids_repository.dart';

class GuardianPayForMePage extends StatefulWidget {
  const GuardianPayForMePage({super.key});

  @override
  State<GuardianPayForMePage> createState() => _GuardianPayForMePageState();
}

class _GuardianPayForMePageState extends State<GuardianPayForMePage> {
  final _repository = getIt<KidsRepository>();
  final _profileRepository = getIt<ProfileRepository>();
  final _exchangeRepository = getIt<ExchangeRateRepository>();

  List<dynamic> _items = const [];
  bool _loading = true;
  String? _error;
  int? _actingOnId;
  String _tutorCurrency = 'CLP';
  String _tutorCountry = 'CL';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadTutorCountry(), _load()]);
  }

  Future<void> _loadTutorCountry() async {
    final result = await _profileRepository.getMe();
    if (!mounted) return;
    result.when(
      success: (profile) {
        final code = (profile.countryCode ?? '').trim().toUpperCase();
        final resolved = code.isNotEmpty
            ? code
            : CountryRegistration.defaultCountryCode();
        setState(() {
          _tutorCountry = resolved;
          _tutorCurrency = CountryRegistration.currencyForCountry(resolved);
        });
      },
      failure: (_) {
        final resolved = CountryRegistration.defaultCountryCode();
        setState(() {
          _tutorCountry = resolved;
          _tutorCurrency = CountryRegistration.currencyForCountry(resolved);
        });
      },
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.payForMeRequests();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items = items;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  int _requestId(Map item) {
    final raw = item['requestId'] ?? item['id'];
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  bool _isPending(Map item) {
    final status = '${item['status'] ?? item['requestStatus'] ?? ''}'
        .toLowerCase();
    return status == '1' || status.contains('pending');
  }

  String _requestCurrency(Map item) {
    final raw = '${item['currency'] ?? item['Currency'] ?? ''}'
        .trim()
        .toUpperCase();
    if (raw.isNotEmpty) return raw;
    final country = '${item['country'] ?? item['countryCode'] ?? ''}'
        .trim()
        .toUpperCase();
    if (country.isNotEmpty) {
      return CountryRegistration.currencyForCountry(country);
    }
    return 'COP';
  }

  Future<void> _approve(Map item) async {
    final id = _requestId(item);
    if (id <= 0) return;
    setState(() => _actingOnId = id);
    final result = await _repository.approvePayForMeRequest(id);
    if (!mounted) return;
    result.when(
      success: (data) {
        final token = '${data['token'] ?? ''}'.trim();
        final pin = '${data['pin'] ?? ''}'.trim();
        final secretShown = data['secretShown'] == true;
        if (secretShown && token.isNotEmpty && pin.isNotEmpty) {
          _showIssuedSecret(data);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Solicitud aprobada. La credencial ya había sido emitida o no requiere mostrarse.',
              ),
            ),
          );
        }
        _load();
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
    if (mounted) setState(() => _actingOnId = null);
  }

  Future<void> _showIssuedSecret(Map<String, dynamic> data) async {
    final token = '${data['token'] ?? ''}';
    final pin = '${data['pin'] ?? ''}';
    final expiresAt = DateTime.tryParse(
      '${data['expiresAt'] ?? ''}',
    )?.toLocal();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.key_outlined),
        title: const Text('Credencial emitida una sola vez'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'No cierres esta pantalla hasta compartir la credencial con el comercio autorizado.',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'PIN: $pin',
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              token,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Expira: ${expiresAt.hour.toString().padLeft(2, '0')}:'
                '${expiresAt.minute.toString().padLeft(2, '0')}:'
                '${expiresAt.second.toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido, ocultar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reject(Map item) async {
    final id = _requestId(item);
    if (id <= 0) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar solicitud'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
    if (reason == null || !mounted) return;
    setState(() => _actingOnId = id);
    final result = await _repository.rejectPayForMeRequest(
      id,
      reason: reason.isEmpty ? null : reason,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Solicitud rechazada.')));
        _load();
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
    if (mounted) setState(() => _actingOnId = null);
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes de pago')),
      body: RefreshIndicator(
        onRefresh: _bootstrap,
        child: _loading
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [CiervoLoadingState(itemCount: 4)],
              )
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              )
            : _items.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  CiervoEmptyState(
                    title: 'Sin solicitudes',
                    description:
                        'Cuando un menor pida dinero, podrás aprobarlo aquí.',
                    icon: Icons.family_restroom_outlined,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final raw = _items[index];
                  if (raw is! Map) return const SizedBox.shrink();
                  final item = Map<String, dynamic>.from(raw);
                  final status =
                      '${item['status'] ?? item['requestStatus'] ?? ''}';
                  final color = PayForMeLabels.statusColor(context, status);
                  final id = _requestId(item);
                  final pending = _isPending(item);
                  final busy = _actingOnId == id;
                  final amount = _num(item['amount']);
                  final requestCurrency = _requestCurrency(item);

                  return CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['childName'] ?? item['requesterName'] ?? 'Menor'} · '
                          '${item['businessName'] ?? item['description'] ?? 'Solicitud Pinduck'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$requestCurrency ${amount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        _DebitPreview(
                          amount: amount,
                          fromCurrency: requestCurrency,
                          toCurrency: _tutorCurrency,
                          tutorCountry: _tutorCountry,
                          exchangeRepository: _exchangeRepository,
                        ),
                        if (item['description'] != null)
                          Text('${item['description']}'),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            PayForMeLabels.statusLabel(status),
                            style: TextStyle(color: color),
                          ),
                        ),
                        if (pending) ...[
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: CiervoButton(
                                  label: busy ? '...' : 'Aprobar',
                                  icon: Icons.check,
                                  onPressed: busy ? null : () => _approve(item),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy ? null : () => _reject(item),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Rechazar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _DebitPreview extends StatefulWidget {
  const _DebitPreview({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.tutorCountry,
    required this.exchangeRepository,
  });

  final double amount;
  final String fromCurrency;
  final String toCurrency;
  final String tutorCountry;
  final ExchangeRateRepository exchangeRepository;

  @override
  State<_DebitPreview> createState() => _DebitPreviewState();
}

class _DebitPreviewState extends State<_DebitPreview> {
  String? _line;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _DebitPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount ||
        oldWidget.fromCurrency != widget.fromCurrency ||
        oldWidget.toCurrency != widget.toCurrency) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final from = widget.fromCurrency.trim().toUpperCase();
    final to = widget.toCurrency.trim().toUpperCase();
    if (widget.amount <= 0) {
      setState(() => _line = null);
      return;
    }
    if (from == to) {
      setState(() {
        _line =
            'Se debitará $to ${widget.amount.toStringAsFixed(0)} de tu cuenta '
            '(${CountryRegistration.countryLabel(widget.tutorCountry)}).';
      });
      return;
    }

    setState(() {
      _loading = true;
      _line = null;
    });
    final result = await widget.exchangeRepository.convert(
      amount: widget.amount,
      from: from,
      to: to,
    );
    if (!mounted) return;
    result.when(
      success: (conversion) {
        setState(() {
          _loading = false;
          _line =
              '≈ $to ${conversion.convertedAmount.toStringAsFixed(0)} '
              'en tu cuenta (${CountryRegistration.countryLabel(widget.tutorCountry)}). '
              'Tasa aprox. ${conversion.exchangeRate.toStringAsFixed(4)}.';
        });
      },
      failure: (_) {
        setState(() {
          _loading = false;
          _line =
              'El menor pide en $from. Tu cuenta es $to; '
              'al aprobar el servidor debe convertir a tu moneda.';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          'Calculando equivalente en ${widget.toCurrency}...',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    if (_line == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        _line!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
