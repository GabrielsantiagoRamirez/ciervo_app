class PlaceDetail {
  const PlaceDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.gallery = const [],
    required this.rating,
    required this.reviewCount,
    required this.locationLabel,
    required this.distanceKm,
    required this.description,
    required this.tags,
    required this.promotions,
    required this.reviews,
  });

  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final List<String> gallery;
  final double rating;
  final int reviewCount;
  final String locationLabel;
  final double distanceKm;
  final String description;
  final List<String> tags;
  final List<PlacePromotion> promotions;
  final List<PlaceReview> reviews;
}

class PlacePromotion {
  const PlacePromotion({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class PlaceReview {
  const PlaceReview({
    required this.userName,
    required this.comment,
    required this.rating,
    required this.timeAgo,
    this.id,
  });

  final int? id;
  final String userName;
  final String comment;
  final double rating;
  final String timeAgo;
}
