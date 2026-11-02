import 'dart:developer';

import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/salesOrderReport_screen.dart';
import 'package:DataCareUltra/salesReport_screen.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/day_book_math.dart';
import 'package:DataCareUltra/utils/report_queries.dart';
import 'package:DataCareUltra/whSalesReport_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// One-screen answer to "how did today go".
///
/// Deliberately reuses the existing report definitions rather than inventing
/// new aggregates: the same rows each report screen shows are fetched for a
/// single day and totalled in Dart, so the figures here always agree with the
/// detailed report behind them.
///
/// Balances are worded, never signed. A "-1,200.00" on this screen had owners
/// asking what the minus meant; "1,200.00 Debit" is what their accountant
/// says, so it is what the screen says (see [balanceLabel]).
class DayBookScreen extends StatefulWidget {
  const DayBookScreen({super.key});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _hairline = Color(0xFFEEF2F6);
  static const Color _accentAmber = Color(0xFFD97706);
  static const Color _accentPurple = Color(0xFF7C3AED);
  static const Color _accentCyan = Color(0xFF0891B2);

  Color get _cta => _brand;

  late ReportQueries _queries;
  DateTime _date = DateTime.now();
  String companyName = "";
  late LoadingProvider loadingProvider;

  // Sales
  int _salesBills = 0;
  double _salesAmount = 0;
  double _salesOutstanding = 0;
  double _salesWeight = 0;
  MetalWeights _salesMetal = MetalWeights.zero;

  // Cash book for the day
  double _cashReceived = 0;
  double _cashPaid = 0;
  double _openingCash = 0;
  double _cashOnHand = 0;

  // Purchases
  PurchaseTotals _purchases = const PurchaseTotals();
  double _oldGoldAmount = 0;

  // Wholesale / tour sales
  int _whBills = 0;
  double _whAmount = 0;
  double _whOutstanding = 0;

  // Orders
  int _orderCount = 0;
  double _orderAmount = 0;
  double _orderAdvance = 0;

  bool _loadFailed = false;

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

