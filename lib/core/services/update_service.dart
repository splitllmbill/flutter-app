import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';
import '../utils/app_theme.dart';

/// Whether the running build is current, has an optional update, or must
/// update before continuing.
enum AppUpdateStatus { upToDate, optional, mandatory }

class AppUpdateInfo {
  final AppUpdateStatus status;
  final String latest;
  final String? url;
  final String notes;

  const AppUpdateInfo(this.status, this.latest, this.url, this.notes);
}

/// Compare dotted numeric versions so "1.10.0" > "1.9.0" (a plain string
/// compare gets that wrong). Build metadata after '+' is ignored, and any
/// non-numeric noise in a segment is stripped. Returns -1 / 0 / 1.
int compareVersions(String a, String b) {
  List<int> parse(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();

  final pa = parse(a);
  final pb = parse(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}

/// Ask the backend what the latest version is and compare it to the running
/// build. Returns null on web (updates happen on reload) or on any error, so
/// callers can treat "couldn't check" as "don't nag".
Future<AppUpdateInfo?> checkForUpdate(WidgetRef ref) async {
  if (kIsWeb) return null;
  try {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;

    final api = ref.read(apiClientProvider);
    final res = await api.get('/version');
    final data = Map<String, dynamic>.from(res.data as Map);

    final latest = (data['latest'] ?? current).toString();
    final minSupported = (data['minSupported'] ?? '0.0.0').toString();

    String? url;
    if (defaultTargetPlatform == TargetPlatform.android) {
      url = (data['android']?['url'] ?? '').toString();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      url = (data['ios']?['url'] ?? '').toString();
    }
    if (url != null && url.isEmpty) url = null;

    final notes = (data['notes'] ?? '').toString();

    if (compareVersions(current, minSupported) < 0) {
      return AppUpdateInfo(AppUpdateStatus.mandatory, latest, url, notes);
    }
    if (compareVersions(current, latest) < 0) {
      return AppUpdateInfo(AppUpdateStatus.optional, latest, url, notes);
    }
    return AppUpdateInfo(AppUpdateStatus.upToDate, latest, url, notes);
  } catch (_) {
    return null;
  }
}

Future<void> _open(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Checks for an update and, if there is one, shows a dismissible banner
/// (optional) or a blocking dialog (mandatory). No-op when up to date, on web,
/// or when the check fails.
Future<void> maybePromptForUpdate(BuildContext context, WidgetRef ref) async {
  final info = await checkForUpdate(ref);
  if (info == null || !context.mounted) return;

  if (info.status == AppUpdateStatus.mandatory) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Update required'),
          content: Text(
            info.notes.isNotEmpty
                ? info.notes
                : 'Version ${info.latest} is required to keep using SplitLLM. '
                    'Please update to continue.',
          ),
          actions: [
            ElevatedButton(
              onPressed: info.url == null ? null : () => _open(info.url),
              child: const Text('Update now'),
            ),
          ],
        ),
      ),
    );
  } else if (info.status == AppUpdateStatus.optional) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppTheme.cardColor,
        content: Text(
          info.notes.isNotEmpty
              ? 'Version ${info.latest} is available. ${info.notes}'
              : 'Version ${info.latest} is available.',
        ),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              _open(info.url);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
