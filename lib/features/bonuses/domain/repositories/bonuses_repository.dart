import '../../../../core/result/result.dart';
import '../entities/bonus.dart';

abstract interface class BonusesRepository {
  Future<Result<List<Bonus>>> catalog(BonusFilters filters);

  Future<Result<Bonus>> detail(String bonusId);

  Future<Result<Bonus>> claim(String bonusId);

  Future<Result<Bonus>> redeem(String bonusId);

  Future<Result<List<Bonus>>> myBonuses({int page = 1, int pageSize = 30});

  Future<Result<List<Bonus>>> history({int page = 1, int pageSize = 30});
}
