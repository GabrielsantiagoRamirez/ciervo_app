import 'package:flutter/material.dart';

import 'experience_mode.dart';

/// Normaliza el ID operativo de sesión (DIA / NOCHE / 24H) para UI.
///
/// Contrato backend (`/users/me`):
/// - `operationalSessionId` (canónico)
/// - `operationalBand`: `day` | `night` | `24h`
/// - `nightOperationalId` (compat = session actual)
abstract final class OperationalSessionId {
  static final _bandPattern = RegExp(
    r'(DIA|DÍA|NOCHE|NIGHT|DAY|24H|ALLDAY)',
    caseSensitive: false,
  );

  static ExperienceMode? bandFromApi(String? band) =>
      ExperienceModeX.fromValue(band);

  static ExperienceMode? bandFromId(String? raw) {
    final match = _bandPattern.firstMatch(raw ?? '');
    if (match == null) return null;
    return ExperienceModeX.fromValue(match.group(1));
  }

  /// Prioriza `operationalBand` del API, luego franja del ID, luego modo UI.
  static ExperienceMode resolveMode({
    String? band,
    String? rawId,
    ExperienceMode? uiMode,
  }) {
    return bandFromApi(band) ??
        bandFromId(rawId) ??
        uiMode ??
        ExperienceMode.night;
  }

  /// Muestra el ID del backend tal cual cuando ya trae la franja correcta.
  static String displayLabel(
    String? raw, {
    String? band,
    ExperienceMode? mode,
  }) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';
    final effective = resolveMode(band: band, rawId: value, uiMode: mode);
    // Si el ID ya coincide con la banda del API, no reescribir.
    final fromId = bandFromId(value);
    if (fromId == effective || bandFromApi(band) != null && fromId == null) {
      if (fromId == effective) return value;
    }
    final bandToken = switch (effective) {
      ExperienceMode.day => 'DIA',
      ExperienceMode.night => 'NOCHE',
      ExperienceMode.allDay => '24H',
    };
    if (!_bandPattern.hasMatch(value)) return value;
    return value.replaceFirstMapped(_bandPattern, (_) => bandToken);
  }

  static IconData iconFor({String? raw, String? band, ExperienceMode? mode}) {
    return resolveMode(band: band, rawId: raw, uiMode: mode).icon;
  }

  static String shortBandLabel({
    String? raw,
    String? band,
    ExperienceMode? mode,
  }) {
    return resolveMode(band: band, rawId: raw, uiMode: mode).label;
  }
}
