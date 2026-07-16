import 'package:flutter/material.dart';

enum ExperienceMode { day, night, allDay }

extension ExperienceModeX on ExperienceMode {
  String get apiValue => switch (this) {
    ExperienceMode.day => 'day',
    ExperienceMode.night => 'night',
    ExperienceMode.allDay => '24h',
  };

  String get label => switch (this) {
    ExperienceMode.day => 'Día',
    ExperienceMode.night => 'Noche',
    ExperienceMode.allDay => '24h',
  };

  IconData get icon => switch (this) {
    ExperienceMode.day => Icons.wb_sunny_outlined,
    ExperienceMode.night => Icons.nightlight_outlined,
    ExperienceMode.allDay => Icons.schedule_outlined,
  };

  /// 06:00–17:59 → day · 18:00–05:59 → night
  static ExperienceMode fromLocalTime([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    return hour >= 6 && hour < 18 ? ExperienceMode.day : ExperienceMode.night;
  }

  static ExperienceMode? fromValue(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'day' || 'dia' || 'día' => ExperienceMode.day,
      'night' || 'noche' => ExperienceMode.night,
      '24h' || 'allday' || 'all_day' || 'todo' => ExperienceMode.allDay,
      _ => null,
    };
  }
}
