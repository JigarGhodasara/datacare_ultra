import 'dart:convert';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/utils/tag_stock_section.dart';
import 'package:sql_connection/sql_connection.dart';

/// Shared fetchers for the report row-sets that more than one screen needs.
///
/// Both the Day Book and the Graph Reports screen summarise the same rows the
/// detail reports show. Keeping the SQL here means the figures cannot drift
/// between screens, and the long queries exist once rather than in every
/// caller.
///
/// Platform split, and why: the `sql_client_channel` MethodChannel behind
/// [MySQLService] is registered in `AppDelegate.swift` only, so it exists on
/// iOS alone. Android runs the equivalent SQL directly. Both paths return the
/// same row shape, so callers stay platform-agnostic.
class ReportQueries {
  final String coCode;
  final String lcCode;
  final String year;

  ReportQueries({
    required this.coCode,
    required this.lcCode,
    required this.year,
  });

  final _sql = SqlConnection.getInstance();

  /// Runs [query] on whichever platform this is and returns its rows.
  ///
  /// iOS has no general SQL entry point — each report has its own native
  /// method — with one exception: `getPrintLable`, which the tag-estimate
  /// print path uses to execute a query string handed over from Dart. Despite
  /// the name it is a plain execute, and it is what lets a small new report
  /// ship without another AppDelegate method. Android runs the SQL directly.
  Future<List<dynamic>> _run(String query) async {
    if (!Platform.isAndroid) {
      final result = await MySQLService().getPrintLable(query);
      return result[0] as List;
    }
    return jsonDecode(await _sql.queryDatabase(query)) as List;
  }

  /// Runs a statement that returns no rows (INSERT / UPDATE / DELETE).
  ///
  /// Android goes through the plugin's write method, the same one the tag
  /// image upload uses. iOS runs it through the raw-execute channel; that
  /// side only logs server errors, so callers that need to be sure re-read
  /// what they wrote.
  Future<void> execute(String statement) async {
    if (!Platform.isAndroid) {
      await MySQLService().getPrintLable(statement);
      return;
    }
    await _sql.updateData(statement);
  }

  double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

  /// Every group of the company with its type (G gold, S silver, O other,
  /// E imitation, R store), its touch and tax %, and whether it is one the
  /// home page's rate box displays. Used to build the rate entry form.
  Future<List<dynamic>> rateGroups() => _run(
      "SELECT GR_CODE,GR_NAME,GR_TYPE,RATE_DISPLAY,GR_TOUCH,TAX_PRC "
      "FROM GROUP_MAST WHERE CO_CODE = '$coCode' ORDER BY GR_CODE");

  /// The columns of [table]'s primary key, in key order. Lets a write fill a
  /// key column the app did not know about (`RATE_MAST` turned out to carry
  /// a serial number in its key) instead of guessing its name.
  Future<List<String>> primaryKeyColumns(String table) async {
    final rows = await _run(
        "SELECT K.COLUMN_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS T "
        "INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS K "
        "ON T.CONSTRAINT_NAME = K.CONSTRAINT_NAME AND T.TABLE_NAME = K.TABLE_NAME "
        "WHERE T.TABLE_NAME = '$table' AND T.CONSTRAINT_TYPE = 'PRIMARY KEY' "
        "ORDER BY K.ORDINAL_POSITION");
    return [
      for (final r in rows)
        if (r is Map) '${r['COLUMN_NAME'] ?? ''}'.trim(),
    ];
  }

  /// The highest value of [column] among `RATE_MAST` rows of [dateSql] in
  /// this company, location and year; 0 when there are none.
  Future<int> rateMaxSerial(String column, String dateSql) async {
    final rows = await _run("SELECT MAX($column) AS MaxNo FROM RATE_MAST "
        "WHERE CO_CODE = '$coCode' AND LC_CODE = '$lcCode' "
        "AND CO_YEAR = '$year' AND VCH_DATE = '$dateSql'");
    if (rows.isEmpty || rows[0] is! Map) return 0;
    return _num(rows[0]['MaxNo']).toInt();
  }

  /// The most recent `RATE_MAST` row of each group at this location, on any
  /// date. Supplies each group's touch and tax % to the entry form.
  Future<List<dynamic>> latestRates() => _run(
      "SELECT A.GR_CODE,A.GR_TOUCH,A.GR_RATE,A.GR_TAX_PRC,A.GR_TAX_RATE,"
      "A.FINE_GL_RATE,A.FINE_SL_RATE FROM RATE_MAST AS A "
      "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' "
      "AND A.VCH_DATE = (SELECT MAX(B.VCH_DATE) FROM RATE_MAST AS B "
      "WHERE B.CO_CODE = A.CO_CODE AND B.LC_CODE = A.LC_CODE "
      "AND B.GR_CODE = A.GR_CODE)");

