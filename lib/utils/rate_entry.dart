/// Rate entry from the phone: the shop types today's fine gold and fine
/// silver rates, every group's rate follows from its touch, and the SQL
/// here stores the result. Pure Dart so the arithmetic and the statements
/// are unit-tested without a database.
///
/// The fine gold and fine silver rates the shop types are tax-inclusive.
/// For each group, with touch `GROUP_MAST.GR_TOUCH` and tax %
/// `GROUP_MAST.TAX_PRC`, and the fine rate chosen by `GROUP_MAST.GR_TYPE`
/// (G gold, S silver; O other, E imitation and R store carry no metal
/// rate):
///
///     GR_TAX_RATE = fine (with tax) × touch ÷ 100
///     GR_RATE     = fine (with tax) ÷ (1 + tax% ÷ 100) × touch ÷ 100
///
/// both rounded to the rupee, so `GR_RATE` is the rate without tax, which
/// Tag Estimate adds GST to, and `GR_TAX_RATE` the rate with it. Gold is
/// quoted and stored per 10 g. Silver is quoted per kg but every stored
/// group rate is per 10 g, so the typed silver rate is divided by
/// [kSilverKgToTenGram] first. The fine rates themselves are stored as
/// typed, with tax and in the unit quoted, since that is what the home
/// page's rate box shows and what the form offers back next time. A group
/// with no touch, or of a type without a metal rate, gets no rate and is
/// left untouched.
///
/// Storage assumptions, stated once here so they are easy to revisit:
///
/// * `RATE_MAST` is written with the ten columns the app already reads
///   (CO_CODE, LC_CODE, GR_CODE, VCH_DATE, GR_TOUCH, GR_RATE, GR_TAX_PRC,
///   GR_TAX_RATE, FINE_GL_RATE, FINE_SL_RATE) plus CO_YEAR, which the
///   server reported as NOT NULL on the first real save. If a further
///   NOT NULL column turns up the INSERT fails, nothing is written, and the
///   screen shows the server's message so the column can be added here.
/// * One row per group per day. A group that already has today's row is
///   UPDATEd (matched on company, location, group and date), otherwise
///   INSERTed. The table's primary key is company, location, year, date and
///   a serial number rather than the group, so every new row gets the next
///   serial for the day; [rateSerialColumn] finds that column from the key
///   read off the server, since its name differs from what the app reads.
/// * Tag Estimate prices from `GROUP_MAST.GR_RATE`, not `RATE_MAST`, so the
///   group's current rate is updated too when [kSyncGroupMasterRate] is on.
///   Both columns are the same group's rate in the same unit.
library;

/// Whether saving a rate also writes `GROUP_MAST.GR_RATE`, so estimates on
/// the phone use the new rate straight away.
const bool kSyncGroupMasterRate = true;

/// The fine silver rate is typed per kg; group rates are stored per 10 g.
const double kSilverKgToTenGram = 100;

/// A group that can carry a rate: a `GROUP_MAST` row.
class RateGroup {
  final String code;
  final String name;

  /// `RATE_DISPLAY = 'Y'`: the groups the home page's gold/silver box reads.
  /// They are listed first in the entry form.
  final bool display;

  /// `GROUP_MAST.GR_TOUCH`: the purity the group's rate is derived at.
  final double? touch;

  /// `GROUP_MAST.TAX_PRC`: the GST the group's tax-inclusive rate carries.
  final double? taxPrc;

  /// From `GROUP_MAST.GR_TYPE`, see [metalFromType].
  final Metal metal;

  const RateGroup(
    this.code,
    this.name, {
    this.display = false,
    this.touch,
    this.taxPrc,
    this.metal = Metal.unknown,
  });
}

/// Which fine rate a group's rate follows. [other] is a group that has no
/// metal rate at all (other, imitation, store); [unknown] a blank type.
enum Metal { gold, silver, other, unknown }

/// `GROUP_MAST.GR_TYPE` as the ERP defines it: G gold, S silver, and O
/// (other), E (imitation) or R (store) for groups without a metal rate.
Metal metalFromType(String type) => switch (type.trim().toUpperCase()) {
      'G' => Metal.gold,
      'S' => Metal.silver,
      'O' || 'E' || 'R' => Metal.other,
      _ => Metal.unknown,
    };

/// One group's figures for the day. A null [rate] means "leave this group
/// out"; the other figures are optional and stored as 0 when absent.
class RateLine {
  final String code;
  final String name;
  final Metal metal;
  final double? rate;
  final double? touch;
  final double? taxPrc;
  final double? taxRate;

  const RateLine({
    required this.code,
    required this.name,
    this.metal = Metal.unknown,
    this.rate,
    this.touch,
    this.taxPrc,
    this.taxRate,
  });

