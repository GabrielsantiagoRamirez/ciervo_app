// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ciervo_clud/app.dart';
import 'package:ciervo_clud/core/di/service_locator.dart';
import 'package:ciervo_clud/core/experience/experience_mode_cubit.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  testWidgets('Ciervo app renders splash while session is unknown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ExperienceModeCubit(getIt<SecureStorage>()),
        child: const CiervoApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 221));
    await tester.pump(const Duration(milliseconds: 650));

    expect(find.text('Ciervo Club'), findsOneWidget);
  });
}
