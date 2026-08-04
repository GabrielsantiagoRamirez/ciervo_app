import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/secure_storage.dart';
import 'experience_mode.dart';

class ExperienceModeState {
  const ExperienceModeState({required this.mode, required this.hasSelection});

  ExperienceModeState.unselected()
    : mode = ExperienceModeX.fromLocalTime(),
      hasSelection = false;

  final ExperienceMode mode;
  final bool hasSelection;
}

class ExperienceModeCubit extends Cubit<ExperienceModeState> {
  ExperienceModeCubit(this._storage) : super(ExperienceModeState.unselected());

  static const _storageKey = 'ciervo.experienceMode';

  final SecureStorage _storage;

  Future<void> restore() async {
    final stored = await _storage.read(_storageKey);
    final mode =
        ExperienceModeX.fromValue(stored) ?? ExperienceModeX.fromLocalTime();
    // Preferencia recordada o sugerencia por hora local; no elige la sesión.
    emit(ExperienceModeState(mode: mode, hasSelection: false));
  }

  void requireSelection() {
    emit(ExperienceModeState(mode: state.mode, hasSelection: false));
  }

  /// Aplica el modo sugerido por la hora local del dispositivo.
  Future<void> applyLocalTimeSuggestion() {
    return setMode(ExperienceModeX.fromLocalTime());
  }

  Future<void> toggleMode() {
    final next = switch (state.mode) {
      ExperienceMode.day => ExperienceMode.night,
      ExperienceMode.night => ExperienceMode.allDay,
      ExperienceMode.allDay => ExperienceMode.day,
    };
    return setMode(next);
  }

  Future<void> setMode(ExperienceMode mode) async {
    await _storage.write(_storageKey, mode.apiValue);
    emit(ExperienceModeState(mode: mode, hasSelection: true));
  }

  /// Actualiza el look (tema/badge) sin confirmar la sesión ni persistir.
  void previewMode(ExperienceMode mode) {
    if (state.mode == mode && !state.hasSelection) return;
    emit(ExperienceModeState(mode: mode, hasSelection: false));
  }
}
