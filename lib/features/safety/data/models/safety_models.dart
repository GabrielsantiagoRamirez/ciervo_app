enum ReportTargetType {
  user('User'),
  post('Post'),
  business('Business'),
  event('Event'),
  promotion('Promotion'),
  chatMessage('ChatMessage'),
  comment('Comment'),
  ad('Ad'),
  other('Other');

  const ReportTargetType(this.apiValue);
  final String apiValue;
}

enum ReportReason {
  spam('Spam', 'Spam o publicidad engañosa'),
  harassment('Harassment', 'Acoso o intimidación'),
  hate('Hate', 'Lenguaje ofensivo u odio'),
  scam('Scam', 'Estafa o fraude'),
  sexualContent('SexualContent', 'Contenido sexual inapropiado'),
  violence('Violence', 'Violencia o amenaza'),
  fakeProfile('FakeProfile', 'Perfil falso'),
  illegal('Illegal', 'Contenido ilegal'),
  other('Other', 'Otro');

  const ReportReason(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class UserReportModel {
  const UserReportModel({
    required this.id,
    required this.targetType,
    this.targetId,
    this.reportedUserId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String targetType;
  final String? targetId;
  final int? reportedUserId;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;

  factory UserReportModel.fromJson(Map<String, dynamic> json) => UserReportModel(
        id: json['id'] as int? ?? int.tryParse('${json['id']}') ?? 0,
        targetType: json['targetType']?.toString() ?? '',
        targetId: json['targetId']?.toString(),
        reportedUserId: json['reportedUserId'] as int?,
        reason: json['reason']?.toString() ?? '',
        description: json['description']?.toString(),
        status: json['status']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now().toUtc(),
      );
}

class BlockedUserModel {
  const BlockedUserModel({
    required this.userId,
    this.displayName,
    this.ciervoUserCode,
    this.photoUrl,
    required this.blockedAt,
  });

  final int userId;
  final String? displayName;
  final String? ciervoUserCode;
  final String? photoUrl;
  final DateTime blockedAt;

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) => BlockedUserModel(
        userId: json['userId'] as int? ?? int.tryParse('${json['userId']}') ?? 0,
        displayName: json['displayName']?.toString(),
        ciervoUserCode: json['ciervoUserCode']?.toString(),
        photoUrl: json['photoUrl']?.toString(),
        blockedAt: DateTime.tryParse(json['blockedAt']?.toString() ?? '') ??
            DateTime.now().toUtc(),
      );
}

class ContentBlockModel {
  const ContentBlockModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  final int id;
  final String targetType;
  final String targetId;
  final DateTime createdAt;

  factory ContentBlockModel.fromJson(Map<String, dynamic> json) =>
      ContentBlockModel(
        id: json['id'] as int? ?? int.tryParse('${json['id']}') ?? 0,
        targetType: json['targetType']?.toString() ?? '',
        targetId: json['targetId']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now().toUtc(),
      );

  String get key => '$targetType:$targetId';
}
