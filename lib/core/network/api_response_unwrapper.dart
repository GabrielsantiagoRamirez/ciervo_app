import '../errors/app_exception.dart';
import 'api_models.dart';

Object? unwrapApiResponse(Object? response) {
  if (response is Map<String, dynamic>) {
    if (response['status'] == false) {
      final problem = ProblemDetailsModel.fromJson(response);
      throw AppException(
        message:
            response['msg']?.toString() ??
            problem.safeMessage ??
            'No pudimos completar la solicitud.',
        code: response['errorCode']?.toString() ?? response['code']?.toString(),
        statusCode: problem.status,
        correlationId: response['correlationId']?.toString(),
        fieldErrors: problem.errors,
      );
    }
    if (response.containsKey('value')) {
      return response['value'];
    }
    if (response.containsKey('data')) {
      return response['data'];
    }
  }
  return response;
}

Map<String, dynamic> unwrapApiMap(Object? response) {
  final value = unwrapApiResponse(response);
  return value is Map<String, dynamic> ? value : const <String, dynamic>{};
}

List<dynamic> unwrapApiList(Object? response) {
  final value = unwrapApiResponse(response);
  if (value is List) {
    return value;
  }
  if (value is Map<String, dynamic> && value['items'] is List) {
    return value['items'] as List;
  }
  return const [];
}
