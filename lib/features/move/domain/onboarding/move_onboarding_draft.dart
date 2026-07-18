import 'move_onboarding_enums.dart';

class MoveOnboardingIntent {
  const MoveOnboardingIntent({
    required this.idempotencyKey,
    required this.payloadHash,
    required this.createdAt,
  });

  factory MoveOnboardingIntent.fromJson(Map<String, dynamic> json) {
    return MoveOnboardingIntent(
      idempotencyKey: json['idempotencyKey']?.toString() ?? '',
      payloadHash: json['payloadHash']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String idempotencyKey;
  final String payloadHash;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'idempotencyKey': idempotencyKey,
    'payloadHash': payloadHash,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

/// Borrador mínimo: no contiene nombres, documentos, contactos ni placas.
class MoveOnboardingDraft {
  const MoveOnboardingDraft({
    this.countryCode,
    this.currentStage = MoveOnboardingStageType.unknown,
    this.assetIds = const {},
    this.intents = const {},
    this.updatedAt,
  });

  factory MoveOnboardingDraft.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assetIds'];
    final rawIntents = json['intents'];
    return MoveOnboardingDraft(
      countryCode: json['countryCode']?.toString(),
      currentStage: MoveOnboardingStageType.fromValue(json['currentStage']),
      assetIds: rawAssets is Map
          ? Map<String, int>.unmodifiable(
              rawAssets.map(
                (key, value) =>
                    MapEntry(key.toString(), int.tryParse('$value') ?? 0),
              )..removeWhere((_, value) => value <= 0),
            )
          : const {},
      intents: rawIntents is Map
          ? Map<String, MoveOnboardingIntent>.unmodifiable(
              rawIntents.map(
                (key, value) => MapEntry(
                  key.toString(),
                  MoveOnboardingIntent.fromJson(
                    Map<String, dynamic>.from(value as Map),
                  ),
                ),
              ),
            )
          : const {},
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  final String? countryCode;
  final MoveOnboardingStageType currentStage;
  final Map<String, int> assetIds;
  final Map<String, MoveOnboardingIntent> intents;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'countryCode': countryCode,
    'currentStage': currentStage.value,
    'assetIds': assetIds,
    'intents': intents.map((key, value) => MapEntry(key, value.toJson())),
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
  };

  MoveOnboardingDraft copyWith({
    String? countryCode,
    MoveOnboardingStageType? currentStage,
    Map<String, int>? assetIds,
    Map<String, MoveOnboardingIntent>? intents,
    DateTime? updatedAt,
  }) {
    return MoveOnboardingDraft(
      countryCode: countryCode ?? this.countryCode,
      currentStage: currentStage ?? this.currentStage,
      assetIds: assetIds ?? this.assetIds,
      intents: intents ?? this.intents,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

abstract interface class MoveOnboardingDraftStore {
  Future<MoveOnboardingDraft?> read(String userId);

  Future<void> write(String userId, MoveOnboardingDraft draft);

  Future<MoveOnboardingIntent> saveIntent({
    required String userId,
    required String operation,
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  });

  Future<void> completeIntent(String userId, String operation);

  Future<void> clear(String userId);
}
