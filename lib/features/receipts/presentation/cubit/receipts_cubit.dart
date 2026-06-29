import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/repositories/receipts_repository.dart';
import 'receipts_state.dart';

class ReceiptsCubit extends Cubit<ReceiptsState> {
  ReceiptsCubit(this._repository) : super(const ReceiptsState());
  final ReceiptsRepository _repository;

  Future<void> load() async {
    emit(const ReceiptsState(status: ReceiptsStatus.loading));
    final result = await _repository.receipts();
    result.when(
      success: (items) => emit(
        ReceiptsState(
          status: items.isEmpty ? ReceiptsStatus.empty : ReceiptsStatus.loaded,
          receipts: items,
        ),
      ),
      failure: (error) => emit(
        ReceiptsState(
          status: ReceiptsStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> loadDetail(String id) async {
    emit(
      ReceiptsState(status: ReceiptsStatus.loading, receipts: state.receipts),
    );
    final result = await _repository.receipt(id);
    result.when(
      success: (item) => emit(
        ReceiptsState(
          status: ReceiptsStatus.loaded,
          receipts: state.receipts,
          selected: item,
        ),
      ),
      failure: (error) => emit(
        ReceiptsState(
          status: ReceiptsStatus.failure,
          receipts: state.receipts,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }
}
