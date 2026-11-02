import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/book_picker.dart';
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

import 'mySql_services.dart';

class SalesOrderReportScreen extends StatefulWidget {
  /// Date the report should open on — see [SalesReportScreen.initialFrom].
  final DateTime? initialFrom;
  final DateTime? initialTo;

  const SalesOrderReportScreen({super.key, this.initialFrom, this.initialTo});

  @override
  State<SalesOrderReportScreen> createState() => _SalesOrderReportScreenState();
}

class _SalesOrderReportScreenState extends State<SalesOrderReportScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  Color get _cta => _brand;

  static const String _noBook = "Select book";

  final sqlConnection = SqlConnection.getInstance();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> salesOrderReport = [];
  List<dynamic> searchSalesOrderReport = [];
  List<dynamic> bookData = [_noBook];
  String selectedBook = _noBook;
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
      getSalesOrderReportData();
    });
    getFillterBookData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> getSalesOrderReportData() async {
    loadingProvider.startLoading();
    setState(() {});
    try {
      if (Platform.isAndroid) {
        var query =
            "SELECT A.AC_NAME As AC_NAME,A.MOBILE As AC_MOBILE,A.VCH_DATE AS VCH_DATE,A.VCH_NO As VCH_NO,A.TOT_AMT As TotAmt,A.ADV_AMT As AdvAmt,A.ADV_AMT-A.TOT_AMT As PandingAmt,A.DEL_DATE As DeliveryDt FROM SL_ORD_DATA AS A  WHERE A.CO_CODE = '" +
                co_code +
                "' AND A.LC_CODE = '" +
                lc_code +
                "' AND A.VCH_DATE >= '" +
                DateFormat("MM/dd/yyyy").format(fromDate) +
                "' AND A.VCH_DATE <= '" +
                DateFormat("MM/dd/yyyy").format(toDate) +
                "' ";
        if (selectedBook != _noBook) {
          query += "AND A.CO_BOOK = '" + selectedBook.split("-")[0] + "' ";
        }
        query += "ORDER BY A.VCH_DATE DESC,A.VCH_NO";
        log("Query $query");
        dynamic saleOrderData = await sqlConnection.queryDatabase(query);
        salesOrderReport = jsonDecode(saleOrderData);
      } else {
        dynamic result = await MySQLService().getSalesOrderReport(
            co_code,
            lc_code,
            selectedBook,
            DateFormat("MM/dd/yyyy").format(fromDate),
            DateFormat("MM/dd/yyyy").format(toDate));
        salesOrderReport = result[0];
      }
      _applyFilters();
    } catch (e) {
      log('Error fetching sales order report: $e');
      salesOrderReport = [];
      searchSalesOrderReport = [];
      if (mounted) {
        showAppToast(context, "Could not load sales orders. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  Future<void> getFillterBookData() async {
    try {
      if (Platform.isAndroid) {
        var query =
            "SELECT CO_BOOK,BOOK_NAME FROM BOOK_DATA WHERE CO_CODE = '" +
                co_code +
                "' AND LC_CODE='" +
                lc_code +
                "' AND MAIN_BOOK in ('SALES','WHSALES') AND CUR_USE='Y'";
        dynamic bookResult = await sqlConnection.queryDatabase(query);
        for (final action in jsonDecode(bookResult)) {
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
      if (mounted) setState(() {});
    } catch (e) {
      log('Error fetching book list: $e');
    }
  }

  void _applyFilters() {
    final term = _searchController.text.trim().toLowerCase();
    searchSalesOrderReport = salesOrderReport.where((row) {
      if (term.isEmpty) return true;
      final name = '${row["AC_NAME"] ?? ''}'.toLowerCase();
      final mobile = '${row["AC_MOBILE"] ?? ''}';
      final vch = '${row["VCH_NO"] ?? ''}'.toLowerCase();
      return name.contains(term) || mobile.contains(term) || vch.contains(term);
    }).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _toast(String message) {
    if (!mounted) return;
    showAppToast(context, message);
  }

  String _mobile(dynamic data) => '${data["AC_MOBILE"] ?? ''}'.trim();

  double _num(dynamic value) => num.tryParse('${value ?? ''}')?.toDouble() ?? 0;

  String _fmt(dynamic value, [int decimals = 2]) =>
      _num(value).toStringAsFixed(decimals);

  /// Derived rather than read from the query's PandingAmt column, which is
  /// `ADV_AMT - TOT_AMT` and therefore comes back negative whenever an order
  /// is part-paid. Pending is what is still owed: total minus advance.
  double _pending(dynamic data) => _num(data["TotAmt"]) - _num(data["AdvAmt"]);

  String _orderMessage(dynamic data) {
    final buffer = StringBuffer();
    buffer.writeln("*Your order is ready, please collect it.*");
    buffer.writeln();
    buffer.writeln("Order No : ${data["VCH_NO"] ?? ''}");
    buffer.writeln("Order Date : ${data["VCH_DATE"] ?? ''}");
    final delivery = '${data["DeliveryDt"] ?? ''}'.trim();
    if (delivery.isNotEmpty) buffer.writeln("Delivery Date : $delivery");
    buffer.writeln("Order Amount : ${_fmt(data["TotAmt"])}");
    buffer.writeln("Advance Amount : ${_fmt(data["AdvAmt"])}");
    buffer.writeln("Pending Amount : ${_pending(data).toStringAsFixed(2)}");
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
      _toast("No mobile number for this order");
      return;
    }
    try {
      final link =
          WhatsAppUnilink(phoneNumber: "+91$mobile", text: _orderMessage(data));
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
      _toast("No mobile number for this order");
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
      _toast("No mobile number for this order");
      return;
    }
    final body = Uri.encodeComponent(_orderMessage(data));
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
      _orderMessage(data),
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
          if (selectedBook != _noBook) _activeFilterChip(),
          Expanded(
            child: Consumer<LoadingProvider>(
              builder: (context, loading, _) {
                if (loading.isLoading) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: _cta, strokeWidth: 2.6));
                }
                if (searchSalesOrderReport.isEmpty) return _emptyState();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  itemCount: searchSalesOrderReport.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _orderCard(searchSalesOrderReport[index]),
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
                Text("Sales Order Report",
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
            onPressed: () => fillterData(
                bookList: bookData,
                selectedBookValue: selectedBook,
                fromD: fromDate,
                toD: toDate),
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
          hintText: "Search name, mobile or order no",
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
              Text(selectedBook,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _cta)),
              const SizedBox(width: 2),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  selectedBook = _noBook;
                  getSalesOrderReportData();
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

  Widget _orderCard(dynamic data) {
    final pending = _pending(data);
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
                _inlineMeta(
                    Icons.event_rounded, '${data["VCH_DATE"] ?? ''}'.trim()),
                _inlineMeta(Icons.local_shipping_rounded,
                    '${data["DeliveryDt"] ?? ''}'.trim()),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFEEF2F6)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _stat("Order Amt", _fmt(data["TotAmt"]))),
                Container(width: 1, height: 30, color: const Color(0xFFEEF2F6)),
                Expanded(
                    child: _stat("Advance", _fmt(data["AdvAmt"]),
                        color: _success)),
                Container(width: 1, height: 30, color: const Color(0xFFEEF2F6)),
                Expanded(
                  child: _stat("Pending", pending.toStringAsFixed(2),
                      color: pending > 0 ? _danger : _success),
                ),
              ],
            ),
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
    if (value.isEmpty) return const SizedBox.shrink();
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
            child: Icon(Icons.assignment_rounded, color: _cta, size: 34),
          ),
          const SizedBox(height: 16),
          Text("No orders found",
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

  void fillterData({
    required List<dynamic> bookList,
    required String selectedBookValue,
    required DateTime fromD,
    required DateTime toD,
  }) {
    String book = selectedBookValue;
    DateTime from = fromD;
    DateTime to = toD;

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
                            selectedBook = _noBook;
                            Navigator.pop(context);
                            getSalesOrderReportData();
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
                          label: book,
                          onTap: () async {
                            final picked = await showBookPicker(
                              context: context,
                              selected: book,
                              options: bookList
                                  .map((b) =>
                                      PickerOption(b.toString(), b.toString()))
                                  .toList(),
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
                              selectedBook = book;
                              Navigator.pop(context);
                              getSalesOrderReportData();
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
