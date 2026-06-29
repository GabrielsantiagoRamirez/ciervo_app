import '../../../../core/result/result.dart';
import '../entities/receipt.dart';

abstract interface class ReceiptsRepository {
  Future<Result<List<Receipt>>> receipts();
  Future<Result<Receipt>> receipt(String id);
}
