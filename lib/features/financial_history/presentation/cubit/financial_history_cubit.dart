import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/repositories/financial_history_repository.dart';
import 'financial_history_state.dart';

class FinancialHistoryCubit extends Cubit<FinancialHistoryState> {
  FinancialHistoryCubit(this._repository)
    : super(const FinancialHistoryState());
  final FinancialHistoryRepository _repository;

  Future<void> load() async {
    emit(const FinancialHistoryState(status: FinancialHistoryStatus.loading));
    final result = await _repository.history();
    result.when(
      success: (items) => emit(
        FinancialHistoryState(
          status: items.isEmpty
              ? FinancialHistoryStatus.empty
              : FinancialHistoryStatus.loaded,
          items: items,
        ),
      ),
      failure: (error) => emit(
        FinancialHistoryState(
          status: FinancialHistoryStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }
}
