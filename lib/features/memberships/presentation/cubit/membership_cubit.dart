import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../data/memberships_repository.dart';
import '../../domain/membership_state.dart';

class MembershipCubit extends Cubit<MembershipState> {
  MembershipCubit(this._repository) : super(const MembershipState());

  final MembershipsRepository _repository;
  DateTime? _lastLoadedAt;
  Future<void>? _inFlight;

  /// Evita martillar /me + benefits + limits en picos de usuarios.
  static const cacheTtl = Duration(minutes: 5);

  Future<void> load() => loadFresh(force: false);

  Future<void> loadFresh({bool force = true}) async {
    if (!force &&
        state.isLoaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < cacheTtl) {
      return;
    }
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _doLoad();
    _inFlight = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }

  Future<void> _doLoad() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final meResult = await _repository.myMembership();
    final benefitsResult = await _repository.benefits();
    final limitsResult = await _repository.limits();

    var me = state.me;
    var benefits = state.benefits;
    var limits = state.limits;
    String? error;

    meResult.when(
      success: (value) => me = value,
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    benefitsResult.when(
      success: (value) => benefits = value,
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    limitsResult.when(
      success: (value) => limits = value,
      failure: (e) => error ??= UserErrorMessage.from(e),
    );

    if (error == null) _lastLoadedAt = DateTime.now();

    emit(
      MembershipState(
        me: me,
        benefits: benefits,
        limits: limits,
        isLoading: false,
        isLoaded: error == null,
        error: error,
      ),
    );
  }

  void clear() {
    _lastLoadedAt = null;
    _inFlight = null;
    emit(const MembershipState());
  }

  Future<void> refreshIfLoaded() async {
    if (state.isLoaded && !state.isLoading) {
      await loadFresh(force: true);
    }
  }
}
