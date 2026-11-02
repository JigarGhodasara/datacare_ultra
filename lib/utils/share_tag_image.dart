import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Builds the picture shared from "Share tag": the product photo in full, with
/// the tag's figures on a panel underneath it.
///
/// The details used to be painted on a card *over* the photo, which covered
/// whatever sat in the lower middle of the frame — usually the pendant. Giving
/// them their own strip below means the product is never obscured.
///
/// The panel takes two groups. [fullWidthRows] carry text of unpredictable
/// length (the tag number and the item name) and get the whole width.
/// [pairedRows] are short figures and are laid out two to a line, which keeps
/// the panel short so the photo still dominates the picture.
class ShareTagImage {
  const ShareTagImage._();

  /// Renders [photo] with the detail panel beneath it and returns PNG bytes.
  static Future<Uint8List?> compose({
    required ui.Image photo,
    List<List<String>> fullWidthRows = const [],
    List<List<String>> pairedRows = const [],
  }) async {
    final layout = _Layout(
      photo.width.toDouble(),
      photo.height.toDouble(),
      fullWidthRows,
      pairedRows,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // The photo occupies the top of a taller canvas; nothing is drawn over it.
    canvas.drawImageRect(
      photo,
      Rect.fromLTWH(0, 0, layout.imageWidth, layout.imageHeight),
      Rect.fromLTWH(0, 0, layout.imageWidth, layout.imageHeight),
      Paint(),
    );

    if (layout.panelHeight > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
            0, layout.imageHeight, layout.imageWidth, layout.panelHeight),
        Paint()..color = Colors.white,
      );
      // Hairline, so the panel reads as attached to the photo rather than as
      // a gap on images whose bottom edge is already pale.
      canvas.drawRect(
        Rect.fromLTWH(0, layout.imageHeight, layout.imageWidth, layout.rule),
        Paint()..color = const Color(0xFFE2E8F0),
      );
      layout.paint(canvas);
    }

    final picture = recorder.endRecording();
    final out = await picture.toImage(photo.width, layout.totalHeight.ceil());
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    return data?.buffer.asUint8List();
  }

  /// Height the finished picture will have, without rendering it.
  static double totalHeightFor({
    required double imageWidth,
    required double imageHeight,
    List<List<String>> fullWidthRows = const [],
    List<List<String>> pairedRows = const [],
  }) =>
      _Layout(imageWidth, imageHeight, fullWidthRows, pairedRows).totalHeight;

  /// Whether [pairedRows] will actually be laid out two to a line at this
  /// width, or fall back to one per line. Exposed for tests.
  static bool usesTwoColumns({
    required double imageWidth,
    List<List<String>> fullWidthRows = const [],
    List<List<String>> pairedRows = const [],
  }) =>
      _Layout(imageWidth, 100, fullWidthRows, pairedRows).twoColumn;
}

/// One measured line of the panel: a label and its value at fixed positions.
class _Cell {
  final TextPainter label;
  final TextPainter value;
  final double labelX;
  final double valueX;
  const _Cell(this.label, this.value, this.labelX, this.valueX);

  double get height =>
      label.height > value.height ? label.height : value.height;
}

/// Measures the panel. Everything is sized from the image width so the result
/// stays readable whether the photo came off a phone camera or a thumbnail.
class _Layout {
  final double imageWidth;
  final double imageHeight;

  late final double fontSize = (imageWidth * 0.032).clamp(22.0, 60.0);
  late final double padding = fontSize * 0.9;
  late final double lineGap = fontSize * 0.45;
  late final double rule = fontSize * 0.06;
  late final double columnGap = fontSize * 0.9;

  /// Rows of cells. A full-width row holds one cell; a paired row holds two.
  final List<List<_Cell>> lines = [];

  late final bool twoColumn;
  late final double panelHeight;
  double get totalHeight => imageHeight + panelHeight;

  late final TextStyle _labelStyle = TextStyle(
    color: const Color(0xFF475569),
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
  );
  late final TextStyle _valueStyle = TextStyle(
    color: Colors.black,
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
  );

  TextPainter _painter(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.left,
      );

  String _label(List<String> row) => '${row.first} :';
  String _value(List<String> row) => row.length > 1 ? row[1] : '';

  double _widest(List<List<String>> rows, String Function(List<String>) pick,
      TextStyle style) {
    var widest = 0.0;
    for (final r in rows) {
      final p = _painter(pick(r), style)..layout();
      if (p.width > widest) widest = p.width;
    }
    return widest;
  }

  _Layout(this.imageWidth, this.imageHeight, List<List<String>> fullWidthRows,
      List<List<String>> pairedRows) {
    if (fullWidthRows.isEmpty && pairedRows.isEmpty) {
      twoColumn = false;
      panelHeight = 0;
      return;
    }

    // Two columns only when the longest figure genuinely fits in half the
    // width. On a thumbnail it would not, and wrapping every number onto two
    // lines is worse than a taller single column.
    final pairLabelCol = _widest(pairedRows, _label, _labelStyle);
    final pairValueMax = _widest(pairedRows, _value, _valueStyle);
    final half = (imageWidth - padding * 2 - columnGap) / 2;
    twoColumn = pairedRows.length > 1 &&
        pairLabelCol + fontSize * 0.4 + pairValueMax <= half;

    var body = 0.0;

    void addLine(List<_Cell> cells) {
      if (lines.isNotEmpty) body += lineGap;
      lines.add(cells);
      var tallest = 0.0;
      for (final c in cells) {
        if (c.height > tallest) tallest = c.height;
      }
      body += tallest;
    }

    _Cell cellFor(
        List<String> row, double left, double width, double labelColumn) {
      final lp = _painter(_label(row), _labelStyle)..layout();
      final valueX = left + labelColumn + fontSize * 0.4;
      final valueWidth = left + width - valueX;
      final vp = _painter(_value(row), _valueStyle)
        ..layout(maxWidth: valueWidth > fontSize ? valueWidth : imageWidth);
      return _Cell(lp, vp, left, valueX);
    }

    // Tag number and item name: their own line each, full width.
    final fullLabelCol = _widest(fullWidthRows, _label, _labelStyle);
    for (final row in fullWidthRows) {
      addLine([
        cellFor(row, padding, imageWidth - padding * 2, fullLabelCol),
      ]);
    }

    if (twoColumn) {
      for (var i = 0; i < pairedRows.length; i += 2) {
        final cells = <_Cell>[
          cellFor(pairedRows[i], padding, half, pairLabelCol),
        ];
        if (i + 1 < pairedRows.length) {
          cells.add(cellFor(pairedRows[i + 1], padding + half + columnGap, half,
              pairLabelCol));
        }
        addLine(cells);
      }
    } else {
      for (final row in pairedRows) {
        addLine([
          cellFor(row, padding, imageWidth - padding * 2, pairLabelCol),
        ]);
      }
    }

    panelHeight = body + padding * 2;
  }

  void paint(Canvas canvas) {
    var y = imageHeight + padding;
    for (final line in lines) {
      var tallest = 0.0;
      for (final c in line) {
        c.label.paint(canvas, Offset(c.labelX, y));
        c.value.paint(canvas, Offset(c.valueX, y));
        if (c.height > tallest) tallest = c.height;
      }
      y += tallest + lineGap;
    }
  }
}
