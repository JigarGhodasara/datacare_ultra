import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/estimate_cart_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';

/// Combined estimate for several tags at once.
///
/// A customer trying four bangles previously needed four separate quotations,
/// each printed on its own. This collects them and prints one receipt with a
/// grand total.
class EstimateCartScreen extends StatefulWidget {
  const EstimateCartScreen({super.key});

  @override
  State<EstimateCartScreen> createState() => _EstimateCartScreenState();
}

class _EstimateCartScreenState extends State<EstimateCartScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _hairline = Color(0xFFEEF2F6);

  Color get _cta => _brand;

  final sqlConnection = SqlConnection.getInstance();
  bool _busy = false;

  double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

  String _f(double v, [int d = 2]) => v.toStringAsFixed(d);

  // ── Printing ───────────────────────────────────────────────────────────────

  Future<void> _printCombined() async {
    final cart = context.read<EstimateCartProvider>();
    if (cart.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _buildReceipt(cart);
      await _shareDocument(bytes, "combined_estimate_pos");
    } catch (e, st) {
      log('combined estimate failed', error: e, stackTrace: st);
      if (mounted) showAppToast(context, "Could not create the estimate: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<dynamic> _fetchCompany(String coCode) async {
    if (Platform.isAndroid) {
      final q =
          "SELECT CO_NAME,CO_ADD1,CO_ADD2,CO_ADD3,CO_CITY,CO_PIN,CO_MOBILE FROM CO_MAST WHERE CO_CODE = $coCode";
      return jsonDecode(await sqlConnection.queryDatabase(q))[0];
    }
    final data = await MySQLService().getCompanyDetail(coCode);
    return data[0][0];
  }

  /// Shares a generated document through the OS sheet.
  Future<void> _shareDocument(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  /// A4 estimate covering every tag in the cart.
  ///
  /// Laid out as one invoice-style table rather than repeating the single-tag
  /// page per item: with four or five bangles that would run to five sheets
  /// and make the totals impossible to compare at a glance.
  Future<void> _createPdf() async {
    final cart = context.read<EstimateCartProvider>();
    if (cart.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _buildA4(cart);
      await _shareDocument(bytes, "combined_estimate");
    } catch (e, st) {
      log('combined a4 estimate failed', error: e, stackTrace: st);
      if (mounted) showAppToast(context, "Could not create the PDF: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _buildA4(EstimateCartProvider cart) async {
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    final bool isUae = provider.CoSname == "UAE";
    final company = await _fetchCompany(provider.co_code);

    final accent = PdfColor.fromInt(0xFF006EB7);
    final accentDark = PdfColor.fromInt(0xFF00456F);
    final lineClr = PdfColor.fromInt(0xFFD5DEE8);
    final textClr = PdfColor.fromInt(0xFF1E2A36);
    final mutedClr = PdfColor.fromInt(0xFF5B6B7B);

    final pdf = pw.Document();

    // Label/value row, mirroring the single-tag estimate: right-aligned bold
    // label, left-aligned value, hairline separators.
    pw.TableRow detailRow(String label, String value, {bool strong = false}) =>
        pw.TableRow(children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: pw.Text("$label :",
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: textClr)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight:
                        strong ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: strong ? accentDark : textClr)),
          ),
        ]);

    pw.Widget totalBar(String label, String value) => pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: accentDark,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
            ],
          ),
        );

    pw.Widget otherDetailsTable(EstimateItem item) => pw.Table(
          border: pw.TableBorder.all(color: lineClr, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1.2),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: accent),
              children: [
                for (final h in [
                  "Stone",
                  "Pcs",
                  "CT Weight",
                  "Rate",
                  "Net Amount"
                ])
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  ),
              ],
            ),
            for (final d in item.otherDetails)
              pw.TableRow(children: [
                for (final v in [
                  '${d["IT_CODE"] ?? d["IT_NAME"] ?? "-"}'.trim(),
                  _f(_num(d["IT_PCS"]), 0),
                  _f(_num(d["IT_GWT"]), 2),
                  _f(_num(d["IT_RATE"])),
                  _f(_num(d["IT_NET_AMT"])),
                ])
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(v,
                        style: pw.TextStyle(fontSize: 10, color: textClr)),
                  ),
              ]),
          ],
        );

    // One tag rendered in the same shape as the single-tag estimate.
    List<pw.Widget> itemBlock(EstimateItem item, int index) => [
          pw.SizedBox(height: 14),
          pw.Text(
            "${index + 1}. ${item.itemName.isEmpty ? item.tagNo : item.itemName}",
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: textClr),
          ),
          pw.SizedBox(height: 10),
          if (item.imageBytes != null) ...[
            pw.Center(
              child: pw.Container(
                height: 150,
                width: 150,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: lineClr, width: 1),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Image(pw.MemoryImage(item.imageBytes!),
                    fit: pw.BoxFit.contain),
              ),
            ),
            pw.SizedBox(height: 10),
          ],
          pw.Table(
            border: pw.TableBorder(
              left: pw.BorderSide(color: lineClr, width: 0.5),
              right: pw.BorderSide(color: lineClr, width: 0.5),
              top: pw.BorderSide(color: lineClr, width: 0.5),
              bottom: pw.BorderSide(color: lineClr, width: 0.5),
              horizontalInside: pw.BorderSide(color: lineClr, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1.2),
            },
            children: [
              detailRow("Tag No", item.tagNo),
              detailRow("Pcs", item.pcs),
              if (item.designNo.isNotEmpty && item.designNo != "null")
                detailRow("Design", item.designNo),
              detailRow("Gr Wt", _f(item.grossWt, 3)),
              detailRow("Nt Wt", _f(item.netWt, 3)),
              detailRow("Rate 1 Gm", _f(item.rate)),
              detailRow("Item Amt", _f(item.itemAmount)),
              // Percentage and per-gram rate only exist when labour is charged
              // by weight; a flat charge leaves them at zero.
              if (item.labourPrc > 0)
                detailRow(
                    isUae ? "Making prc %" : "Lbr prc %", _f(item.labourPrc)),
              if (item.labourRate > 0)
                detailRow(
                    isUae ? "Making Rate" : "Lbr Rate", _f(item.labourRate)),
              detailRow(
                  isUae ? "Making Amt" : "Lbr Amt", _f(item.labourAmount)),
              if (item.otherAmount > 0)
                detailRow("Oth Amt", _f(item.otherAmount)),
              detailRow("Net Amt", _f(item.netAmount)),
              if (item.gstTax > 0) detailRow("Gst Tax", _f(item.gstTax)),
              detailRow("Total Amt", _f(item.totalAmount), strong: true),
            ],
          ),
          if (item.otherDetails.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text("Other Details",
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: accentDark)),
            pw.SizedBox(height: 4),
            otherDetailsTable(item),
          ],
          pw.SizedBox(height: 12),
        ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border:
                  pw.Border(bottom: pw.BorderSide(color: accent, width: 1.5)),
            ),
            child: pw.Column(children: [
              pw.Text('${company["CO_NAME"]}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: accentDark)),
              pw.SizedBox(height: 3),
              pw.Text('${company["CO_ADD1"]}, ${company["CO_ADD2"]}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 9, color: mutedClr)),
              pw.Text(
                  '${company["CO_ADD3"]}, ${company["CO_CITY"]}-${company["CO_PIN"]}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 9, color: mutedClr)),
              pw.Text('Mo: ${company["CO_MOBILE"]}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 9, color: mutedClr)),
            ]),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("ESTIMATE",
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.Text(
                    "Items: ${cart.count}     Date: ${DateFormat("dd/MM/yyyy").format(DateTime.now())}",
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ],
            ),
          ),
          for (var i = 0; i < cart.items.length; i++)
            ...itemBlock(cart.items[i], i),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text("TOTAL OF ALL ITEMS",
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder(
              left: pw.BorderSide(color: lineClr, width: 0.5),
              right: pw.BorderSide(color: lineClr, width: 0.5),
              top: pw.BorderSide(color: lineClr, width: 0.5),
              bottom: pw.BorderSide(color: lineClr, width: 0.5),
              horizontalInside: pw.BorderSide(color: lineClr, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1.2),
            },
            children: [
              detailRow("Total Items", '${cart.count}'),
              detailRow("Total Pcs", _f(cart.totalPcs, 0)),
              detailRow("Total Gr Wt", _f(cart.totalGrossWt, 3)),
              detailRow("Total Nt Wt", _f(cart.totalNetWt, 3)),
              detailRow("Total Item Amt", _f(cart.totalItemAmount)),
              detailRow(isUae ? "Total Making Amt" : "Total Lbr Amt",
                  _f(cart.totalLabour)),
              if (cart.totalOther > 0)
                detailRow("Total Oth Amt", _f(cart.totalOther)),
              detailRow("Total Net Amt", _f(cart.totalNet)),
              if (cart.totalGst > 0)
                detailRow("Total Gst Tax", _f(cart.totalGst)),
            ],
          ),
          pw.SizedBox(height: 10),
          totalBar("Grand Total", _f(cart.grandTotal)),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text("Thank you! Visit Again",
                style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: mutedClr)),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildReceipt(EstimateCartProvider cart) async {
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    final bool isUae = provider.CoSname == "UAE";
    final String currency = isUae ? "AED " : "";

    final companyDetails = await _fetchCompany(provider.co_code);

    final pdf = pw.Document();
    final mono = pw.Font.courier();
    final monoBold = pw.Font.courierBold();

    pw.Widget rule() => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child:
              pw.Divider(height: 0.5, thickness: 0.5, color: PdfColors.black),
        );

    pw.Widget row(String l, String v, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 1.5),
          child: pw.Row(children: [
            pw.Expanded(
                flex: 5,
                child: pw.Text(l,
                    style: pw.TextStyle(
                        font: bold ? monoBold : mono,
                        fontSize: bold ? 8 : 7,
                        color: PdfColors.black))),
            pw.Expanded(
                flex: 5,
                child: pw.Text(v,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                        font: bold ? monoBold : mono,
                        fontSize: bold ? 8 : 7,
                        color: PdfColors.black))),
          ]),
        );

    pw.Widget small(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(left: 4, bottom: 1.5),
          child: pw.Text(text,
              style: pw.TextStyle(
                  font: mono, fontSize: 6, color: PdfColors.black)),
        );

    pw.Widget centered(String t, double s, {bool bold = false}) => pw.Container(
          width: double.infinity,
          child: pw.Text(t,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  font: bold ? monoBold : mono,
                  fontSize: s,
                  color: PdfColors.black)),
        );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            centered('${companyDetails["CO_NAME"]}', 9, bold: true),
            pw.SizedBox(height: 2),
            centered(
                '${companyDetails["CO_ADD1"]}, ${companyDetails["CO_ADD2"]}',
                6),
            centered(
                '${companyDetails["CO_ADD3"]}, ${companyDetails["CO_CITY"]}-${companyDetails["CO_PIN"]}',
                6),
            centered('Mo: ${companyDetails["CO_MOBILE"]}', 6),
            pw.SizedBox(height: 3),
            rule(),
            centered("ESTIMATE", 9, bold: true),
            rule(),
            row("Date", DateFormat("dd/MM/yyyy").format(DateTime.now())),
            row("Items", '${cart.count}'),
            rule(),
            // One block per tag, numbered so the customer can match a line on
            // the receipt to the piece in front of them.
            for (var i = 0; i < cart.items.length; i++) ...[
              _itemBlock(cart.items[i], i + 1, currency, isUae, row, small,
                  monoBold, mono),
              rule(),
            ],
            row("Item Amt", currency + _f(cart.totalItemAmount)),
            row(isUae ? "Making Amt" : "Labour Amt",
                currency + _f(cart.totalLabour)),
            if (cart.totalOther > 0)
              row("Other Amt", currency + _f(cart.totalOther)),
            row("Net Amt", currency + _f(cart.totalNet)),
            if (cart.totalGst > 0) row("GST Tax", currency + _f(cart.totalGst)),
            rule(),
            row("GRAND TOTAL", currency + _f(cart.grandTotal), bold: true),
            rule(),
            row("Total Pcs", _f(cart.totalPcs, 0)),
            row("Total Gross Wt", _f(cart.totalGrossWt, 3)),
            row("Total Net Wt", _f(cart.totalNetWt, 3)),
            rule(),
            pw.SizedBox(height: 4),
            centered("Thank you, visit again", 6),
            pw.SizedBox(height: 12),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _itemBlock(
    EstimateItem item,
    int index,
    String currency,
    bool isUae,
    pw.Widget Function(String, String, {bool bold}) row,
    pw.Widget Function(String) small,
    pw.Font monoBold,
    pw.Font mono,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          "$index. ${item.itemName.isEmpty ? item.tagNo : item.itemName}",
          style:
              pw.TextStyle(font: monoBold, fontSize: 7, color: PdfColors.black),
        ),
        small("Tag ${item.tagNo}"),
        row("Pcs / Gr Wt", "${item.pcs} / ${_f(item.grossWt, 3)}"),
        row("Net Wt", _f(item.netWt, 3)),
        row("Rate 1 gm", currency + _f(item.rate)),
        row("Item Amt", currency + _f(item.itemAmount)),
        if (item.labourPrc > 0)
          row(isUae ? "Making %" : "Labour %", "${_f(item.labourPrc)} %"),
        if (item.labourRate > 0)
          row(isUae ? "Making Rate" : "Labour Rate",
              currency + _f(item.labourRate)),
        row(isUae ? "Making Amt" : "Labour Amt",
            currency + _f(item.labourAmount)),
        for (final d in item.otherDetails)
          small(
              "${'${d["IT_CODE"] ?? d["IT_NAME"] ?? "-"}'.trim()}  ${currency}${_f(_num(d["IT_NET_AMT"]))}"),
        row("Total", currency + _f(item.totalAmount)),
      ],
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<EstimateCartProvider>();
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _appBar(cart),
      body: cart.isEmpty
          ? _emptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _itemCard(cart.items[i], i, cart),
                    ),
                  ),
                ),
                _totalsBar(cart),
              ],
            ),
    );
  }

  PreferredSizeWidget _appBar(EstimateCartProvider cart) {
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
                Text("Combined Estimate",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(
                    "${cart.count} ${cart.count == 1 ? 'item' : 'items'} in this quotation",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Future<void> _confirmClear(EstimateCartProvider cart) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Clear estimate?",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary)),
        content: Text("All items in this quotation will be removed.",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: _textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Clear",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) cart.clear();
  }

  Widget _itemCard(EstimateItem item, int index, EstimateCartProvider cart) {
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
                Container(
                  height: 26,
                  width: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _cta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${index + 1}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _cta)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName.isEmpty ? item.tagNo : item.itemName,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary)),
                      const SizedBox(height: 2),
                      Text("Tag ${item.tagNo}",
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Remove",
                  onPressed: () => cart.removeAt(index),
                  icon: Icon(Icons.close_rounded, size: 19, color: _danger),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: _hairline),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _stat("Pcs", item.pcs)),
                Container(width: 1, height: 28, color: _hairline),
                Expanded(child: _stat("Gross Wt", _f(item.grossWt, 3))),
                Container(width: 1, height: 28, color: _hairline),
                Expanded(child: _stat("Net Wt", _f(item.netWt, 3))),
                Container(width: 1, height: 28, color: _hairline),
                Expanded(
                    child:
                        _stat("Total", _f(item.totalAmount), color: _success)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary)),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color ?? _textPrimary)),
        ),
      ],
    );
  }

  Widget _totalsBar(EstimateCartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _stat("Total Pcs", _f(cart.totalPcs, 0))),
                Container(width: 1, height: 28, color: _hairline),
                Expanded(child: _stat("Gross Wt", _f(cart.totalGrossWt, 3))),
                Container(width: 1, height: 28, color: _hairline),
                Expanded(child: _stat("Net Wt", _f(cart.totalNetWt, 3))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _cta.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text("Grand Total",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_f(cart.grandTotal),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _cta)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Clear sits beside Print because that is the moment it is
            // wanted: the estimate is printed, the customer leaves, and the
            // next one must start empty. Kept on the left and visually
            // quieter so the destructive action is not the one sitting under
            // the printing thumb.
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: _danger.withValues(alpha: 0.5), width: 1.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _busy ? null : () => _confirmClear(cart),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color: _danger, size: 19),
                          const SizedBox(width: 7),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("Clear",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _danger)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: _cta.withValues(alpha: 0.5), width: 1.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _busy ? null : _createPdf,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded,
                              color: _cta, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("PDF",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _cta)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _cta,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _busy ? null : _printCombined,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white)),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_rounded,
                                    color: Colors.white, size: 19),
                                const SizedBox(width: 9),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text("POS Print",
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            child: Icon(Icons.playlist_add_rounded, color: _cta, size: 34),
          ),
          const SizedBox(height: 16),
          Text("No items yet",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
                "Search a tag, then tap \"Add to estimate\" to build a combined quotation",
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
}
