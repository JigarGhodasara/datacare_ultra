import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/date_range_sheet.dart';
import 'package:DataCareUltra/utils/image_url.dart';
import 'package:DataCareUltra/utils/insight_help.dart' show rangeLabel;
import 'package:DataCareUltra/utils/report_queries.dart';
import 'package:DataCareUltra/utils/share_tag_image.dart';
import 'package:DataCareUltra/utils/summary_stat_row.dart';
import 'package:DataCareUltra/utils/tag_stock_pdf.dart';
import 'package:DataCareUltra/utils/tag_stock_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Tags in, tags out, and what is left on the shelf — each row with its photo
/// and a share button.
///
/// Tap tags to pick several; picked tags can be shared as pictures together
/// or laid out in a PDF. The PDF button in the top bar exports whatever the
/// list is showing when nothing is picked.
class TagStockReportScreen extends StatefulWidget {
  const TagStockReportScreen({super.key});

  @override
  State<TagStockReportScreen> createState() => _TagStockReportScreenState();
}

class _TagStockReportScreenState extends State<TagStockReportScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _hairline = Color(0xFFEEF2F6);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  TagStockSection _section = TagStockSection.stock;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 29));
  DateTime _toDate = DateTime.now();

  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _rows = [];
  List<dynamic> _visible = [];

  /// Keys ([tagRowKey]) of the tags the user has picked. Non-empty means the
  /// screen is in selection mode.
  final Set<String> _selected = {};

  bool get _selecting => _selected.isNotEmpty;

  late LoadingProvider _loading;
  late ReportQueries _queries;
  String _webPath = '';
  String _serverHost = '';
  String _companyName = '';
  bool _imagesEnabled = false;

  /// Tag currently being shared, so its button can show a spinner instead of
  /// the screen freezing while the photo downloads.
  String? _sharing;

  /// True while a bulk export is running, so the buttons that start one are
  /// disabled rather than queueing a second behind it.
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loading = Provider.of<LoadingProvider>(context, listen: false);
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    _queries = ReportQueries(
      coCode: provider.co_code,
      lcCode: provider.lc_code,
      year: provider.co_year,
    );
    _webPath = provider.webPath;
    _serverHost = provider.serverHost;
    _companyName = provider.co_name.trim();
    _imagesEnabled = tagImagesEnabled(provider.webImage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

  Future<void> _load() async {
    _loading.startLoading();
    // A selection made against one list means nothing against another.
    _selected.clear();
    if (mounted) setState(() {});
    try {
      final from = DateFormat('MM/dd/yyyy').format(_fromDate);
      final to = DateFormat('MM/dd/yyyy').format(_toDate);
      _rows = await _queries.tagStockRows(_section, from, to);
      _applySearch();
    } catch (e, st) {
      log('tag stock report failed', error: e, stackTrace: st);
      _rows = [];
      _visible = [];
      if (mounted) {
        showAppToast(context, 'Could not load the report. Please try again.');
      }
    } finally {
      _loading.stopLoading();
      if (mounted) setState(() {});
    }
  }

  void _applySearch() {
    final term = _searchController.text.trim().toLowerCase();
    _visible = term.isEmpty
        ? List.of(_rows)
        : _rows.where((r) {
            final tag = '${r['TagNo'] ?? ''}'.toLowerCase();
            final item = '${r['ItmName'] ?? ''}'.toLowerCase();
            return tag.contains(term) || item.contains(term);
          }).toList();
  }

  String _imageUrl(dynamic row) {
    if (!_imagesEnabled) return '';
    final file = tagImageFileName(row);
    if (file.isEmpty) return '';
    return buildTagImageUrl(_webPath, file, serverHost: _serverHost);
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void _toggle(dynamic row) {
    final key = tagRowKey(row);
    if (key.isEmpty) return;
    setState(() {
      if (!_selected.remove(key)) _selected.add(key);
    });
  }

  bool _isSelected(dynamic row) => _selected.contains(tagRowKey(row));

  /// Everything the list is showing is picked. A search narrows the list, so
  /// it narrows this too — "select all" means all of what you can see.
  bool get _allVisibleSelected =>
      _visible.isNotEmpty &&
      _visible.every((r) => _selected.contains(tagRowKey(r)));

  void _selectAllVisible() {
    setState(() {
      if (_allVisibleSelected) {
        _selected.clear();
      } else {
        _selected.addAll(_visible.map(tagRowKey).where((k) => k.isNotEmpty));
      }
    });
  }

  void _clearSelection() => setState(_selected.clear);

  List<dynamic> get _selectedRows =>
      _visible.where((r) => _selected.contains(tagRowKey(r))).toList();

  // ── Totals ─────────────────────────────────────────────────────────────────

  double get _totalPcs => _visible.fold(0.0, (t, r) => t + _num(r['Pcs']));
  double get _totalGross => _visible.fold(0.0, (t, r) => t + _num(r['Grwt']));
  double get _totalNet => _visible.fold(0.0, (t, r) => t + _num(r['NetWt']));

  // ── Sharing ────────────────────────────────────────────────────────────────

  Future<Uint8List?> _download(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      return response.bodyBytes;
    } catch (e) {
      log('tag image download failed: $e');
      return null;
    }
  }

  Rect? get _shareOrigin {
    final box = context.findRenderObject() as RenderBox?;
    // Required on iPad, which anchors the share sheet to it; without it the
    // sheet cannot be presented.
    return box != null ? box.localToGlobal(Offset.zero) & box.size : null;
  }

  /// One tag as a picture: its photo with the figures underneath. Null when
  /// the tag has no usable photo.
  Future<File?> _composeFile(dynamic row) async {
    final tag = '${row['TagNo'] ?? ''}'.trim();
    final details = _detailRows(row);
    final url = _imageUrl(row);
    final bytes = url.isEmpty ? null : await _download(url);
    if (bytes == null) return null;

    final codec = await ui.instantiateImageCodec(bytes);
    final photo = (await codec.getNextFrame()).image;
    final composed = await ShareTagImage.compose(
      photo: photo,
      fullWidthRows: details.$1,
      pairedRows: details.$2,
    );
    if (composed == null) return null;

    final dir = await getTemporaryDirectory();
    final srNo = '${row['VCH_SRNO'] ?? ''}'.trim();
    final file = File(
        '${dir.path}/tag_${tag.isEmpty ? 'item' : tag}${srNo.isEmpty ? '' : '_$srNo'}.png');
    await file.writeAsBytes(composed);
    return file;
  }

  /// Shares one tag as a picture.
  ///
  /// Falls back to sharing the figures as text when the tag has no photo, so
  /// the button always does something useful rather than reporting an error
  /// for a piece that was simply never photographed.
  Future<void> _shareRow(dynamic row) async {
    final tag = '${row['TagNo'] ?? ''}'.trim();
    setState(() => _sharing = tag);
    try {
      final file = await _composeFile(row);
      if (!mounted) return;
      if (file == null) {
        await _shareText([row]);
        return;
      }
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: _shareOrigin,
      );
    } catch (e, st) {
      log('share tag failed', error: e, stackTrace: st);
      if (mounted) showAppToast(context, 'Could not share this tag.');
    } finally {
      if (mounted) setState(() => _sharing = null);
    }
  }

  /// Shares every picked tag as a picture in one go. Tags with no photo ride
  /// along as text, so nothing picked is silently dropped.
  Future<void> _shareSelectedImages() async {
    final rows = _selectedRows;
    if (rows.isEmpty) return;
    await _runExport('Preparing pictures', rows.length, (progress) async {
      final files = <XFile>[];
      final unphotographed = <dynamic>[];
      for (var i = 0; i < rows.length; i++) {
        final file = await _composeFile(rows[i]);
        if (file == null) {
          unphotographed.add(rows[i]);
        } else {
          files.add(XFile(file.path, mimeType: 'image/png'));
        }
        progress.value = i + 1;
      }
      if (!mounted) return;
      if (files.isEmpty) {
        await _shareText(unphotographed);
        return;
      }
      await Share.shareXFiles(
        files,
        text: unphotographed.isEmpty ? null : _textFor(unphotographed),
        sharePositionOrigin: _shareOrigin,
      );
    });
  }

  Future<void> _shareText(List<dynamic> rows) async {
    await Share.share(_textFor(rows), sharePositionOrigin: _shareOrigin);
  }

  String _textFor(List<dynamic> rows) {
    final blocks = <String>[];
    for (final row in rows) {
      final details = _detailRows(row);
      blocks.add([
        for (final r in [...details.$1, ...details.$2]) '${r[0]}: ${r[1]}',
      ].join('\n'));
    }
    return blocks.join('\n\n');
  }

  /// Figures for one tag, split the way ShareTagImage expects: text that
  /// varies in length gets the full width, short numbers pair up.
  (List<List<String>>, List<List<String>>) _detailRows(dynamic row) {
    final item = '${row['ItmName'] ?? ''}'.trim();
    final size = '${row['Size'] ?? ''}'.trim();
    return (
      [
        ['Tag No', '${row['TagNo'] ?? '-'}'],
        if (item.isNotEmpty) ['Item', item],
      ],
      [
        ['Pcs', _num(row['Pcs']).toStringAsFixed(0)],
        ['Gr Wt', _num(row['Grwt']).toStringAsFixed(3)],
        ['Nt Wt', _num(row['NetWt']).toStringAsFixed(3)],
        if (size.isNotEmpty && size != '0') ['Size', size],
        ['Date', '${row['VchDate'] ?? '-'}'],
      ],
    );
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  String get _periodLabel => _section.usesDateRange
      ? rangeLabel(_fromDate, _toDate)
      : 'As on ${DateFormat('dd MMM yyyy').format(DateTime.now())}';

  /// Lays the given tags out in a PDF and hands it to the share sheet.
  ///
  /// Photos are fetched a few at a time — they come from a web server, not
  /// the shared SQL connection, so this is safe — and shrunk off the UI
  /// thread before they go in, or fifty tags would make a fifty-megabyte file.
  Future<void> _exportPdf(List<dynamic> rows) async {
    if (rows.isEmpty) {
      showAppToast(context, 'Nothing to put in the PDF.');
      return;
    }
    await _runExport('Preparing PDF', rows.length, (progress) async {
      final photos = List<Uint8List?>.filled(rows.length, null);
      const batch = 4;
      for (var start = 0; start < rows.length; start += batch) {
        final end =
            start + batch > rows.length ? rows.length : start + batch;
        await Future.wait([
          for (var i = start; i < end; i++)
            () async {
              final url = _imageUrl(rows[i]);
              final bytes = url.isEmpty ? null : await _download(url);
              if (bytes != null) {
                photos[i] = await compute(shrinkPhotoForPdf, bytes);
              }
            }(),
        ]);
        progress.value = end;
      }

      final pdf = await TagStockPdf.build(
        companyName: _companyName,
        title: _section.label,
        period: _periodLabel,
        rows: [
          for (var i = 0; i < rows.length; i++)
            TagPdfRow.fromRow(rows[i], photo: photos[i]),
        ],
      );

      final dir = await getTemporaryDirectory();
      final name = tagPdfFileName(_section.label,
          from: _section.usesDateRange ? _fromDate : null,
          to: _section.usesDateRange ? _toDate : null);
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(pdf);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        sharePositionOrigin: _shareOrigin,
      );
    });
  }

  /// Runs a bulk job behind a progress dialog, so a twenty-photo export is
  /// visibly working rather than a frozen screen.
  Future<void> _runExport(
    String label,
    int total,
    Future<void> Function(ValueNotifier<int> progress) job,
  ) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final progress = ValueNotifier<int>(0);
    var dialogOpen = true;
    // Not awaited: the dialog stays up while the job runs and is popped by
    // hand below.
    // ignore: unawaited_futures
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _progressDialog(label, total, progress),
    ).whenComplete(() => dialogOpen = false);

    try {
      await job(progress);
    } catch (e, st) {
      log('$label failed', error: e, stackTrace: st);
      if (mounted) showAppToast(context, 'Could not finish. Please try again.');
    } finally {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _progressDialog(String label, int total, ValueNotifier<int> progress) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (_, done, __) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary)),
                const SizedBox(height: 4),
                Text(
                    done >= total
                        ? 'Finishing up…'
                        : 'Photo $done of $total',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? null : (done / total).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: _hairline,
                    valueColor: const AlwaysStoppedAnimation(_brand),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back while picking clears the picks rather than leaving the screen —
      // the expected behaviour of every multi-select list on the phone.
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selecting) _clearSelection();
      },
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: _selecting ? _selectionAppBar() : _appBar(),
        bottomNavigationBar: _selecting ? _selectionBar() : null,
        body: Column(
          children: [
            _sectionSelector(),
            if (_section.usesDateRange) _rangeBar(),
            _searchField(),
            Expanded(
              child: Consumer<LoadingProvider>(
                builder: (context, loading, _) {
                  if (loading.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: _brand, strokeWidth: 2.6),
                    );
                  }
                  if (_visible.isEmpty) return _emptyState();
                  return RefreshIndicator(
                    color: _brand,
                    onRefresh: _load,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _visible.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _summaryCard(),
                          );
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: index == _visible.length ? 0 : 12),
                          child: _tagCard(_visible[index - 1]),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
                Text('Tag Stock Report',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(
                    _section.usesDateRange
                        ? '${DateFormat('dd/MM/yyyy').format(_fromDate)}  –  '
                            '${DateFormat('dd/MM/yyyy').format(_toDate)}'
                        : 'As on today',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          if (_section.usesDateRange)
            IconButton(
              tooltip: 'Date range',
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range_rounded,
                  color: Colors.white, size: 20),
            ),
          IconButton(
            tooltip: 'PDF of this list',
            onPressed:
                _exporting || _visible.isEmpty ? null : () => _exportPdf(_visible),
            icon: Icon(Icons.picture_as_pdf_rounded,
                color: Colors.white
                    .withValues(alpha: _visible.isEmpty ? 0.45 : 1),
                size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// Replaces the title bar while tags are being picked.
  PreferredSizeWidget _selectionAppBar() {
    final n = _selected.length;
    return AppBar(
      elevation: 0,
      backgroundColor: _textPrimary,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          IconButton(
            tooltip: 'Clear selection',
            onPressed: _clearSelection,
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$n ${n == 1 ? 'tag' : 'tags'} selected',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text('Tap tags to add or remove',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _selectAllVisible,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: Icon(
                _allVisibleSelected
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
                size: 19),
            label: Text(_allVisibleSelected ? 'None' : 'All',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// The two things you can do with a selection, pinned to the bottom where
  /// the thumb is.
  Widget _selectionBar() {
    final n = _selected.length;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _actionButton(
                label: 'Share pictures',
                icon: Icons.share_rounded,
                filled: false,
                onTap: _exporting ? null : _shareSelectedImages,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionButton(
                label: 'Make PDF ($n)',
                icon: Icons.picture_as_pdf_rounded,
                filled: true,
                onTap: _exporting ? null : () => _exportPdf(_selectedRows),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    final fg = filled ? Colors.white : _brand;
    return Material(
      color: filled ? _brand : _brand.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangeSheet(
      context,
      from: _fromDate,
      to: _toDate,
    );
    if (picked == null) return;
    _fromDate = picked.start;
    _toDate = picked.end;
    _load();
  }

  Widget _sectionSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hairline),
        ),
        child: Row(
          children: [
            for (final s in TagStockSection.values) _sectionTab(s),
          ],
        ),
      ),
    );
  }

  Widget _sectionTab(TagStockSection section) {
    final selected = _section == section;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_section == section) return;
          _section = section;
          setState(() {});
          _load();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? _brand : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(section.label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _textSecondary)),
          ),
        ),
      ),
    );
  }

  Widget _rangeBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _pickRange,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 15, color: _brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '${DateFormat('dd MMM yyyy').format(_fromDate)}  –  '
                    '${DateFormat('dd MMM yyyy').format(_toDate)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary)),
              ),
              Icon(Icons.expand_more_rounded,
                  size: 18, color: _textSecondary.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextFormField(
        controller: _searchController,
        cursorColor: _brand,
        onChanged: (_) => setState(_applySearch),
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w500, color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search tag number or item',
          hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _brand, size: 21),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: _textSecondary, size: 19),
                  onPressed: () {
                    _searchController.clear();
                    setState(_applySearch);
                  },
                ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brand, width: 1.6),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
        ),
      ),
    );
  }

  Color get _sectionColour {
    switch (_section) {
      case TagStockSection.inTag:
        return _success;
      case TagStockSection.outTag:
        return _danger;
      case TagStockSection.stock:
        return _brand;
    }
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _sectionColour,
            Color.lerp(_sectionColour, Colors.black, 0.25)!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_section.caption,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9))),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    '${_visible.length} ${_visible.length == 1 ? 'tag' : 'tags'}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SummaryStatRow(stats: [
            SummaryStat('Pieces', _totalPcs.toStringAsFixed(0), flex: 3),
            SummaryStat('Gross wt', _totalGross.toStringAsFixed(3),
                unit: 'gm', flex: 4),
            SummaryStat('Net wt', _totalNet.toStringAsFixed(3),
                unit: 'gm', flex: 4),
          ]),
          if (!_selecting) ...[
            const SizedBox(height: 10),
            Text('Tap tags to pick them for a PDF or to share together',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.78))),
          ],
        ],
      ),
    );
  }

  Widget _tagCard(dynamic row) {
    final tag = '${row['TagNo'] ?? '-'}'.trim();
    final item = '${row['ItmName'] ?? ''}'.trim();
    final url = _imageUrl(row);
    final busy = _sharing == tag;
    final picked = _isSelected(row);

    // A tap picks the tag. There is no detail screen behind a card for the
    // tap to open, so making the first pick wait for a long-press only hid
    // the feature; the tick circle on every thumbnail says it is tappable.
    return GestureDetector(
      onTap: () => _toggle(row),
      onLongPress: () => _toggle(row),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.all(picked ? 1.75 : 1.25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: picked
                ? [_brand, _brand.withValues(alpha: 0.55)]
                : [
                    _brand.withValues(alpha: 0.4),
                    _brand.withValues(alpha: 0.08),
                  ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: picked ? const Color(0xFFF0F7FC) : Colors.white,
            borderRadius: BorderRadius.circular(20.75),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _thumbnail(url),
                  Positioned(
                    top: -5,
                    left: -5,
                    child: _checkMark(picked),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tag.isEmpty ? '-' : tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: _brand)),
                    if (item.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color: _textPrimary)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _chip('Pcs', _num(row['Pcs']).toStringAsFixed(0)),
                        _chip('Gr', _num(row['Grwt']).toStringAsFixed(3)),
                        _chip('Nt', _num(row['NetWt']).toStringAsFixed(3)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${row['VchDate'] ?? ''}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // While picking, the whole card is the control; a share button
              // beside it would be a second target doing something else.
              if (_selecting)
                _checkMark(picked, large: true)
              else
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: busy ? null : () => _shareRow(row),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: _brand),
                            )
                          : const Icon(Icons.share_rounded,
                              size: 18, color: _brand),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkMark(bool picked, {bool large = false}) {
    final size = large ? 28.0 : 22.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: picked ? _brand : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
            color: picked ? _brand : _border, width: picked ? 0 : 1.5),
        boxShadow: large
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1)),
              ],
      ),
      child: picked
          ? Icon(Icons.check_rounded,
              size: large ? 18 : 14, color: Colors.white)
          : null,
    );
  }

  Widget _chip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary)),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _textPrimary)),
      ],
    );
  }

  Widget _thumbnail(String url) {
    return Container(
      width: 66,
      height: 66,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _hairline,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border.withValues(alpha: 0.7)),
      ),
      child: url.isEmpty
          ? Icon(Icons.diamond_outlined,
              size: 26, color: _textSecondary.withValues(alpha: 0.55))
          : Image.network(
              url,
              fit: BoxFit.cover,
              // A missing photo is normal — not every piece is photographed —
              // so it falls back to the placeholder rather than an error icon.
              errorBuilder: (_, __, ___) => Icon(Icons.diamond_outlined,
                  size: 26, color: _textSecondary.withValues(alpha: 0.55)),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _brand),
                      ),
                    ),
            ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.16),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _brand.withValues(alpha: 0.08),
                ),
                child: Icon(Icons.sell_outlined,
                    size: 44, color: _brand.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              Text('No tags found',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary)),
              const SizedBox(height: 6),
              Text(
                  _section.usesDateRange
                      ? '${_section.caption} in this date range'
                      : 'Nothing is in stock right now',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
