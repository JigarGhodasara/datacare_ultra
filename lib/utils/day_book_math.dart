/// Arithmetic and wording behind the Day Book screen.
///
/// Kept out of the widget so each rule can be checked on its own: how a cash
/// balance is worded, which purchase books count as old gold, how a weight is
/// split between gold and silver. Every one of these was a place a shopkeeper
/// could be misled by a figure that was technically right.
library;

double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

/// A cash balance in words rather than a sign.
///
/// The ledger stores cash as `SUM(CR_AMT − DR_AMT)`, so cash in hand comes
/// through positive and reads "Credit" everywhere else in the app (see the
/// cash-on-hand box). A bare "-1,200.00" left the owner asking what they were
/// meant to do about the minus; "1,200.00 Debit" is the word their accountant
/// uses, so it is the word shown.
String balanceLabel(double value) {
  if (value.abs() < 0.005) return '0.00';
  return '${value.abs().toStringAsFixed(2)} ${balanceSide(value)}';
}

/// "Credit", "Debit", or empty when the balance is nil.
String balanceSide(double value) {
  if (value.abs() < 0.005) return '';
  return value > 0 ? 'Credit' : 'Debit';
}

/// The day before [day], at midnight.
///
/// Built from the date parts rather than subtracting 24 hours, so a clock
/// change can never make "yesterday" land two days back.
DateTime previousDay(DateTime day) => DateTime(day.year, day.month, day.day - 1);

/// Whether a purchase book is an old-gold book.
///
/// Matched on the word OLD at the start of the name or after a non-letter —
/// never a bare substring, because "GOLD" contains "OLD" and every book in the
/// shop would otherwise qualify.
bool isOldGoldBook(dynamic mainBook, dynamic bookName) {
  final pattern = RegExp(r'(?:^|[^A-Z])OLD');
  for (final raw in [mainBook, bookName]) {
    final name = '${raw ?? ''}'.trim().toUpperCase();
    if (name.isNotEmpty && pattern.hasMatch(name)) return true;
  }
  return false;
}

/// Weight split by metal.
class MetalWeights {
  final double gold;
  final double silver;

  /// Items whose type is neither G nor S — diamond, platinum, an item with no
  /// type set. Kept so the parts still add up to the total shown beside them.
  final double other;

  const MetalWeights(this.gold, this.silver, this.other);

  static const zero = MetalWeights(0, 0, 0);

  double get total => gold + silver + other;

  MetalWeights operator +(MetalWeights o) =>
      MetalWeights(gold + o.gold, silver + o.silver, other + o.other);
}

/// Sums [weightKey] across [rows], split by the metal in [typeKey].
///
/// Item types come from ITEM_MAST.IT_TYPE, a padded CHAR column, so the value
/// is trimmed before it is compared.
MetalWeights metalWeights(
  dynamic rows, {
  String typeKey = 'ItType',
  String weightKey = 'Nwt',
}) {
  var out = MetalWeights.zero;
  if (rows is! List) return out;
  for (final r in rows) {
    if (r is! Map) continue;
    final type = '${r[typeKey] ?? ''}'.trim().toUpperCase();
    final wt = _num(r[weightKey]);
    out = out +
        switch (type) {
          'G' => MetalWeights(wt, 0, 0),
          'S' => MetalWeights(0, wt, 0),
          _ => MetalWeights(0, 0, wt),
        };
  }
  return out;
}

/// The day's purchases, with old gold kept apart from stock bought in.
class PurchaseTotals {
  final int bills;
  final double pcs;
  final MetalWeights weights;

  final int oldGoldBills;
  final double oldGoldPcs;
  final MetalWeights oldGoldWeights;

  const PurchaseTotals({
    this.bills = 0,
    this.pcs = 0,
    this.weights = MetalWeights.zero,
    this.oldGoldBills = 0,
    this.oldGoldPcs = 0,
    this.oldGoldWeights = MetalWeights.zero,
  });

  bool get isEmpty => bills == 0 && oldGoldBills == 0;
}

/// Totals purchase rows grouped per voucher and item type.
///
/// A voucher appears once per metal it carries, so bills are counted on
/// VCH_NO + CO_BOOK rather than on rows, the same way the sales figures are.
PurchaseTotals purchaseTotals(dynamic rows) {
  if (rows is! List) return const PurchaseTotals();
  final seen = <String>{};
  final seenOld = <String>{};
  var pcs = 0.0, oldPcs = 0.0;
  var weights = MetalWeights.zero, oldWeights = MetalWeights.zero;

  for (final r in rows) {
    if (r is! Map) continue;
    final key = '${r['VCH_NO'] ?? ''}-${r['CO_BOOK'] ?? ''}';
    final split = metalWeights([r]);
    if (isOldGoldBook(r['MAIN_BOOK'], r['BOOK_NAME'])) {
      seenOld.add(key);
      oldPcs += _num(r['Pcs']);
      oldWeights = oldWeights + split;
    } else {
      seen.add(key);
      pcs += _num(r['Pcs']);
      weights = weights + split;
    }
  }
  return PurchaseTotals(
    bills: seen.length,
    pcs: pcs,
    weights: weights,
    oldGoldBills: seenOld.length,
    oldGoldPcs: oldPcs,
    oldGoldWeights: oldWeights,
  );
}