  /// Cash in hand at the close of [date]: `SUM(CR − DR)` on the cash account,
  /// positive when there is cash. Same figure the dashboard's cash box shows.
  Future<double> cashBalance(String date) async {
    if (!Platform.isAndroid) {
      final result = await MySQLService().getCashOnHand(coCode, lcCode, date);
      return _num(result[0][0]['BalAmt']);
    }
    final rows = await _run(
        "Select Sum(A.CR_AMT-A.DR_AMT) as BalAmt FROM AC_DATA AS A "
        "WHERE A.CO_CODE = '$coCode' and A.LC_CODE = '$lcCode' "
        "AND A.AC_CODE = '00001' and A.VCH_DATE <= '$date'");
    return rows.isEmpty ? 0 : _num(rows[0]['BalAmt']);
  }

  /// Cash that came in and went out on [date].
  ///
  /// On the cash account a credit raises the balance, so receipts are the
  /// CR_AMT side and payments the DR_AMT side — the same convention
  /// [cashBalance] nets.
  Future<({double received, double paid})> cashMovement(String date) async {
    final rows = await _run(
        "SELECT SUM(A.CR_AMT) As Received, SUM(A.DR_AMT) As Paid "
        "FROM AC_DATA AS A "
        "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' "
        "AND A.AC_CODE = '00001' "
        "AND A.VCH_DATE >= '$date' AND A.VCH_DATE <= '$date'");
    if (rows.isEmpty) return (received: 0.0, paid: 0.0);
    return (received: _num(rows[0]['Received']), paid: _num(rows[0]['Paid']));
  }

  /// Net weight sold on [date], one row per item type (G, S, …).
  ///
  /// Same rows and the same book filter as [salesRows], so the parts add up to
  /// the Net Wt shown beside them; only the grouping differs.
  Future<List<dynamic>> salesWeightByMetal(String date) => _run(
      "SELECT C.IT_TYPE As ItType, SUM(A.ITM_NWT) As Nwt "
      "FROM (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) "
      "LEFT JOIN ITEM_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.IT_CODE = C.IT_CODE "
      "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' AND A.CO_YEAR = '$year' "
      "AND A.ITM_SIGN = '-' AND A.VCH_DATE >= '$date' AND A.VCH_DATE <= '$date' "
      "AND B.MAIN_BOOK IN ('SALES','SALES RETURN') "
      "GROUP BY C.IT_TYPE");

  /// Stock bought in on [date], per voucher and item type.
  ///
  /// A purchase is a MAIN_STOCK arrival with TR_TYPE 'P' — the same test the
  /// Stock Report's "Purchase" line uses — so the two agree. The book columns
  /// come along so old-gold books can be told apart from ordinary purchases.
  Future<List<dynamic>> purchaseRows(String date) => _run(
      "SELECT A.VCH_NO, A.CO_BOOK, B.MAIN_BOOK, B.BOOK_NAME, C.IT_TYPE As ItType, "
      "SUM(A.ITM_PCS) As Pcs, SUM(A.ITM_GWT) As Gwt, SUM(A.ITM_NWT) As Nwt "
      "FROM (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) "
      "LEFT JOIN ITEM_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.IT_CODE = C.IT_CODE "
      "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' AND A.CO_YEAR = '$year' "
      "AND A.ITM_SIGN = '+' AND A.TR_TYPE = 'P' "
      "AND A.VCH_DATE >= '$date' AND A.VCH_DATE <= '$date' "
      "GROUP BY A.VCH_NO, A.CO_BOOK, B.MAIN_BOOK, B.BOOK_NAME, C.IT_TYPE");

  /// Old gold taken against sales bills on [date], by value.
  ///
  /// This is the exchange line on the bill (SL_DATA.OLD_GL_AMT), which is how
  /// most old gold enters a retail shop — not through a purchase book at all.
  Future<double> oldGoldAmount(String date) async {
    final rows = await _run(
        "SELECT SUM(A.OLD_GL_AMT) As OldGoldAmt FROM SL_DATA AS A "
        "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' AND A.CO_YEAR = '$year' "
        "AND A.VCH_DATE >= '$date' AND A.VCH_DATE <= '$date'");
    return rows.isEmpty ? 0 : _num(rows[0]['OldGoldAmt']);
  }

