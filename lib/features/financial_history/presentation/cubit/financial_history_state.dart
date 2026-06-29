import '../../domain/entities/financial_history_item.dart';

enum FinancialHistoryStatus { initial, loading, loaded, empty, failure }

class FinancialHistoryState {
  const FinancialHistoryState({
    this.status = FinancialHistoryStatus.initial,
    this.items = const [],
    this.errorMessage,
  });
  final FinancialHistoryStatus status;
  final List<FinancialHistoryItem> items;
  final String? errorMessage;
}
