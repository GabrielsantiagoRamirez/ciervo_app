import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/secure_storage.dart';
import 'experience_mode.dart';

class ExperienceModeState {
  const ExperienceModeState({
    required this.mode,
    required this.hasSelection,
  });

  const ExperienceModeState.unselected()
      : mode = ExperienceMode.night,
        hasSelection = false;

  final ExperienceMode mode;
  final bool hasSelection;
}

class ExperienceModeCubit extends Cubit<ExperienceModeState> {
  ExperienceModeCubit(this._storage)
      : super(const ExperienceModeState.unselected());

  static const _storageKey = 'ciervo.experienceMode';

  final SecureStorage _storage;

  Future<void> restore() async {
    final stored = await _storage.read(_storageKey);
    final mode = ExperienceModeX.fromValue(stored);
    if (mode == null) {
      emit(const ExperienceModeState.unselected());
      return;
    }
    // Storage remembers the preference, but does not choose for this session.
    emit(ExperienceModeState(mode: mode, hasSelection: false));
  }

  void requireSelection() {
    emit(ExperienceModeState(mode: state.mode, hasSelection: false));
  }

  Future<void> toggleMode() {
    return setMode(
      state.mode == ExperienceMode.night
          ? ExperienceMode.day
          : ExperienceMode.night,
    );
  }

  Future<void> setMode(ExperienceMode mode) async {
    await _storage.write(_storageKey, mode.apiValue);
    emit(ExperienceModeState(mode: mode, hasSelection: true));
  }
}
