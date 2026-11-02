/// Software editions that unlock the full feature set.
///
/// The licence key is `HDD_MAST.REF_NO`. Two characters are read from it at
/// company/year selection and held on the provider:
///   * `sType` — SUBSTRING(REF_NO, 7, 1)
///   * `dType` — SUBSTRING(REF_NO, 1, 1)
///
/// E / U / P / A are the full editions; B and S are the limited ones.
const Set<String> fullEditions = {'E', 'U', 'P', 'A'};

String _normalise(String? value) => (value ?? '').trim().toUpperCase();

/// Whether this licence may use the full-edition-only features.
///
/// Checks **both** letters, exactly as the login gate does. Depending on how a
/// key is issued the edition can sit in either position — and a shorter REF_NO
/// makes SUBSTRING(REF_NO,7,1) come back empty, leaving `dType` as the only
/// letter present. Testing `sType` alone let such a licence log in and then be
/// refused at the feature, which is the opposite of what the licence allows.
///
/// Values are trimmed and upper-cased first: they are substrings of a padded
/// CHAR column, so `"U "` is realistic and a bare `==` would deny a valid key.
bool hasFullEdition(String? sType, [String? dType]) =>
    fullEditions.contains(_normalise(sType)) ||
    fullEditions.contains(_normalise(dType));

/// Limited editions: Basic and Standard.
const Set<String> limitedEditions = {'B', 'S'};

/// What a licence entitles the user to.
enum Edition {
  /// E / U / P / A — everything unlocked.
  full,

  /// B / S — the app opens, but the full-edition features are gated.
  limited,

  /// Nothing recognisable was found in HDD_MAST.
  unknown,
}

/// The edition letters read from HDD_MAST, and what they grant.
class EditionKey {
  /// SUBSTRING(REF_NO, 7, 1), normalised.
  final String sType;

  /// SUBSTRING(REF_NO, 1, 1), normalised.
  final String dType;

  final Edition edition;

  const EditionKey(this.sType, this.dType, this.edition);

  static const EditionKey none = EditionKey('', '', Edition.unknown);
}

Edition _editionOf(String sType, String dType) {
  if (fullEditions.contains(sType) || fullEditions.contains(dType)) {
    return Edition.full;
  }
  if (limitedEditions.contains(sType) || limitedEditions.contains(dType)) {
    return Edition.limited;
  }
  return Edition.unknown;
}

/// Grades the licence from the rows `SELECT SUBSTRING(REF_NO,...) FROM HDD_MAST`
/// returns.
///
/// Reads **every** row and keeps the best entitlement found, rather than
/// trusting row zero. That query carries no WHERE and no ORDER BY, so when
/// HDD_MAST holds more than one row — a superseded demo licence, a second
/// installation — the row that arrives first is whatever the server felt like
/// returning. Grading off row zero locked a genuine Enterprise customer out of
/// their own software.
///
/// Erring towards the *better* licence is deliberate: refusing a paying
/// customer is a far worse failure than honouring a stale row alongside a
/// valid one.
EditionKey readEdition(dynamic rows) {
  if (rows is! List || rows.isEmpty) return EditionKey.none;

  EditionKey? best;
  for (final row in rows) {
    if (row is! Map) continue;
    final sType = _normalise('${row['SoftType'] ?? ''}');
    final dType = _normalise('${row['DemoType'] ?? ''}');
    if (sType.isEmpty && dType.isEmpty) continue;

    final key = EditionKey(sType, dType, _editionOf(sType, dType));
    if (key.edition == Edition.full) return key;
    best ??= key;
    if (key.edition == Edition.limited && best.edition == Edition.unknown) {
      best = key;
    }
  }
  return best ?? EditionKey.none;
}
