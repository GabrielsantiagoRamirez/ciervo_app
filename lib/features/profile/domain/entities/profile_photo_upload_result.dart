class ProfilePhotoUploadResult {
  const ProfilePhotoUploadResult({
    required this.mediaId,
    this.photoUrl,
    this.imageUrl,
    this.storagePath,
    this.photoUpdatedAt,
  });

  final String mediaId;
  final String? photoUrl;
  final String? imageUrl;
  final String? storagePath;
  final DateTime? photoUpdatedAt;
}
