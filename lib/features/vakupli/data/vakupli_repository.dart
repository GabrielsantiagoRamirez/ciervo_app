import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/vakupli_plan.dart';

class VakupliRepository {
  const VakupliRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<VakupliPlan>>> plans({int page = 1, int pageSize = 20}) async {
    final result = await listGroups(page: page, pageSize: pageSize);
    return result.when(
      success: (pageResult) => Success(pageResult.items),
      failure: Failure.new,
    );
  }

  Future<Result<VakupliGroupsPage>> listGroups({
    int page = 1,
    int pageSize = 20,
  }) =>
      _guard(() async {
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

  Future<Result<VakupliPlan>> createPlan({
    required String title,
    required double totalAmount,
    required VakupliSplitOption splitOption,
    String? description,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/vakupli/groups',
          data: {
            'name': title.trim(),
            if (description != null && description.trim().isNotEmpty)
              'description': description.trim(),
            'initialContributionAmount': totalAmount,
            'currency': 'COP',
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
  }) =>
      _guard(() async {
        await _client.dio.post<void>(
          '/api/vakupli/groups/$planId/invite',
          data: {
            'userId': int.tryParse(userId) ?? userId,
            'amount': amount,
            'currency': 'COP',
          },
        );
      });

  Future<Result<List<VakupliFriend>>> participants(int groupId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/vakupli/groups/$groupId/participants',
        );
        final items = unwrapApiList(response.data);
        return items
            .whereType<Map>()
            .map((item) {
              final map = Map<String, dynamic>.from(item);
              final name =
                  '${map['displayName'] ?? map['name'] ?? map['userName'] ?? 'Participante'}';
              return VakupliFriend(
                name: name,
                initials: _initials(name),
              );
            })
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
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/vakupli/chat/$planId/send',
          data: {'content': text.trim()},
        );
        return _messageFromJson(unwrapApiMap(response.data));
      });

  Future<Result<Map<String, dynamic>>> paySplit({
    required int planId,
    required double amount,
  }) =>
      _guard(() async {
        final contributionsResponse = await _client.dio.get<dynamic>(
          '/api/vakupli/groups/$planId/contributions',
        );
        final contributions = unwrapApiList(contributionsResponse.data)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final pending = contributions.firstWhere(
          (item) {
            final status =
                '${item['status'] ?? item['contributionStatus'] ?? ''}'.toLowerCase();
            return status.contains('pending') || status == '1' || status == '0';
          },
          orElse: () => contributions.isNotEmpty ? contributions.first : {},
        );
        final contributionId = pending['id'] ?? pending['contributionId'];
        if (contributionId == null) {
          throw Exception('No hay cuota pendiente para pagar.');
        }
        final response = await _client.dio.post<dynamic>(
          '/api/vakupli/contributions/$contributionId/pay',
          data: {
            'paymentMethod': 'wallet',
            'idempotencyKey':
                'vakupli-$contributionId-${DateTime.now().microsecondsSinceEpoch}',
          },
        );
        return unwrapApiMap(response.data);
      });

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

    return VakupliPlan(
      id: _intOrNull(json['id'] ?? json['groupId']),
      title: '${json['name'] ?? json['title'] ?? 'Plan Vakupli'}',
      timeLeftLabel: _timeLeftLabel(json, paymentMap),
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
      paidContributions: paid,
      totalContributions: total,
    );
  }

  VakupliMessage _messageFromJson(Map<String, dynamic> json) => VakupliMessage(
        id: _intOrNull(json['id'] ?? json['messageId']),
        senderName: '${json['senderName'] ?? json['sender'] ?? 'Usuario'}',
        text: '${json['content'] ?? json['text'] ?? json['body'] ?? ''}',
        timeLabel: _formatTime(
          DateTime.tryParse('${json['createdAt'] ?? json['sentAt'] ?? ''}'),
        ),
        isCurrentUser: json['isOwnMessage'] == true || json['isCurrentUser'] == true,
      );

  String _statusLabel(Map<String, dynamic> json, Map<String, dynamic> paymentMap) {
    if (paymentMap['isCompleted'] == true) return 'Completado';
    final groupStatus =
        '${paymentMap['groupStatus'] ?? json['status'] ?? 'active'}'.toLowerCase();
    return switch (groupStatus) {
      'active' => 'Activo',
      'confirmed' => 'Confirmado',
      'completed' || 'closed' => 'Completado',
      'cancelled' => 'Cancelado',
      'draft' => 'Borrador',
      _ => 'Activo',
    };
  }

  String _timeLeftLabel(Map<String, dynamic> json, Map<String, dynamic> paymentMap) {
    if (paymentMap['isCompleted'] == true) return 'Finalizado';
    return '${json['code'] ?? 'Plan activo'}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.day}/${local.month} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
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
