import 'dart:convert';

import 'package:flutter/services.dart';

import 'admin_division_models.dart';

/// Catálogo local de divisiones administrativas (DANE/DIVIPOLA CO, INE CL).
class AdminDivisionCatalog {
  AdminDivisionCatalog._();

  static final AdminDivisionCatalog instance = AdminDivisionCatalog._();

  List<ColombiaDepartment>? _colombia;
  List<ChileRegion>? _chile;

  Future<void> ensureLoaded() async {
    _colombia ??= await _loadColombia();
    _chile ??= await _loadChile();
  }

  Future<List<ColombiaDepartment>> colombiaDepartments() async {
    await ensureLoaded();
    return _colombia!;
  }

  Future<List<ChileRegion>> chileRegions() async {
    await ensureLoaded();
    return _chile!;
  }

  bool hasCatalog(String countryCode) =>
      countryCode == 'CO' || countryCode == 'CL';

  Future<List<ColombiaDepartment>> _loadColombia() async {
    final raw = await rootBundle.loadString(
      'assets/data/locations/colombia.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['departments'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ColombiaDepartment.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<ChileRegion>> _loadChile() async {
    final raw = await rootBundle.loadString('assets/data/locations/chile.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['regions'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ChileRegion.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
