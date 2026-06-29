import '../../../../core/result/result.dart';
import '../entities/financial_history_item.dart';

abstract interface class FinancialHistoryRepository {
  Future<Result<List<FinancialHistoryItem>>> history();
}
