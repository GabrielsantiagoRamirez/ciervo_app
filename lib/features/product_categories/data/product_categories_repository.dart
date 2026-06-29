import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/product_category.dart';

class ProductCategoriesRepository {
  const ProductCategoriesRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<ProductCategory>>> byBusinessCategory(
    int businessCategoryId,
  ) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '/api/product-categories',
        queryParameters: {'businessCategoryId': businessCategoryId},
      );
      final items = unwrapApiList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .where((category) => category.active)
          .toList();
      return Success(items);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

ProductCategory _fromJson(Map<String, dynamic> json) => ProductCategory(
      id: _int(json['id'] ?? json['productCategoryId']),
      code: _string(json['code']),
      name: _string(json['name'] ?? json['displayName']),
      businessCategoryId: _int(json['businessCategoryId']),
      active: json['active'] != false && json['isActive'] != false,
    );

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

String _string(dynamic value) => value?.toString() ?? '';
