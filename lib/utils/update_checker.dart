import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/utils/app_version.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Result of a store version lookup.
class UpdateInfo {
  /// Version installed on this device, e.g. "1.0.17".
  final String currentVersion;

  /// Version currently published on the store.
  final String storeVersion;

  /// Canonical store listing URL, when the lookup returned one.
  final String? storeUrl;

  const UpdateInfo({
    required this.currentVersion,
    required this.storeVersion,
    this.storeUrl,
  });

  bool get updateAvailable => compareVersions(currentVersion, storeVersion) < 0;
}

/// How long to wait on the store before giving up and letting the user in.
const Duration _timeout = Duration(seconds: 8);

/// Looks up the published version of this app on the current platform's store.
///
/// Returns null whenever the version cannot be determined — no network, a
/// timeout, an unpublished app, or a change in the Play Store's HTML. Callers
/// MUST treat null as "carry on": failing open matters because the Play Store
/// has no official version API, and the scrape below will eventually break
/// when Google changes their markup. Locking every user out of the app because
/// of that would be far worse than missing an update prompt.
Future<UpdateInfo?> checkForUpdate() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;

    String? storeVersion;
    String? storeUrl;

    if (Platform.isIOS) {
      final result = await _lookupAppStore(info.packageName);
      storeVersion = result?.$1;
      storeUrl = result?.$2;
    } else if (Platform.isAndroid) {
      storeVersion = await _lookupPlayStore(info.packageName);
    }

    if (storeVersion == null || storeVersion.trim().isEmpty) return null;

    return UpdateInfo(
      currentVersion: current,
      storeVersion: storeVersion.trim(),
      storeUrl: storeUrl,
    );
  } catch (e) {
    log('Update check failed, continuing without it: $e');
    return null;
  }
}

/// Apple's public lookup API. Keyed on bundle id, so it needs no hardcoded
/// numeric App Store id, and it hands back the canonical listing URL too.
Future<(String, String?)?> _lookupAppStore(String bundleId) async {
  // Lookup is storefront-scoped: an app not sold in a given country returns
  // zero results there. India first (the primary market), then the default
  // US storefront, then the numeric id as a last resort in case the bundle id
  // on the build ever drifts from the one on the listing.
  final urls = <String>[
    "https://itunes.apple.com/lookup?bundleId=$bundleId&country=IN",
    "https://itunes.apple.com/lookup?bundleId=$bundleId",
    if (StoreIds.iosAppStoreId.isNotEmpty)
      "https://itunes.apple.com/lookup?id=${StoreIds.iosAppStoreId}",
  ];

  for (final url in urls) {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode != 200) continue;

      final body = jsonDecode(response.body);
      final results = body["results"];
      if (results is! List || results.isEmpty) continue;

      final entry = results.first;
      final version = '${entry["version"] ?? ''}'.trim();
      if (version.isEmpty) continue;

      final storeUrl = '${entry["trackViewUrl"] ?? ''}'.trim();
      return (version, storeUrl.isEmpty ? null : storeUrl);
    } catch (e) {
      log('App Store lookup failed for $url: $e');
    }
  }
  return null;
}

/// Google publishes no version API, so this reads the public listing page.
///
/// Several patterns are tried because the markup has changed repeatedly over
/// the years. If none match, null is returned and the check is skipped.
Future<String?> _lookupPlayStore(String packageId) async {
  final uri = Uri.parse(
      "https://play.google.com/store/apps/details?id=$packageId&hl=en&gl=US");
  final response = await http.get(uri, headers: {
    // Without a browser UA the store serves a stripped page with no version.
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/120.0 Safari/537.36",
  }).timeout(_timeout);
  if (response.statusCode != 200) return null;

  final html = response.body;
  final patterns = <RegExp>[
    RegExp(r'\[\[\["(\d+(?:\.\d+)+)"\]\]'),
    RegExp(r'"softwareVersion"\s*:\s*"([^"]+)"'),
    RegExp(r'Current Version.{0,64}?>(\d+(?:\.\d+)+)<'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(html);
    final value = match?.group(1)?.trim();
    // Guard against matching something that isn't a version number.
    if (value != null && RegExp(r'^\d+(\.\d+)+$').hasMatch(value)) {
      return value;
    }
  }
  return null;
}
