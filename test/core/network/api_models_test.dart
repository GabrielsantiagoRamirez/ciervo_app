import 'package:ciervo_clud/core/network/api_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea envelope y paginación tipada', () {
    final envelope = ApiEnvelope<PagedResponse<int>>.fromJson(
      {
        'status': true,
        'value': {
          'page': 2,
          'pageSize': 2,
          'total': 5,
          'totalPages': 3,
          'items': [3, 4],
        },
      },
      (value) => PagedResponse<int>.fromJson(
        Map<String, dynamic>.from(value! as Map),
        (item) => item! as int,
      ),
    );

    expect(envelope.status, isTrue);
    expect(envelope.value?.items, [3, 4]);
    expect(envelope.value?.hasNextPage, isTrue);
  });

  test('prioriza detail y conserva errores RFC 7807', () {
    final problem = ProblemDetailsModel.fromJson({
      'title': 'Solicitud inválida',
      'status': 400,
      'detail': 'Revisa los datos.',
      'correlationId': 'corr-1',
      'errors': {
        'amount': ['Debe ser mayor que cero'],
      },
    });

    expect(problem.safeMessage, 'Revisa los datos.');
    expect(problem.status, 400);
    expect(problem.correlationId, 'corr-1');
    expect(problem.errors['amount'], ['Debe ser mayor que cero']);
  });
}
