import 'dart:developer';

import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/date_range_sheet.dart';
import 'package:DataCareUltra/utils/insight_help.dart';
import 'package:DataCareUltra/utils/rank_list.dart';
import 'package:DataCareUltra/utils/rank_list_metrics.dart';
import 'package:DataCareUltra/utils/report_queries.dart';
import 'package:DataCareUltra/utils/summary_stat_row.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Design tokens, shared by the screen and the small widgets it is built from.
// They were static members of the state class until the ranked list became a
// widget of its own and needed the same palette.
const Color _brand = Color(0xFF006EB7);
const Color _cta = _brand;
const Color _textPrimary = Color(0xFF0F172A);
const Color _textSecondary = Color(0xFF64748B);
const Color _border = Color(0xFFCBD5E1);
const Color _pageBg = Color(0xFFF8FAFC);
const Color _hairline = Color(0xFFEEF2F6);
const Color _success = Color(0xFF059669);
const Color _danger = Color(0xFFDC2626);
const Color _accentAmber = Color(0xFFD97706);

enum _ChartKind { salesTrend, stockByItem, insights }

/// Whether a chart plots money or grams.
///
/// Retail and wholesale shops read the same report differently — one cares
/// about amount billed, the other about metal moved — so every chart offers
/// both rather than picking one.
enum _Metric {
  amount('Amount'),
  weight('Weight');

  const _Metric(this.label);
  final String label;
}

/// A point on the day axis of the sales chart.
class _DayPoint {
  final DateTime day;
  final double sales;
  final double outstanding;
  final double netWt;
  final int bills;

  const _DayPoint(
      this.day, this.sales, this.outstanding, this.netWt, this.bills);

  double get total => sales;
}

/// A bar on the stock chart.
class _ItemBar {
  final String name;
  final double weight;
  final double pcs;

  const _ItemBar(this.name, this.weight, this.pcs);
}

/// Totals for the whole stock, not just the bars that fit on the chart, so
/// the "top 8" can be shown as a share of everything.
class _StockTotals {
  final int itemCount;
  final double weight;
  final double pcs;

  const _StockTotals(this.itemCount, this.weight, this.pcs);
}

class GraphReportsScreen extends StatefulWidget {
  const GraphReportsScreen({super.key});

  @override
  State<GraphReportsScreen> createState() => _GraphReportsScreenState();
}

class _GraphReportsScreenState extends State<GraphReportsScreen> {
  _ChartKind _kind = _ChartKind.salesTrend;