  /// Counter sales (MAIN_BOOK SALES / SALES RETURN) for a date range.
  ///
  /// Rows are per voucher line, so amounts repeat across the lines of one
  /// voucher — de-duplicate on VCH_NO + CO_BOOK before totalling.
  Future<List<dynamic>> salesRows(String fromDate, String toDate) async {
    if (!Platform.isAndroid) {
      final result = await MySQLService().getSalesReport(
          coCode, lcCode, year, fromDate, toDate, "Select book");
      return result[0] as List;
    }
    final query =
        "SELECT A.CO_CODE,A.LC_CODE,A.CO_YEAR,(convert(varchar(50),A.VCH_DATE,105)) as VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_NAME,C.AC_NAME,C.AC_MOBILE, A.MAIN_USER, SUM(ITM_PCS) As Pcs,Sum(A.ITM_GWT) As Gwt,SUM(A.ITM_NWT) As Nwt,SUM(A.ITM_FINE) As Fine, (Select D.TOT_AMT From SL_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.LC_CODE = D.LC_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As NetAmt, (Select E.BILL_OS From SL_DATA AS E Where A.CO_CODE = E.CO_CODE AND A.LC_CODE = E.LC_CODE AND A.CO_YEAR = E.CO_YEAR AND A.CO_BOOK = E.CO_BOOK  AND A.VCH_NO = E.VCH_NO ) As OsAmt from (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) LEFT JOIN AC_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.AC_CODE = C.AC_CODE WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' AND A.CO_YEAR = '$year' AND A.ITM_SIGN = '-' AND A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate' AND B.MAIN_BOOK IN ('SALES','SALES RETURN') "
        "GROUP BY A.CO_CODE,A.LC_CODE,A.CO_YEAR,A.VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_NAME,C.AC_NAME,C.AC_MOBILE,A.MAIN_USER ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO";
    return jsonDecode(await _sql.queryDatabase(query)) as List;
  }

  /// Wholesale / tour / labour sales for a date range.
  Future<List<dynamic>> whSalesRows(String fromDate, String toDate) async {
    if (!Platform.isAndroid) {
      final result = await MySQLService()
          .getWhSalesReport(coCode, lcCode, year, fromDate, toDate);
      return result[0] as List;
    }
    final query =
        "SELECT A.CO_CODE,A.CO_YEAR,(convert(varchar(50),A.VCH_DATE,105)) as VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_SNAME,C.AC_CODE,C.AC_NAME,C.AC_MOBILE, SUM(ITM_PCS) As Pcs,Sum(A.ITM_GWT) As Gwt,SUM(A.ITM_NWT) As Nwt, (Select E.DR_AMT+E.SL_LBR_AMT+E.SL_OTH_AMT+E.SL_ITM_AMT From RATE_CUT_DATA AS E Where A.CO_CODE = E.CO_CODE AND A.CO_YEAR = E.CO_YEAR AND A.CO_BOOK = E.CO_BOOK  AND A.VCH_NO = E.VCH_NO ) As NetAmt, (Select M.SL_BILL_OS From RATE_CUT_DATA AS M Where A.CO_CODE = M.CO_CODE AND A.CO_YEAR = M.CO_YEAR AND A.CO_BOOK = M.CO_BOOK  AND A.VCH_NO = M.VCH_NO ) As BillOs from (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) LEFT JOIN AC_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.AC_CODE = C.AC_CODE WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' AND A.CO_YEAR = '$year' AND A.ITM_SIGN = '-' AND A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate' AND (REPLACE(B.MAIN_BOOK,' ','') IN ('WHSALES','TOURSALES') OR REPLACE(B.MAIN_BOOK,' ','') LIKE '%LABOUR%' OR REPLACE(B.MAIN_BOOK,' ','') LIKE '%LBR%') "
        "GROUP BY A.CO_CODE,A.CO_YEAR,A.VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_SNAME,C.AC_CODE,C.AC_NAME,C.AC_MOBILE ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO";
    return jsonDecode(await _sql.queryDatabase(query)) as List;
  }

