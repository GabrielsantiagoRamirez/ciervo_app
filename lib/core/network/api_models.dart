typedef JsonMap = Map<String, dynamic>;

class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.status,
    this.value,
    this.message,
    this.errorCode,
  });

  factory ApiEnvelope.fromJson(
    JsonMap json,
    T Function(Object? json) decodeValue,
  ) {
    return ApiEnvelope<T>(
      status: json['status'] == true,
      value: json.containsKey('value') ? decodeValue(json['value']) : null,
      message: _stringOrNull(json['msg']),
      errorCode: _stringOrNull(json['errorCode']),
    );
  }

  final bool status;
  final T? value;
  final String? message;
  final String? errorCode;
}

class ProblemDetailsModel {
  const ProblemDetailsModel({
    this.type,
    this.title,
    this.status,
    this.detail,
    this.instance,
    this.correlationId,
    this.errors = const <String, List<String>>{},
  });

  factory ProblemDetailsModel.fromJson(JsonMap json) {
    return ProblemDetailsModel(
      type: _stringOrNull(json['type']),
      title: _stringOrNull(json['title']),
      status: _intOrNull(json['status']),
      detail: _stringOrNull(json['detail']),
      instance: _stringOrNull(json['instance']),
      correlationId: _stringOrNull(json['correlationId']),
      errors: parseFieldErrors(json['errors']),
    );
  }

  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final String? instance;
  final String? correlationId;
  final Map<String, List<String>> errors;

  String? get safeMessage {
    final detailValue = detail?.trim();
    if (detailValue != null && detailValue.isNotEmpty) return detailValue;
    final titleValue = title?.trim();
    if (titleValue != null && titleValue.isNotEmpty) return titleValue;
    for (final messages in errors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return null;
  }
}

class PagedResponse<T> {
  const PagedResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory PagedResponse.fromJson(
    JsonMap json,
    T Function(Object? json) decodeItem,
  ) {
    final rawItems = json['items'];
    return PagedResponse<T>(
      page: _intOrNull(json['page']) ?? 1,
      pageSize: _intOrNull(json['pageSize']) ?? 0,
      total: _intOrNull(json['total']) ?? 0,
      totalPages: _intOrNull(json['totalPages']) ?? 0,
      items: rawItems is List
          ? List<T>.unmodifiable(rawItems.map(decodeItem))
          : List<T>.unmodifiable(const []),
    );
  }

  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final List<T> items;

  bool get hasNextPage => page < totalPages;
}

class CursorPage<T> {
  const CursorPage({
    required this.nextCursor,
    required this.hasMore,
    required this.items,
  });

  factory CursorPage.fromJson(
    JsonMap json,
    T Function(Object? json) decodeItem,
  ) {
    final rawItems = json['items'];
    return CursorPage<T>(
      nextCursor: _intOrNull(json['nextCursor']) ?? 0,
      hasMore: json['hasMore'] == true,
      items: rawItems is List
          ? List<T>.unmodifiable(rawItems.map(decodeItem))
          : List<T>.unmodifiable(const []),
    );
  }

  final int nextCursor;
  final bool hasMore;
  final List<T> items;
}

Map<String, List<String>> parseFieldErrors(Object? raw) {
  if (raw is! Map) return const <String, List<String>>{};
  return Map<String, List<String>>.unmodifiable(
    raw.map((key, value) {
      final values = value is Iterable
          ? value
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : <String>[
              if (value != null && value.toString().trim().isNotEmpty)
                value.toString().trim(),
            ];
      return MapEntry(key.toString(), values);
    }),
  );
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? _intOrNull(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}
