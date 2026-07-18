import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../data/repositories/master_kids_repository.dart';
import '../../domain/models/master_kids_models.dart';

class MasterKidRulesPage extends StatefulWidget {
  const MasterKidRulesPage({
    required this.repository,
    required this.kidId,
    super.key,
  });

  final MasterKidsRepository repository;
  final int kidId;

  @override
  State<MasterKidRulesPage> createState() => _MasterKidRulesPageState();
}

class _MasterKidRulesPageState extends State<MasterKidRulesPage> {
  final _daily = TextEditingController();
  final _weekly = TextEditingController();
  final _monthly = TextEditingController();
  final _currency = TextEditingController(text: 'COP');
  final _timezone = TextEditingController(text: 'America/Bogota');
  final _merchantId = TextEditingController();
  final _blockedMerchantId = TextEditingController();
  final _categoryId = TextEditingController();
  final _countryCode = TextEditingController();
  final _physicalCardId = TextEditingController();
  final Set<int> _days = {1, 2, 3, 4, 5};
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);
  KidRulesSnapshot? _rules;
  bool _scheduleActive = true;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _daily,
      _weekly,
      _monthly,
      _currency,
      _timezone,
      _merchantId,
      _blockedMerchantId,
      _categoryId,
      _countryCode,
      _physicalCardId,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await widget.repository.rules(widget.kidId);
    if (!mounted) return;
    result.when(
      success: (value) {
        _rules = value;
        _daily.text = _amount(value.limits.dailyLimit);
        _weekly.text = _amount(value.limits.weeklyLimit);
        _monthly.text = _amount(value.limits.monthlyLimit);
        _currency.text = value.limits.currency;
        if (value.schedules.isNotEmpty) {
          final schedule = value.schedules.first;
          _timezone.text = schedule.timezone;
          _scheduleActive = schedule.isActive;
          _applySchedule(schedule.scheduleJson);
        }
      },
      failure: (error) => _message = UserErrorMessage.from(error),
    );
    setState(() => _busy = false);
  }

  void _applySchedule(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final days = decoded['days'];
      if (days is List) {
        _days
          ..clear()
          ..addAll(days.whereType<num>().map((value) => value.toInt()));
      }
      _start = _time(decoded['start']?.toString()) ?? _start;
      _end = _time(decoded['end']?.toString()) ?? _end;
    } on FormatException {
      // El backend puede tener un formato histórico; la UI conserva defaults.
    }
  }

  Future<void> _run(
    Future<Result<Object?>> Function() action, {
    String success = 'Configuración actualizada.',
    bool reload = true,
  }) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await action();
    if (!mounted) return;
    result.when(
      success: (_) => _message = success,
      failure: (error) => _message = UserErrorMessage.from(error),
    );
    setState(() => _busy = false);
    if (result is Success<Object?> && reload) await _load();
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _saveLimits() => _run(
    () => widget.repository.updateLimits(
      widget.kidId,
      ChildSpendingLimitCommand(
        dailyLimit: double.tryParse(_daily.text),
        weeklyLimit: double.tryParse(_weekly.text),
        monthlyLimit: double.tryParse(_monthly.text),
        currency: _currency.text.trim().toUpperCase(),
      ),
    ),
  );

  Future<void> _saveSchedule() => _run(
    () => widget.repository.updateSchedule(
      widget.kidId,
      KidSpendingScheduleCommand(
        timezone: _timezone.text.trim(),
        scheduleJson: jsonEncode({
          'days': _days.toList()..sort(),
          'start': _formatTime(_start),
          'end': _formatTime(_end),
        }),
        isActive: _scheduleActive,
      ),
    ),
  );

  Future<void> _addCategory() async {
    final id = int.tryParse(_categoryId.text.trim());
    if (id == null) return _invalid('Ingresa un ID de categoría válido.');
    final ids = {...?_rules?.categories.map((item) => item.id), id}.toList();
    await _run(
      () => widget.repository.updateCategories(
        widget.kidId,
        KidCategoriesCommand(ids),
      ),
    );
    _categoryId.clear();
  }

  Future<void> _removeCategory(KidRuleItem item) async {
    if (!await _confirm(
      'Quitar categoría',
      '¿Quitar “${item.label}” de las categorías permitidas?',
    )) {
      return;
    }
    final ids = _rules!.categories
        .where((value) => value.id != item.id)
        .map((value) => value.id)
        .toList();
    await _run(
      () => widget.repository.updateCategories(
        widget.kidId,
        KidCategoriesCommand(ids),
      ),
    );
  }

  Future<void> _merchant(bool blocked) async {
    final controller = blocked ? _blockedMerchantId : _merchantId;
    final id = int.tryParse(controller.text.trim());
    if (id == null) return _invalid('Ingresa un comercio válido.');
    await _run(
      () => blocked
          ? widget.repository.blockMerchant(
              widget.kidId,
              KidRuleMerchantCommand(id),
            )
          : widget.repository.addMerchant(
              widget.kidId,
              KidRuleMerchantCommand(id),
            ),
    );
    controller.clear();
  }

  Future<void> _removeMerchant(
    KidRuleItem item, {
    required bool blocked,
  }) async {
    if (!await _confirm(
      blocked ? 'Desbloquear comercio' : 'Quitar comercio',
      blocked
          ? '¿Permitir nuevamente compras en “${item.label}”?'
          : '¿Quitar “${item.label}” de los comercios permitidos?',
    )) {
      return;
    }
    await _run(
      () => blocked
          ? widget.repository.unblockMerchant(widget.kidId, item.id)
          : widget.repository.removeMerchant(widget.kidId, item.id),
    );
  }

  Future<void> _country() async {
    final code = _countryCode.text.trim().toUpperCase();
    if (code.length != 2) return _invalid('Usa un código de país de 2 letras.');
    await _run(
      () => widget.repository.addCountry(
        widget.kidId,
        KidRuleCountryCommand(code),
      ),
    );
    _countryCode.clear();
  }

  Future<void> _removeCountry(KidRuleCountry item) async {
    if (!await _confirm(
      'Quitar país',
      '¿Quitar ${item.name} de los países permitidos?',
    )) {
      return;
    }
    await _run(() => widget.repository.removeCountry(widget.kidId, item.code));
  }

  Future<void> _geofence([KidGeofence? current]) async {
    final command = await showDialog<KidGeofenceCommand>(
      context: context,
      builder: (_) => _GeofenceDialog(current: current),
    );
    if (command == null) return;
    await _run(
      () => current == null
          ? widget.repository.addGeofence(widget.kidId, command)
          : widget.repository.updateGeofence(widget.kidId, current.id, command),
    );
  }

  Future<void> _removeGeofence(KidGeofence item) async {
    if (!await _confirm(
      'Eliminar geocerca',
      'Esta acción eliminará “${item.name}”. ¿Continuar?',
    )) {
      return;
    }
    await _run(() => widget.repository.removeGeofence(widget.kidId, item.id));
  }

  Future<void> _setNfc(bool enabled) async {
    final cardId = _physicalCardId.text.trim();
    if (cardId.isEmpty) return _invalid('Ingresa la tarjeta NFC.');
    if (!enabled &&
        !await _confirm(
          'Deshabilitar tarjeta',
          'La tarjeta dejará de poder usarse para pagos. ¿Continuar?',
        )) {
      return;
    }
    await _run(
      () => enabled
          ? widget.repository.enableNfc(widget.kidId, cardId)
          : widget.repository.disableNfc(widget.kidId, cardId),
      reload: false,
    );
  }

  void _invalid(String message) => setState(() => _message = message);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reglas Kids'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _rules == null && _busy
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_message != null)
                MaterialBanner(
                  content: Text(_message!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _message = null),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              _Section(
                title: 'Límites',
                children: [
                  _number(_daily, 'Diario'),
                  _number(_weekly, 'Semanal'),
                  _number(_monthly, 'Mensual'),
                  TextField(
                    controller: _currency,
                    decoration: const InputDecoration(labelText: 'Moneda'),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _saveLimits,
                    child: const Text('Guardar límites'),
                  ),
                ],
              ),
              _Section(
                title: 'Horario permitido',
                children: [
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      return FilterChip(
                        label: Text(_dayNames[index]),
                        selected: _days.contains(day),
                        onSelected: _busy
                            ? null
                            : (selected) => setState(
                                () => selected
                                    ? _days.add(day)
                                    : _days.remove(day),
                              ),
                      );
                    }),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeButton(
                          label: 'Desde',
                          value: _start,
                          onChanged: (value) => setState(() => _start = value),
                        ),
                      ),
                      Expanded(
                        child: _TimeButton(
                          label: 'Hasta',
                          value: _end,
                          onChanged: (value) => setState(() => _end = value),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _timezone,
                    decoration: const InputDecoration(
                      labelText: 'Zona horaria',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _scheduleActive,
                    title: const Text('Horario activo'),
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _scheduleActive = value),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _saveSchedule,
                    child: const Text('Guardar horario'),
                  ),
                ],
              ),
              _RuleItemsSection(
                title: 'Comercios permitidos',
                items: _rules?.merchants ?? const [],
                controller: _merchantId,
                addLabel: 'Agregar comercio',
                onAdd: _busy ? null : () => _merchant(false),
                onDelete: (item) => _removeMerchant(item, blocked: false),
              ),
              _RuleItemsSection(
                title: 'Categorías permitidas',
                items: _rules?.categories ?? const [],
                controller: _categoryId,
                addLabel: 'Agregar categoría',
                onAdd: _busy ? null : _addCategory,
                onDelete: _removeCategory,
              ),
              _Section(
                title: 'Países permitidos',
                children: [
                  for (final item in _rules?.countries ?? const [])
                    ListTile(
                      title: Text(item.name),
                      subtitle: Text(item.code),
                      trailing: IconButton(
                        tooltip: 'Quitar',
                        onPressed: _busy ? null : () => _removeCountry(item),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  TextField(
                    controller: _countryCode,
                    maxLength: 2,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código de país (ej. CO)',
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy ? null : _country,
                    child: const Text('Agregar país'),
                  ),
                ],
              ),
              _Section(
                title: 'Geocercas',
                children: [
                  for (final item in _rules?.geofences ?? const [])
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.radiusMeters.toStringAsFixed(0)} m · '
                        '${item.centerLatitude}, ${item.centerLongitude}',
                      ),
                      onTap: _busy ? null : () => _geofence(item),
                      trailing: IconButton(
                        tooltip: 'Eliminar',
                        onPressed: _busy ? null : () => _removeGeofence(item),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _geofence,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Nueva geocerca'),
                  ),
                ],
              ),
              _RuleItemsSection(
                title: 'Comercios bloqueados',
                items: _rules?.blockedMerchants ?? const [],
                controller: _blockedMerchantId,
                addLabel: 'Bloquear comercio',
                onAdd: _busy ? null : () => _merchant(true),
                onDelete: (item) => _removeMerchant(item, blocked: true),
              ),
              _Section(
                title: 'Tarjeta NFC física',
                children: [
                  TextField(
                    controller: _physicalCardId,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Identificador físico',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : () => _setNfc(true),
                          child: const Text('Habilitar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => _setNfc(false),
                          child: const Text('Deshabilitar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
  );

  Widget _number(TextEditingController controller, String label) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
  );
}

class _RuleItemsSection extends StatelessWidget {
  const _RuleItemsSection({
    required this.title,
    required this.items,
    required this.controller,
    required this.addLabel,
    required this.onAdd,
    required this.onDelete,
  });
  final String title;
  final List<KidRuleItem> items;
  final TextEditingController controller;
  final String addLabel;
  final VoidCallback? onAdd;
  final ValueChanged<KidRuleItem> onDelete;

  @override
  Widget build(BuildContext context) => _Section(
    title: title,
    children: [
      if (items.isEmpty) const Text('No hay elementos configurados.'),
      for (final item in items)
        ListTile(
          title: Text(item.label),
          trailing: IconButton(
            tooltip: 'Quitar',
            onPressed: () => onDelete(item),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'ID (solo si no aparece en la lista)',
        ),
      ),
      FilledButton.tonal(onPressed: onAdd, child: Text(addLabel)),
    ],
  );
}

class _GeofenceDialog extends StatefulWidget {
  const _GeofenceDialog({this.current});
  final KidGeofence? current;

  @override
  State<_GeofenceDialog> createState() => _GeofenceDialogState();
}

class _GeofenceDialogState extends State<_GeofenceDialog> {
  late final TextEditingController _name;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _radius;
  String? _error;

  @override
  void initState() {
    super.initState();
    final value = widget.current;
    _name = TextEditingController(text: value?.name);
    _latitude = TextEditingController(text: value?.centerLatitude.toString());
    _longitude = TextEditingController(text: value?.centerLongitude.toString());
    _radius = TextEditingController(
      text: value?.radiusMeters.toString() ?? '250',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _radius.dispose();
    super.dispose();
  }

  void _submit() {
    final latitude = double.tryParse(_latitude.text);
    final longitude = double.tryParse(_longitude.text);
    final radius = double.tryParse(_radius.text);
    if (_name.text.trim().isEmpty ||
        latitude == null ||
        longitude == null ||
        radius == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        radius < 50 ||
        radius > 50000) {
      setState(
        () => _error = 'Revisa nombre, coordenadas y radio (50–50000 m).',
      );
      return;
    }
    Navigator.pop(
      context,
      KidGeofenceCommand(
        name: _name.text.trim(),
        centerLatitude: latitude,
        centerLongitude: longitude,
        radiusMeters: radius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.current == null ? 'Nueva geocerca' : 'Editar geocerca'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          TextField(
            controller: _latitude,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Latitud'),
          ),
          TextField(
            controller: _longitude,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Longitud'),
          ),
          TextField(
            controller: _radius,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Radio en metros'),
          ),
          if (_error != null) Text(_error!),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Guardar')),
    ],
  );
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value.format(context)),
    onTap: () async {
      final selected = await showTimePicker(
        context: context,
        initialTime: value,
      );
      if (selected != null) onChanged(selected);
    },
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

const _dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

String _amount(double? value) =>
    value == null ? '' : value.toStringAsFixed(value % 1 == 0 ? 0 : 2);

TimeOfDay? _time(String? value) {
  final parts = value?.split(':');
  if (parts == null || parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTime(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
