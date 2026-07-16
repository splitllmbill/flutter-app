import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers.dart';

/// Result of scanning a receipt with the vision model.
class ScannedReceipt {
  final String? name;
  final double? amount;
  final String? currency;
  final String? date;
  final String? category;
  final List<Map<String, dynamic>> items;

  ScannedReceipt({
    this.name,
    this.amount,
    this.currency,
    this.date,
    this.category,
    this.items = const [],
  });

  String get itemsSummary =>
      items.map((i) => '${i['name']}: ${i['amount']}').join('\n');
}

/// Opens the photo picker, sends the image to `POST /llm/receipt`, and
/// returns the parsed expense. Returns null if the user cancelled.
/// Throws with a readable message when the model can't read the receipt.
Future<ScannedReceipt?> pickAndScanReceipt(WidgetRef ref) async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 85,
  );
  if (image == null) return null;

  final bytes = await image.readAsBytes();
  final api = ref.read(apiClientProvider);
  final response = await api.post('/llm/receipt', data: {
    'image': base64Encode(bytes),
    'mimeType': image.mimeType ?? 'image/jpeg',
  });

  final output = response.data['llmoutput'];
  final parsed = output is List && output.isNotEmpty
      ? Map<String, dynamic>.from(output.first)
      : null;
  if (parsed == null || parsed['error'] != null) {
    throw Exception(parsed?['error'] ?? response.data['message'] ?? 'Scan failed');
  }

  return ScannedReceipt(
    name: parsed['name']?.toString(),
    amount: parsed['amount'] is num
        ? (parsed['amount'] as num).toDouble()
        : double.tryParse('${parsed['amount']}'),
    currency: parsed['currency']?.toString().toUpperCase(),
    date: parsed['date']?.toString(),
    category: parsed['category']?.toString(),
    items: parsed['items'] is List
        ? (parsed['items'] as List)
            .whereType<Map>()
            .map((i) => Map<String, dynamic>.from(i))
            .toList()
        : const [],
  );
}