  bool get hasRate => rate != null && rate! > 0;

  bool get hasTouch => touch != null && touch! > 0;

  /// Why [computeLines] would give this group no rate, or null if it can.
  String? get skipReason {
    if (metal == Metal.other) return 'Not a gold or silver group';
    if (metal == Metal.unknown) return 'Group type not set in group master';
    if (!hasTouch) return 'No touch set for this group';
    return null;
  }

  RateLine copyWith({
    Metal? metal,
    double? rate,
    double? touch,
    double? taxPrc,
    double? taxRate,
  }) =>
      RateLine(
        code: code,
        name: name,
        metal: metal ?? this.metal,
        rate: rate ?? this.rate,
        touch: touch ?? this.touch,
        taxPrc: taxPrc ?? this.taxPrc,
        taxRate: taxRate ?? this.taxRate,
      );
}

/// Everything one save writes: the fine metal rates shared by every row and
/// the per-group lines.
class RateDraft {
  final double fineGold;
  final double fineSilver;
  final List<RateLine> lines;

  const RateDraft({
    required this.fineGold,
    required this.fineSilver,
    required this.lines,
  });

  List<RateLine> get rated => lines.where((l) => l.hasRate).toList();
}

/// Reads a typed number: blank or junk gives null, commas are ignored so
/// "1,23,450" works, and a negative value is treated as junk.
double? parseRate(String text) {
  final cleaned = text.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  final v = double.tryParse(cleaned);
  if (v == null || v < 0) return null;
  return v;
}

/// A number as SQL Server should see it: at most three decimals, no
/// trailing zeros, never in exponent form.
String sqlNum(double v) {
  var s = v.toStringAsFixed(3);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s == '-0' ? '0' : s;
}

/// Rate including tax, to the paisa: `rate × (1 + tax% ÷ 100)`.
double taxRateFor(double rate, double taxPrc) =>
    double.parse((rate * (1 + taxPrc / 100)).toStringAsFixed(2));

/// A text value inside single quotes, with any quote doubled.
String sqlStr(String s) => s.replaceAll("'", "''");

/// The `RATE_MAST` key columns the app fills by itself.
const Set<String> kRateKnownKeyColumns = {
  'CO_CODE',
  'LC_CODE',
  'CO_YEAR',
  'GR_CODE',
  'VCH_DATE',
};

/// The serial-number column in `RATE_MAST`'s primary key, given the key's
/// columns as the server lists them: the one column the app does not fill
/// itself. Null when the key has no such column. Throws when there is more
/// than one, since the app could not fill them meaningfully.
String? rateSerialColumn(List<String> pkColumns) {
  final extra = [
    for (final c in pkColumns)
      if (c.trim().isNotEmpty && !kRateKnownKeyColumns.contains(c.trim().toUpperCase()))
        c.trim(),
  ];
  if (extra.isEmpty) return null;
  if (extra.length > 1) {
    throw StateError(
        'RATE_MAST key has columns the app cannot fill: ${extra.join(', ')}');
  }
  return extra.single;
}

/// The statements that store [draft] for [dateSql] (`MM/dd/yyyy`), in the
/// order they must run. Groups already having a row that day
/// ([existingCodes]) are updated, the rest inserted; groups without a rate
/// are skipped. New rows are numbered in [serialColumn] from
/// [firstSerial] upwards when the key has such a column.
List<String> rateSaveStatements({
  required String coCode,
  required String lcCode,
  required String coYear,
  required String dateSql,
  required RateDraft draft,
  required Set<String> existingCodes,
  String? serialColumn,
  int firstSerial = 1,
  bool syncGroupMaster = kSyncGroupMasterRate,
}) {
  final co = sqlStr(coCode);
  final lc = sqlStr(lcCode);
  final yr = sqlStr(coYear);
  final fg = sqlNum(draft.fineGold);
  final fs = sqlNum(draft.fineSilver);
  final out = <String>[];
  var serial = firstSerial;

  for (final line in draft.rated) {
    final gr = sqlStr(line.code);
    final rate = sqlNum(line.rate!);
    final touch = sqlNum(line.touch ?? 0);
    final taxPrc = sqlNum(line.taxPrc ?? 0);
    final taxRate = sqlNum(line.taxRate ?? taxRateFor(line.rate!, line.taxPrc ?? 0));

    if (existingCodes.contains(line.code)) {
      out.add("UPDATE RATE_MAST SET GR_TOUCH=$touch,GR_RATE=$rate,"
          "GR_TAX_PRC=$taxPrc,GR_TAX_RATE=$taxRate,"
          "FINE_GL_RATE=$fg,FINE_SL_RATE=$fs "
          "WHERE CO_CODE='$co' AND LC_CODE='$lc' AND GR_CODE='$gr' "
          "AND VCH_DATE='$dateSql'");
    } else {
      final serialCol = serialColumn == null ? '' : ',$serialColumn';
      final serialVal = serialColumn == null ? '' : ',${serial++}';
      out.add("INSERT INTO RATE_MAST(CO_CODE,LC_CODE,CO_YEAR,GR_CODE,VCH_DATE,"
          "GR_TOUCH,GR_RATE,GR_TAX_PRC,GR_TAX_RATE,FINE_GL_RATE,FINE_SL_RATE"
          "$serialCol) "
          "VALUES('$co','$lc','$yr','$gr','$dateSql',"
          "$touch,$rate,$taxPrc,$taxRate,$fg,$fs$serialVal)");
    }
    if (syncGroupMaster) {
      out.add("UPDATE GROUP_MAST SET GR_RATE=$rate "
          "WHERE CO_CODE='$co' AND GR_CODE='$gr'");
    }
  }
  return out;
}

