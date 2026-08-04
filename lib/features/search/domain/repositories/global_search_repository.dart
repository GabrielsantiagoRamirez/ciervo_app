import '../../../../core/result/result.dart';
import '../entities/global_search_models.dart';

abstract interface class GlobalSearchRepository {
  Future<Result<GlobalSearchResult>> search({
    String? query,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 20,

    /// null / vacío = todos los tipos. Valores API: people,businesses,...
    String? types,
  });
}
