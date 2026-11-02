import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The Tag Stock Report as a PDF: a photo and the figures for every tag the
/// user picked, under a header that says which report, which dates and whose
/// shop. Built here, away from the screen, so the document can be produced
/// and checked without a device.

double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

/// Identifies one tag row for selection. A tag number repeats across
/// re-issues, so the voucher serial is part of the key.
String tagRowKey(dynamic row) {
  if (row is! Map) return '';
  final tag = '${row['TagNo'] ?? ''}'.trim();
  final srNo = '${row['VCH_SRNO'] ?? ''}'.trim();
  return '$tag#$srNo';
}

/// One line of the PDF table.
class TagPdfRow {
  final String tagNo;
  final String item;
  final String size;
  final String date;
  final double pcs;
  final double grossWt;
  final double netWt;

  /// JPEG or PNG bytes, already shrunk by [shrinkPhotoForPdf]. Null when the
  /// piece was never photographed or the photo could not be fetched.
  final Uint8List? photo;

  const TagPdfRow({
    required this.tagNo,
    required this.item,
    required this.size,
    required this.date,
    required this.pcs,
    required this.grossWt,
    required this.netWt,
    this.photo,
  });

  factory TagPdfRow.fromRow(dynamic row, {Uint8List? photo}) {
    final size = '${row['Size'] ?? ''}'.trim();
    return TagPdfRow(
      tagNo: '${row['TagNo'] ?? ''}'.trim(),
      item: '${row['ItmName'] ?? ''}'.trim(),
      size: size == '0' ? '' : size,
      date: '${row['VchDate'] ?? ''}'.trim(),
      pcs: _num(row['Pcs']),
      grossWt: _num(row['Grwt']),
      netWt: _num(row['NetWt']),
      photo: photo,
    );
  }
}

/// Longest side a photo keeps inside the PDF, in pixels.
///
/// Tag photos come off the server at phone-camera size, a megabyte or more
/// each; fifty of them in one document would be a file nobody can send on
/// WhatsApp. At this size a photo fills its 48pt cell crisply on a retina
/// screen and costs ten to twenty kilobytes.
const int kPdfPhotoMaxSide = 320;

/// Re-encodes a photo small enough to embed, or null when the bytes are not an
/// image at all.
///
/// Decoding also bakes in the EXIF orientation, so a photo shot in portrait
/// lands upright in the PDF rather than on its side. Pure CPU work: callers
/// run it off the UI thread with `compute`.
Uint8List? shrinkPhotoForPdf(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    // A truncated download or an HTML error page saved as a photo. The
    // decoder throws on some of these rather than returning null; either way
    // the tag simply goes in without a picture.
    return null;
  }
  if (decoded == null) return null;
  final longest =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  final scaled = longest <= kPdfPhotoMaxSide
      ? decoded
      : img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? kPdfPhotoMaxSide : null,
          height: decoded.height > decoded.width ? kPdfPhotoMaxSide : null,
          interpolation: img.Interpolation.average,
        );
  return Uint8List.fromList(img.encodeJpg(scaled, quality: 72));
}

/// File name for the export: the report and the dates, nothing a share sheet
/// will choke on.
String tagPdfFileName(String sectionLabel, {DateTime? from, DateTime? to}) {
  final section = sectionLabel.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
  final f = DateFormat('yyyy-MM-dd');
  if (from != null && to != null) {
    return '${section}_${f.format(from)}_to_${f.format(to)}.pdf';
  }
  return '${section}_${f.format(DateTime.now())}.pdf';
}

class TagStockPdf {
  static const PdfColor _ink = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _muted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _rule = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor _band = PdfColor.fromInt(0xFFF1F5F9);
  static const PdfColor _brand = PdfColor.fromInt(0xFF006EB7);