double? _numOf(dynamic v) {
  final s = '${v ?? ''}'.trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

/// One line per group carrying what the day's rate is derived from: the
/// group's metal, touch and tax % from the group master (touch and tax %
/// falling back to the ones stored with its last rate row, today's if there
/// is one). The stored rate is kept so the form can show what the group is
/// on now. Display groups come first, then code order.
List<RateLine> prefillLines({
  required List<RateGroup> groups,
  required List<dynamic> todayRows,
  required List<dynamic> latestRows,
}) {
  Map<String, dynamic> byCode(List<dynamic> rows) => {
        for (final r in rows)
          if (r is Map) '${r['GR_CODE'] ?? ''}'.trim(): r,
      };
  final today = byCode(todayRows);
  final latest = byCode(latestRows);

  final sorted = [...groups]..sort((a, b) {
      if (a.display != b.display) return a.display ? -1 : 1;
      return a.code.compareTo(b.code);
    });

  return [
    for (final g in sorted)
      () {
        final r = today[g.code] ?? latest[g.code];
        final rate = r == null ? null : _numOf(r['GR_RATE']);
        final rowTouch = r == null ? null : _numOf(r['GR_TOUCH']);
        final rowTax = r == null ? null : _numOf(r['GR_TAX_PRC']);
        return RateLine(
          code: g.code,
          name: g.name,
          metal: g.metal,
          rate: rate,
          touch: (g.touch ?? 0) > 0 ? g.touch : rowTouch,
          taxPrc: (g.taxPrc ?? 0) > 0 ? g.taxPrc : rowTax,
          taxRate: r == null ? null : _numOf(r['GR_TAX_RATE']),
        );
      }(),
  ];
}

/// Rounds to the rupee.
double _rupee(double v) => v.roundToDouble();

/// Today's rate for every group from the tax-inclusive fine rates (gold per
/// 10 g, silver per kg), rounded to the rupee and per 10 g: the tax rate is
/// `fine × touch ÷ 100`, and the rate is the same with the group's tax %
/// taken back out. A group whose metal is unknown or whose touch is missing
/// gets no rate, so it is skipped on save and its stored figures are left
/// alone.
List<RateLine> computeLines({
  required List<RateLine> lines,
  required double fineGold,
  required double fineSilver,
}) {
  return [
    for (final l in lines)
      () {
        final fine = switch (l.metal) {
          Metal.gold => fineGold,
          Metal.silver => fineSilver / kSilverKgToTenGram,
          Metal.other || Metal.unknown => 0.0,
        };
        if (fine <= 0 || !l.hasTouch) {
          return RateLine(
            code: l.code,
            name: l.name,
            metal: l.metal,
            touch: l.touch,
            taxPrc: l.taxPrc,
          );
        }
        final taxPrc = l.taxPrc ?? 0;
        final withTax = fine * l.touch! / 100;
        return RateLine(
          code: l.code,
          name: l.name,
          metal: l.metal,
          rate: _rupee(withTax / (1 + taxPrc / 100)),
          touch: l.touch,
          taxPrc: taxPrc,
          taxRate: _rupee(withTax),
        );
      }(),
  ];
}

/// The fine gold and silver rates to offer: today's if entered, else the most
/// recent, else zero.
({double gold, double silver}) prefillFine({
  required List<dynamic> todayRows,
  required List<dynamic> latestRows,
}) {
  for (final rows in [todayRows, latestRows]) {
    for (final r in rows) {
      if (r is! Map) continue;
      final g = _numOf(r['FINE_GL_RATE']);
      final s = _numOf(r['FINE_SL_RATE']);
      if ((g ?? 0) > 0 || (s ?? 0) > 0) return (gold: g ?? 0, silver: s ?? 0);
    }
  }
  return (gold: 0, silver: 0);
}