  /// Sales orders raised in a date range.
  Future<List<dynamic>> orderRows(String fromDate, String toDate) async {
    if (!Platform.isAndroid) {
      final result = await MySQLService()
          .getSalesOrderReport(coCode, lcCode, "Select book", fromDate, toDate);
      return result[0] as List;
    }
    final query =
        "SELECT A.AC_NAME As AC_NAME,A.MOBILE As AC_MOBILE,A.VCH_DATE AS VCH_DATE,A.VCH_NO As VCH_NO,A.TOT_AMT As TotAmt,A.ADV_AMT As AdvAmt,A.DEL_DATE As DeliveryDt FROM SL_ORD_DATA AS A "
        "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' AND A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate' ORDER BY A.VCH_NO";
    return jsonDecode(await _sql.queryDatabase(query)) as List;
  }

  /// Stock movement per item for a date range, unfiltered by group or table.
  ///
  /// Returns ItName, opening (OpPcs/OpWt), sold in range (SlPcs/SlWt) and
  /// closing (ClPcs/ClWt) — the same columns the iOS native call returns, so
  /// both platforms can drive the same analytics.
  Future<List<dynamic>> stockRows(
      String fromDate, String toDate, String itType) async {
    if (!Platform.isAndroid) {
      final result = await MySQLService().getStockReport(
        coCode: coCode,
        lcCode: lcCode,
        year: year,
        fromDate: fromDate,
        toDate: toDate,
        itType: itType,
        stkType: '',
        grpCode: '',
        itmCode: '',
        prdCode: '',
        tblCode: '',
      );
      return result[0] as List;
    }
    var query =
        "SELECT B.IT_CODE AS ItCode ,B.IT_NAME AS ItName,B.IT_TYPE As ItType, "
        "SUM(CASE WHEN A.VCH_DATE <  '$fromDate' THEN (CASE WHEN ITM_SIGN = '+' THEN  A.ITM_PCS ELSE  -A.ITM_PCS END) ELSE 0 END) AS OpPcs,"
        "SUM(CASE WHEN A.VCH_DATE <  '$fromDate' THEN (CASE WHEN ITM_SIGN = '+' THEN A.ITM_NWT ELSE -A.ITM_NWT END) ELSE 0 END) AS OpWt,"
        "SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate' THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'S' THEN A.ITM_PCS ELSE 0 END) ELSE 0 END) AS SlPcs,"
        "SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate' THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'S' THEN A.ITM_NWT ELSE 0 END) ELSE 0 END) AS SlWt,"
        "SUM(CASE WHEN A.VCH_DATE <=  '$toDate' THEN(CASE WHEN ITM_SIGN = '+' THEN A.ITM_PCS ELSE -A.ITM_PCS END) ELSE 0 END) AS ClPcs,"
        "SUM(CASE WHEN A.VCH_DATE <=  '$toDate' THEN(CASE WHEN ITM_SIGN = '+' THEN A.ITM_NWT ELSE -A.ITM_NWT END) ELSE 0 END) AS ClWt "
        "FROM MAIN_STOCK AS A LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE "
        "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' AND A.CO_YEAR = '$year'";
    if (itType.isNotEmpty) {
      query += " AND B.IT_TYPE = '$itType' ";
    }
    query += " GROUP BY B.IT_CODE,B.IT_NAME,B.IT_TYPE ORDER BY B.IT_NAME";
    return jsonDecode(await _sql.queryDatabase(query)) as List;
  }

  /// Tag-level rows for the Tag Stock Report.
  ///
  /// One row per tag movement (or per tag still held, for the stock section),
  /// carrying what the screen shows: item name, pieces, weights, the voucher
  /// date and the two fields the image file name is built from.
  ///
  /// [from] and [to] are ignored for [TagStockSection.stock], which reports a
  /// position rather than a period.
  Future<List<dynamic>> tagStockRows(
    TagStockSection section,
    String from,
    String to,
  ) async {
    if (!Platform.isAndroid) {
      final result = await MySQLService().getTagStockReport(
        coCode,
        lcCode,
        year,
        section.name,
        from,
        to,
      );
      return result[0] as List;
    }

    final columns =
        "A.TAG_NO AS TagNo, A.VCH_SRNO, A.IT_CODE, B.IT_NAME AS ItmName, "
        "C.DESIGN_IMG_ID AS DesignImgId, C.DESIGN_NO, C.ITM_SIZE AS Size, "
        "(convert(varchar(50),A.VCH_DATE,105)) AS VchDate, "
        "SUM(A.ITM_PCS) AS Pcs, SUM(A.ITM_GWT) AS Grwt, SUM(A.ITM_NWT) AS NetWt";

    final query = "SELECT $columns "
        "FROM ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C "
        "ON A.CO_CODE = C.CO_CODE AND A.TAG_NO = C.TAG_NO "
        "AND A.VCH_SRNO = C.VCH_SRNO AND A.IT_CODE = C.IT_CODE) "
        "LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE "
        "AND A.IT_CODE = B.IT_CODE) "
        "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' "
        "AND A.CO_YEAR = '$year' AND A.TAG_NO <> 'N' "
        "${tagSectionPredicate(section, from, to)}"
        "GROUP BY A.TAG_NO, A.VCH_SRNO, A.IT_CODE, B.IT_NAME, "
        "C.DESIGN_IMG_ID, C.DESIGN_NO, C.ITM_SIZE, A.VCH_DATE "
        "${tagSectionHaving(section)}"
        "ORDER BY A.VCH_DATE DESC, A.TAG_NO DESC";
    return jsonDecode(await _sql.queryDatabase(query)) as List;
  }

