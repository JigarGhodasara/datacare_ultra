import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DailyrateScreen extends StatefulWidget {
  const DailyrateScreen({super.key});

  @override
  State<DailyrateScreen> createState() => _DailyrateScreenState();
}

class _DailyrateScreenState extends State<DailyrateScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _pageBg = Color(0xFFF8FAFC);

  Color get _cta => _brand;

  final sqlConnection = SqlConnection.getInstance();
  late LoadingProvider loadingProvider;
  String co_code = "";
  String lc_code = "";
  String year = "";
  String companyName = "";
  List<dynamic> dailyRate = [];

  /// Shown to the user, in the Indian day-first order.
  String get _today => DateFormat("dd/MM/yyyy").format(DateTime.now());

  /// Sent to SQL Server, which reads a date literal month-first by default.
  ///
  /// These must not be the same string. Passing `dd/MM/yyyy` meant that from
  /// the 13th of any month the literal had an impossible month number, so
  /// RATE_MAST matched nothing and the screen showed "No rates found" — every
  /// other report in the app already sends `MM/dd/yyyy`.
  String get _todaySql => DateFormat("MM/dd/yyyy").format(DateTime.now());

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
      getWHSalesReportData();
    });
  }

  Future<void> getWHSalesReportData() async {
    loadingProvider.startLoading();
    setState(() {});
    try {
      if (Platform.isAndroid) {
        var query =
            "SELECT A.GR_CODE,B.GR_NAME,A.GR_TOUCH,A.GR_RATE,A.GR_TAX_RATE,A.GR_TAX_PRC FROM RATE_MAST AS A "
            "LEFT JOIN GROUP_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.GR_CODE = B.GR_CODE "
            "WHERE A.CO_CODE='$co_code' AND A.LC_CODE='$lc_code' AND VCH_DATE = '$_todaySql'\n";
        log("Query $query");
        dynamic dRate = await sqlConnection.queryDatabase(query);
        dailyRate = jsonDecode(dRate);
      } else {
        dynamic result =
            await MySQLService().getDailyRates(co_code, lc_code, _todaySql);
        dailyRate = result[0];
      }
    } catch (e) {
      log('Error fetching daily rates: $e');
      dailyRate = [];
      if (mounted) _toast("Could not load rates. Please try again.");
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: _textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _fmt(dynamic value, int decimals) {
    if (value == null) return '-';
    final parsed = num.tryParse(value.toString());
    if (parsed == null) return value.toString().trim();
    return parsed.toStringAsFixed(decimals);
  }

  String _text(dynamic value) => '${value ?? ''}'.trim();

  String _rateMessage(dynamic data) {
    final buffer = StringBuffer();
    buffer.writeln("*Today's Rate*");
    buffer.writeln("Date : $_today");
    buffer.writeln();
    final name = _text(data['GR_NAME']);
    final code = _text(data['GR_CODE']);
    buffer.writeln(
        "*${name.isEmpty ? code : name}*${code.isEmpty ? '' : ' ($code)'}");
    buffer.writeln("Rate : ${_fmt(data['GR_RATE'], 2)}");
    buffer.writeln("Touch % : ${_fmt(data['GR_TOUCH'], 2)}");
    buffer.writeln("Tax % : ${_fmt(data['GR_TAX_PRC'], 2)}");
    buffer.writeln("Tax Rate : ${_fmt(data['GR_TAX_RATE'], 2)}");
    if (companyName.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(companyName.trim());
    }
    return buffer.toString();
  }

  String _allRatesMessage() {
    final buffer = StringBuffer();
    buffer.writeln("*Today's Rate*");
    buffer.writeln("Date : $_today");
    for (final data in dailyRate) {
      final name = _text(data['GR_NAME']);
      final code = _text(data['GR_CODE']);
      buffer.writeln();
      buffer.writeln(
          "*${name.isEmpty ? code : name}*${code.isEmpty ? '' : ' ($code)'}");
      buffer.writeln("Rate : ${_fmt(data['GR_RATE'], 2)}");
      buffer.writeln("Touch % : ${_fmt(data['GR_TOUCH'], 2)}");
      buffer.writeln("Tax % : ${_fmt(data['GR_TAX_PRC'], 2)}");
      buffer.writeln("Tax Rate : ${_fmt(data['GR_TAX_RATE'], 2)}");
    }
    if (companyName.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(companyName.trim());
    }
    return buffer.toString();
  }

  Future<void> _sendWhatsApp(String message) async {
    // No recipient stored against a rate, so open WhatsApp's contact picker.
    final url = "https://wa.me/?text=${Uri.encodeComponent(message)}";
    try {
      final launched =
          await launchUrlString(url, mode: LaunchMode.externalApplication);
      if (!launched) _toast("WhatsApp is not installed");
    } catch (_) {
      _toast("Unable to open WhatsApp");
    }
  }

  Future<void> _sendSms(String message) async {
    final body = Uri.encodeComponent(message);
    final url = Platform.isIOS ? "sms:&body=$body" : "sms:?body=$body";
    try {
      final launched = await launchUrlString(url);
      if (!launched) _toast("Unable to open Messages");
    } catch (_) {
      _toast("Unable to open Messages");
    }
  }

  Future<void> _shareMessage(String message) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      message,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _copyMessage(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    _toast("Rate copied to clipboard");
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

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
          return RefreshIndicator(
            color: _cta,
            onRefresh: getWHSalesReportData,
            child: dailyRate.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.18),
                      _emptyState(),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    itemCount: dailyRate.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _summaryBanner(),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _rateCard(dailyRate[index - 1]),
                      );
                    },
                  ),
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
                Text("Daily Rate",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(_today,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          if (dailyRate.isNotEmpty)
            IconButton(
              tooltip: "Share all rates",
              onPressed: () => _shareMessage(_allRatesMessage()),
              icon: const Icon(Icons.ios_share_rounded,
                  color: Colors.white, size: 21),
            ),
          const SizedBox(width: 4),
        ],
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
        boxShadow: [
          BoxShadow(
            color: _cta.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(AppImage.gold, scale: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Rates for today",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 2),
                Text(
                    "${dailyRate.length} group${dailyRate.length == 1 ? '' : 's'} listed",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _copyMessage(_allRatesMessage()),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.copy_rounded, color: Colors.white, size: 19),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateCard(dynamic data) {
    final name = _text(data['GR_NAME']);
    final code = _text(data['GR_CODE']);
    final message = _rateMessage(data);

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
                      Text(name.isEmpty ? (code.isEmpty ? '-' : code) : name,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary)),
                      if (code.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _cta.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(code,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: _cta)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("RATE",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: _textSecondary)),
                    const SizedBox(height: 2),
                    Text(_fmt(data['GR_RATE'], 2),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: _cta)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFEEF2F6)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _statTile("Touch %", _fmt(data['GR_TOUCH'], 2))),
                Container(width: 1, height: 34, color: const Color(0xFFEEF2F6)),
                Expanded(
                    child: _statTile("Tax %", _fmt(data['GR_TAX_PRC'], 2))),
                Container(width: 1, height: 34, color: const Color(0xFFEEF2F6)),
                Expanded(
                    child: _statTile("Tax Rate", _fmt(data['GR_TAX_RATE'], 2))),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFEEF2F6)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionChip(
                    image: AppImage.whatsapp,
                    label: "WhatsApp",
                    onTap: () => _sendWhatsApp(message)),
                _actionChip(
                    image: AppImage.chat,
                    label: "Message",
                    onTap: () => _sendSms(message)),
                _actionChip(
                    image: AppImage.share,
                    label: "Share",
                    onTap: () => _shareMessage(message)),
                _actionChip(
                    icon: Icons.copy_rounded,
                    label: "Copy",
                    onTap: () => _copyMessage(message)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textSecondary)),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary)),
      ],
    );
  }

  Widget _actionChip({
    String? image,
    IconData? icon,
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
                child: image != null
                    ? Padding(
                        padding: const EdgeInsets.all(9),
                        child: Image.asset(image, fit: BoxFit.contain),
                      )
                    : Icon(icon, size: 18, color: _cta),
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
            child: Icon(Icons.trending_up_rounded, color: _cta, size: 34),
          ),
          const SizedBox(height: 16),
          Text("No rates found",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 4),
          Text("No rate has been entered for $_today",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: getWHSalesReportData,
            icon: Icon(Icons.refresh_rounded, size: 18, color: _cta),
            label: Text("Refresh",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _cta)),
          ),
        ],
      ),
    );
  }
}
