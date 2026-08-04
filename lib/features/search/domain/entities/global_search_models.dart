enum GlobalSearchItemType {
  person,
  business,
  product,
  promotion,
  service,
  event,
  unknown;

  static GlobalSearchItemType fromApi(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    return switch (value) {
      'person' ||
      'people' ||
      'persona' ||
      'personas' ||
      'user' ||
      'users' => person,
      'business' ||
      'businesses' ||
      'lugar' ||
      'lugares' ||
      'comercio' ||
      'comercios' => business,
      'product' ||
      'products' ||
      'producto' ||
      'productos' ||
      'comida' => product,
      'promotion' ||
      'promotions' ||
      'promo' ||
      'promos' ||
      'promocion' ||
      'promociones' => promotion,
      'service' || 'services' || 'servicio' || 'servicios' => service,
      'event' || 'events' || 'evento' || 'eventos' => event,
      _ => unknown,
    };
  }

  /// Valor `types=` del API (inglés plural).
  String get apiTypesParam => switch (this) {
    person => 'people',
    business => 'businesses',
    product => 'products',
    promotion => 'promotions',
    service => 'services',
    event => 'events',
    unknown => 'all',
  };

  String get chipLabel => switch (this) {
    person => 'Personas',
    business => 'Lugares',
    product => 'Productos',
    promotion => 'Promos',
    service => 'Servicios',
    event => 'Eventos',
    unknown => 'Otros',
  };
}

class GlobalSearchItem {
  const GlobalSearchItem({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.distanceKm,
    this.imageUrl,
    this.username,
    this.ciervoUserCode,
    this.accountType,
    this.businessId,
    this.ciervoId,
    this.city,
    this.price,
    this.currency,
    this.businessName,
  });

  final GlobalSearchItemType type;
  final String id;
  final String title;
  final String? subtitle;
  final double? distanceKm;
  final String? imageUrl;
  final String? username;
  final String? ciervoUserCode;
  final String? accountType;
  final String? businessId;
  final String? ciervoId;
  final String? city;
  final double? price;
  final String? currency;
  final String? businessName;

  String get distanceLabel {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()} m';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  String get priceLabel {
    if (price == null) return '';
    final cur = (currency ?? 'COP').toUpperCase();
    final amount = price! % 1 == 0
        ? price!.toStringAsFixed(0)
        : price!.toStringAsFixed(2);
    return '$cur $amount';
  }

  factory GlobalSearchItem.fromJson(Map<String, dynamic> json) {
    final type = GlobalSearchItemType.fromApi(
      '${json['type'] ?? json['Type'] ?? ''}',
    );
    final nested = json['negocio'] ?? json['business'] ?? json['place'];
    final nestedMap = nested is Map
        ? Map<String, dynamic>.from(nested)
        : const <String, dynamic>{};

    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key] ?? nestedMap[key];
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return null;
    }

    double? numOrNull(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse('$value');
    }

    final id =
        pick(const ['id', 'Id', 'businessId', 'userId', 'productId']) ?? '';
    final title =
        pick(const [
          'title',
          'name',
          'fullName',
          'displayName',
          'businessName',
        ]) ??
        'Sin título';

    return GlobalSearchItem(
      type: type,
      id: id,
      title: title,
      subtitle: pick(const ['subtitle', 'address', 'city', 'category']),
      distanceKm: numOrNull(json['distanceKm'] ?? json['DistanceKm']),
      imageUrl: pick(const [
        'imageUrl',
        'logoUrl',
        'photoUrl',
        'thumbnailUrl',
        'avatarUrl',
      ]),
      username: pick(const ['username', 'userName']),
      ciervoUserCode: pick(const [
        'ciervoUserCode',
        'ciervoId',
        'userCode',
        'CiervoUserCode',
      ]),
      accountType: pick(const ['accountType', 'AccountType']),
      businessId: pick(const ['businessId', 'BusinessId', 'storeId']),
      ciervoId: pick(const ['ciervoId', 'CiervoId', 'businessCode']),
      city: pick(const ['city', 'City']),
      price: numOrNull(json['price'] ?? json['Price'] ?? json['offerPrice']),
      currency: pick(const ['currency', 'Currency']),
      businessName: pick(const ['businessName', 'BusinessName', 'storeName']),
    );
  }
}

class GlobalSearchCounts {
  const GlobalSearchCounts({
    this.people = 0,
    this.businesses = 0,
    this.products = 0,
    this.promotions = 0,
    this.services = 0,
    this.events = 0,
  });

  final int people;
  final int businesses;
  final int products;
  final int promotions;
  final int services;
  final int events;

  int get total =>
      people + businesses + products + promotions + services + events;

  int forType(GlobalSearchItemType type) => switch (type) {
    GlobalSearchItemType.person => people,
    GlobalSearchItemType.business => businesses,
    GlobalSearchItemType.product => products,
    GlobalSearchItemType.promotion => promotions,
    GlobalSearchItemType.service => services,
    GlobalSearchItemType.event => events,
    GlobalSearchItemType.unknown => 0,
  };

  factory GlobalSearchCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GlobalSearchCounts();
    int read(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value.toInt();
        final parsed = int.tryParse('$value');
        if (parsed != null) return parsed;
      }
      return 0;
    }

    return GlobalSearchCounts(
      people: read(const ['people', 'personas', 'person']),
      businesses: read(const ['businesses', 'lugares', 'business']),
      products: read(const ['products', 'productos', 'comida', 'product']),
      promotions: read(const ['promotions', 'promos', 'promociones']),
      services: read(const ['services', 'servicios', 'service']),
      events: read(const ['events', 'eventos', 'event']),
    );
  }
}

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.items,
    this.query = '',
    this.originLatitude,
    this.originLongitude,
    this.radiusKm,
    this.total = 0,
    this.counts = const GlobalSearchCounts(),
  });

  final List<GlobalSearchItem> items;
  final String query;
  final double? originLatitude;
  final double? originLongitude;
  final double? radiusKm;
  final int total;
  final GlobalSearchCounts counts;

  factory GlobalSearchResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'] ?? const [];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (e) => GlobalSearchItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <GlobalSearchItem>[];

    final countsRaw = json['counts'] ?? json['Counts'];
    final counts = GlobalSearchCounts.fromJson(
      countsRaw is Map ? Map<String, dynamic>.from(countsRaw) : null,
    );

    double? d(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    return GlobalSearchResult(
      items: items,
      query: '${json['query'] ?? json['Query'] ?? ''}',
      originLatitude: d(json['originLatitude'] ?? json['OriginLatitude']),
      originLongitude: d(json['originLongitude'] ?? json['OriginLongitude']),
      radiusKm: d(json['radiusKm'] ?? json['RadiusKm']),
      total: (json['total'] is num)
          ? (json['total'] as num).toInt()
          : items.length,
      counts: counts,
    );
  }
}
