import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

import 'mySql_services.dart';

class SalesZoomingReport extends StatefulWidget {
  final String vchNo;
  final String coBook;
  final String bookName;

  const SalesZoomingReport({
    super.key,
    required this.vchNo,
    required this.coBook,
    required this.bookName,
  });

  @override
  State<SalesZoomingReport> createState() => _SalesZoomingReportState();
}

class _SalesZoomingReportState extends State<SalesZoomingReport> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  Color get _cta => _brand;

  final sqlConnection = SqlConnection.getInstance();
  late LoadingProvider loadingProvider;
  String co_code = "";
  String year = "";
  String lc_code = "";
  dynamic invoiceDetail;
  dynamic productDetail;

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    year =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_year;
    lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getInvoiceDetail();
    });
  }

  void getInvoiceDetail() async {
    loadingProvider.startLoading();
    setState(() {});
    try {
      if (Platform.isAndroid) {
        String query =
            "SELECT VCH_NO,VCH_DATE,MOBILE,NET_AMT,DISC_AMT,TOT_AMT,OLD_GL_AMT,CASH_AMT,KASAR_AMT,OS_ADJ_AMT,AC_NAME FROM SL_DATA WHERE CO_CODE='$co_code' AND LC_CODE='$lc_code' AND VCH_NO='${widget.vchNo}' AND CO_BOOK='${widget.coBook}'";
        log("QUERY $query");
        dynamic result = await sqlConnection.queryDatabase(query);
        invoiceDetail = jsonDecode(result)[0];

        String productQuery =
            "SELECT IT_CODE,ITM_REMARK,TAG_NO,ITM_PCS,ITM_GWT,ITM_OTH_WT,ITM_NWT,ITM_RATE,ITM_AMT,LBR_PRC,LBR_RATE,LBR_AMT,OTH_AMT,ITM_MRP,TOT_AMT FROM SL_DETL WHERE CO_CODE = '$co_code' AND LC_CODE = '$lc_code' AND CO_BOOK = '${widget.coBook}' AND VCH_NO = '${widget.vchNo}' ORDER BY SR_NO ";
        log("QUERY $productQuery");
        dynamic productResult = await sqlConnection.queryDatabase(productQuery);
        productDetail = jsonDecode(productResult);
      } else {
        dynamic result = await MySQLService().getZoomingSalesInvoiceDetails(
            coCode: co_code,
            lcCode: lc_code,
            vchNo: widget.vchNo,
            coBook: widget.coBook);
        invoiceDetail = result[0][0];

        dynamic productResult = await MySQLService()
            .getZoomingSalesProductDetails(
                coCode: co_code,
                lcCode: lc_code,
                vchNo: widget.vchNo,
                coBook: widget.coBook);
        productDetail = productResult[0];
      }
    } catch (e) {
      log('Error fetching invoice detail: $e');
      invoiceDetail = null;
      if (mounted) {
        showAppToast(context, "Could not load invoice. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  String _fmt(dynamic value, int decimals) {
    if (value == null) return '0${decimals > 0 ? '.${'0' * decimals}' : ''}';
    if (value is num) return value.toStringAsFixed(decimals);
    final parsed = num.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return parsed.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _appBar(),
      body: Consumer<LoadingProvider>(
        builder: (context, loading, _) {
          if (loading.isLoading) {
            return Center(
                child:
                    CircularProgressIndicator(color: _cta, strokeWidth: 2.6));
          }
          if (invoiceDetail == null) {
            return _emptyState();
          }
          final items = productDetail is List ? productDetail as List : [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _customerCard(),
              const SizedBox(height: 16),
              _sectionLabel("Item details", items.length),
              const SizedBox(height: 12),
              ...List.generate(
                items.length,
                (i) => Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                  child: _itemCard(items[i]),
                ),
              ),
              const SizedBox(height: 16),
              _summaryCard(),
            ],
          );
        },
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
                Text("Sales Detail",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text("Invoice ${widget.vchNo}",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _gradientCard({required Widget child}) {
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
        child: child,
      ),
    );
  }

  Widget _customerCard() {
    return _gradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: _cta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded, color: _cta, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${invoiceDetail['AC_NAME'] ?? ''}'.trim(),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${invoiceDetail['MOBILE'] ?? ''}'.trim().isEmpty
                          ? 'No mobile'
                          : '${invoiceDetail['MOBILE']}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFEEF2F6)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _infoTile(
                      "Invoice No", '${invoiceDetail['VCH_NO'] ?? ''}')),
              Expanded(
                  child: _infoTile(
                      "Invoice Date", '${invoiceDetail['VCH_DATE'] ?? ''}')),
            ],
          ),
          const SizedBox(height: 10),
          _infoTile("Book Name", widget.bookName),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _textSecondary)),
        const SizedBox(height: 3),
        Text(value.trim().isEmpty ? '-' : value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary)),
      ],
    );
  }

  Widget _sectionLabel(String text, int count) {
    return Row(
      children: [
        Text(text,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _cta.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _cta)),
        ),
      ],
    );
  }

  Widget _itemCard(dynamic item) {
    return _gradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item['ITM_REMARK'] ?? ''}'.trim().isEmpty
                      ? 'Item'
                      : '${item['ITM_REMARK']}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _cta),
                ),
              ),
              if ('${item['TAG_NO'] ?? ''}'.trim().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _pageBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text('${item['TAG_NO']}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFEEF2F6)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _metric("Pcs", _fmt(item['ITM_PCS'], 0)),
                    _metric("Item Rate", _fmt(item['ITM_RATE'], 2)),
                    _metric("Lbr Prc", _fmt(item['LBR_PRC'], 2)),
                    _metric("Lbr Amt", _fmt(item['LBR_AMT'], 2)),
                    _metric("MRP", _fmt(item['ITM_MRP'], 2)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _metric("Gross Wt", _fmt(item['ITM_GWT'], 3)),
                    _metric("Net Wt", _fmt(item['ITM_NWT'], 3)),
                    _metric("Item Amt", _fmt(item['ITM_AMT'], 2)),
                    _metric("Lbr Rate", _fmt(item['LBR_RATE'], 2)),
                    _metric("Oth Amt", _fmt(item['OTH_AMT'], 2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _cta.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Amount",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary)),
                Text(_fmt(item['TOT_AMT'], 2),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _cta)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary)),
          const SizedBox(width: 8),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return _gradientCard(
      child: Column(
        children: [
          _summaryRow("Net Amount", _fmt(invoiceDetail['NET_AMT'], 2),
              valueColor: _success),
          _summaryRow("Discount Amount", _fmt(invoiceDetail['DISC_AMT'], 2),
              valueColor: _danger),
          _summaryRow("Total Amount", _fmt(invoiceDetail['TOT_AMT'], 2)),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFEEF2F6)),
          const SizedBox(height: 8),
          _summaryRow("Old Gold Amount", _fmt(invoiceDetail['OLD_GL_AMT'], 2)),
          _summaryRow("Cash Amount", _fmt(invoiceDetail['CASH_AMT'], 2)),
          _summaryRow("Kasar Amount", _fmt(invoiceDetail['KASAR_AMT'], 2)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _danger.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Outstanding Amount",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary)),
                Text(_fmt(invoiceDetail['OS_ADJ_AMT'], 2),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary)),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? _textPrimary)),
        ],
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
          Text("No invoice details",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 4),
          Text("This invoice has no data to display",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary)),
        ],
      ),
    );
  }
}
