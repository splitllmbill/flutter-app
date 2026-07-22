import 'package:flutter_test/flutter_test.dart';
import 'package:splitllm/core/services/update_service.dart';

void main() {
  group('compareVersions', () {
    test('equal versions', () {
      expect(compareVersions('1.0.0', '1.0.0'), 0);
    });

    test('numeric ordering, not string ordering', () {
      // String compare would call "1.9.0" > "1.10.0"; numeric must not.
      expect(compareVersions('1.9.0', '1.10.0'), -1);
      expect(compareVersions('1.10.0', '1.9.0'), 1);
    });

    test('patch and minor bumps', () {
      expect(compareVersions('1.0.0', '1.0.1'), -1);
      expect(compareVersions('1.2.0', '1.1.9'), 1);
    });

    test('ignores build metadata after +', () {
      expect(compareVersions('1.0.0+5', '1.0.0+9'), 0);
    });

    test('missing segments treated as zero', () {
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1', '1.0.1'), -1);
    });

    test('strips non-numeric noise', () {
      expect(compareVersions('1.0.0-beta', '1.0.0'), 0);
    });
  });
}
