import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_enums.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_requests.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identity serializa el contrato camelCase exacto', () {
    final request = MoveIdentityOnboardingRequest(
      firstNames: 'Ana María',
      lastNames: 'Pérez Soto',
      documentType: 'CC',
      documentNumber: 'DEMO0001',
      countryCode: 'CO',
      city: 'Bogotá',
      email: 'persona@example.invalid',
      phone: null,
      birthDate: DateTime.utc(1990, 5, 20),
      selfieMediaAssetId: 101,
      acceptMoveTerms: true,
      termsVersion: '2026-01',
      termsContentHash: List.filled(64, 'a').join(),
    );

    expect(request.toJson(), {
      'firstNames': 'Ana María',
      'lastNames': 'Pérez Soto',
      'documentType': 'CC',
      'documentNumber': 'DEMO0001',
      'countryCode': 'CO',
      'city': 'Bogotá',
      'email': 'persona@example.invalid',
      'phone': null,
      'birthDate': '1990-05-20',
      'selfieMediaAssetId': 101,
      'acceptMoveTerms': true,
      'termsVersion': '2026-01',
      'termsContentHash': List.filled(64, 'a').join(),
    });
    expect(request.validate(nowUtc: DateTime.utc(2026, 7, 18)), isEmpty);
  });

  test('enums conservan Draft=0 y unknown seguro', () {
    expect(MoveDriverStatus.fromValue(0), MoveDriverStatus.draft);
    expect(MoveDriverStatus.fromValue('Draft'), MoveDriverStatus.draft);
    expect(MoveDriverStatus.fromValue('future'), MoveDriverStatus.unknown);
    expect(
      MoveVehicleDocumentType.fromValue(99),
      MoveVehicleDocumentType.unknown,
    );
  });

  test('status parsea stages, review y estados desconocidos', () {
    final status = MoveDriverOnboardingStatus.fromJson({
      'driverId': 25,
      'status': 'Draft',
      'percentage': 67,
      'canSubmit': false,
      'canGoOnline': false,
      'vehicleDocuments': [
        {
          'id': 31,
          'type': 1,
          'status': 99,
          'expiresAt': null,
          'rowVersion': 'AAAA',
        },
      ],
      'stages': [
        {
          'stage': 1,
          'name': 'Identity',
          'complete': true,
          'percentage': 100,
          'missing': <String>[],
          'reasons': <String>[],
        },
      ],
      'missing': ['active_wallet'],
      'reasons': <String>[],
    });

    expect(status.status, MoveDriverStatus.draft);
    expect(status.stages.single.stage, MoveOnboardingStageType.identity);
    expect(status.vehicleDocuments.single.status, MoveDocumentStatus.unknown);
    expect(status.missing, ['active_wallet']);
  });
}
