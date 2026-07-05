import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ciervo_clud/core/di/service_locator.dart';
import 'package:ciervo_clud/features/family_payments/domain/repositories/family_payments_repository.dart';
import 'package:ciervo_clud/features/family_payments/presentation/cubit/family_payment_methods_cubit.dart';
import 'package:ciervo_clud/features/family_payments/presentation/pages/add_family_card_page.dart';

class _FakeFamilyPaymentsRepository implements FamilyPaymentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    if (getIt.isRegistered<FamilyPaymentsRepository>()) {
      getIt.unregister<FamilyPaymentsRepository>();
    }
    getIt.registerSingleton<FamilyPaymentsRepository>(
      _FakeFamilyPaymentsRepository(),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<FamilyPaymentsRepository>()) {
      getIt.unregister<FamilyPaymentsRepository>();
    }
  });

  testWidgets('AddFamilyCardPage provee FamilyPaymentMethodsCubit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AddFamilyCardPage(),
      ),
    );

    expect(find.byType(BlocProvider<FamilyPaymentMethodsCubit>), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
