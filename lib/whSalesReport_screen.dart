import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/book_picker.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class WhsalesreportScreen extends StatefulWidget {
  /// Date the report should open on — see [SalesReportScreen.initialFrom].
  final DateTime? initialFrom;
  final DateTime? initialTo;

  const WhsalesreportScreen({super.key, this.initialFrom, this.initialTo});

  @override
  State<WhsalesreportScreen> createState() => _WhsalesreportScreenState();
}

class _WhsalesreportScreenState extends State<WhsalesreportScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  Color get _cta => _brand;

  /// Sentinel for "no book filter applied".
  static const String _allBooks = "";

  /// MAIN_BOOK values this report covers: WH Sales, Tour Sales and the labour
  /// books. REPLACE normalises the 'WH SALES' vs 'WHSALES' spacing difference,
  /// and the LIKE clauses catch whichever wording the labour books use, so the
  /// exact stored spelling doesn't have to be known up front.
  ///
  /// The report query and the book-list query MUST share this condition — if
  /// they drift apart the filter can offer a book that returns no rows.
  /// [col] is the qualified column name, since the report query aliases
  /// BOOK_DATA as B while the book-list query selects from it directly.
  static String _mainBookFilter(String col) =>
      "(REPLACE($col,' ','') IN ('WHSALES','TOURSALES') "
      "OR REPLACE($col,' ','') LIKE '%LABOUR%' "
      "OR REPLACE($col,' ','') LIKE '%LBR%')";

  final sqlConnection = SqlConnection.getInstance();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> whSalesReport = [];
  List<dynamic> searchWhSalesReport = [];

  /// Book list shown in the filter. Always sourced from the database — never
  /// hardcoded — so the codes and names match whatever is set up in the
  /// software. Each entry is {"code": "034", "name": "..."}.
  List<Map<String, String>> bookData = [];
  String selectedBookCode = _allBooks;

  late DateTime fromDate = widget.initialFrom ?? DateTime.now();
  late DateTime toDate = widget.initialTo ?? DateTime.now();
  String co_code = "";
  String lc_code = "";
  String year = "";
  String companyName = "";
  late LoadingProvider loadingProvider;

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    co_code = provider.co_code;
    lc_code = provider.lc_code;
    year = provider.co_year;
    companyName = provider.co_name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getWHSalesReportData();
    });
    getFilterBookData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> getWHSalesReportData() async {
    loadingProvider.startLoading();
    setState(() {});
    try {
      if (Platform.isAndroid) {
        var query =
            "SELECT A.CO_CODE,A.CO_YEAR,(convert(varchar(50),A.VCH_DATE,105)) as VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_SNAME,C.AC_CODE,C.AC_NAME,C.AC_MOBILE, SUM(ITM_PCS) As Pcs,Sum(A.ITM_GWT) As Gwt,SUM(A.ITM_NWT) As Nwt, (Select D.TOT_FINE_DR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As TotDrFine, (Select D.KSR_FINE_CR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As KasarFine, (Select D.TOT_FINE_CR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As TotRecFine, (Select D.TOT_FINE_DR-D.KSR_FINE_CR- D.TOT_FINE_CR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As OsFine, (Select E.DR_AMT+E.SL_LBR_AMT+E.SL_OTH_AMT+E.SL_ITM_AMT From RATE_CUT_DATA AS E Where A.CO_CODE = E.CO_CODE AND A.CO_YEAR = E.CO_YEAR AND A.CO_BOOK = E.CO_BOOK  AND A.VCH_NO = E.VCH_NO ) As NetAmt, (Select H.SL_CHQ_AMT+H.SL_CARD_AMT+SL_CASH_AMT+SL_KASAR_AMT From RATE_CUT_DATA AS H Where A.CO_CODE = H.CO_CODE AND A.CO_YEAR = H.CO_YEAR AND A.CO_BOOK = H.CO_BOOK  AND A.VCH_NO = H.VCH_NO ) As TotRcvAmt, (Select M.SL_BILL_OS From RATE_CUT_DATA AS M Where A.CO_CODE = M.CO_CODE AND A.CO_YEAR = M.CO_YEAR AND A.CO_BOOK = M.CO_BOOK  AND A.VCH_NO = M.VCH_NO ) As BillOs from (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) LEFT JOIN AC_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.AC_CODE = C.AC_CODE WHERE A.CO_CODE = '" +
                co_code +
                "' AND A.LC_CODE = '" +
                lc_code +
                "' AND A.CO_YEAR = '" +
                year +
                "' AND A.ITM_SIGN = '-' AND A.VCH_DATE >= '" +
                DateFormat("MM/dd/yyyy").format(fromDate) +
                "' AND A.VCH_DATE <= '" +
                DateFormat("MM/dd/yyyy").format(toDate) +
                "' AND ${_mainBookFilter('B.MAIN_BOOK')} ";
        // Book is pushed into the query, exactly like the sales screen does.
        if (selectedBookCode != _allBooks) {
          query += "AND A.CO_BOOK = '$selectedBookCode' ";
        }
        query +=
            "GROUP BY A.CO_CODE,A.CO_YEAR,A.VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_SNAME,C.AC_CODE,C.AC_NAME,C.AC_MOBILE ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO";
        log("Query $query");
        dynamic whSaleData = await sqlConnection.queryDatabase(query);
        whSalesReport = jsonDecode(whSaleData);
      } else {
        dynamic result = await MySQLService().getWhSalesReport(
            co_code,
            lc_code,
            year,
            DateFormat("MM/dd/yyyy").format(fromDate),
            DateFormat("MM/dd/yyyy").format(toDate),
            selectedBookCode);
        whSalesReport = result[0];
      }
      _mergeBooksFromRows();
      _applyFilters();
    } catch (e) {
      log('Error fetching WH sales report: $e');
      whSalesReport = [];
      searchWhSalesReport = [];
      if (mounted) {
        showAppToast(context, "Could not load report. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  /// Lists the WH Sales / Tour Sales / labour books with the names configured
  /// in the software, using the same MAIN_BOOK condition as the report so the
  /// two can't disagree. Not limited by the date range, so narrowing the dates
  /// cannot make books disappear from the filter.
  ///
  /// Only books marked CUR_USE='Y' are listed — a book switched off in the
  /// software will not appear here until it is switched back on.
  Future<void> getFilterBookData() async {
    try {
      if (!Platform.isAndroid) {
        final iosBooks = await MySQLService().getWhSalesFilterData(
          co_code,
          lc_code,
        );
        for (final row in iosBooks[0]) {
          final code = '${row["CO_BOOK"] ?? ''}'.trim();
          if (code.isEmpty) continue;
          _addBook(code, '${row["BOOK_NAME"] ?? ''}'.trim());
        }
        if (mounted) setState(() {});
        return;
      }
      final query = "SELECT CO_BOOK,BOOK_NAME,BOOK_SNAME FROM BOOK_DATA "
          "WHERE CO_CODE = '$co_code' AND LC_CODE = '$lc_code' "
          "AND ${_mainBookFilter('MAIN_BOOK')} AND CUR_USE='Y' "
          "ORDER BY CO_BOOK";
      log("Book query $query");
      final dynamic result = await sqlConnection.queryDatabase(query);
      for (final row in jsonDecode(result)) {
        final code = '${row["CO_BOOK"] ?? ''}'.trim();
        if (code.isEmpty) continue;
        final fullName = '${row["BOOK_NAME"] ?? ''}'.trim();
        final shortName = '${row["BOOK_SNAME"] ?? ''}'.trim();
        _addBook(code, fullName.isNotEmpty ? fullName : shortName);
      }
      if (mounted) setState(() {});
    } catch (e) {
      // Non-fatal: the list still tops up from the loaded rows.
      log('Error fetching WH book list: $e');
    }
  }

  /// Safety net: a book can exist in the voucher data even if BOOK_DATA missed
  /// it, so top the list up from whatever the report actually returned.
  void _mergeBooksFromRows() {
    for (final row in whSalesReport) {
      final code = '${row["CO_BOOK"] ?? ''}'.trim();
      if (code.isEmpty) continue;
      _addBook(code, '${row["BOOK_SNAME"] ?? ''}'.trim());
    }
  }

  void _addBook(String code, String name) {
    final existing = bookData.indexWhere((b) => b["code"] == code);
    if (existing == -1) {
      bookData.add({"code": code, "name": name});
      bookData.sort((a, b) => a["code"]!.compareTo(b["code"]!));
    } else if ((bookData[existing]["name"] ?? '').isEmpty && name.isNotEmpty) {
      bookData[existing] = {"code": code, "name": name};
    }
  }

  String _bookLabel(String code) {
    if (code == _allBooks) return "All books";
    final match = bookData.firstWhere((b) => b["code"] == code,
        orElse: () => {"code": code, "name": ""});
    final name = match["name"] ?? '';
    return name.isEmpty ? code : "$code - $name";
  }

  /// Search runs over the loaded rows. The book is already applied in SQL on
  /// Android; it is re-checked here because the iOS channel method takes no
  /// book parameter, and it is a harmless no-op on Android.
  void _applyFilters() {
    final term = _searchController.text.trim().toLowerCase();
    searchWhSalesReport = whSalesReport.where((row) {
      if (selectedBookCode != _allBooks &&
          '${row["CO_BOOK"] ?? ''}'.trim() != selectedBookCode) {
        return false;
      }
      if (term.isEmpty) return true;
      final name = '${row["AC_NAME"] ?? ''}'.toLowerCase();
      final mobile = '${row["AC_MOBILE"] ?? ''}';
      final vch = '${row["VCH_NO"] ?? ''}'.toLowerCase();
      return name.contains(term) || mobile.contains(term) || vch.contains(term);
    }).toList();
  }

  // ── Action helpers ─────────────────────────────────────────────────────────

  void _toast(String message) {
    if (!mounted) return;
    showAppToast(context, message);
  }

  String _mobile(dynamic data) => '${data["AC_MOBILE"] ?? ''}'.trim();

  String _fmt(dynamic value, int decimals) {
    if (value == null) return '0${decimals > 0 ? '.${'0' * decimals}' : ''}';
    final parsed = num.tryParse(value.toString());
    if (parsed == null) return value.toString().trim();
    return parsed.toStringAsFixed(decimals);
  }

  String _invoiceMessage(dynamic data) {
    final buffer = StringBuffer();
    buffer.writeln("*Thanks For Buying Ornaments*");
    buffer.writeln();
    buffer.writeln("Invoice No : ${data["VCH_NO"] ?? ''}");
    buffer.writeln("Invoice Date : ${data["VCH_DATE"] ?? ''}");
    final book = '${data["BOOK_SNAME"] ?? ''}'.trim();
    if (book.isNotEmpty) buffer.writeln("Book : $book");
    buffer.writeln("Gross Wt : ${_fmt(data["Gwt"], 3)}");
    buffer.writeln("Net Wt : ${_fmt(data["Nwt"], 3)}");
    buffer.writeln("Issue Fine : ${_fmt(data["TotDrFine"], 3)}");
    buffer.writeln("Receive Fine : ${_fmt(data["TotRecFine"], 3)}");
    buffer.writeln("Os Fine : ${_fmt(data["OsFine"], 3)}");
    buffer.writeln("Issue Amount : ${_fmt(data["NetAmt"], 2)}");
    buffer.writeln("Receive Amount : ${_fmt(data["TotRcvAmt"], 2)}");
    buffer.writeln("Os Amount : ${_fmt(data["BillOs"], 2)}");
    buffer.writeln();
    buffer.writeln('${data["AC_NAME"] ?? ''}');
    if (companyName.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(companyName.trim());
    }
    return buffer.toString();
  }

  Future<void> _sendWhatsApp(dynamic data) async {
    final mobile = _mobile(data);
    if (mobile.isEmpty) {
      _toast("No mobile number for this account");
      return;
    }
    try {
      final link = WhatsAppUnilink(
          phoneNumber: "+91$mobile", text: _invoiceMessage(data));
      final launched =
          await launchUrlString('$link', mode: LaunchMode.externalApplication);
      if (!launched) _toast("WhatsApp is not installed");
    } catch (_) {
      _toast("Unable to open WhatsApp");
    }
  }

  Future<void> _makeCall(dynamic data) async {
    final mobile = _mobile(data);
    if (mobile.isEmpty) {
      _toast("No mobile number for this account");
      return;
    }
    try {
      final launched = await launchUrlString("tel:+91$mobile");
      if (!launched) _toast("Unable to start the call");
    } catch (_) {
      _toast("Unable to start the call");
    }
  }

  Future<void> _sendSms(dynamic data) async {
    final mobile = _mobile(data);
    if (mobile.isEmpty) {
      _toast("No mobile number for this account");
      return;
    }
    final body = Uri.encodeComponent(_invoiceMessage(data));
    final url = Platform.isIOS
        ? "sms:+91$mobile&body=$body"
        : "sms:+91$mobile?body=$body";
    try {
      final launched = await launchUrlString(url);
      if (!launched) _toast("Unable to open Messages");
    } catch (_) {
      _toast("Unable to open Messages");
    }
  }

  Future<void> _shareMessage(dynamic data) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _invoiceMessage(data),
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _appBar(),
      body: Column(
        children: [
          _searchField(),
          if (selectedBookCode != _allBooks) _activeFilterChip(),
          Expanded(
            child: Consumer<LoadingProvider>(
              builder: (context, loading, _) {
                if (loading.isLoading) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: _cta, strokeWidth: 2.6));
                }
                if (searchWhSalesReport.isEmpty) return _emptyState();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  itemCount: searchWhSalesReport.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _salesCard(searchWhSalesReport[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_brand, _brand.withValues(alpha: 0.82)],
          ),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("WH Sales Report",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(
                    "${DateFormat("dd/MM/yyyy").format(fromDate)}  –  ${DateFormat("dd/MM/yyyy").format(toDate)}",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          IconButton(
            tooltip: "Filters",
            onPressed: () => fillterData(fromD: fromDate, toD: toDate),
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextFormField(
        controller: _searchController,
        cursorColor: _cta,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w500, color: _textPrimary),
        decoration: InputDecoration(
          hintText: "Search name, mobile or invoice no",
          hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Icon(Icons.search_rounded, color: _cta, size: 21),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: _textSecondary, size: 19),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                    setState(() {});
                  },
                ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _cta, width: 1.6),
          ),
        ),
        onChanged: (_) {
          _applyFilters();
          setState(() {});
        },
      ),
    );
  }

  Widget _activeFilterChip() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          padding: const EdgeInsets.only(left: 12, right: 6, top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: _cta.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cta.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_bookLabel(selectedBookCode),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _cta)),
              const SizedBox(width: 2),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  selectedBookCode = _allBooks;
                  getWHSalesReportData();
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 15, color: _cta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _salesCard(dynamic data) {
    return Container(
      padding: const EdgeInsets.all(1.25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cta.withValues(alpha: 0.4), _cta.withValues(alpha: 0.08)],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.75),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('${data["AC_NAME"] ?? ''}'.trim(),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cta.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('#${data["VCH_NO"] ?? ''}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _cta)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _inlineMeta(Icons.phone_rounded, _mobile(data)),
                _inlineMeta(Icons.event_rounded, '${data["VCH_DATE"] ?? ''}'),
                _inlineMeta(Icons.menu_book_rounded,
                    '${data["BOOK_SNAME"] ?? ''}'.trim()),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFEEF2F6)),
            const SizedBox(height: 12),
            _statRow([
              _stat("Pcs", _fmt(data["Pcs"], 0)),
              _stat("Gross Wt", _fmt(data["Gwt"], 3)),
              _stat("Net Wt", _fmt(data["Nwt"], 3)),
            ]),
            const SizedBox(height: 12),
            _statRow([
              _stat("Issue Fine", _fmt(data["TotDrFine"], 3), color: _danger),
              _stat("Rec Fine", _fmt(data["TotRecFine"], 3), color: _success),
              _stat("Os Fine", _fmt(data["OsFine"], 3), color: _danger),
            ]),
            const SizedBox(height: 12),
            _statRow([
              _stat("Issue Amt", _fmt(data["NetAmt"], 2), color: _danger),
              _stat("Rec Amt", _fmt(data["TotRcvAmt"], 2), color: _success),
              _stat("Os Amt", _fmt(data["BillOs"], 2), color: _danger),
            ]),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFEEF2F6)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionChip(
                    image: AppImage.whatsapp,
                    label: "WhatsApp",
                    onTap: () => _sendWhatsApp(data)),
                _actionChip(
                    image: AppImage.telephone,
                    label: "Call",
                    onTap: () => _makeCall(data)),
                _actionChip(
                    image: AppImage.chat,
                    label: "Message",
                    onTap: () => _sendSms(data)),
                _actionChip(
                    image: AppImage.share,
                    label: "Share",
                    onTap: () => _shareMessage(data)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineMeta(IconData icon, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _textSecondary),
        const SizedBox(width: 4),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: _textSecondary)),
      ],
    );
  }

  Widget _statRow(List<Widget> children) {
    final row = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        row.add(
            Container(width: 1, height: 30, color: const Color(0xFFEEF2F6)));
      }
      row.add(Expanded(child: children[i]));
    }
    return Row(children: row);
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textSecondary)),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: color ?? _textPrimary)),
        ),
      ],
    );
  }

  Widget _actionChip({
    required String image,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: _pageBg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 5),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: _cta.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded, color: _cta, size: 34),
          ),
          const SizedBox(height: 16),
          Text("No records found",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text("Try a different date range, book or search term",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary)),
          ),
        ],
      ),
    );
  }

  // ── Filter sheet ───────────────────────────────────────────────────────────

  void fillterData({required DateTime fromD, required DateTime toD}) {
    DateTime from = fromD;
    DateTime to = toD;
    String book = selectedBookCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      height: 4,
                      width: 42,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
                    child: Row(
                      children: [
                        Text("Filters",
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            fromDate = DateTime.now();
                            toDate = DateTime.now();
                            selectedBookCode = _allBooks;
                            Navigator.pop(context);
                            getWHSalesReportData();
                          },
                          child: Text("Clear all",
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _textSecondary)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded,
                              color: _textSecondary, size: 21),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: const Color(0xFFEEF2F6)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel("Date range"),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _dateBox(
                                value: from,
                                onTap: () async {
                                  final picked =
                                      await _selectDate(context, from);
                                  if (picked != null) {
                                    from = picked;
                                    if (to.isBefore(from)) to = from;
                                    setModalState(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dateBox(
                                value: to,
                                onTap: () async {
                                  final picked = await _selectDate(context, to);
                                  if (picked != null) {
                                    to = picked;
                                    if (to.isBefore(from)) from = to;
                                    setModalState(() {});
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _fieldLabel("Book"),
                        const SizedBox(height: 8),
                        bookPickerField(
                          label: _bookLabel(book),
                          onTap: () async {
                            final picked = await showBookPicker(
                              context: context,
                              selected: book,
                              options: [
                                PickerOption(_allBooks, _bookLabel(_allBooks)),
                                ...bookData.map((b) => PickerOption(
                                    b["code"]!, _bookLabel(b["code"]!))),
                              ],
                            );
                            if (picked != null) {
                              book = picked;
                              setModalState(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _cta,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              fromDate = from;
                              toDate = to;
                              selectedBookCode = book;
                              Navigator.pop(context);
                              getWHSalesReportData();
                            },
                            child: Text("Apply filters",
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: _textSecondary));
  }

  Widget _dateBox({required DateTime value, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(DateFormat("dd/MM/yyyy").format(value),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary)),
            ),
            Icon(Icons.calendar_today_rounded, size: 16, color: _cta),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime init) async {
    return showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _brand,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _textPrimary),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
