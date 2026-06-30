import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/settlement_catalog.dart';

class SettlementPolicy {
  const SettlementPolicy({
    required this.settlementFrequencyDays,
    required this.policyMessage,
    required this.securityMessage,
  });

  final int settlementFrequencyDays;
  final String policyMessage;
  final String securityMessage;

  factory SettlementPolicy.fromJson(Map<String, dynamic> json) =>
      SettlementPolicy(
        settlementFrequencyDays:
            int.tryParse('${json['settlementFrequencyDays'] ?? 7}') ?? 7,
        policyMessage:
            '${json['policyMessage'] ?? json['message'] ?? 'Las liquidaciones se realizan cada 7 días.'}',
        securityMessage:
            '${json['securityMessage'] ?? 'Tus datos serán usados únicamente para realizar tus pagos.'}',
      );

  static const fallback = SettlementPolicy(
    settlementFrequencyDays: 7,
    policyMessage: 'Las liquidaciones se realizan cada 7 días.',
    securityMessage:
        'Tus datos serán usados únicamente para realizar tus pagos.',
  );
}

class CatalogRepository {
  const CatalogRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<SettlementCountry>>> settlementCountries() async {
    try {
      final response =
          await _client.dio.get<dynamic>('/api/catalogs/settlement-countries');
      final failure = _catalogFailure(response.data);
      if (failure != null) return Failure(failure);

      final items = unwrapApiList(response.data)
          .whereType<Map>()
          .map((item) => SettlementCountry.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.code.isNotEmpty)
          .toList();
      return Success(items);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const Success([]);
      }
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<Result<List<BankOption>>> banks({required String country}) =>
      _fetchBanks('/api/catalogs/banks', {'country': country});

  Future<Result<List<SettlementMethodOption>>> settlementMethods({
    required String country,
  }) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '/api/catalogs/settlement-methods',
        queryParameters: {'country': country},
      );
      final failure = _catalogFailure(response.data);
      if (failure != null) return Failure(failure);

      final items = unwrapApiList(response.data)
          .whereType<Map>()
          .map(
            (item) => SettlementMethodOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.code.isNotEmpty && item.name.isNotEmpty)
          .toList();
      return Success(items);
    } on DioException catch (error) {
      final mapped = ErrorMapper.fromObject(error);
      if (error.response?.statusCode == 404) {
        return Failure(
          AppException(
            message: mapped.message.contains('completar')
                ? 'Liquidación no disponible para este país.'
                : mapped.message,
            statusCode: 404,
          ),
        );
      }
      return Failure(mapped);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<Result<SettlementPolicy>> settlementPolicy({
    required String country,
  }) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '/api/delivery/settlement-policy',
        queryParameters: {'country': country},
      );
      final failure = _catalogFailure(response.data);
      if (failure != null) return Failure(failure);
      return Success(
        SettlementPolicy.fromJson(unwrapApiMap(response.data)),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const Success(SettlementPolicy.fallback);
      }
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<Result<List<BankOption>>> _fetchBanks(
    String path,
    Map<String, dynamic> query,
  ) async {
    try {
      final response = await _client.dio.get<dynamic>(
        path,
        queryParameters: query,
      );
      final failure = _catalogFailure(response.data);
      if (failure != null) return Failure(failure);

      final items = unwrapApiList(response.data)
          .whereType<Map>()
          .map((item) => BankOption.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList();
      return Success(items);
    } on DioException catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  AppException? _catalogFailure(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final status = map['status'];
    if (status == false) {
      return AppException(
        message: map['msg']?.toString() ??
            map['message']?.toString() ??
            'Este país no está disponible para liquidaciones.',
        code: map['code']?.toString(),
      );
    }
    final wrapped = map['value'] ?? map['data'];
    if (wrapped is Map) {
      final inner = Map<String, dynamic>.from(wrapped);
      if (inner['status'] == false) {
        return AppException(
          message: inner['msg']?.toString() ??
              inner['message']?.toString() ??
              'Este país no está disponible para liquidaciones.',
          code: inner['code']?.toString(),
        );
      }
    }
    return null;
  }
}
