class ProfileData {
  const ProfileData({
    required this.name,
    required this.membershipLabel,
    required this.avatarInitials,
    required this.preferences,
    required this.recentExperiences,
    required this.wallet,
    required this.reviews,
  });

  final String name;
  final String membershipLabel;
  final String avatarInitials;
  final List<String> preferences;
  final List<ProfileExperience> recentExperiences;
  final ProfileWallet wallet;
  final List<ProfileReview> reviews;
}

class ProfileExperience {
  const ProfileExperience({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
}

class ProfileWallet {
  const ProfileWallet({
    required this.balance,
    required this.cardMask,
    required this.cardType,
  });

  final double balance;
  final String cardMask;
  final String cardType;
}

class ProfileReview {
  const ProfileReview({
    required this.placeName,
    required this.comment,
    required this.rating,
    required this.timeLabel,
  });

  final String placeName;
  final String comment;
  final double rating;
  final String timeLabel;
}
