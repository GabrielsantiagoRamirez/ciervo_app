import '../../domain/entities/receipt.dart';

enum ReceiptsStatus { initial, loading, loaded, empty, failure }

class ReceiptsState {
  const ReceiptsState({
    this.status = ReceiptsStatus.initial,
    this.receipts = const [],
    this.selected,
    this.errorMessage,
  });
  final ReceiptsStatus status;
  final List<Receipt> receipts;
  final Receipt? selected;
  final String? errorMessage;
}
