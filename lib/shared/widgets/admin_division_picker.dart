import 'package:flutter/material.dart';

import '../../core/location/admin_division_catalog.dart';
import '../../core/location/admin_division_models.dart';
import '../../core/theme/app_spacing.dart';

class AdminDivisionPicker extends StatefulWidget {
  const AdminDivisionPicker({
    required this.countryCode,
    this.initialSelection,
    required this.onChanged,
    super.key,
  });

  final String countryCode;
  final AdminDivisionSelection? initialSelection;
  final ValueChanged<AdminDivisionSelection?> onChanged;

  @override
  State<AdminDivisionPicker> createState() => _AdminDivisionPickerState();
}

class _AdminDivisionPickerState extends State<AdminDivisionPicker> {
  bool _loading = true;
  List<ColombiaDepartment> _coDepartments = const [];
  List<ChileRegion> _clRegions = const [];

  String? _coDepartmentCode;
  String? _coCityCode;
  String? _clRegionCode;
  String? _clProvinceCode;
  String? _clCommuneCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminDivisionPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryCode != widget.countryCode) {
      _resetSelection();
      _load();
    }
  }

  void _resetSelection() {
    _coDepartmentCode = null;
    _coCityCode = null;
    _clRegionCode = null;
    _clProvinceCode = null;
    _clCommuneCode = null;
    widget.onChanged(null);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final catalog = AdminDivisionCatalog.instance;
    if (widget.countryCode == 'CO') {
      _coDepartments = await catalog.colombiaDepartments();
    } else if (widget.countryCode == 'CL') {
      _clRegions = await catalog.chileRegions();
    }
    _applyInitialSelection();
    if (mounted) setState(() => _loading = false);
  }

  void _applyInitialSelection() {
    final initial = widget.initialSelection;
    if (initial == null) return;
    if (widget.countryCode == 'CO') {
      final department = _coDepartments
          .where((item) => item.name == initial.departmentName)
          .firstOrNull;
      _coDepartmentCode = department?.code;
      final city = department?.cities
          .where((item) => item.name == initial.cityName)
          .firstOrNull;
      _coCityCode = city?.code;
    } else if (widget.countryCode == 'CL') {
      final region = _clRegions
          .where((item) => item.name == initial.regionName)
          .firstOrNull;
      _clRegionCode = region?.code;
      final province = region?.provinces
          .where((item) => item.name == initial.provinceName)
          .firstOrNull;
      _clProvinceCode = province?.code;
      final commune = province?.communes
          .where((item) => item.name == initial.cityName)
          .firstOrNull;
      _clCommuneCode = commune?.code;
    }
    _notify();
  }

  void _notify() {
    if (widget.countryCode == 'CO') {
      final department = _coDepartments
          .where((item) => item.code == _coDepartmentCode)
          .firstOrNull;
      final city = department?.cities
          .where((item) => item.code == _coCityCode)
          .firstOrNull;
      if (department == null || city == null) {
        widget.onChanged(null);
        return;
      }
      widget.onChanged(
        AdminDivisionSelection(
          countryCode: 'CO',
          departmentName: department.name,
          cityName: city.name,
          cityCode: city.code,
        ),
      );
      return;
    }

    if (widget.countryCode == 'CL') {
      final region = _clRegions
          .where((item) => item.code == _clRegionCode)
          .firstOrNull;
      final province = region?.provinces
          .where((item) => item.code == _clProvinceCode)
          .firstOrNull;
      final commune = province?.communes
          .where((item) => item.code == _clCommuneCode)
          .firstOrNull;
      if (region == null || province == null || commune == null) {
        widget.onChanged(null);
        return;
      }
      widget.onChanged(
        AdminDivisionSelection(
          countryCode: 'CL',
          regionName: region.name,
          provinceName: province.name,
          cityName: commune.name,
          cityCode: commune.code,
        ),
      );
    }
  }

  Widget _divisionDropdown({
    required String? value,
    required String label,
    required List<({String code, String name})> options,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (item) => DropdownMenuItem(
              value: item.code,
              child: Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => options
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminDivisionCatalog.instance.hasCatalog(widget.countryCode)) {
      return const SizedBox.shrink();
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.countryCode == 'CO') {
      final department = _coDepartments
          .where((item) => item.code == _coDepartmentCode)
          .firstOrNull;
      final cities = department?.cities ?? const [];
      return Column(
        children: [
          _divisionDropdown(
            value: _coDepartmentCode,
            label: 'Departamento',
            options: _coDepartments
                .map((item) => (code: item.code, name: item.name))
                .toList(),
            onChanged: (value) => setState(() {
              _coDepartmentCode = value;
              _coCityCode = null;
              _notify();
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          _divisionDropdown(
            value: _coCityCode,
            label: 'Municipio / Ciudad',
            options: cities
                .map((item) => (code: item.code, name: item.name))
                .toList(),
            onChanged: department == null
                ? null
                : (value) => setState(() {
                    _coCityCode = value;
                    _notify();
                  }),
          ),
        ],
      );
    }

    final region = _clRegions
        .where((item) => item.code == _clRegionCode)
        .firstOrNull;
    final provinces = region?.provinces ?? const [];
    final province = provinces
        .where((item) => item.code == _clProvinceCode)
        .firstOrNull;
    final communes = province?.communes ?? const [];

    return Column(
      children: [
        _divisionDropdown(
          value: _clRegionCode,
          label: 'Región',
          options: _clRegions
              .map((item) => (code: item.code, name: item.name))
              .toList(),
          onChanged: (value) => setState(() {
            _clRegionCode = value;
            _clProvinceCode = null;
            _clCommuneCode = null;
            _notify();
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        _divisionDropdown(
          value: _clProvinceCode,
          label: 'Provincia',
          options: provinces
              .map((item) => (code: item.code, name: item.name))
              .toList(),
          onChanged: region == null
              ? null
              : (value) => setState(() {
                  _clProvinceCode = value;
                  _clCommuneCode = null;
                  _notify();
                }),
        ),
        const SizedBox(height: AppSpacing.md),
        _divisionDropdown(
          value: _clCommuneCode,
          label: 'Comuna',
          options: communes
              .map((item) => (code: item.code, name: item.name))
              .toList(),
          onChanged: province == null
              ? null
              : (value) => setState(() {
                  _clCommuneCode = value;
                  _notify();
                }),
        ),
      ],
    );
  }
}