  Future<void> _load() async {
    loadingProvider.startLoading();
    _loadFailed = false;
    setState(() {});

    final date = DateFormat("MM/dd/yyyy").format(_date);
    try {
      // Sequential, not Future.wait: every one of these runs SQL over the
      // same shared connection, and issuing them at once made them trip over
      // each other — an intermittent "could not load" on a day that actually
      // had data.
      await _loadSales(date);
      await _loadWhSales(date);
      await _loadOrders(date);
      await _loadCash(date);
      // The figures below are additions to the original screen. Each is
      // loaded on its own so that one of them failing — an older database
      // without a column, say — marks the page incomplete rather than
      // blanking the sales totals that were loading fine before.
      await _soft('sales metal', () => _loadSalesMetal(date));
      await _soft('cash movement', () => _loadCashMovement(date));
      await _soft('opening cash', () => _loadOpeningCash());
      await _soft('purchases', () => _loadPurchases(date));
    } catch (e) {
      log('Day book load failed: $e');
      _loadFailed = true;
      if (mounted) {
        showAppToast(context, "Could not load the day book. Pull to refresh.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  Future<void> _soft(String what, Future<void> Function() load) async {
    try {
      await load();
    } catch (e) {
      log('Day book $what failed: $e');
      _loadFailed = true;
    }
  }

  Future<void> _loadSales(String date) async {
    _salesBills = 0;
    _salesAmount = 0;
    _salesOutstanding = 0;
    _salesWeight = 0;
    try {
      final rows = await _queries.salesRows(date, date);
      // Rows are per voucher line, so bills are counted by distinct VCH_NO
      // while the amounts already come through as per-voucher totals.
      final seen = <String>{};
      for (final r in rows) {
        final vch = '${r["VCH_NO"] ?? ''}-${r["CO_BOOK"] ?? ''}';
        if (seen.add(vch)) {
          _salesAmount += _num(r["NetAmt"]);
          _salesOutstanding += _num(r["OsAmt"]);
        }
        _salesWeight += _num(r["Nwt"]);
      }
      _salesBills = seen.length;
    } catch (e) {
      log('Day book sales failed: $e');
      rethrow;
    }
  }

  Future<void> _loadSalesMetal(String date) async {
    _salesMetal = MetalWeights.zero;
    _salesMetal = metalWeights(await _queries.salesWeightByMetal(date));
  }

  Future<void> _loadCashMovement(String date) async {
    _cashReceived = 0;
    _cashPaid = 0;
    final m = await _queries.cashMovement(date);
    _cashReceived = m.received;
    _cashPaid = m.paid;
  }

  /// Opening balance is simply yesterday's closing balance.
  Future<void> _loadOpeningCash() async {
    _openingCash = 0;
    _openingCash = await _queries
        .cashBalance(DateFormat("MM/dd/yyyy").format(previousDay(_date)));
  }

  Future<void> _loadPurchases(String date) async {
    _purchases = const PurchaseTotals();
    _oldGoldAmount = 0;
    _purchases = purchaseTotals(await _queries.purchaseRows(date));
    _oldGoldAmount = await _queries.oldGoldAmount(date);
  }

  Future<void> _loadWhSales(String date) async {
    _whBills = 0;
    _whAmount = 0;
    _whOutstanding = 0;
    try {
      final rows = await _queries.whSalesRows(date, date);
      final seen = <String>{};
      for (final r in rows) {
        final vch = '${r["VCH_NO"] ?? ''}-${r["CO_BOOK"] ?? ''}';
        if (seen.add(vch)) {
          _whAmount += _num(r["NetAmt"]);
          _whOutstanding += _num(r["BillOs"]);
        }
      }
      _whBills = seen.length;
    } catch (e) {
      log('Day book wh sales failed: $e');
      rethrow;
    }
  }

  Future<void> _loadOrders(String date) async {
    _orderCount = 0;
    _orderAmount = 0;
    _orderAdvance = 0;
    try {
      final rows = await _queries.orderRows(date, date);
      for (final r in rows) {
        _orderCount++;
        _orderAmount += _num(r["TotAmt"]);
        _orderAdvance += _num(r["AdvAmt"]);
      }
    } catch (e) {
      log('Day book orders failed: $e');
      rethrow;
    }
  }

  Future<void> _loadCash(String date) async {
    _cashOnHand = 0;
    try {
      _cashOnHand = await _queries.cashBalance(date);
    } catch (e) {
      log('Day book cash failed: $e');
      rethrow;
    }
  }

  // ── Formatting ─────────────────────────────────────────────────────────────

  String _amt(double v) => v.toStringAsFixed(2);
  String _wt(double v) => v.toStringAsFixed(3);

  Color _sideColour(double v) => v < 0 ? _danger : _success;

  // ── Share ──────────────────────────────────────────────────────────────────

  String _summaryMessage() {
    final b = StringBuffer();
    b.writeln("*Day Book — ${DateFormat("dd/MM/yyyy").format(_date)}*");
    b.writeln();
    b.writeln("*Cash*");
    b.writeln("Opening Balance : ${balanceLabel(_openingCash)}");
    b.writeln("Received : ${_amt(_cashReceived)}");
    b.writeln("Paid : ${_amt(_cashPaid)}");
    b.writeln("Cash on Hand : ${balanceLabel(_cashOnHand)}");
    b.writeln();
    b.writeln("*Sales*");
    b.writeln("Bills : $_salesBills");
    b.writeln("Amount : ${_amt(_salesAmount)}");
    b.writeln("Outstanding : ${_amt(_salesOutstanding)}");
    b.writeln("Net Wt : ${_wt(_salesWeight)}");
    b.writeln("Gold : ${_wt(_salesMetal.gold)}  Silver : ${_wt(_salesMetal.silver)}");
    b.writeln();
    b.writeln("*Purchases*");
    b.writeln("Bills : ${_purchases.bills}");
    b.writeln("Pcs : ${_purchases.pcs.toStringAsFixed(0)}");
    b.writeln(
        "Gold : ${_wt(_purchases.weights.gold)}  Silver : ${_wt(_purchases.weights.silver)}");
    b.writeln("Old Gold Amount : ${_amt(_oldGoldAmount)}");
    b.writeln(
        "Old Gold Wt : ${_wt(_purchases.oldGoldWeights.gold)}  Old Silver Wt : ${_wt(_purchases.oldGoldWeights.silver)}");
    b.writeln();
    b.writeln("*WH / Tour Sales*");
    b.writeln("Bills : $_whBills");
    b.writeln("Amount : ${_amt(_whAmount)}");
    b.writeln("Outstanding : ${_amt(_whOutstanding)}");
    b.writeln();
    b.writeln("*Orders*");
    b.writeln("Count : $_orderCount");
    b.writeln("Amount : ${_amt(_orderAmount)}");
    b.writeln("Advance : ${_amt(_orderAdvance)}");
    b.writeln();
    b.writeln("Total Business : ${_amt(_salesAmount + _whAmount)}");
    if (companyName.trim().isNotEmpty) {
      b.writeln();
      b.writeln(companyName.trim());
    }
    return b.toString();
  }

  Future<void> _share() async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _summaryMessage(),
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: _brand, onPrimary: Colors.white),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _textPrimary),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _date = picked;
      _load();
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(_date, DateTime.now());
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _appBar(isToday),
      body: Consumer<LoadingProvider>(
        builder: (context, loading, _) {
          if (loading.isLoading) {
            return Center(
                child:
                    CircularProgressIndicator(color: _cta, strokeWidth: 2.6));
          }
          return RefreshIndicator(
            color: _cta,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _headlineCard(),
                const SizedBox(height: 14),
                // Cash is its own section, not a line inside Sales: receipts
                // and payments cover every account, not just sale bills, and
                // the owner reads this block as the cash book — opening, in,
                // out, closing.
                _section(
                  title: "Cash",
                  accent: _success,
                  icon: Icons.account_balance_wallet_rounded,
                  rows: [
                    _StatRow(stats: [
                      _Stat("Received", _amt(_cashReceived), color: _success),
                      _Stat("Paid", _amt(_cashPaid), color: _danger),
                    ]),
                    _StatRow(caption: "Balance", stats: [
                      _Stat("Opening", balanceLabel(_openingCash)),
                      _Stat("Cash on Hand", balanceLabel(_cashOnHand),
                          color: _sideColour(_cashOnHand)),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                _section(
                  title: "Sales",
                  accent: _brand,
                  icon: Icons.point_of_sale_rounded,
                  onOpen: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SalesReportScreen(
                              initialFrom: _date, initialTo: _date))),
                  rows: [
                    _StatRow(stats: [
                      _Stat("Bills", '$_salesBills'),
                      _Stat("Amount", _amt(_salesAmount), color: _success),
                      _Stat("Outstanding", _amt(_salesOutstanding),
                          color: _danger),
                    ]),
                    _StatRow(caption: "Weight", stats: [
                      _Stat("Net Wt", _wt(_salesWeight)),
                      _Stat("Gold", _wt(_salesMetal.gold)),
                      _Stat("Silver", _wt(_salesMetal.silver)),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                _section(
                  title: "Purchases",
                  accent: _accentCyan,
                  icon: Icons.shopping_bag_rounded,
                  rows: [
                    _StatRow(caption: "Bought in", stats: [
                      _Stat("Bills", '${_purchases.bills}'),
                      _Stat("Pcs", _purchases.pcs.toStringAsFixed(0)),
                      _Stat("Gold", _wt(_purchases.weights.gold)),
                      _Stat("Silver", _wt(_purchases.weights.silver)),
                    ]),
                    _StatRow(caption: "Old gold", stats: [
                      _Stat("Amount", _amt(_oldGoldAmount), color: _success),
                      _Stat("Gold", _wt(_purchases.oldGoldWeights.gold)),
                      _Stat("Silver", _wt(_purchases.oldGoldWeights.silver)),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                _section(
                  title: "WH / Tour Sales",
                  accent: _accentPurple,
                  icon: Icons.local_shipping_rounded,
                  onOpen: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WhsalesreportScreen(
                              initialFrom: _date, initialTo: _date))),
                  rows: [
                    _StatRow(stats: [
                      _Stat("Bills", '$_whBills'),
                      _Stat("Amount", _amt(_whAmount), color: _success),
                      _Stat("Outstanding", _amt(_whOutstanding),
                          color: _danger),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                _section(
                  title: "Orders",
                  accent: _accentAmber,
                  icon: Icons.assignment_rounded,
                  onOpen: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SalesOrderReportScreen(
                              initialFrom: _date, initialTo: _date))),
                  rows: [
                    _StatRow(stats: [
                      _Stat("Orders", '$_orderCount'),
                      _Stat("Amount", _amt(_orderAmount)),
                      _Stat("Advance", _amt(_orderAdvance), color: _success),
                    ]),
                  ],
                ),
                if (_loadFailed) ...[
                  const SizedBox(height: 14),
                  _failureNote(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _appBar(bool isToday) {
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
                Text("Day Book",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(
                    isToday
                        ? "Today · ${DateFormat("dd/MM/yyyy").format(_date)}"
                        : DateFormat("dd/MM/yyyy").format(_date),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          IconButton(
            tooltip: "Change date",
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded,
                color: Colors.white, size: 19),
          ),
          IconButton(
            tooltip: "Share summary",
            onPressed: _share,
            icon: const Icon(Icons.ios_share_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// The blue card at the top.
  ///
  /// The big figure is the day's opening cash balance — the number the owner
  /// starts the morning from — with the business done sitting under it.
  /// Outstanding used to be in the stat row and has gone: on this card it read
  /// as part of the business done, when it is money not yet received. It stays
  /// in red inside each sales section, next to the bills it belongs to.
  Widget _headlineCard() {
    final total = _salesAmount + _whAmount;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cta, Color.lerp(_cta, const Color(0xFF0D47A1), 0.35)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Opening balance",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(balanceLabel(_openingCash),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined,
                    size: 15, color: Colors.white.withValues(alpha: 0.9)),
                const SizedBox(width: 7),
                Text("Total business",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9))),
                const Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_amt(total),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _headlineStat(
                      "Sale bills", '${_salesBills + _whBills}')),
              Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.25)),
              Expanded(
                  child: _headlineStat(
                      "Purchase bills", '${_purchases.bills}')),
              Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.25)),
              Expanded(child: _headlineStat("Orders", '$_orderCount')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headlineStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
      ],
    );
  }

  /// A white card: heading, then one or more rows of figures.
  ///
  /// [onOpen] is optional because not every section has a detail report
  /// behind it yet — Purchases does not — and an arrow that leads nowhere is
  /// worse than no arrow.
  Widget _section({
    required String title,
    required Color accent,
    required IconData icon,
    required List<_StatRow> rows,
    VoidCallback? onOpen,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hairline),
      ),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary)),
              ),
              if (onOpen != null)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: _hairline),
              const SizedBox(height: 10),
            ],
            if (rows[i].caption != null) ...[
              Text(rows[i].caption!.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: accent)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                for (var j = 0; j < rows[i].stats.length; j++) ...[
                  if (j > 0) Container(width: 1, height: 30, color: _hairline),
                  Expanded(child: _statCell(rows[i].stats[j])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCell(_Stat s) {
    return Column(
      children: [
        Text(s.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary)),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(s.value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: s.color ?? _textPrimary)),
        ),
      ],
    );
  }

  Widget _failureNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 17, color: _danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                "Some figures could not be loaded, so totals may be incomplete. Pull down to retry.",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final Color? color;

  const _Stat(this.label, this.value, {this.color});
}

/// One line of figures inside a section, with an optional small heading
/// above it ("Weight", "Cash", "Old gold").
class _StatRow {
  final String? caption;
  final List<_Stat> stats;

  const _StatRow({this.caption, required this.stats});
}
