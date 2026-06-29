import '../../../../core/result/result.dart';
import '../entities/favorite_business.dart';
import '../entities/favorite_filters.dart';

abstract interface class FavoritesRepository {
  Future<Result<List<FavoriteBusiness>>> list(FavoriteFilters filters);

  Future<Result<bool>> check(String businessId);

  Future<Result<void>> add(String businessId);

  Future<Result<void>> remove(String businessId);
}
