import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../../../core/utils/idempotency_key.dart';
import '../domain/entities/vakupli_plan.dart';

class VakupliRepository {
  const VakupliRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<VakupliPlan>>> plans({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await listGroups(page: page, pageSize: pageSize);
    return result.when(
      success: (pageResult) => Success(pageResult.items),
      failure: Failure.new,
    );
  }

  Future<Result<VakupliGroupsPage>> listGroups({
    int page = 1,
    int pageSize = 20,
  }) => _guard(() async {
    final response = await _client.dio.get<dynamic>(
      '/api/vakupli/groups',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final value = unwrapApiResponse(response.data);
    final map = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
    final itemsRaw = map['items'] ?? map['Items'] ?? const [];
    final items = (itemsRaw is List ? itemsRaw : const [])
        .whereType<Map>()
        .map((item) => _planFromJson(Map<String, dynamic>.from(item)))
        .toList();
    return VakupliGroupsPage(
      items: items,
      page: _intOr(map['page'] ?? map['Page'], page),
      pageSize: _intOr(map['pageSize'] ?? map['PageSize'], pageSize),
      total: _intOr(map['total'] ?? map['Total'], items.length),
      totalPages: _intOr(map['totalPages'] ?? map['TotalPages'], 1),
    );
  });

  Future<Result<List<VakupliContact>>> contacts({int take = 50}) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/vakupli/contacts',
          queryParameters: {'take': take},
        );
        return _contactsFromResponse(response.data);
      });

  Future<Result<List<VakupliContact>>> searchContacts({
    required String query,
    int take = 20,
  }) {
    final q = query.trim();
    if (q.isEmpty) return contacts(take: take);
    return _guard(() async {
      final response = await _client.dio.get<dynamic>(
        '/api/vakupli/contacts/search',
        queryParameters: {'q': q, 'take': take},
      );
      return _contactsFromResponse(response.data);
    });
  }

  Future<Result<VakupliPlan>> createPlan({
    required String title,
    required double totalAmount,
    required VakupliSplitOption splitOption,
    String? description,
    String currency = 'COP',
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/vakupli/groups',
      data: {
        'name': title.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'initialContributionAmount': totalAmount,
        'currency': currency.trim().toUpperCase(),
        'isPrivate': true,
        'joinType': 1,
      },
    );
    return _planFromJson(unwrapApiMap(response.data));
  });

  Future<Result<void>> inviteToPlan({
    required int planId,
    required String userId,
    required double amount,
    String currency = 'COP',
  }) => _guard(() async {
    await _client.dio.post<void>(
      '/api/vakupli/groups/$planId/invite',
      data: {
        'userId': int.tryParse(userId) ?? userId,
        'amount': amount,
        'currency': currency.trim().toUpperCase(),
      },
    );
  });

  Future<Result<VakupliExtraSlotsMe>> myExtraSlots() => _guard(() async {
    final response = await _client.dio.get<dynamic>(
      '/api/vakupli/extra-slots/me',
    );
    return VakupliExtraSlotsMe.fromJson(unwrapApiMap(response.data));
  });

  Future<Result<VakupliExtraSlotsPurchase>> purchaseExtraSlots({
    required int groupId,
    int packs = 1,
    int? walletCardId,
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/vakupli/groups/$groupId/extra-slots',
      data: {
        'packs': packs,
        'walletCardId': ?walletCardId,
        'idempotencyKey': idempotencyKey,
      },
    );
    return VakupliExtraSlotsPurchase.fromJson(unwrapApiMap(response.data));
  });

  Future<Result<VakupliPlan>> updateGroup({
    required int groupId,
    String? name,
    String? description,
    bool? isPrivate,
    int? joinType,
  }) => _guard(() async {
    final response = await _client.dio.put<dynamic>(
      '/api/vakupli/groups/$groupId',
      data: {
        if (name != null) 'name': name.trim(),
        if (description != null) 'description': description.trim(),
        if (isPrivate != null) 'isPrivate': isPrivate,
        if (joinType != null) 'joinType': joinType,
      },
    );
    return _planFromJson(unwrapApiMap(response.data));
  });

  Future<Result<void>> cancelGroup(int groupId) => _guard(() async {
    await _client.dio.post<void>('/api/vakupli/groups/$groupId/cancel');
  });

  Future<Result<void>> deleteGroup(int groupId) => _guard(() async {
    await _client.dio.delete<void>('/api/vakupli/groups/$groupId');
  });

  Future<Result<void>> leaveGroup(int groupId) => _guard(() async {
    await _client.dio.post<void>('/api/vakupli/groups/$groupId/leave');
  });

  Future<Result<List<VakupliFriend>>> participants(int groupId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/vakupli/groups/$groupId/participants',
        );
        final items = unwrapApiList(response.data);
        return items
            .whereType<Map>()
            .map((item) => _friendFromJson(Map<String, dynamic>.from(item)))
            .toList();
      });

  Future<Result<List<VakupliMessage>>> messages(int groupId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/vakupli/chat/$groupId/messages',
          queryParameters: {'take': 50},
        );
        final items = unwrapApiList(response.data);
        return items
            .whereType<Map>()
            .map((item) => _messageFromJson(Map<String, dynamic>.from(item)))
            .toList();
      });

  Future<Result<VakupliMessage>> sendMessage({
    required int planId,
    required String text,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/vakupli/chat/$planId/send',
      data: {'content': text.trim()},
    );
    return _messageFromJson(unwrapApiMap(response.data));
  });

  Future<Result<Map<String, dynamic>>> paySplit({
    required int planId,
    required double amount,
    int? walletCardId,
    String paymentMethod = 'wallet',
  }) => _guard(() async {
    final response = await _client.dio.get<dynamic>(
      '/api/vakupli/groups/$planId/contributions',
    );
    final contributions = unwrapApiList(
      response.data,
    ).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    final pending = contributions.firstWhere((item) {
      final status = '${item['status'] ?? item['contributionStatus'] ?? ''}'
          .toLowerCase();
      return status.contains('pending') || status == '1' || status == '0';
    }, orElse: () => contributions.isNotEmpty ? contributions.first : {});
    final contributionId = pending['id'] ?? pending['contributionId'];
    if (contributionId == null) {
      throw Exception('No hay cuota pendiente para pagar.');
    }
    final payResponse = await _client.dio.post<dynamic>(
      '/api/vakupli/contributions/$contributionId/pay',
      data: {
        'paymentMethod': paymentMethod,
        'walletCardId': ?walletCardId,
        'idempotencyKey': IdempotencyKey.generate(),
      },
    );
    return unwrapApiMap(payResponse.data);
  });

  /// Monto pendiente de la cuota del grupo (para UI de saldo).
  Future<Result<({double amount, String currency})>> pendingContributionDue(
    int planId,
  ) => _guard(() async {
    final response = await _client.dio.get<dynamic>(
      '/api/vakupli/groups/$planId/contributions',
    );
    final contributions = unwrapApiList(
      response.data,
    ).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    final pending = contributions.firstWhere((item) {
      final status = '${item['status'] ?? item['contributionStatus'] ?? ''}'
          .toLowerCase();
      return status.contains('pending') || status == '1' || status == '0';
    }, orElse: () => contributions.isNotEmpty ? contributions.first : {});
    if (pending.isEmpty) {
      throw Exception('No hay cuota pendiente para pagar.');
    }
    return (
      amount: _num(pending['amount'] ?? pending['contributionAmount']),
      currency: _nullable(pending['currency']) ?? 'COP',
    );
  });

  List<VakupliContact> _contactsFromResponse(Object? raw) {
    final value = unwrapApiResponse(raw);
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => VakupliContact.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.userId > 0)
          .toList();
    }
    final map = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
    final items = map['items'] ?? map['contacts'] ?? map['data'] ?? const [];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => VakupliContact.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.userId > 0)
        .toList();
  }

  VakupliFriend _friendFromJson(Map<String, dynamic> map) {
    final name =
        '${map['displayName'] ?? map['name'] ?? map['userName'] ?? 'Participante'}'
            .trim();
    final paymentStatus = VakupliPaymentStatus.fromApi(
      map['paymentStatus'] ?? map['status'],
    );
    final hasPaid =
        map['hasPaid'] == true || paymentStatus == VakupliPaymentStatus.paid;
    return VakupliFriend(
      name: name.isEmpty ? 'Participante' : name,
      initials: _initials(name.isEmpty ? 'Participante' : name),
      userId: _intOrNull(map['userId'] ?? map['id']),
      username: _nullable(map['username']),
      photoUrl: _nullable(map['photoUrl'] ?? map['avatarUrl']),
      countryCode: _nullable(map['countryCode']),
      paymentStatus: hasPaid ? VakupliPaymentStatus.paid : paymentStatus,
      hasPaid: hasPaid,
      amount: _numOrNull(map['amount'] ?? map['contributionAmount']),
      currency: _nullable(map['currency']) ?? 'COP',
      contributionId: _intOrNull(map['contributionId']),
    );
  }

  VakupliPlan _planFromJson(Map<String, dynamic> json) {
    final paymentStatus = json['paymentStatus'] ?? json['PaymentStatus'];
    final paymentMap = paymentStatus is Map
        ? Map<String, dynamic>.from(paymentStatus)
        : <String, dynamic>{};
    final paid = _intOr(
      paymentMap['paidContributions'] ?? paymentMap['PaidContributions'],
      0,
    );
    final total = _intOr(
      paymentMap['totalContributions'] ?? paymentMap['TotalContributions'],
      0,
    );
    final totalAmount = _num(
      paymentMap['totalAmount'] ??
          json['initialContributionAmount'] ??
          json['totalAmount'] ??
          json['amount'],
    );
    final status = _statusLabel(json, paymentMap);
    final createdAt = DateTime.tryParse('${json['createdAt'] ?? ''}');
    final maxGuests = _intOrNull(json['maxGuests']);
    final maxTotal = _intOrNull(json['maxTotal']);
    final planGuests = _intOrNull(json['planGuests']);
    final purchasedExtraGuests = _intOrNull(json['purchasedExtraGuests']);
    final extraSlotPackSize = _intOr(json['extraSlotPackSize'], 4);
    final usedSlots = _intOrNull(json['usedSlots']);
    final remainingSlots = _intOrNull(json['remainingSlots']);
    final maxParticipants = maxTotal ??
        (maxGuests != null
            ? maxGuests + 1
            : _intOr(json['maxParticipants'], 4));
    final participantCount = usedSlots ??
        _intOr(json['participantCount'] ?? paymentMap['participantCount'], 0);
    final periodEnds = DateTime.tryParse(
      '${json['extraSlotsPeriodEndsAt'] ?? ''}',
    );
    final expiresAt = DateTime.tryParse(
      '${json['expiresAt'] ?? paymentMap['expiresAt'] ?? ''}',
    );
    final remainingSeconds = _intOrNull(
      json['remainingSeconds'] ?? paymentMap['remainingSeconds'],
    );

    return VakupliPlan(
      id: _intOrNull(json['id'] ?? json['groupId']),
      title: '${json['name'] ?? json['title'] ?? 'Plan Vaku'}',
      timeLeftLabel: _timeLeftLabel(
        expiresAt: expiresAt,
        remainingSeconds: remainingSeconds,
        createdAt: createdAt,
        paymentCompleted: paymentMap['isCompleted'] == true,
      ),
      statusLabel: status,
      totalAmount: totalAmount,
      selfDestructLabel: 'Chat temporal del grupo',
      friends: const [],
      messages: const [],
      chatId: _intOrNull(json['chatId'] ?? json['ChatId']),
      code: json['code']?.toString(),
      shareUrl: json['shareUrl']?.toString(),
      deepLink: json['deepLink']?.toString(),
      createdAt: createdAt,
      expiresAt: expiresAt,
      remainingSeconds: remainingSeconds,
      paidContributions: paid,
      totalContributions: total,
      participantCount: participantCount,
      maxParticipants: maxParticipants,
      maxGuests: maxGuests,
      maxTotal: maxTotal ?? maxParticipants,
      planGuests: planGuests,
      purchasedExtraGuests: purchasedExtraGuests,
      extraSlotPackSize: extraSlotPackSize,
      nextPackPriceUsd: _numOrNull(json['nextPackPriceUsd']),
      extraSlotsPeriodEndsAt: periodEnds,
      extraSlotsPeriodActive: json['extraSlotsPeriodActive'] == true,
      usedSlots: usedSlots,
      remainingSlots: remainingSlots,
      planCode: _nullable(json['planCode'] ?? json['membershipPlan']),
    );
  }

  VakupliMessage _messageFromJson(Map<String, dynamic> json) => VakupliMessage(
    id: _intOrNull(json['id'] ?? json['messageId']),
    senderName: '${json['senderName'] ?? json['sender'] ?? 'Usuario'}',
    text: '${json['content'] ?? json['text'] ?? json['body'] ?? ''}',
    timeLabel: _formatTime(
      DateTime.tryParse('${json['createdAt'] ?? json['sentAt'] ?? ''}'),
    ),
    isCurrentUser:
        json['isOwnMessage'] == true || json['isCurrentUser'] == true,
  );

  String _statusLabel(
    Map<String, dynamic> json,
    Map<String, dynamic> paymentMap,
  ) {
    if (paymentMap['isCompleted'] == true) return 'Completado';
    final groupStatus =
        '${paymentMap['groupStatus'] ?? json['status'] ?? 'active'}'
            .toLowerCase();
    return switch (groupStatus) {
      'active' => 'Activo',
      'confirmed' => 'Confirmado',
      'completed' || 'closed' => 'Completado',
      'cancelled' => 'Cancelado',
      'draft' => 'Borrador',
      _ => 'Activo',
    };
  }

  String _timeLeftLabel({
    required DateTime? expiresAt,
    required int? remainingSeconds,
    required DateTime? createdAt,
    required bool paymentCompleted,
  }) {
    if (paymentCompleted) return 'Finalizado';
    // Preferir remainingSeconds del API (countdown listo).
    if (remainingSeconds != null) {
      return _formatSeconds(remainingSeconds);
    }
    if (expiresAt != null) return _formatCountdown(expiresAt);
    // Fallback solo si el API aún no manda campos: createdAt + 24h.
    if (createdAt != null) {
      return _formatCountdown(createdAt.toUtc().add(const Duration(hours: 24)));
    }
    return 'Activo';
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return 'Expirado';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours >= 24) {
      final days = hours ~/ 24;
      final remHours = hours % 24;
      return '${days}d ${remHours}h';
    }
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  String _formatCountdown(DateTime endsAt) {
    final left = endsAt.toUtc().difference(DateTime.now().toUtc());
    return _formatSeconds(left.isNegative ? 0 : left.inSeconds);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.day}/${local.month} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  double? _numOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  int _intOr(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse('$value');
  }

  String? _nullable(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } on DioException catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
