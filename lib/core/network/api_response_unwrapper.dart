import '../errors/app_exception.dart';

Object? unwrapApiResponse(Object? response) {
  if (response is Map<String, dynamic>) {
    if (response['status'] == false) {
      throw AppException(
        message:
            response['msg']?.toString() ?? 'No pudimos completar la solicitud.',
        code: response['errorCode']?.toString() ?? response['code']?.toString(),
        correlationId: response['correlationId']?.toString(),
        fieldErrors: _fieldErrors(response['errors']),
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

Map<String, List<String>> _fieldErrors(Object? raw) {
  if (raw is! Map) return const <String, List<String>>{};

  return Map<String, List<String>>.unmodifiable(
    raw.map((key, value) {
      final messages = value is Iterable
          ? value.map((item) => item.toString()).toList(growable: false)
          : <String>[if (value != null) value.toString()];
      return MapEntry(key.toString(), messages);
    }),
  );
}
