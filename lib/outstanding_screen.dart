import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/ledgerZoomingReport.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/report_queries.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

enum _SortMode { amount, name }

/// Accounts that owe money, biggest first, with one-tap reminders.
///
/// A debit balance means the customer owes us: the ledger computes the account
/// balance as SUM(CR_AMT - DR_AMT), so anything below zero is outstanding.
///
/// Restricted to the party account groups — see [_partyGroups] — so bank,
/// cash-on-hand and other control accounts never appear here.
class OutstandingScreen extends StatefulWidget {
  const OutstandingScreen({super.key});

  @override
  State<OutstandingScreen> createState() => _OutstandingScreenState();
}

class _OutstandingScreenState extends State<OutstandingScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _hairline = Color(0xFFEEF2F6);

  Color get _cta => _brand;

  final sqlConnection = SqlConnection.getInstance();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _all = [];
  List<dynamic> _visible = [];
  _SortMode _sort = _SortMode.amount;

  String co_code = "";
  String lc_code = "";
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
    companyName = provider.co_name;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    loadingProvider.startLoading();
    setState(() {});
    try {
      final today = DateFormat("MM/dd/yyyy").format(DateTime.now());
      List<dynamic> rows;

      rows = await ReportQueries(coCode: co_code, lcCode: lc_code, year: '')
          .outstandingRows(today);

      _all = rows;
      _applyFilters();
    } catch (e) {
      log('Error loading outstanding: $e');
      _all = [];
      _visible = [];
      if (mounted) {
        showAppToast(context, "Could not load outstanding. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  void _applyFilters() {
    final term = _searchController.text.trim().toLowerCase();
    final list = _all.where((r) {
      if (term.isEmpty) return true;
      final name = '${r["AC_NAME"] ?? ''}'.toLowerCase();
      final mobile = '${r["AC_MOBILE"] ?? ''}';
      final city = '${r["AC_CITY"] ?? ''}'.toLowerCase();
      return name.contains(term) ||
          mobile.contains(term) ||
          city.contains(term);
    }).toList();

    list.sort((a, b) => _sort == _SortMode.amount
        ? _num(b["DrAmt"]).compareTo(_num(a["DrAmt"]))
        : '${a["AC_NAME"] ?? ''}'
            .toLowerCase()
            .compareTo('${b["AC_NAME"] ?? ''}'.toLowerCase()));
    _visible = list;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

  String _fmt(dynamic v, int d) => _num(v).toStringAsFixed(d);

  String _mobile(dynamic d) => '${d["AC_MOBILE"] ?? ''}'.trim();

  double get _totalOutstanding =>
      _visible.fold(0.0, (sum, r) => sum + _num(r["DrAmt"]));

  /// Metal owed, totalled across the parties on screen.
  ///
  /// A party can owe money, gold, silver or any mix of the three, so the
  /// banner reports all three rather than money alone — the amount figure on
  /// its own understated what was actually outstanding.
  double get _totalGold =>
      _visible.fold(0.0, (sum, r) => sum + _num(r["DrGold"]));

  double get _totalSilver =>
      _visible.fold(0.0, (sum, r) => sum + _num(r["DrSilver"]));

  String _reminderMessage(dynamic d) {
    final buffer = StringBuffer();
    buffer.writeln("Dear ${'${d["AC_NAME"] ?? ''}'.trim()},");
    buffer.writeln();
    buffer.writeln(
        "This is a gentle reminder regarding your pending balance with us.");
    buffer.writeln();
    buffer.writeln("Outstanding Amount : ${_fmt(d["DrAmt"], 2)}");
    if (_num(d["DrGold"]) > 0) {
      buffer.writeln("Gold : ${_fmt(d["DrGold"], 3)} gm");
    }
    if (_num(d["DrSilver"]) > 0) {
      buffer.writeln("Silver : ${_fmt(d["DrSilver"], 3)} gm");
    }
    buffer.writeln();
    buffer.writeln("Kindly arrange the payment at your convenience.");
    if (companyName.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln("Regards,");
      buffer.writeln(companyName.trim());
    }
    return buffer.toString();
  }

  void _toast(String m) {
    if (mounted) showAppToast(context, m);
  }

  Future<void> _sendWhatsApp(dynamic d) async {
    final mobile = _mobile(d);
    if (mobile.isEmpty) {
      _toast("No mobile number for this account");
      return;
    }
    try {
      final link =
          WhatsAppUnilink(phoneNumber: "+91$mobile", text: _reminderMessage(d));
      final ok =
          await launchUrlString('$link', mode: LaunchMode.externalApplication);
      if (!ok) _toast("WhatsApp is not installed");
    } catch (_) {
      _toast("Unable to open WhatsApp");
    }
  }

  Future<void> _makeCall(dynamic d) async {
    final mobile = _mobile(d);
    if (mobile.isEmpty) {
      _toast("No mobile number for this account");
      return;
    }
    try {
      final ok = await launchUrlString("tel:+91$mobile");
      if (!ok) _toast("Unable to start the call");
    } catch (_) {
      _toast("Unable to start the call");
    }
  }

  Future<void> _sendSms(dynamic d) async {
    final mobile = _mobile(d);
    if (mobile.isEmpty) {
      _toast("No mobile number for this account");
      return;
    }
    final body = Uri.encodeComponent(_reminderMessage(d));
    final url = Platform.isIOS
        ? "sms:+91$mobile&body=$body"
        : "sms:+91$mobile?body=$body";
    try {
      final ok = await launchUrlString(url);
      if (!ok) _toast("Unable to open Messages");
    } catch (_) {
      _toast("Unable to open Messages");
    }
  }

  Future<void> _share(dynamic d) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _reminderMessage(d),
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
          Expanded(
            child: Consumer<LoadingProvider>(
              builder: (context, loading, _) {
                if (loading.isLoading) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: _cta, strokeWidth: 2.6));
                }
                if (_visible.isEmpty) return _emptyState();
                return RefreshIndicator(
                  color: _cta,
                  onRefresh: _load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: _visible.length + 1,
                    itemBuilder: (context, i) => i == 0
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _summaryBanner(),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _card(_visible[i - 1]),
                          ),
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
                Text("Outstanding",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text("As on ${DateFormat("dd/MM/yyyy").format(DateTime.now())}",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          IconButton(
            tooltip:
                _sort == _SortMode.amount ? "Sort by name" : "Sort by amount",
            onPressed: () {
              _sort =
                  _sort == _SortMode.amount ? _SortMode.name : _SortMode.amount;
              _applyFilters();
              setState(() {});
            },
            icon: Icon(
                _sort == _SortMode.amount
                    ? Icons.sort_rounded
                    : Icons.sort_by_alpha_rounded,
                color: Colors.white,
                size: 21),
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
          hintText: "Search name, mobile or city",
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

  Widget _summaryBanner() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total outstanding",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9))),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(_totalOutstanding.toStringAsFixed(2),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    "${_visible.length} ${_visible.length == 1 ? 'party' : 'parties'}",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
          // Only shown when metal is actually owed, so a shop that deals only
          // in cash is not given two permanent "0.000 gm" readings.
          if (_totalGold > 0 || _totalSilver > 0) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(child: _metalTotal("Gold", _totalGold)),
                Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.25)),
                Expanded(child: _metalTotal("Silver", _totalSilver)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metalTotal(String label, double grams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85))),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text("${grams.toStringAsFixed(3)} gm",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _card(dynamic d) {
    final gold = _num(d["DrGold"]);
    final silver = _num(d["DrSilver"]);
    final name = '${d["AC_NAME"] ?? ''}'.trim();
    final city = '${d["AC_CITY"] ?? ''}'.trim();

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? '-' : name,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 2,
                        children: [
                          _meta(Icons.phone_rounded, _mobile(d)),
                          _meta(Icons.location_on_rounded, city),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("OUTSTANDING",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: _textSecondary)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_fmt(d["DrAmt"], 2),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: _danger)),
                    ),
                  ],
                ),
              ],
            ),
            if (gold > 0 || silver > 0) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (gold > 0) _metalChip("Gold", _fmt(gold, 3)),
                  if (silver > 0) _metalChip("Silver", _fmt(silver, 3)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Container(height: 1, color: _hairline),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _action(AppImage.whatsapp, "Remind", () => _sendWhatsApp(d)),
                _action(AppImage.telephone, "Call", () => _makeCall(d)),
                _action(AppImage.chat, "Message", () => _sendSms(d)),
                _action(AppImage.share, "Share", () => _share(d)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Ledgerzoomingreport(
                      name: name,
                      acCode: '${d["AC_CODE"] ?? ''}',
                    ),
                  ),
                ),
                icon: Icon(Icons.receipt_long_rounded, size: 17, color: _cta),
                label: Text("View ledger",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _cta)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _textSecondary),
        const SizedBox(width: 4),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: _textSecondary)),
      ],
    );
  }

  Widget _metalChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text("$label  $value gm",
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary)),
    );
  }

  Widget _action(String image, String label, VoidCallback onTap) {
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
            child: Icon(Icons.verified_rounded, color: _cta, size: 34),
          ),
          const SizedBox(height: 16),
          Text("Nothing outstanding",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text("No party account currently carries a debit balance",
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
