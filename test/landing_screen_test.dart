import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitllm/features/landing/presentation/landing_screen.dart';

/// Pumps [LandingScreen] at the given logical size and fails if any layout
/// exception (e.g. unbounded height, overflow) is thrown during the frame.
Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Collect any layout errors (overflow, unbounded constraints) raised during
  // the frame; forward to the default handler so failures print the offending
  // widget for debugging.
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details);
    FlutterError.presentError(details);
  };

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: LandingScreen()),
    ),
  );
  await tester.pump();

  FlutterError.onError = previous;
  expect(errors, isEmpty, reason: 'layout errors at width ${size.width}');
  expect(find.text('Split Bills Smartly with AI'), findsOneWidget);
  expect(find.text('Effortless Control'), findsOneWidget);
  expect(find.text('Ready to balance your life?'), findsOneWidget);
}

void main() {
  // Cover the responsive breakpoints: small mobile, large phone, tablet
  // portrait, the nav cut-in (1024), and wide desktop.
  const sizes = <String, Size>{
    'small mobile': Size(320, 3600),
    'large phone': Size(414, 3200),
    'tablet portrait': Size(768, 2800),
    'nav breakpoint': Size(1024, 2600),
    'desktop': Size(1440, 2400),
  };

  sizes.forEach((name, size) {
    testWidgets('renders without layout errors on $name', (tester) async {
      await _pumpAt(tester, size);
    });
  });
}
