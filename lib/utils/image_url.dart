/// Builds the URL for a tag / design image.
///
/// Both halves are trimmed before joining. The values come from SQL Server
/// `CHAR` columns (WEB_PATH, TAG_NO, DesignImgId), which are **space padded**
/// to their declared width. The Android and iOS SQL drivers do not agree on
/// whether that padding is stripped, so a path that works on one platform can
/// arrive as `"http://host/img/   "` on the other and fail to load.
///
/// Any remaining spaces are percent-encoded rather than left raw, since a
/// literal space makes the URL invalid.
///
/// Returns an empty string when either half is missing, so callers can treat
/// "no image configured" and "image failed" the same way.
/// When [serverHost] is given, a WEB_PATH pointing at the machine's own
/// loopback or LAN address is re-pointed at the host the app is actually
/// connected to. See [reachableBase].
String buildTagImageUrl(String? basePath, String? fileName,
    {String? serverHost}) {
  final base = reachableBase(basePath, serverHost);
  final name = (fileName ?? '').trim();
  if (base.isEmpty || name.isEmpty) return '';
  return '$base$name'.replaceAll(' ', '%20');
}

/// Hosts that only resolve on the machine or network that stored them.
bool _isLocalHost(String host) {
  final h = host.toLowerCase();
  if (h == 'localhost' || h == '127.0.0.1' || h == '::1') return true;
  // Private IPv4 ranges: 10.x, 192.168.x, and 172.16-31.x
  if (RegExp(r'^10\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(h)) return true;
  if (RegExp(r'^192\.168\.\d{1,3}\.\d{1,3}$').hasMatch(h)) return true;
  final m = RegExp(r'^172\.(\d{1,3})\.\d{1,3}\.\d{1,3}$').firstMatch(h);
  if (m != null) {
    final second = int.tryParse(m.group(1)!) ?? 0;
    if (second >= 16 && second <= 31) return true;
  }
  // A bare machine name with no dots — resolvable on the shop LAN only.
  if (!h.contains('.') && h.isNotEmpty) return true;
  return false;
}

/// Returns the image base URL, re-hosted when WEB_PATH is unreachable.
///
/// WEB_PATH is configured on the shop's own server, so it is usually written
/// as something like `http://localhost/images/` or `http://192.168.1.5/images/`.
/// That works for anyone on the shop LAN and fails for everyone else — which
/// is why images loaded in the shop but not when staff connected to the same
/// server over its static public IP.
///
/// The fix is to trust the host the app is already talking to: if WEB_PATH
/// names a loopback, private-range or dotless host and [serverHost] names a
/// different one, the host is swapped and everything else about the URL — the
/// scheme, port and folder — is kept as configured.
///
/// A WEB_PATH on a real public host is left completely alone: the images may
/// genuinely live on another machine, and guessing would break a working setup.
String reachableBase(String? basePath, String? serverHost) {
  final base = (basePath ?? '').trim();
  if (base.isEmpty) return '';

  // "103.26.205.95:9797" — the port belongs to SQL Server, not the web server,
  // so only the host part is of interest here.
  final target = (serverHost ?? '').trim().split(':').first.trim();
  if (target.isEmpty || _isLocalHost(target)) return base;

  final uri = Uri.tryParse(base);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return base;
  if (!_isLocalHost(uri.host)) return base;
  if (uri.host.toLowerCase() == target.toLowerCase()) return base;

  return uri.replace(host: target).toString();
}

/// Whether the company is configured to serve tag images at all (WEB_IMAGE).
///
/// Trimmed and lower-cased because the column is `CHAR(1)`: iOS commonly
/// receives `"Y "`, and a bare `== "y"` comparison silently fails there, which
/// is why images appeared on Android but not on iOS.
bool tagImagesEnabled(String? webImage) =>
    (webImage ?? '').trim().toLowerCase() == 'y';
