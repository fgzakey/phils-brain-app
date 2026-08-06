// Boot smoke test: the app builds, loads prefs from (mocked) storage and
// reaches the home shell with its five navigation destinations. Network calls
// fail under flutter_test's stubbed HttpClient; AppState swallows those into
// per-screen error fields, so the shell itself must still render.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phils_brain_app/app_state.dart';
import 'package:phils_brain_app/main.dart';

void main() {
  testWidgets('App boots to the home shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'password': 'test'});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState()..loadPrefs(),
        child: const PhilsBrainApp(),
      ),
    );

    // First frame shows the prefs-loading spinner; a couple of pumps later the
    // shell is up. pumpAndSettle would hang on the screens' own spinners.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Essays'), findsOneWidget);
    expect(find.text('Praxis'), findsOneWidget);
  });
}
