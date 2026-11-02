import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store identifiers for the published builds.
///
/// [androidPackage] is the applicationId from android/app/build.gradle.
/// [iosAppStoreId] is the numeric id Apple assigns once the app is on the App
/// Store — visible in App Store Connect, or in the store URL as
/// `https://apps.apple.com/app/id<THIS NUMBER>`.
class StoreIds {
  static const String androidPackage = "com.datacareultra.ultra";

  /// The "Apple ID" shown under General Information in App Store Connect.
  /// Used as a fallback link target; the live lookup normally supplies the
  /// canonical URL itself.
  static const String iosAppStoreId = "6738963579";

  static const String iosAppName = "DataCare Ultra";
}

/// Compares dotted version strings ("1.0.17", "1.2", "2.0.0.1").
///
/// Returns a negative number if [a] is older than [b], zero if they are the
/// same, positive if [a] is newer. Missing segments count as 0, so "1.2" and
/// "1.2.0" are equal. Non-numeric segments are treated as 0 rather than
/// throwing, so a malformed value can never crash the gate.
int compareVersions(String a, String b) {
  final left = _segments(a);
  final right = _segments(b);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l - r;
  }
  return 0;
}

List<int> _segments(String value) {
  // Drop any build suffix ("1.0.17+24" -> "1.0.17") and any pre-release tag.
  final cleaned = value.trim().split('+').first.split('-').first;
  if (cleaned.isEmpty) return const [0];
  return cleaned
      .split('.')
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}

/// Version of the build currently installed on the device, e.g. "1.0.17".
Future<String> currentAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

/// Opens the platform store listing for this app.
///
/// Android tries the Play Store app first via the `market:` scheme and falls
/// back to the web listing; iOS does the same with `itms-apps:`. Returns false
/// if nothing could be opened, so the caller can surface a message instead of
/// leaving the user on a dead button.
Future<bool> openStoreListing({String? storeUrl}) async {
  final candidates = <Uri>[];

  // A URL resolved from the store lookup is always the most accurate target.
  if (storeUrl != null && storeUrl.trim().isNotEmpty) {
    final parsed = Uri.tryParse(storeUrl.trim());
    if (parsed != null) candidates.add(parsed);
  }

  if (Platform.isAndroid) {
    candidates.add(Uri.parse("market://details?id=${StoreIds.androidPackage}"));
    candidates.add(Uri.parse(
        "https://play.google.com/store/apps/details?id=${StoreIds.androidPackage}"));
  } else if (Platform.isIOS) {
    if (StoreIds.iosAppStoreId.isNotEmpty) {
      candidates.add(Uri.parse(
          "itms-apps://itunes.apple.com/app/id${StoreIds.iosAppStoreId}"));
      candidates.add(
          Uri.parse("https://apps.apple.com/app/id${StoreIds.iosAppStoreId}"));
    } else {
      // No id configured yet — search rather than risk the wrong listing.
      final term = Uri.encodeComponent(StoreIds.iosAppName);
      candidates.add(Uri.parse("itms-apps://search.itunes.apple.com/WebObjects/"
          "MZSearch.woa/wa/search?media=software&term=$term"));
      candidates.add(Uri.parse("https://www.apple.com/app-store/"));
    }
  }

  for (final uri in candidates) {
    try {
      // Deliberately no canLaunchUrl() guard: on iOS it returns false for any
      // scheme not listed in LSApplicationQueriesSchemes, which would skip the
      // itms-apps candidate even when it would have opened fine. Attempting
      // the launch and falling through on failure is both simpler and more
      // reliable, since the https candidate always works as a backstop.
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {
      // Try the next candidate.
    }
  }
  return false;
}