  /// Account groups that represent parties who can owe us money. Without this
  /// the list also picks up bank, cash-on-hand and other control accounts.
  /// Stored as plain numbers because AC_GR is a padded CHAR column.
  static const List<int> partyGroups = [5, 10, 15, 20];

  static List<String> get _partyGroupVariants => [
        for (final g in partyGroups) ...[
          '$g',
          g.toString().padLeft(2, '0'),
          g.toString().padLeft(3, '0'),
        ]
      ].toSet().toList();

  static bool isPartyGroup(dynamic acGr) {
    final n = int.tryParse('${acGr ?? ''}'.trim());
    return n != null && partyGroups.contains(n);
  }

  /// Parties carrying a debit balance as on [date], biggest first.
  ///
  /// A debit balance means the customer owes us: the ledger computes the
  /// balance as SUM(CR_AMT - DR_AMT), so anything below zero is outstanding.
  Future<List<dynamic>> outstandingRows(String date) async {
    if (!Platform.isAndroid) {
      // The native ledger call filters a single group per request, so the
      // party groups are fetched once and then queried one at a time.
      final groupResult = await MySQLService().getGroup(coCode);
      final codes = (groupResult[0] as List)
          .where((g) => isPartyGroup(g["AC_GR"]))
          .map((g) => '${g["AC_GR"]}'.trim())
          .where((c) => c.isNotEmpty)
          .toList();

      // One group at a time. SQLClient is a shared singleton on the iOS side
      // too, so these cannot safely overlap.
      final batches = <dynamic>[];
      for (final code in codes) {
        batches.add(await MySQLService()
            .getLedgerReportData(coCode, lcCode, date, false, code, "", ""));
      }

      final rows = [
        for (final b in batches)
          ...(b[0] as List)
              .where((r) => (double.tryParse('${r["DrAmt"] ?? ''}') ?? 0) > 0)
      ];
      rows.sort((a, b) => (double.tryParse('${b["DrAmt"] ?? ''}') ?? 0)
          .compareTo(double.tryParse('${a["DrAmt"] ?? ''}') ?? 0));
      return rows;
    }

    final groupIn = _partyGroupVariants.map((g) => "'$g'").join(',');
    final query = "SELECT A.AC_CODE,B.AC_NAME,B.AC_MOBILE,B.AC_CITY, "
        "abs(SUM(A.CR_AMT-A.DR_AMT)) As DrAmt, "
        "Case WHEN SUM(CASE WHEN A.IT_TYPE='G' THEN (CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE -A.FINE_WT END) ELSE 0 END) < 0 "
        "then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN (CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE -A.FINE_WT END) ELSE 0 END)) else 0 end As DrGold, "
        "Case WHEN SUM(CASE WHEN A.IT_TYPE='S' THEN (CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE -A.FINE_WT END) ELSE 0 END) < 0 "
        "then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN (CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE -A.FINE_WT END) ELSE 0 END)) else 0 end As DrSilver "
        "FROM AC_DATA AS A LEFT JOIN AC_MAST AS B ON A.CO_CODE = B.CO_CODE And A.AC_CODE = B.AC_CODE "
        "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' AND A.VCH_DATE <= '$date' "
        "AND LTRIM(RTRIM(B.AC_GR)) IN ($groupIn) "
        "GROUP BY A.AC_CODE,B.AC_NAME,B.AC_MOBILE,B.AC_CITY "
        "HAVING SUM(A.CR_AMT-A.DR_AMT) < 0 "
        "ORDER BY SUM(A.CR_AMT-A.DR_AMT)";
    return jsonDecode(await _sql.queryDatabase(query)) as List;
  }
}