  /// Builds the document. [period] is already worded — "01 – 30 Nov 2026" or
  /// "As on 30 Nov 2026" — because the screen knows which applies.
  static Future<Uint8List> build({
    required String companyName,
    required String title,
    required String period,
    required List<TagPdfRow> rows,
  }) async {
    final doc = pw.Document(
      title: '$title — $companyName',
      author: companyName,
    );

    final totalPcs = rows.fold<double>(0, (s, r) => s + r.pcs);
    final totalGross = rows.fold<double>(0, (s, r) => s + r.grossWt);
    final totalNet = rows.fold<double>(0, (s, r) => s + r.netWt);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 30, 28, 30),
        header: (ctx) => _header(ctx, companyName, title, period),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          _summary(rows.length, totalPcs, totalGross, totalNet),
          pw.SizedBox(height: 12),
          _table(rows),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _header(
      pw.Context ctx, String company, String title, String period) {
    // The full header once; a one-line reminder on every later page, so the
    // table gets the room.
    if (ctx.pageNumber > 1) {
      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.6))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('$title  ·  $period',
                style: const pw.TextStyle(fontSize: 9, color: _muted)),
            pw.Text(company,
                style: const pw.TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
      );
    }
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 1.2))),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(company.isEmpty ? 'Tag Stock Report' : company,
                    style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink)),
                pw.SizedBox(height: 2),
                pw.Text('Tag Stock Report  ·  $title',
                    style: const pw.TextStyle(fontSize: 10, color: _muted)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(period,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink)),
              pw.SizedBox(height: 2),
              pw.Text(
                  'Printed ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('DataCare Ultra',
              style: const pw.TextStyle(fontSize: 8, color: _muted)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _summary(
      int tags, double pcs, double gross, double net) {
    pw.Widget stat(String label, String value) => pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
              pw.SizedBox(height: 2),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink)),
            ],
          ),
        );
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: pw.BoxDecoration(
        color: _band,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          stat('Tags', '$tags'),
          stat('Pieces', pcs.toStringAsFixed(0)),
          stat('Gross wt', '${gross.toStringAsFixed(3)} gm'),
          stat('Net wt', '${net.toStringAsFixed(3)} gm'),
        ],
      ),
    );
  }

  static pw.Widget _table(List<TagPdfRow> rows) {
    final headStyle = pw.TextStyle(
        fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _muted);
    const cellStyle = pw.TextStyle(fontSize: 9, color: _ink);
    final boldCell = pw.TextStyle(
        fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _ink);

    pw.Widget head(String t, {pw.TextAlign align = pw.TextAlign.left}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          child: pw.Text(t, style: headStyle, textAlign: align),
        );
    pw.Widget cell(String t,
            {pw.TextAlign align = pw.TextAlign.left,
            pw.TextStyle? style}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          child: pw.Text(t.isEmpty ? '-' : t,
              style: style ?? cellStyle, textAlign: align),
        );

    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _rule, width: 0.5),
        bottom: pw.BorderSide(color: _rule, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FixedColumnWidth(58),
        2: pw.FlexColumnWidth(3.2),
        3: pw.FlexColumnWidth(0.9),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.4),
        6: pw.FlexColumnWidth(1.0),
        7: pw.FlexColumnWidth(1.5),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: _ink, width: 0.8))),
          children: [
            head('#'),
            head('Photo'),
            head('Tag / Item'),
            head('Pcs', align: pw.TextAlign.right),
            head('Gr Wt', align: pw.TextAlign.right),
            head('Nt Wt', align: pw.TextAlign.right),
            head('Size', align: pw.TextAlign.right),
            head('Date', align: pw.TextAlign.right),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            children: [
              cell('${i + 1}',
                  style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: _photo(rows[i].photo),
              ),
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(rows[i].tagNo.isEmpty ? '-' : rows[i].tagNo,
                        style: boldCell),
                    if (rows[i].item.isNotEmpty) ...[
                      pw.SizedBox(height: 1.5),
                      pw.Text(rows[i].item,
                          style: const pw.TextStyle(
                              fontSize: 8.5, color: _muted)),
                    ],
                  ],
                ),
              ),
              cell(rows[i].pcs.toStringAsFixed(0), align: pw.TextAlign.right),
              cell(rows[i].grossWt.toStringAsFixed(3),
                  align: pw.TextAlign.right),
              cell(rows[i].netWt.toStringAsFixed(3), align: pw.TextAlign.right),
              cell(rows[i].size, align: pw.TextAlign.right),
              cell(rows[i].date, align: pw.TextAlign.right),
            ],
          ),
      ],
    );
  }

  static pw.Widget _photo(Uint8List? bytes) {
    return pw.Container(
      width: 48,
      height: 48,
      decoration: pw.BoxDecoration(
        color: _band,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: bytes == null
          ? pw.Center(
              child: pw.Text('no photo',
                  style: const pw.TextStyle(fontSize: 6.5, color: _muted)))
          : pw.ClipRRect(
              horizontalRadius: 4,
              verticalRadius: 4,
              child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
            ),
    );
  }
}
