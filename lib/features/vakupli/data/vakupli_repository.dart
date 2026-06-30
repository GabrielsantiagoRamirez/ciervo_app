import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/vakupli_plan.dart';

class VakupliRepository {
  const VakupliRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<VakupliPlan>>> plans() => _guard(() async {
        final response = await _client.dio.get<dynamic>('/api/vakupli/plans');
        final value = unwrapApiResponse(response.data);
        final items = value is List
            ? value
            : value is Map && value['items'] is List
            ? value['items'] as List
            : const [];
        return items
            .whereType<Map>()
            .map((item) => _planFromJson(Map<String, dynamic>.from(item)))
            .toList();
      });

  Future<Result<VakupliPlan>> createPlan({
    required String title,
    required double totalAmount,
    required VakupliSplitOption splitOption,
    String? description,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/vakupli/plans',
          data: {
            'title': title.trim(),
            'totalAmount': totalAmount,
            'currency': 'COP',
            'splitOption': splitOption.name,
            if (description != null && description.trim().isNotEmpty)
              'description': description.trim(),
          },
        );
        return _planFromJson(unwrapApiMap(response.data));
      });

  Future<Result<void>> inviteToPlan({
    required int planId,
    required String userId,
  }) =>
      _guard(() async {
        await _client.dio.post<void>(
          '/api/vakupli/plans/$planId/invites',
          data: {'userId': int.tryParse(userId) ?? userId},
        );
      });

  Future<Result<List<VakupliMessage>>> messages(int planId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/vakupli/plans/$planId/messages',
        );
        final value = unwrapApiResponse(response.data);
        final items = value is List
            ? value
            : value is Map && value['items'] is List
            ? value['items'] as List
            : const [];
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
          '/api/vakupli/plans/$planId/messages',
          data: {'text': text.trim()},
        );
        return _messageFromJson(unwrapApiMap(response.data));
      });

  Future<Result<Map<String, dynamic>>> paySplit({
    required int planId,
    required double amount,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/vakupli/plans/$planId/pay',
          data: {'amount': amount, 'currency': 'COP'},
        );
        return unwrapApiMap(response.data);
      });

  VakupliPlan _planFromJson(Map<String, dynamic> json) {
    final friendsRaw = json['friends'] ?? json['participants'];
    final messagesRaw = json['messages'];
    return VakupliPlan(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      title: '${json['title'] ?? 'Plan Vakupli'}',
      timeLeftLabel: '${json['timeLeftLabel'] ?? json['expiresIn'] ?? ''}',
      statusLabel: '${json['statusLabel'] ?? json['status'] ?? 'Activo'}',
      totalAmount: _num(json['totalAmount'] ?? json['amount']),
      selfDestructLabel:
          '${json['selfDestructLabel'] ?? 'Chat temporal del plan'}',
      friends: friendsRaw is List
          ? friendsRaw
                .whereType<Map>()
                .map(
                  (f) => VakupliFriend(
                    name: '${f['name'] ?? 'Amigo'}',
                    initials: '${f['initials'] ?? _initials('${f['name']}')}',
                  ),
                )
                .toList()
          : const [],
      messages: messagesRaw is List
          ? messagesRaw
                .whereType<Map>()
                .map((m) => _messageFromJson(Map<String, dynamic>.from(m)))
                .toList()
          : const [],
    );
  }

  VakupliMessage _messageFromJson(Map<String, dynamic> json) => VakupliMessage(
        senderName: '${json['senderName'] ?? json['sender'] ?? 'Usuario'}',
        text: '${json['text'] ?? json['body'] ?? ''}',
        timeLabel: '${json['timeLabel'] ?? json['createdAt'] ?? ''}',
        isCurrentUser: json['isCurrentUser'] == true || json['isMine'] == true,
      );

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

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