  /// Defaults to the last 30 days: a single day makes a pointless trend line.
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 29));
  DateTime _toDate = DateTime.now();

  /// Stock chart shows the heaviest items; more than this and the labels
  /// become unreadable on a phone.
  static const int _topItemCount = 8;

  List<_DayPoint> _points = [];
  /// Every item in stock. The chart shows the top few; see [_items].
  List<_ItemBar> _stockAll = [];

  /// The heaviest (or most numerous) items, re-picked from the whole stock
  /// every time the metric changes.
  ///
  /// The top eight used to be chosen once, by weight, at load — and the
  /// By Pieces switch merely re-sorted those same eight. An item with many
  /// light pieces was never in the list to begin with, so the pieces view was
  /// showing the wrong items in the right order.
  List<_ItemBar> get _items {
    final sorted = List<_ItemBar>.from(_stockAll)
      ..sort((a, b) =>
          _byWeight ? b.weight.compareTo(a.weight) : b.pcs.compareTo(a.pcs));
    return sorted.take(_topItemCount).toList();
  }

  /// Share of the whole stock the charted items make up, as a percentage.
  double get _topShare {
    final total = _byWeight ? _stockTotals.weight : _stockTotals.pcs;
    if (total <= 0) return 0;
    final top =
        _items.fold<double>(0, (s, b) => s + (_byWeight ? b.weight : b.pcs));
    return top / total * 100;
  }
  _StockTotals _stockTotals = const _StockTotals(0, 0, 0);

  /// Same-length window immediately before the chosen range, so the header can
  /// say whether business is up or down rather than just how much it was.
  double _previousTotal = 0;

  /// Net weight over that same window, so the up/down indicator compares
  /// grams with grams when the weight metric is selected.
  double _previousNetWt = 0;

  /// Shared by the sales and stock charts, so switching once applies
  /// everywhere rather than per-tab.
  _Metric _metric = _Metric.amount;

  bool get _byWeight => _metric == _Metric.weight;

  // Insights
  List<RankEntry> _topItems = [];
  List<RankEntry> _trendingItems = [];
  List<RankEntry> _topCustomers = [];
  List<RankEntry> _topOutstanding = [];

  /// The window Insights compares against, kept so the tab can name it in
  /// plain dates. "Trending" means nothing until you can see what it was
  /// measured against.
  DateTime _prevFrom = DateTime.now();
  DateTime _prevTo = DateTime.now();

  late LoadingProvider loadingProvider;
  late ReportQueries _queries;
  String companyName = "";

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    companyName = provider.co_name;
    _queries = ReportQueries(
      coCode: provider.co_code,
      lcCode: provider.lc_code,
      year: provider.co_year,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

  /// Sales rows come back with VCH_DATE already converted to `dd-mm-yyyy`
  /// (SQL Server style 105). Returns null rather than throwing so one odd row
  /// cannot break the whole chart.
  DateTime? _parseVchDate(dynamic raw) {
    final text = '${raw ?? ''}'.trim();
    if (text.isEmpty) return null;
    final parts = text.split(RegExp(r'[-/]'));
    if (parts.length < 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y =
        int.tryParse(parts[2].length > 4 ? parts[2].substring(0, 4) : parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _load() async {
    loadingProvider.startLoading();
    setState(() {});
    final from = DateFormat("MM/dd/yyyy").format(_fromDate);
    final to = DateFormat("MM/dd/yyyy").format(_toDate);
    try {
      if (_kind == _ChartKind.stockByItem) {
        await _loadStock(from, to);
      } else if (_kind == _ChartKind.insights) {
        await _loadInsights(from, to);
      } else {
        await _loadSales(from, to);
      }
    } catch (e) {
      log('graph load failed: $e');
      _points = [];
      _stockAll = [];
      if (mounted) {
        showAppToast(context, "Could not load the chart. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadSales(String from, String to) async {
    // Preceding window of equal length, for the up/down indicator.
    final prevTo = _fromDate.subtract(const Duration(days: 1));
    final prevFrom = prevTo.subtract(Duration(days: _spanDays - 1));
    final prevFromStr = DateFormat("MM/dd/yyyy").format(prevFrom);
    final prevToStr = DateFormat("MM/dd/yyyy").format(prevTo);

    // Awaited one at a time, never Future.wait: ReportQueries talks over a
    // single shared SqlConnection, and firing queries at it concurrently made
    // them trip over each other — which is what produced the intermittent
    // "Could not load the chart" message.
    final current = await _queries.salesRows(from, to);
    final previous = await _queries.salesRows(prevFromStr, prevToStr);
    final results = [current, previous];

    final byDay = <DateTime, List<double>>{};

    void accumulate(List<dynamic> rows) {
      // Amounts repeat across the lines of one voucher, so count each
      // voucher once. Weight is per line and must not be de-duplicated.
      final seen = <String>{};
      for (final r in rows) {
        final day = _parseVchDate(r["VCH_DATE"]);
        if (day == null) continue;
        // [sales, outstanding, netWt, bills]
        final slots = byDay.putIfAbsent(day, () => [0, 0, 0, 0]);
        slots[2] += _num(r["Nwt"]);
        final key = '${r["VCH_NO"] ?? ''}-${r["CO_BOOK"] ?? ''}';
        if (!seen.add(key)) continue;
        slots[0] += _num(r["NetAmt"]);
        slots[1] += _num(r["OsAmt"]);
        slots[3] += 1;
      }
    }

    double totalOf(List<dynamic> rows) {
      final seen = <String>{};
      double sum = 0;
      for (final r in rows) {
        final key = '${r["VCH_NO"] ?? ''}-${r["CO_BOOK"] ?? ''}';
        if (!seen.add(key)) continue;
        sum += _num(r["NetAmt"]);
      }
      return sum;
    }

    // Weight is per line, so no de-duplication here — see accumulate().
    double weightOf(List<dynamic> rows) =>
        rows.fold(0.0, (s, r) => s + _num(r["Nwt"]));

    accumulate(results[0]);
    _previousTotal = totalOf(results[1]);
    _previousNetWt = weightOf(results[1]);

    final days = byDay.keys.toList()..sort();
    _points = [
      for (final d in days)
        _DayPoint(
            d, byDay[d]![0], byDay[d]![1], byDay[d]![2], byDay[d]![3].toInt())
    ];
  }

  Future<void> _loadStock(String from, String to) async {
    final rows = await _queries.stockRows(from, to, '');
    final bars = <_ItemBar>[
      for (final r in rows)
        _ItemBar(
            '${r["ItName"] ?? ''}'.trim(), _num(r["ClWt"]), _num(r["ClPcs"]))
    ].where((b) => b.name.isNotEmpty && (b.weight > 0 || b.pcs > 0)).toList();

    _stockTotals = _StockTotals(
      bars.length,
      bars.fold(0.0, (s, b) => s + b.weight),
      bars.fold(0.0, (s, b) => s + b.pcs),
    );
    _stockAll = bars;
    _touchedSlice = null;
  }

  /// Everything the Insights tab shows, in one pass.
  ///
  /// Sold quantities come from the stock movement columns (SlWt / SlPcs)
  /// because the sales report is grouped per voucher and carries no item
  /// name — it can tell you who bought, but not what.
  Future<void> _loadInsights(String from, String to) async {
    _prevTo = _fromDate.subtract(const Duration(days: 1));
    _prevFrom = _prevTo.subtract(Duration(days: _spanDays - 1));

    // Sequential, not Future.wait — see the note in _loadSales. Four
    // concurrent queries on one shared connection was the single biggest
    // source of the "Could not load the chart" failures.
    final results = [
      await _queries.stockRows(from, to, ''),
      await _queries.stockRows(DateFormat("MM/dd/yyyy").format(_prevFrom),
          DateFormat("MM/dd/yyyy").format(_prevTo), ''),
      await _queries.salesRows(from, to),
      await _queries.outstandingRows(DateFormat("MM/dd/yyyy").format(_toDate)),
    ];

    // Every list below keeps all its rows. They used to be cut to five to fit
    // the card; the cards now scroll inside a fixed window instead, so there
    // is no reason to throw the rest of the shop's data away.

    // ── Top selling items, by weight sold in the range ──
    final sold = <String, double>{};
    final soldPcs = <String, double>{};
    for (final r in results[0]) {
      final name = '${r["ItName"] ?? ''}'.trim();
      if (name.isEmpty) continue;
      final wt = _num(r["SlWt"]);
      final pcs = _num(r["SlPcs"]);
      // A piece sold with no weight entered is still a sale. The old `wt <= 0`
      // test dropped those rows, and the item disappeared from the list
      // altogether rather than appearing with its piece count.
      if (wt <= 0 && pcs <= 0) continue;
      sold[name] = (sold[name] ?? 0) + wt;
      soldPcs[name] = (soldPcs[name] ?? 0) + pcs;
    }
    final soldNames = sold.keys.toList()
      ..sort((a, b) {
        final byWeight = sold[b]!.compareTo(sold[a]!);
        return byWeight != 0 ? byWeight : soldPcs[b]!.compareTo(soldPcs[a]!);
      });
    _topItems = [
      for (final n in soldNames)
        RankEntry(n, sold[n]!,
            subtitle: sold[n]! > 0
                ? "${_pcsText(soldPcs[n]!)} sold"
                : "weight not entered",
            display: sold[n]! > 0 ? null : _pcsText(soldPcs[n]!))
    ];

    // ── Trending: biggest rise against the previous window ──
    final prevSold = <String, double>{};
    for (final r in results[1]) {
      final name = '${r["ItName"] ?? ''}'.trim();
      if (name.isEmpty) continue;
      prevSold[name] = (prevSold[name] ?? 0) + _num(r["SlWt"]);
    }
    final deltas = <String, double>{};
    for (final entry in sold.entries) {
      final delta = entry.value - (prevSold[entry.key] ?? 0);
      if (delta > 0) deltas[entry.key] = delta;
    }
    final trendNames = deltas.keys.toList()
      ..sort((a, b) => deltas[b]!.compareTo(deltas[a]!));
    _trendingItems = [
      for (final n in trendNames)
        RankEntry(n, deltas[n]!,
            subtitle: _riseText(prevSold[n] ?? 0, deltas[n]!))
    ];

    // ── Best customers, by amount billed ──
    final byCustomer = <String, double>{};
    final billCount = <String, int>{};
    final mobiles = <String, String>{};
    final seen = <String>{};
    for (final r in results[2]) {
      final key = '${r["VCH_NO"] ?? ''}-${r["CO_BOOK"] ?? ''}';
      if (!seen.add(key)) continue;
      final name = '${r["AC_NAME"] ?? ''}'.trim();
      if (name.isEmpty) continue;
      byCustomer[name] = (byCustomer[name] ?? 0) + _num(r["NetAmt"]);
      billCount[name] = (billCount[name] ?? 0) + 1;
      mobiles[name] = '${r["AC_MOBILE"] ?? ''}'.trim();
    }
    final custNames = byCustomer.keys.toList()
      ..sort((a, b) => byCustomer[b]!.compareTo(byCustomer[a]!));
    _topCustomers = [
      for (final n in custNames)
        RankEntry(n, byCustomer[n]!,
            subtitle: _customerText(billCount[n] ?? 0, mobiles[n]))
    ];

    // ── Highest outstanding parties ──
    // Already sorted largest-first by the query; rows with nothing owing or no
    // name attached are noise rather than data.
    _topOutstanding = [
      for (final r in results[3])
        if (_num(r["DrAmt"]) > 0 && '${r["AC_NAME"] ?? ''}'.trim().isNotEmpty)
          RankEntry('${r["AC_NAME"] ?? ''}'.trim(), _num(r["DrAmt"]),
              subtitle: '${r["AC_CITY"] ?? ''}'.trim())
    ];
  }

  String _pcsText(double pcs) =>
      "${pcs.toStringAsFixed(0)} ${pcs == 1 ? 'pc' : 'pcs'}";

  /// The sub-line on a trending row.
  ///
  /// "was 12.500 gm" left the reader to do the division. The percentage is the
  /// part a shopkeeper actually reads, so it leads, with the baseline kept
  /// beside it for anyone who wants to check the arithmetic.
  String _riseText(double previous, double rise) {
    if (previous <= 0) return "New — nothing sold last period";
    final pct = (rise / previous) * 100;
    return "Up ${pct.toStringAsFixed(0)}% from ${previous.toStringAsFixed(3)} gm";
  }

  String _customerText(int bills, String? mobile) {
    final billed = "$bills ${bills == 1 ? 'bill' : 'bills'}";
    final phone = (mobile ?? '').trim();
    return phone.isEmpty ? billed : "$billed  ·  $phone";
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangeSheet(
      context,
      from: _fromDate,
      to: _toDate,
    );
    if (picked != null) {
      _fromDate = picked.start;
      _toDate = picked.end;
      _load();
    }
  }

  // ── Totals shown above the chart ───────────────────────────────────────────

  double get _totalSales => _points.fold(0.0, (s, p) => s + p.sales);
  double get _totalOutstanding =>
      _points.fold(0.0, (s, p) => s + p.outstanding);
  double get _totalNetWt => _points.fold(0.0, (s, p) => s + p.netWt);
  int get _totalBills => _points.fold(0, (s, p) => s + p.bills);
  // Every figure on the Sales tab follows the Amount / Weight switch. Best
  // days, Avg / day and the comparison used to stay in rupees whatever the
  // switch said, so a weight view carried rupee figures under a gram headline.
  double get _grandTotal => _byWeight ? _totalNetWt : _totalSales;
  double get _previousGrandTotal =>
      _byWeight ? _previousNetWt : _previousTotal;
  double get _avgPerDay => _points.isEmpty ? 0 : _grandTotal / _points.length;

  /// Percentage change against the preceding window. Null when there is no
  /// prior business to compare against — showing "+100%" from zero would be
  /// meaningless.
  double? get _changePct {
    if (_previousGrandTotal <= 0) return null;
    return ((_grandTotal - _previousGrandTotal) / _previousGrandTotal) * 100;
  }

  double get _peak =>
      _points.fold(0.0, (m, p) => _metricOf(p) > m ? _metricOf(p) : m);

  /// Days in the chosen range, both ends included. Every comparison window on
  /// this screen is this many days long.
  int get _spanDays => _toDate.difference(_fromDate).inDays + 1;

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _appBar(),
      body: Column(
        children: [
          _kindSelector(),
          if (_kind != _ChartKind.stockByItem) _rangeBar(),
          Expanded(
            child: Consumer<LoadingProvider>(
              builder: (context, loading, _) {
                if (loading.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _cta, strokeWidth: 2.6));
                }
                final empty = switch (_kind) {
                  _ChartKind.stockByItem => _items.isEmpty,
                  _ChartKind.insights => _topItems.isEmpty &&
                      _trendingItems.isEmpty &&
                      _topCustomers.isEmpty &&
                      _topOutstanding.isEmpty,
                  _ => _points.isEmpty,
                };
                if (empty) return _emptyState();
                return RefreshIndicator(
                  color: _cta,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    children: [
                      if (_kind == _ChartKind.insights) ...[
                        _insightsIntro(),
                        const SizedBox(height: 12),
                        _insightCard(
                          title: "Top selling items",
                          icon: Icons.local_fire_department_rounded,
                          accent: _accentAmber,
                          rows: _topItems,
                          help: topSellingHelp(_fromDate, _toDate),
                          format: (v) => "${v.toStringAsFixed(3)} gm",
                        ),
                        const SizedBox(height: 12),
                        _insightCard(
                          title: "Trending items",
                          icon: Icons.trending_up_rounded,
                          accent: _success,
                          rows: _trendingItems,
                          help: trendingHelp(
                              _fromDate, _toDate, _prevFrom, _prevTo),
                          format: (v) => "+${v.toStringAsFixed(3)} gm",
                        ),
                        const SizedBox(height: 12),
                        _insightCard(
                          title: "Best customers",
                          icon: Icons.workspace_premium_rounded,
                          accent: _cta,
                          rows: _topCustomers,
                          help: bestCustomersHelp(_fromDate, _toDate),
                          format: _compact,
                        ),
                        const SizedBox(height: 12),
                        _insightCard(
                          title: "Highest outstanding",
                          icon: Icons.error_outline_rounded,
                          accent: _danger,
                          rows: _topOutstanding,
                          help: outstandingHelp(_toDate),
                          format: _compact,
                        ),
                      ] else if (_kind == _ChartKind.stockByItem) ...[
                        _stockKpis(),
                        const SizedBox(height: 12),
                        _metricToggle(),
                        const SizedBox(height: 12),
                        _chartCard(
                          _stockChart(),
                          "Top $_topItemCount items by ${_byWeight ? 'weight' : 'pieces'}",
                          subtitle:
                              "${_topShare.toStringAsFixed(1)}% of your total stock "
                              "${_byWeight ? 'weight' : 'pieces'} · tap a slice to see it",
                          height: 236,
                        ),
                        const SizedBox(height: 12),
                        _stockBreakdown(),
                      ] else ...[
                        _summaryCard(),
                        const SizedBox(height: 12),
                        _metricToggle(),
                        const SizedBox(height: 12),
                        _chartCard(_salesChart(),
                            _byWeight ? "Net weight per day" : "Sales per day"),
                        const SizedBox(height: 12),
                        _salesKpis(),
                        const SizedBox(height: 12),
                        _topDays(),
                      ],
                    ],
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
                Text("Graph Reports",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(
                    _kind == _ChartKind.stockByItem
                        ? "Closing stock"
                        : "${DateFormat("dd/MM/yyyy").format(_fromDate)}  –  ${DateFormat("dd/MM/yyyy").format(_toDate)}",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          if (_kind != _ChartKind.stockByItem)
            IconButton(
              tooltip: "Date range",
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range_rounded,
                  color: Colors.white, size: 20),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _kindSelector() {
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
            _kindTab("Sales", Icons.show_chart_rounded, _ChartKind.salesTrend),
            _kindTab(
                "Stock", Icons.inventory_2_rounded, _ChartKind.stockByItem),
            _kindTab(
                "Insights", Icons.auto_awesome_rounded, _ChartKind.insights),
          ],
        ),
      ),
    );
  }

  /// A tab carries its icon as well as its name: three words alone give the
  /// eye nothing to aim at, and "Insights" in particular does not say what it
  /// holds.
  Widget _kindTab(String label, IconData icon, _ChartKind kind) {
    final selected = _kind == kind;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_kind == kind) return;
          _kind = kind;
          setState(() {});
          _load();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _cta : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 15, color: selected ? Colors.white : _textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rangeBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickRange,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: _cta.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    size: 14, color: _cta),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rangeLabel(_fromDate, _toDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                    Text(
                        "$_spanDays ${_spanDays == 1 ? 'day' : 'days'}"
                        "${_kind == _ChartKind.salesTrend ? '  ·  ${_points.length} with sales' : ''}",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary)),
                  ],
                ),
              ),
              Text("Change",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _cta)),
              const Icon(Icons.chevron_right_rounded, size: 18, color: _cta),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final change = _changePct;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cta, Color.lerp(_cta, const Color(0xFF0D47A1), 0.35)!],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_byWeight ? "Total net weight" : "Total business",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                          _byWeight
                              ? "${_grandTotal.toStringAsFixed(3)} gm"
                              : _grandTotal.toStringAsFixed(2),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
              // Only shown when there is prior business to compare against;
              // a jump from zero is not a meaningful percentage.
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          change >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 15,
                          color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                          "${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%",
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          if (change != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  "vs ${_metricLabel(_previousGrandTotal)} in the previous "
                  "${_spanDays == 1 ? 'day' : '$_spanDays days'}",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8))),
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          // "Sales" used to sit here beside "Best day", repeating the headline
          // figure directly above it. These three say something the headline
          // does not.
          SummaryStatRow(stats: [
            SummaryStat("Bills", '$_totalBills', flex: 3),
            _metricStat("Avg / day", _avgPerDay),
            _metricStat("Best day", _peak),
          ]),
        ],
      ),
    );
  }

  /// Large rupee figures do not fit on an axis label, so shorten them.
  String _compact(double v) {
    if (v >= 10000000) return "${(v / 10000000).toStringAsFixed(2)}Cr";
    if (v >= 100000) return "${(v / 100000).toStringAsFixed(2)}L";
    if (v >= 1000) return "${(v / 1000).toStringAsFixed(1)}K";
    return v.toStringAsFixed(0);
  }

  Widget _chartCard(
    Widget chart,
    String title, {
    String? subtitle,
    double height = 240,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hairline),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary)),
                ],
              ],
            ),
          ),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }

  // ── Detail cards ───────────────────────────────────────────────────────────

  /// White card with a heading.
  ///
  /// [subtitle] is the one line that says what the card is for. A heading like
  /// "Breakdown" or "Best days" names the card without explaining it, and that
  /// gap is most of what made this screen hard to read.
  Widget _sectionCard({
    required String title,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hairline),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: _textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _kpiTile(String label, String value, {Color? color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: color ?? _textSecondary),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color ?? _textPrimary)),
          ),
        ],
      ),
    );
  }

  /// Bills and Avg / day moved up into the summary card, so this one no longer
  /// repeats them. What is left splits the headline total into the part
  /// already received and the part still owed, which is the question a shop
  /// owner actually asks of a sales figure.
  Widget _salesKpis() {
    final received = _totalSales - _totalOutstanding;
    return _sectionCard(
      title: "Breakdown",
      subtitle: "Of the business billed in these dates",
      child: Row(children: [
        Expanded(
            child: _kpiTile("Received", _compact(received < 0 ? 0 : received),
                color: _success, icon: Icons.check_circle_outline_rounded)),
        const SizedBox(width: 10),
        Expanded(
            child: _kpiTile("Still owed", _compact(_totalOutstanding),
                color: _danger, icon: Icons.error_outline_rounded)),
        const SizedBox(width: 10),
        Expanded(
            child: _kpiTile("Net wt", "${_totalNetWt.toStringAsFixed(3)} gm",
                icon: Icons.scale_rounded)),
      ]),
    );
  }

  /// A stat on the blue summary card in the current metric: grams carry their
  /// unit as a smaller suffix, rupees are compacted.
  SummaryStat _metricStat(String label, double v) => _byWeight
      ? SummaryStat(label, v.toStringAsFixed(3), unit: 'gm', flex: 4)
      : SummaryStat(label, _compact(v), flex: 4);

  /// The five biggest days, so a spike on the chart can be named.
  ///
  /// Biggest in the selected metric: by grams moved when Weight is chosen,
  /// by rupees billed when Amount is. The ranking changes too, not just the
  /// unit — the heaviest day is rarely the day that billed the most.
  Widget _topDays() {
    final sorted = List<_DayPoint>.from(_points)
      ..sort((a, b) => _metricOf(b).compareTo(_metricOf(a)));
    final top = sorted.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    final best = _metricOf(top.first);

    return _sectionCard(
      title: "Best days",
      subtitle: _byWeight
          ? "Your five heaviest days by net weight, with the number of bills"
          : "Your five biggest days by amount, with the number of bills",
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(DateFormat("dd MMM").format(top[i].day),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: best == 0 ? 0 : _metricOf(top[i]) / best,
                      minHeight: 8,
                      backgroundColor: _hairline,
                      valueColor: AlwaysStoppedAnimation(
                          _byWeight ? _success : _cta),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  // "1234.567 gm" needs more room than "12.3K".
                  width: _byWeight ? 90 : 66,
                  child: Text(_metricLabel(_metricOf(top[i])),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                ),
                SizedBox(
                  width: 34,
                  child: Text("${top[i].bills}",
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stockKpis() {
    return _sectionCard(
      title: "Stock summary",
      subtitle: "Everything on your shelf right now",
      child: Row(children: [
        Expanded(
            child: _kpiTile("Items", '${_stockTotals.itemCount}',
                icon: Icons.inventory_2_rounded)),
        const SizedBox(width: 10),
        Expanded(
            child: _kpiTile(
                "Total wt", "${_stockTotals.weight.toStringAsFixed(3)} gm",
                color: _success, icon: Icons.scale_rounded)),
        const SizedBox(width: 10),
        Expanded(
            child: _kpiTile("Pieces", _stockTotals.pcs.toStringAsFixed(0),
                icon: Icons.tag_rounded)),
      ]),
    );
  }

  /// Ranked list under the stock chart, with each item's share of total stock.
  ///
  /// This list is the chart's legend: each rank badge wears its slice's
  /// colour, and tapping a row lifts that slice out of the donut. A second
  /// legend beside the pie used to repeat these same names with less room and
  /// fewer decimals, so the two disagreed to the eye about the same figures.
  Widget _stockBreakdown() {
    final items = _items;
    final totalValue = _byWeight ? _stockTotals.weight : _stockTotals.pcs;
    return _sectionCard(
      title: _byWeight ? "Share by weight" : "Share by pieces",
      subtitle: "Of your whole stock, not just these $_topItemCount",
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(height: 1, color: _hairline),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(
                  () => _touchedSlice = _touchedSlice == i ? null : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                decoration: BoxDecoration(
                  color: _touchedSlice == i
                      ? _sliceColour(i).withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 22,
                      width: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _sliceColour(i)
                            .withValues(alpha: _touchedSlice == i ? 1 : 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${i + 1}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _touchedSlice == i
                                  ? Colors.white
                                  : _sliceColour(i))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(items[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Text(_stockValueLabel(items[i]),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 46,
                      child: Text(
                          totalValue == 0
                              ? "-"
                              : "${(((_byWeight ? items[i].weight : items[i].pcs) / totalValue) * 100).toStringAsFixed(1)}%",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "833.940 gm" or "12 pcs" — three decimals on grams everywhere on this
  /// screen, so the chart and the list under it never show the same item
  /// with two different figures.
  String _stockValueLabel(_ItemBar b) => _byWeight
      ? "${b.weight.toStringAsFixed(3)} gm"
      : "${b.pcs.toStringAsFixed(0)} pcs";

  /// One line at the top of the Insights tab naming the two windows every list
  /// below is built from.
  ///
  /// "Trending items, +3.500 gm" is a riddle until you can see what it was
  /// measured against, and the comparison window is never something the user
  /// chose — the screen works it out. So it says so, in dates.
  Widget _insightsIntro() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: _cta.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cta.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 17, color: _cta),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Showing ${rangeLabel(_fromDate, _toDate)}",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary)),
                const SizedBox(height: 2),
                Text(
                    "Compared with the ${_spanDays == 1 ? 'day' : '$_spanDays days'} before it "
                    "(${rangeLabel(_prevFrom, _prevTo)}). Tap the info button on any "
                    "card to see how its numbers are worked out.",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ranked list card used by every insight.
  ///
  /// The list holds every row and scrolls inside a fixed window — see
  /// [RankList]. The caption and the info button are the other half of the
  /// job: a ranked list of grams means nothing to a shopkeeper who cannot tell
  /// what was ranked, or against what.
  Widget _insightCard({
    required String title,
    required IconData icon,
    required Color accent,
    required List<RankEntry> rows,
    required InsightHelp help,
    required String Function(double) format,
  }) {
    final noun = switch (title) {
      "Best customers" => rows.length == 1 ? "customer" : "customers",
      "Highest outstanding" => rows.length == 1 ? "party" : "parties",
      _ => rows.length == 1 ? "item" : "items",
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hairline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: _textPrimary)),
              ),
              if (rows.isNotEmpty) ...[
                const SizedBox(width: 8),
                _countPill("${rows.length} $noun", accent,
                    scrollable: rankListScrolls(rows.length)),
              ],
              const Spacer(),
              _helpButton(title, icon, accent, help),
            ],
          ),
          const SizedBox(height: 7),
          Text(help.caption,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary)),
          const SizedBox(height: 10),
          Container(height: 1, color: _hairline),
          const SizedBox(height: 4),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text("Nothing to show for these dates",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary)),
            )
          else
            RankList(rows: rows, accent: accent, format: format),
        ],
      ),
    );
  }

  /// How many rows the list holds, and — when there are more than fit — that
  /// they are reached by scrolling it.
  Widget _countPill(String text, Color accent, {required bool scrollable}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                  color: accent)),
          if (scrollable) ...[
            const SizedBox(width: 4),
            Icon(Icons.swipe_vertical_rounded, size: 11, color: accent),
          ],
        ],
      ),
    );
  }

  Widget _helpButton(
      String title, IconData icon, Color accent, InsightHelp help) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showInsightHelp(title, icon, accent, help),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.info_outline_rounded, size: 18, color: _textSecondary),
      ),
    );
  }

  /// Plain-language explanation of one list, in a sheet rather than on the
  /// card: the detail matters the first time and is clutter every time after.
  void _showInsightHelp(
      String title, IconData icon, Color accent, InsightHelp help) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, size: 19, color: accent),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: _textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _helpBlock("What this shows", help.what),
                const SizedBox(height: 10),
                _helpBlock("How it is worked out", help.how),
                if (help.note != null) ...[
                  const SizedBox(height: 10),
                  _helpBlock("Worth knowing", help.note!, accent: accent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _helpBlock(String label, String body, {Color? accent}) {
    final tone = accent ?? _textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: tone)),
          const SizedBox(height: 6),
          Text(body,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.8,
                  height: 1.48,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary)),
        ],
      ),
    );
  }

  // ── Charts ─────────────────────────────────────────────────────────────────

  Widget _salesChart() {
    // Peak of the series actually being drawn — using the amount peak while
    // plotting grams would flatten the line into the floor of the chart.
    final peak =
        _points.fold<double>(0, (m, p) => _metricOf(p) > m ? _metricOf(p) : m);
    final maxY = (peak == 0 ? 1.0 : peak) * 1.15;
    // With many days, only every Nth label is drawn or they overlap.
    final labelEvery = (_points.length / 5).ceil().clamp(1, 999);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: _hairline, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) => Text(
                  _byWeight ? value.toStringAsFixed(0) : _compact(value),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _points.length) return const SizedBox();
                if (i % labelEvery != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat("dd/MM").format(_points[i].day),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => _textPrimary,
            getTooltipItems: (spots) => spots.map((s) {
              final p = _points[s.spotIndex];
              return LineTooltipItem(
                "${DateFormat("dd MMM").format(p.day)}\n"
                "${_byWeight ? 'Net wt' : 'Sales'}: ${_metricLabel(s.y)}",
                GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          _line([
            for (var i = 0; i < _points.length; i++)
              FlSpot(i.toDouble(), _metricOf(_points[i]))
          ], _byWeight ? _success : _cta),
        ],
      ),
    );
  }

  /// The value a day contributes to the sales chart under the current metric.
  double _metricOf(_DayPoint p) => _byWeight ? p.netWt : p.total;

  /// Formats a chart value for the current metric — grams need three decimals
  /// and a unit, rupees read better compacted.
  String _metricLabel(double v) =>
      _byWeight ? "${v.toStringAsFixed(3)} gm" : _compact(v);

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 2.6,
      // A dot per day is noise across a month; they appear on touch instead.
      dotData: FlDotData(show: spots.length <= 12),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.02),
          ],
        ),
      ),
    );
  }

  /// Amount / Weight switch, shown above every chart.
  Widget _metricToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hairline),
      ),
      child: Row(
        children: [
          for (final m in _Metric.values) _metricTab(m),
        ],
      ),
    );
  }

  Widget _metricTab(_Metric metric) {
    final selected = _metric == metric;
    // On the stock tab "weight vs pieces" is the clearer wording for the same
    // choice, since stock is counted in pieces rather than billed in rupees.
    final label = _kind == _ChartKind.stockByItem
        ? (metric == _Metric.weight ? 'By Weight' : 'By Pieces')
        : metric.label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_metric == metric) return;
          _metric = metric;
          // The top items are re-picked by the getter; no round trip needed.
          // A lifted slice would point at a different item under the new
          // ordering, so it is dropped.
          _touchedSlice = null;
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _success : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _textSecondary)),
        ),
      ),
    );
  }

  /// Slice colours. Fixed rather than generated so the same item keeps the
  /// same colour between the chart and the legend below it.
  static const List<Color> _sliceColours = [
    Color(0xFF006EB7),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFD97706),
    Color(0xFF0891B2),
    Color(0xFFDC2626),
    Color(0xFF2563EB),
    Color(0xFF65A30D),
  ];

  Color _sliceColour(int i) => _sliceColours[i % _sliceColours.length];

  /// Stock as a pie rather than bars.
  ///
  /// Bars needed a readable label under every column, and item names here run
  /// long enough that they had to be cut to nine characters — which made
  /// different items look identical on screen. A pie carries no axis labels,
  /// so the full names live in the legend beside it with room to breathe, and
  /// each item's share of the total is what the shape itself shows.
  /// Which slice is lifted out of the donut, if any. Set by tapping the chart
  /// or a row of the list under it; tapping the same one again clears it.
  int? _touchedSlice;

  /// The donut fills the card's width on its own, with the legend moved into
  /// the list below (see [_stockBreakdown]). Side by side, the pie got the
  /// narrower half of a phone and came out the size of a coin, while the
  /// legend beside it cramped eight names into two-decimal figures that did
  /// not match the three-decimal list under it. The centre of the donut now
  /// names whatever slice is touched, so a thin slice with no room for a
  /// label still reads.
  Widget _stockChart() {
    double valueOf(_ItemBar b) => _byWeight ? b.weight : b.pcs;
    final items = _items;
    final total = items.fold<double>(0, (sum, b) => sum + valueOf(b));
    if (total <= 0) return const SizedBox(height: 40);
    final touched =
        _touchedSlice != null && _touchedSlice! < items.length
            ? _touchedSlice
            : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 58,
            startDegreeOffset: -90,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                // Only a completed tap toggles; reacting to every move of the
                // finger makes the slice flicker in and out under it.
                if (event is! FlTapUpEvent) return;
                final i = response?.touchedSection?.touchedSectionIndex;
                setState(() {
                  _touchedSlice = (i == null || i < 0 || i == _touchedSlice)
                      ? null
                      : i;
                });
              },
            ),
            sections: [
              for (var i = 0; i < items.length; i++)
                PieChartSectionData(
                  value: valueOf(items[i]),
                  color: _sliceColour(i),
                  radius: touched == i ? 60 : 50,
                  // A percentage is only legible on a slice wide enough to
                  // hold it; thinner slices are read by tapping them.
                  showTitle: valueOf(items[i]) / total >= 0.06,
                  title:
                      "${(valueOf(items[i]) / total * 100).toStringAsFixed(0)}%",
                  titleStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        // The hole in the middle: the touched item, or what the whole chart
        // covers. Ignores pointers so taps fall through to the slices.
        IgnorePointer(
          child: SizedBox(
            width: 104,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: touched == null
                  ? [
                      Text("Top ${items.length}",
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary)),
                      const SizedBox(height: 1),
                      Text("${_topShare.toStringAsFixed(0)}% of stock",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary)),
                    ]
                  : [
                      Text(items[touched].name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: _sliceColour(touched))),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_stockValueLabel(items[touched]),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary)),
                      ),
                      Text(
                          "${(valueOf(items[touched]) / total * 100).toStringAsFixed(1)}%",
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary)),
                    ],
            ),
          ),
        ),
      ],
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
            child: const Icon(Icons.bar_chart_rounded, color: _cta, size: 34),
          ),
          const SizedBox(height: 16),
          Text("Nothing to chart",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
                _kind == _ChartKind.stockByItem
                    ? "No closing stock found for this year"
                    : "No sales found in this date range",
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
