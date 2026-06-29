enum ExperienceMode {
  day,
  night,
}

extension ExperienceModeX on ExperienceMode {
  String get apiValue => switch (this) {
        ExperienceMode.day => 'day',
        ExperienceMode.night => 'night',
      };

  String get label => switch (this) {
        ExperienceMode.day => 'Dia',
        ExperienceMode.night => 'Noche',
      };

  static ExperienceMode? fromValue(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'day' || 'dia' => ExperienceMode.day,
      'night' || 'noche' => ExperienceMode.night,
      _ => null,
    };
  }
}
