enum FavoriteSortBy {
  recent('recent'),
  name('name'),
  distance('distance'),
  mostVisited('mostVisited');

  const FavoriteSortBy(this.apiValue);

  final String apiValue;

  String get label => switch (this) {
        FavoriteSortBy.recent => 'Recientes',
        FavoriteSortBy.name => 'Nombre',
        FavoriteSortBy.distance => 'Distancia',
        FavoriteSortBy.mostVisited => 'Mas visitados',
      };
}

class FavoriteFilters {
  const FavoriteFilters({
    this.country,
    this.city,
    this.zone,
    this.categoryId,
    this.nearLat,
    this.nearLng,
    this.radiusKm,
    this.sortBy = FavoriteSortBy.recent,
    this.page = 1,
    this.pageSize = 30,
  });

  final String? country;
  final String? city;
  final String? zone;
  final int? categoryId;
  final double? nearLat;
  final double? nearLng;
  final double? radiusKm;
  final FavoriteSortBy sortBy;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
        if (country != null && country!.isNotEmpty) 'country': country,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (zone != null && zone!.isNotEmpty) 'zone': zone,
        if (categoryId != null) 'categoryId': categoryId,
        if (nearLat != null) 'nearLat': nearLat,
        if (nearLng != null) 'nearLng': nearLng,
        if (radiusKm != null) 'radiusKm': radiusKm,
        'sortBy': sortBy.apiValue,
        'page': page,
        'pageSize': pageSize,
      };

  FavoriteFilters copyWith({
    String? country,
    String? city,
    String? zone,
    int? categoryId,
    double? nearLat,
    double? nearLng,
    double? radiusKm,
    FavoriteSortBy? sortBy,
    int? page,
    int? pageSize,
  }) =>
      FavoriteFilters(
        country: country ?? this.country,
        city: city ?? this.city,
        zone: zone ?? this.zone,
        categoryId: categoryId ?? this.categoryId,
        nearLat: nearLat ?? this.nearLat,
        nearLng: nearLng ?? this.nearLng,
        radiusKm: radiusKm ?? this.radiusKm,
        sortBy: sortBy ?? this.sortBy,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );
}
