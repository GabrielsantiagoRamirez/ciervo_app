import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_enums.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_status.dart';
import 'package:ciervo_clud/features/move/presentation/onboarding/move_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('estado muestra progreso, máscaras, faltantes y motivos', (
    tester,
  ) async {
    const status = MoveDriverOnboardingStatus(
      driverId: 11,
      status: MoveDriverStatus.rejected,
      percentage: 75,
      canSubmit: false,
      canGoOnline: false,
      maskedDocument: '***1234',
      maskedLicense: '***9876',
      maskedPlate: 'AB***12',
      vehicleDocuments: [],
      stages: [
        MoveOnboardingStage(
          stage: MoveOnboardingStageType.identity,
          name: 'Identidad',
          complete: false,
          percentage: 75,
          missing: ['selfie'],
          reasons: ['imagen borrosa'],
        ),
      ],
      missing: ['licencia vigente'],
      reasons: ['corregir identidad'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MoveOnboardingStatusSummary(status: status),
          ),
        ),
      ),
    );

    expect(find.text('Rechazado'), findsOneWidget);
    expect(find.text('Progreso 75%'), findsOneWidget);
    expect(find.text('Documento: ***1234'), findsOneWidget);
    expect(find.textContaining('Falta: selfie'), findsOneWidget);
    expect(find.text('• licencia vigente'), findsOneWidget);
    expect(find.text('• corregir identidad'), findsOneWidget);
  });
}
