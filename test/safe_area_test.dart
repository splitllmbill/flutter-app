import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitllm/features/auth/presentation/login_screen.dart';
import 'package:splitllm/features/landing/presentation/landing_screen.dart';

/// Mobile edge-to-edge regressions: with a simulated status-bar/notch inset,
/// interactive content must render below the inset (backgrounds may — and
/// should — still extend behind the system bars).
const double _topInset = 47; // typical notch height, logical px at dpr 1.0

Future<void> _pumpWithInset(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 844); // phone portrait
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = const FakeViewPadding(top: _topInset, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: home)));
  await tester.pump(const Duration(seconds: 1)); // settle entry animations
}

void main() {
  testWidgets('landing header and hero clear the status bar', (tester) async {
    await _pumpWithInset(tester, const LandingScreen());

    // Every header/CTA button must sit below the inset.
    for (final element in find.text('Get Started').evaluate()) {
      final top = tester.getTopLeft(find.byWidget(element.widget)).dy;
      expect(top, greaterThanOrEqualTo(_topInset));
    }

    // Scroll content clears the fixed header (72) plus the inset.
    final headline = find.text('Just another expense\nsplitting app.');
    expect(tester.getTopLeft(headline).dy, greaterThanOrEqualTo(_topInset + 72));
  });

  testWidgets('login form clears the status bar', (tester) async {
    await _pumpWithInset(tester, const LoginScreen());

    final scroll = find.byType(SingleChildScrollView);
    expect(tester.getTopLeft(scroll).dy, greaterThanOrEqualTo(_topInset));
  });
}
