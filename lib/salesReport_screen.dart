import 'dart:convert';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/book_picker.dart';
import 'package:DataCareUltra/salesZoomingReport.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class SalesReportScreen extends StatefulWidget {
  /// Date the report should open on.
  ///
  /// Passed by the Day Book so that drilling into Sales keeps the day the user
  /// was already looking at, instead of silently resetting to today and
  /// showing figures for a different date than the one they filtered.
  final DateTime? initialFrom;
  final DateTime? initialTo;

  const SalesReportScreen({Key? key, this.initialFrom, this.initialTo})
      : super(key: key);

  @override
  State<SalesReportScreen> createState() => _SalesreportScreenState();
}

class _SalesreportScreenState extends State<SalesReportScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  Color get _cta => _brand;

  final sqlConnection = SqlConnection.getInstance();
  late DateTime fromDate = widget.initialFrom ?? DateTime.now();
  late DateTime toDate = widget.initialTo ?? DateTime.now();
  late LoadingProvider loadingProvider;
  List<dynamic> salesReport = [];
  List<dynamic> searchSalesReport = [];
  List<dynamic> bookData = ["Select book"];
  String selectedBook = "Select book";
  String co_code = "";
  String lc_code = "";
  String year = "";

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    year =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getSalesReport();
    });
    getFillterBookData();
  }

  getSalesReport() async {
    loadingProvider.startLoading();
    setState(() {});
    try {
      if (Platform.isAndroid) {
        var query =
            "SELECT A.CO_CODE,A.LC_CODE,A.CO_YEAR,(convert(varchar(50),A.VCH_DATE,105)) as VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_NAME,C.AC_NAME,C.AC_MOBILE, A.MAIN_USER, SUM(ITM_PCS) As Pcs,Sum(A.ITM_GWT) As Gwt,SUM(A.ITM_NWT) As Nwt,SUM(A.ITM_FINE) As Fine, (Select D.TOT_AMT From SL_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.LC_CODE = D.LC_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As NetAmt, (Select E.BILL_OS From SL_DATA AS E Where A.CO_CODE = E.CO_CODE AND A.LC_CODE = E.LC_CODE AND A.CO_YEAR = E.CO_YEAR AND A.CO_BOOK = E.CO_BOOK  AND A.VCH_NO = E.VCH_NO ) As OsAmt from (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) LEFT JOIN AC_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.AC_CODE = C.AC_CODE WHERE A.CO_CODE = '" +
                co_code +
                "' AND A.LC_CODE = '" +
                lc_code +
                "' AND A.CO_YEAR = '" +
                year +
                "' AND A.ITM_SIGN = '-' AND A.VCH_DATE >= '" +
                DateFormat("MM/dd/yyyy").format(fromDate) +
                "' AND A.VCH_DATE <= '" +
                DateFormat("MM/dd/yyyy").format(toDate) +
                "' AND B.MAIN_BOOK IN ('SALES','SALES RETURN') ";

        if (selectedBook != "Select book") {
          query += "AND A.CO_BOOK = '" + selectedBook.split("-")[0] + "' ";
        }

        query +=
            "GROUP BY A.CO_CODE,A.LC_CODE,A.CO_YEAR,A.VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_NAME,C.AC_NAME,C.AC_MOBILE,A.MAIN_USER ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO";
        dynamic result = await sqlConnection.queryDatabase(query);
        salesReport = jsonDecode(result);
        searchSalesReport = jsonDecode(result);
      } else {
        dynamic salesData = await MySQLService().getSalesReport(
            co_code,
            lc_code,
            year,
            DateFormat("MM/dd/yyyy").format(fromDate),
            DateFormat("MM/dd/yyyy").format(toDate),
            selectedBook);
        salesReport = salesData[0];
        searchSalesReport = salesData[0];
      }
    } catch (e) {
      salesReport = [];
      searchSalesReport = [];
      if (mounted) _toast("Could not load sales report. Please try again.");
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  getFillterBookData() async {
    if (Platform.isAndroid) {
      var query = "SELECT CO_BOOK,BOOK_NAME FROM BOOK_DATA WHERE CO_CODE = '" +
          co_code +
          "' AND LC_CODE='" +
          lc_code +
          "' AND MAIN_BOOK in ('SALES','WHSALES') AND CUR_USE='Y'";

      dynamic bookResult = await sqlConnection.queryDatabase(query);
      List<dynamic> data = jsonDecode(bookResult);
      for (final action in data) {
        bookData.add("${action["CO_BOOK"]}-${action["BOOK_NAME"]}");
      }
    } else {
      dynamic salesFilterData = await MySQLService().getSalesFilterData(
        co_code,
        lc_code,
      );
      for (final action in salesFilterData[0]) {
        bookData.add("${action["CO_BOOK"]}-${action["BOOK_NAME"]}");
      }
    }
  }

  // ---------- action helpers ----------

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _mobile(dynamic data) => '${data['AC_MOBILE'] ?? ''}'.trim();

  String _fmt(dynamic value, int decimals) {
    final parsed = double.tryParse('${value ?? ''}');
    if (parsed == null || parsed == 0) return '';
    return parsed.toStringAsFixed(decimals);
  }

  String _invoiceMessage(dynamic data) {
    final net = _fmt(data['NetAmt'], 2);
    final os = _fmt(data['OsAmt'], 2);
    final buffer = StringBuffer();
    buffer.writeln('*Thanks For Buying Ornaments*');
    buffer.writeln('Invoice No : ${data['VCH_NO'] ?? ''}');
    buffer.writeln('Invoice Date : ${data['VCH_DATE'] ?? ''}');
    buffer.writeln('Sales Amount : $net');
    buffer.writeln('Os Amount : $os');
    buffer.write('${data['AC_NAME'] ?? ''}');
    return buffer.toString();
  }

  Future<void> _sendWhatsApp(dynamic data) async {
    final mobile = _mobile(data);
    if (mobile.isEmpty) {
      _toast('Mobile number does not exist');
      return;
    }
    final link = WhatsAppUnilink(
      phoneNumber: '+91$mobile',
      text: _invoiceMessage(data),
    );
    await launchUrlString('$link', mode: LaunchMode.externalApplication);
  }

  Future<void> _makeCall(dynamic data) async {
    final mobile = _mobile(data);
    if (mobile.isEmpty) {
      _toast('Mobile number does not exist');
      return;
    }
    await launchUrlString('tel:+91$mobile');
  }

  Future<void> _sendSms(dynamic data) async {
    final mobile = _mobile(data);
    if (mobile.isEmpty) {
      _toast('Mobile number does not exist');
      return;
    }
    final body = Uri.encodeComponent(_invoiceMessage(data));
    await launchUrlString('sms:+91$mobile?body=$body');
  }

  Future<void> _shareMessage(dynamic data) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _invoiceMessage(data),
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  // ---------- filter sheet ----------

  fillterData(
      {required List<dynamic> bookList,
      required String selectedBookValue,
      required DateTime fromD,
      required DateTime toD}) {
    String selectedbook = selectedBookValue;
    DateTime from = fromD;
    DateTime to = toD;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        final safeBottom = MediaQuery.of(context).padding.bottom;
        final maxSheetH = MediaQuery.of(context).size.height * 0.88;

        Widget filterLabel(String text) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_cta, _cta.withValues(alpha: 0.55)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        Widget dateBox(DateTime value, VoidCallback onTap) {
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _cta.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: _cta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          DateFormat('dd-MM-yyyy').format(value),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: _cta, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetH),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color.lerp(Colors.white, _pageBg, 0.22)!,
                    ],
                  ),
                  border: Border.all(color: _cta.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: _cta.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, -8),
                      spreadRadius: -8,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, safeBottom + 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _border,
                                    _border.withValues(alpha: 0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _pageBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _border.withValues(alpha: 0.65),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: _textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Filters',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.45,
                                    color: _textPrimary,
                                  ),
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: _cta,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: _cta.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  fromDate = DateTime.now();
                                  toDate = DateTime.now();
                                  selectedBook = "Select book";
                                  getSalesReport();
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Clear all',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: _border.withValues(alpha: 0.65),
                          ),
                          const SizedBox(height: 18),
                          filterLabel('Date range'),
                          Row(
                            children: [
                              dateBox(from, () async {
                                DateTime? dat =
                                    await _selectDate(context, from);
                                if (dat != null) from = dat;
                                setModalState(() {});
                              }),
                              const SizedBox(width: 10),
                              dateBox(to, () async {
                                DateTime? dat = await _selectDate(context, to);
                                if (dat != null) to = dat;
                                setModalState(() {});
                              }),
                            ],
                          ),
                          const SizedBox(height: 18),
                          filterLabel('Book'),
                          bookPickerField(
                            label: selectedbook,
                            onTap: () async {
                              final picked = await showBookPicker(
                                context: context,
                                selected: selectedbook,
                                options: bookList
                                    .map((b) => PickerOption(
                                        b.toString(), b.toString()))
                                    .toList(),
                              );
                              if (picked != null) {
                                selectedbook = picked;
                                setModalState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _cta,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.75),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                fromDate = from;
                                toDate = to;
                                selectedBook = selectedbook;
                                getSalesReport();
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Apply filters',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
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
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  // ---------- card widgets ----------

  Widget _detailLine(String label, String value, {Color? valueColor}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                height: 1.3,
              ),
            ),
          ),
          Text(
            ': ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _border,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: valueColor ?? _textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({required VoidCallback onTap, required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _pageBg,
            border: Border.all(color: _border.withValues(alpha: 0.65)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _salesCard(dynamic data, {required bool isLast}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SalesZoomingReport(
                  vchNo: '${data["VCH_NO"] ?? ''}',
                  coBook: '${data["CO_BOOK"] ?? ''}',
                  bookName: '${data["BOOK_NAME"] ?? ''}',
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cta.withValues(alpha: 0.4),
                  _cta.withValues(alpha: 0.08),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _cta.withValues(alpha: 0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.25),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.75),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${data["AC_NAME"] ?? ''}',
                          style: GoogleFonts.plusJakartaSans(
                            color: _cta,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            height: 1.25,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _textSecondary.withValues(alpha: 0.65),
                        size: 26,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _border.withValues(alpha: 0.65),
                  ),
                  const SizedBox(height: 12),
                  _detailLine('Mobile', '${data["AC_MOBILE"] ?? ''}'),
                  _detailLine('Invoice date', '${data["VCH_DATE"] ?? ''}'),
                  _detailLine('Book name', '${data["BOOK_NAME"] ?? ''}'),
                  _detailLine('Sales weight', _fmt(data["Nwt"], 3)),
                  _detailLine('Sales amount', _fmt(data["NetAmt"], 2),
                      valueColor: _success),
                  _detailLine('Os amount', _fmt(data["OsAmt"], 2),
                      valueColor: _danger),
                  _detailLine('Entry user', '${data["MAIN_USER"] ?? ''}'),
                  const SizedBox(height: 6),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _border.withValues(alpha: 0.65),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          child: _actionChip(
                            onTap: () => _sendWhatsApp(data),
                            child: Image.asset(AppImage.whatsapp, scale: 18),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          child: _actionChip(
                            onTap: () => _makeCall(data),
                            child: Image.asset(AppImage.telephone, scale: 18),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          child: _actionChip(
                            onTap: () => _sendSms(data),
                            child: Image.asset(AppImage.chat, scale: 18),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          child: _actionChip(
                            onTap: () => _shareMessage(data),
                            child: Image.asset(AppImage.share, scale: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cta.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 46,
              color: _cta.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No sales records found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filters or search',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        automaticallyImplyLeading: false,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white.withValues(alpha: 0.96),
                _pageBg,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _cta,
              size: 22,
            ),
          ),
        ),
        title: Text(
          'Sales report',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            color: _cta,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: _border.withValues(alpha: 0.65),
          ),
        ),
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                fillterData(
                    bookList: bookData,
                    selectedBookValue: selectedBook,
                    fromD: fromDate,
                    toD: toDate);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: Icon(Icons.tune_rounded, color: _cta, size: 26),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    _cta.withValues(alpha: 0.2),
                    _cta.withValues(alpha: 0.06),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cta.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(1.25),
              child: TextFormField(
                cursorColor: _cta,
                keyboardType: TextInputType.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by account name',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: _textSecondary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.75),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.75),
                    borderSide:
                        BorderSide(color: _border.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.75),
                    borderSide: BorderSide(color: _cta, width: 1.5),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            _cta.withValues(alpha: 0.18),
                            _cta.withValues(alpha: 0.06),
                          ],
                        ),
                      ),
                      child: Icon(Icons.search_rounded, color: _cta, size: 22),
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != "") {
                    searchSalesReport = salesReport
                        .where((text) =>
                            text.containsKey("AC_NAME") &&
                            text["AC_NAME"]
                                .toString()
                                .toLowerCase()
                                .contains(value.trim().toLowerCase()))
                        .toList();
                    setState(() {});
                  } else {
                    searchSalesReport.clear();
                    searchSalesReport.addAll(salesReport);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<LoadingProvider>(
              builder: (context, loading, _) {
                if (loading.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: _cta),
                  );
                }
                if (searchSalesReport.isEmpty) {
                  return _emptyState();
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: searchSalesReport.length,
                  itemBuilder: (context, index) => _salesCard(
                    searchSalesReport[index],
                    isLast: index == searchSalesReport.length - 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
