class ChildPhotoUpload {
  const ChildPhotoUpload({required this.mediaId, this.photoUrl});

  final String mediaId;
  final String? photoUrl;
}

class LinkChildRequest {
  const LinkChildRequest({
    required this.kidsPublicId,
    required this.relationshipType,
    this.isPrimaryGuardian = false,
  });

  final String kidsPublicId;
  final int relationshipType;
  final bool isPrimaryGuardian;

  Map<String, dynamic> toJson() => {
        'kidsPublicId': kidsPublicId.trim(),
        'relationshipType': relationshipType,
        'isPrimaryGuardian': isPrimaryGuardian,
      };
}
