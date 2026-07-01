import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../data/memberships_repository.dart';
import '../../domain/entities/plan_limit.dart';
import '../../domain/membership_state.dart';

class MembershipCubit extends Cubit<MembershipState> {
  MembershipCubit(this._repository) : super(const MembershipState());

  final MembershipsRepository _repository;

  Future<void> load() => loadFresh();

  Future<void> loadFresh() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final results = await Future.wait([
      _repository.myMembership(),
      _repository.benefits(),
      _repository.limits(),
    ]);

    var me = state.me;
    var benefits = state.benefits;
    var limits = state.limits;
    String? error;

    final meResult = results[0] as Result<Map<String, dynamic>>;
    final benefitsResult = results[1] as Result<Map<String, dynamic>>;
    final limitsResult = results[2] as Result<Map<String, PlanLimit>>;

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

  void clear() => emit(const MembershipState());

  Future<void> refreshIfLoaded() async {
    if (state.isLoaded && !state.isLoading) {
      await loadFresh();
    }
  }
}
