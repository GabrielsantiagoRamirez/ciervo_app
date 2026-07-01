import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/kid_parental_rules.dart';
import '../../domain/repositories/family_payments_repository.dart';

class KidScheduleRulesPage extends StatefulWidget {
  const KidScheduleRulesPage({required this.kidId, super.key});
  final String kidId;

  @override
  State<KidScheduleRulesPage> createState() => _KidScheduleRulesPageState();
}

class _KidScheduleRulesPageState extends State<KidScheduleRulesPage> {
  final _repository = getIt<FamilyPaymentsRepository>();
  TimeOfDay? _start;
  TimeOfDay? _end;
  final Set<int> _days = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _dayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

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
    final result = await _repository.kidSchedule(widget.kidId);
    if (!mounted) return;
    result.when(
      success: (schedule) {
        _start = _parseTime(schedule.startTime);
        _end = _parseTime(schedule.endTime);
        _days
          ..clear()
          ..addAll(schedule.allowedDays);
        setState(() => _loading = false);
      },
      failure: (error) => setState(() {
        _loading = false;
        _error = UserErrorMessage.from(error);
      }),
    );
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || !value.contains(':')) return null;
    final parts = value.split(':');
    final hour = int.tryParse(parts.first);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0');
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (start ? _start : _end) ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _repository.saveKidSchedule(
      kidId: widget.kidId,
      schedule: KidScheduleRules(
        startTime: _formatTime(_start),
        endTime: _formatTime(_end),
        allowedDays: _days.toList()..sort(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horarios guardados.')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horarios')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 3),
            )
          : _error != null
              ? Padding(
                  padding: pagePaddingOf(context),
                  child: CiervoErrorState(
                    title: 'No pudimos cargar los horarios',
                    description: _error!,
                    onRetry: _load,
                  ),
                )
              : SingleChildScrollView(
                  padding: pagePaddingOf(context),
                  child: CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: const Text('Hora inicio'),
                          subtitle: Text(_formatTime(_start).isEmpty
                              ? 'Seleccionar'
                              : _formatTime(_start)),
                          onTap: () => _pickTime(start: true),
                        ),
                        ListTile(
                          leading: const Icon(Icons.access_time_filled),
                          title: const Text('Hora fin'),
                          subtitle: Text(_formatTime(_end).isEmpty
                              ? 'Seleccionar'
                              : _formatTime(_end)),
                          onTap: () => _pickTime(start: false),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Días permitidos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Wrap(
                          spacing: 8,
                          children: List.generate(7, (index) {
                            final day = index + 1;
                            final selected = _days.contains(day);
                            return FilterChip(
                              label: Text(_dayLabels[index]),
                              selected: selected,
                              onSelected: (value) => setState(() {
                                if (value) {
                                  _days.add(day);
                                } else {
                                  _days.remove(day);
                                }
                              }),
                            );
                          }),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        CiervoButton(
                          label: _saving ? 'Guardando...' : 'Guardar horarios',
                          icon: Icons.save_outlined,
                          state: _saving
                              ? CiervoButtonState.loading
                              : CiervoButtonState.normal,
                          onPressed: _saving ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
