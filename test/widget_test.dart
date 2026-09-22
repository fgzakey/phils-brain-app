// Boot smoke test & ontology tests: the app builds, loads prefs from (mocked) storage and
// reaches the home shell with its five navigation destinations. Network calls
// fail under flutter_test's stubbed HttpClient; AppState swallows those into
// per-screen error fields, so the shell itself must still render.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phils_brain_app/app_state.dart';
import 'package:phils_brain_app/main.dart';
import 'package:phils_brain_app/models.dart';
import 'package:phils_brain_app/virtues.dart';

void main() {
  test('32 Canonical Virtues ontology and Golden Mean continuum', () {
    expect(kVirtues.length, 32);
    expect(kVirtueSpheres.length, 6);

    // Every virtue must have valid bounds and belong to a valid sphere
    final sphereIds = kVirtueSpheres.map((s) => s.id).toSet();
    for (final v in kVirtues) {
      expect(sphereIds.contains(v.sphere), isTrue);
      expect(v.virtueEn.isNotEmpty, isTrue);
      expect(v.virtueEs.isNotEmpty, isTrue);
      expect(v.deficiencyEn.isNotEmpty, isTrue);
      expect(v.deficiencyEs.isNotEmpty, isTrue);
      expect(v.excessEn.isNotEmpty, isTrue);
      expect(v.excessEs.isNotEmpty, isTrue);
      expect(v.poeticEn.isNotEmpty, isTrue);
      expect(v.poeticEs.isNotEmpty, isTrue);
      expect(getVirtueBySlug(v.slug), isNotNull);
    }

    final focus = getFocusVirtueForDate();
    expect(focus, isNotNull);
    expect(focus.slug.startsWith('practices/virtue-'), isTrue);
  });

  test('PraxisNode parses practice virtue node and meta', () {
    final node = PraxisNode.fromJson({
      'id': 101,
      'slug': 'practices/virtue-courage',
      'node_type': 'practice',
      'title': 'Courageous',
      'meta': {
        'kind': 'virtue',
        'sphere': 'courage_and_fortitude',
        'virtue_en': 'Courageous',
        'virtue_es': 'Valiente',
        'deficiency_en': 'Cowardly',
        'deficiency_es': 'Cobarde',
        'excess_en': 'Reckless / Rash',
        'excess_es': 'Temerario / Imprudente',
        'poetic_en': 'The steady flame that burns through the shadows of doubt.',
        'poetic_es': 'La llama constante que arde a través de las sombras de la duda.',
      },
    });

    expect(node.isVirtue, isTrue);
    expect(node.virtueMeta, isNotNull);
    expect(node.virtueMeta!.sphere, 'courage_and_fortitude');
    expect(node.virtueMeta!.virtueEn, 'Courageous');
    expect(node.virtueMeta!.deficiencyEn, 'Cowardly');
    expect(node.virtueMeta!.excessEn, 'Reckless / Rash');
  });

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
    expect(
        find.descendant(
            of: find.byType(NavigationBar), matching: find.text('Essays')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(NavigationBar), matching: find.text('Praxis')),
        findsOneWidget);
  });
}
