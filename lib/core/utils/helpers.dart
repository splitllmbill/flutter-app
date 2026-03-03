import 'dart:math';

/// Utility functions ported from React State.tsx.
class AppUtils {
  AppUtils._();

  /// Convert string to title case.
  static String toTitleCase(String? str) {
    if (str == null || str.isEmpty) return '--';
    return str.replaceAllMapped(
      RegExp(r'\w\S*'),
      (match) =>
          match.group(0)![0].toUpperCase() +
          match.group(0)!.substring(1).toLowerCase(),
    );
  }

  /// Generate a random color palette.
  static List<String> generatePalette(int numColors) {
    final palette = <String>[];
    final colorSet = <String>{};
    final random = Random();

    while (palette.length < numColors) {
      final r = random.nextInt(256);
      final g = random.nextInt(256);
      final b = random.nextInt(256);
      final color =
          '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';

      if (!colorSet.contains(color)) {
        palette.add(color);
        colorSet.add(color);
      }
    }

    return palette;
  }

  /// Format currency amount
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    if (amount == amount.roundToDouble()) {
      return '$symbol${amount.toInt()}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
