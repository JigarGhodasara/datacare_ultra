import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:DataCareUltra/dailyRate_screen.dart';
import 'package:DataCareUltra/ledgerReport_screen.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/phoneBook_screen.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/qrCode_screen.dart';
import 'package:DataCareUltra/reminder_screen.dart';
import 'package:DataCareUltra/salesOrderReport_screen.dart';
import 'package:DataCareUltra/salesReport_screen.dart';
import 'package:DataCareUltra/stockReport_screen.dart';
import 'package:DataCareUltra/tagEstimate_screen.dart';
import 'package:DataCareUltra/tagImage_screen.dart';
import 'package:DataCareUltra/utils/cashonhand.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/ratebox_screen.dart';
import 'package:DataCareUltra/whSalesReport_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardScreen
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── Design tokens ─────────────────────────────────────────────────────────
  static const Color _brand       = Color(0xFF1565C0);
  static const Color _brandDark   = Color(0xFF0D47A1);
  static const Color _brandLight  = Color(0xFF1976D2);
  static const Color _pageBg      = Color(0xFFEEF2F7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border      = Color(0xFFCBD5E1);

  // Accent palette for report tiles
  static const Color _accentPurple = Color(0xFF7C3AED);
  static const Color _accentGreen  = Color(0xFF059669);
  static const Color _accentAmber  = Color(0xFFD97706);
  static const Color _accentCyan   = Color(0xFF0891B2);
  static const Color _accentRed    = Color(0xFFDC2626);

  Color get _ctaFill => AppColor.PRIMARY_COLOR ?? _brand;

  // ── State ─────────────────────────────────────────────────────────────────
  final sqlConnection = SqlConnection.getInstance();
  String todayGoldRate    = '';
  String todaySilverRate  = '';
  String cashOnHandAmount = '';

  /// Legacy list kept for compatibility (not rendered in current build).
  List report = [
    {"name": "Ledger Report", "image": AppImage.notebook},
    {"name": "Stock Report",  "image": AppImage.databaseGif},
    {"name": "Sales Report",  "image": AppImage.statistics},
    {"name": "Tag Image",     "image": AppImage.notebook},
    {"name": "PhoneBook",     "image": AppImage.contactBook},
    {"name": "Estimate",      "image": AppImage.costBook},
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    getGoldSilverRate();
    getHdd();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUSINESS LOGIC  –  UNCHANGED
  // ═══════════════════════════════════════════════════════════════════════════

  void getGoldSilverRate() async {
    String co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    String lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    if (Platform.isAndroid) {
      dynamic result = await sqlConnection.queryDatabase(
          "SELECT FINE_GL_RATE,FINE_SL_RATE,A.VCH_DATE FROM RATE_MAST AS A INNER JOIN GROUP_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.GR_CODE = B.GR_CODE WHERE A.CO_CODE = '" +
              co_code +
              "' AND A.LC_CODE = '" +
              lc_code +
              "' AND A.VCH_DATE <= '" +
              DateFormat("MM/dd/yyyy").format(DateTime.now()) +
              "' AND B.RATE_DISPLAY = 'Y' GROUP BY FINE_GL_RATE,FINE_SL_RATE,A.VCH_DATE ORDER BY A.VCH_DATE DESC ");
      print("result for rate $result");
      if (jsonDecode(result).length != 0) {
        todayGoldRate   = jsonDecode(result)[0]['FINE_GL_RATE'].toString();
        todaySilverRate = jsonDecode(result)[0]['FINE_SL_RATE'].toString();
      }
      dynamic resultOfweb = await sqlConnection.queryDatabase(
          "SELECT WEB_IMAGE,WEB_PATH FROM CO_SET_NEW WHERE CO_CODE ='" +
              co_code +
              "' ");
      print("resultofWeb $resultOfweb");
      print("resultofWeb ${jsonDecode(resultOfweb)[0]["WEB_IMAGE"]}");
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeWebImage(jsonDecode(resultOfweb)[0]["WEB_IMAGE"]);
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeWebPath(jsonDecode(resultOfweb)[0]["WEB_PATH"]);
      dynamic rateSetting = await sqlConnection.queryDatabase(
          "SELECT SL_AMT_TYPE FROM CO_SET WHERE CO_CODE ='" + co_code + "' ");
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeAmountType(jsonDecode(rateSetting)[0]["SL_AMT_TYPE"]);
      String cashOnHandQuery =
          "Select Sum(A.CR_AMT-A.DR_AMT) as BalAmt FROM AC_DATA AS A LEFT JOIN AC_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.AC_CODE = B.AC_CODE WHERE A.CO_CODE = '$co_code' and A.LC_CODE = '$lc_code'  AND A.AC_CODE = '00001' and VCH_DATE <= '${DateFormat("MM/dd/yyyy").format(DateTime.now())}'";
      dynamic resultOfCashonHand =
          await sqlConnection.queryDatabase(cashOnHandQuery);
      log("Query $resultOfCashonHand");
      cashOnHandAmount =
          jsonDecode(resultOfCashonHand)[0]['BalAmt'].toString();
      print(
          "RateSetting result ${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).amountType}");
    } else {
      dynamic result = await MySQLService().getRates(
          co_code, lc_code, DateFormat("MM/dd/yyyy").format(DateTime.now()));
      print("Here value $result");
      if (result[0].length != 0) {
        todayGoldRate   = result[0][0]['FINE_GL_RATE'].toString();
        todaySilverRate = result[0][0]['FINE_SL_RATE'].toString();
      }
      dynamic image = await MySQLService().getForImage(co_code);
      print("IMagesss $image");
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeWebImage(image[0][0]["WEB_IMAGE"]);
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeWebPath(image[0][0]["WEB_PATH"]);
      dynamic rateSetting = await MySQLService().getRateSetting(co_code);
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeAmountType(rateSetting[0][0]["SL_AMT_TYPE"]);
      dynamic cashonhandResult = await MySQLService().getCashOnHand(
          co_code,
          lc_code,
          DateFormat("MM/dd/yyyy").format(DateTime.now()).toString());
      cashOnHandAmount = cashonhandResult[0][0]['BalAmt'].toString();
    }
    setState(() {});
  }

  void getHdd() async {
    if (Platform.isAndroid) {
      dynamic result =
          await sqlConnection.queryDatabase("SELECT * FROM HDD_MAST");
      print("HDD NO $result");
      if (jsonDecode(result).length != 0) {
        print("hdd No ${jsonDecode(result)[0]['REF_NO']}");
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .changedHdd(jsonDecode(result)[0]['REF_NO']);
      }
    } else {
      dynamic result =
          await MySQLService().getHdd("SELECT * FROM HDD_MAST");
      if (result[0].length != 0) {
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .changedHdd(result[0][0]['REF_NO']);
      }
      print("Here value $result");
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY WIDGET  –  Kept for compatibility (not called in build)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget rateContainer(
      {required String title, required String rate, required image}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DailyrateScreen()));
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_ctaFill, _ctaFill.withValues(alpha: 0.82)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _ctaFill.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.goldenColor.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                      child: Image.asset(image, height: 48, width: 48)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(title,
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(rate,
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Image.asset(AppImage.goldChart,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 56,
                      width: 56),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM UI HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Top navigation bar ──────────────────────────────────────────────────────
  Widget _buildTopBar(String coName, double w) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // App logo
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.24), width: 1),
            ),
            child: Image.asset(AppImage.appLogo, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          // Company name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DataCare Ultra',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  coName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: w < 360 ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Date chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22), width: 1),
            ),
            child: Text(
              DateFormat('dd MMM').format(DateTime.now()),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome / hero card ──────────────────────────────────────────────────────
  Widget _buildWelcomeCard(String coName) {
    final now  = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final dayLabel = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _brand.withValues(alpha: 0.22),
              blurRadius: 36,
              offset: const Offset(0, 16),
              spreadRadius: -8,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: text content ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Live session" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'LIVE SESSION',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF16A34A),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),
                  // Greeting (gradient text)
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (b) => LinearGradient(
                      colors: [_textPrimary, _ctaFill],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(b),
                    child: Text(
                      greeting,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Date
                  Text(
                    dayLabel,
                    style: GoogleFonts.plusJakartaSans(
                      color: _textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // ── Right: brand icon ──────────────────────────────────────────
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_ctaFill, _brandDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ctaFill.withValues(alpha: 0.38),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(AppImage.appLogo, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar
          Container(
            width: 4,
            height: 40,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_ctaFill, _ctaFill.withValues(alpha: 0.25)],
              ),
            ),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Individual quick-action tile ────────────────────────────────────────────
  Widget _premiumActionTile({
    required String title,
    required String image,
    required Color accent,
    required GestureTapCallback ontap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: ontap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent,
                        Color.lerp(accent, Colors.black, 0.22)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.36),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Image.asset(image,
                      color: Colors.white, fit: BoxFit.contain),
                ),
                const SizedBox(width: 11),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Tap to open',
                        style: GoogleFonts.plusJakartaSans(
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.08),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Quick-actions 2×2 grid ──────────────────────────────────────────────────
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Row 1: Scan  |  Tag Estimate
          Row(
            children: [
              Expanded(
                child: _premiumActionTile(
                  title: 'Scan',
                  image: AppImage.qr,
                  accent: _ctaFill,
                  ontap: () {
                    if (Provider.of<CommonCompanyYearSelectionProvider>(
                                context,
                                listen: false)
                            .sType ==
                        "B" ||
                        Provider.of<CommonCompanyYearSelectionProvider>(
                                context,
                                listen: false)
                            .sType ==
                            "S") {
                      showUpgradeRequiredDialog(context);
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  QRViewExample(isFromTagScreen: false)));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _premiumActionTile(
                  title: 'Tag Estimate',
                  image: AppImage.tag,
                  accent: _accentPurple,
                  ontap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TagestimateScreen()));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Reminder  |  PhoneBook
          Row(
            children: [
              Expanded(
                child: _premiumActionTile(
                  title: 'Reminder',
                  image: AppImage.bell,
                  accent: _accentAmber,
                  ontap: () {
                    if (Provider.of<CommonCompanyYearSelectionProvider>(
                                context,
                                listen: false)
                            .sType ==
                        "E" ||
                        Provider.of<CommonCompanyYearSelectionProvider>(
                                context,
                                listen: false)
                            .sType ==
                            "A") {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ReminderScreen()));
                    } else if (Provider.of<CommonCompanyYearSelectionProvider>(
                            context,
                            listen: false)
                        .sType !=
                        "") {
                      showUpgradeRequiredDialog(context);
                    } else {
                      if (Provider.of<CommonCompanyYearSelectionProvider>(
                                  context,
                                  listen: false)
                              .dType ==
                          "E" ||
                          Provider.of<CommonCompanyYearSelectionProvider>(
                                  context,
                                  listen: false)
                              .dType ==
                              "A") {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ReminderScreen()));
                      } else {
                        showUpgradeRequiredDialog(context);
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _premiumActionTile(
                  title: 'PhoneBook',
                  image: AppImage.phonebook,
                  accent: _accentGreen,
                  ontap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PhonebookScreen()));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Individual report tile (full-width with coloured left border) ───────────
  Widget _premiumReportTile({
    required String icon,
    required String title,
    required String subtitle,
    required Color accent,
    required GestureTapCallback ontap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: ontap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border(
                left: BorderSide(color: accent, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Coloured icon box
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.black, 0.2)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(icon,
                        color: Colors.white, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 14),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            color: _textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow pill
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.10),
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reports column ──────────────────────────────────────────────────────────
  Widget _buildReportsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Ledger
          _premiumReportTile(
            icon: AppImage.ledger,
            title: 'Ledger Report',
            subtitle: 'Account balances & transactions',
            accent: _ctaFill,
            ontap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const LedgerreportScreen()));
            },
          ),
          // Stock
          _premiumReportTile(
            icon: AppImage.stock,
            title: 'Stock Report',
            subtitle: 'Inventory & stock movement',
            accent: _accentPurple,
            ontap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const StockreportScreen()));
            },
          ),
          // Sales
          _premiumReportTile(
            icon: AppImage.sales,
            title: 'Sales Report',
            subtitle: 'Sales performance & analytics',
            accent: _accentGreen,
            ontap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SalesReportScreen()));
            },
          ),
          // Tag Image
          _premiumReportTile(
            icon: AppImage.tag,
            title: 'Tag Image',
            subtitle: 'Product tag images & management',
            accent: _accentAmber,
            ontap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TagimageScreen()));
            },
          ),
          // WH Sales
          _premiumReportTile(
            icon: AppImage.whSales,
            title: 'WH Sales Report',
            subtitle: 'Wholesale sales & distribution',
            accent: _accentCyan,
            ontap: () {
              if (Provider.of<CommonCompanyYearSelectionProvider>(
                          context,
                          listen: false)
                      .sType ==
                  "B" ||
                  Provider.of<CommonCompanyYearSelectionProvider>(
                          context,
                          listen: false)
                      .sType ==
                      "S") {
                showUpgradeRequiredDialog(context);
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            WhsalesreportScreen()));
              }
            },
          ),
          // Sales Order
          _premiumReportTile(
            icon: AppImage.salesOrder,
            title: 'Sales Order Report',
            subtitle: 'Pending & completed orders',
            accent: _accentRed,
            ontap: () {
              if (Provider.of<CommonCompanyYearSelectionProvider>(
                          context,
                          listen: false)
                      .sType ==
                  "B" ||
                  Provider.of<CommonCompanyYearSelectionProvider>(
                          context,
                          listen: false)
                      .sType ==
                      "S") {
                showUpgradeRequiredDialog(context);
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SalesOrderReportScreen()));
              }
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIXED HEADER  –  blue zone + orbs + top bar + welcome card (never scrolls)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFixedHeader(String coName, double w) {
    return Container(
      // Blue gradient fills the entire header block
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFF1976D2),
          ],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: SafeArea(
        // Only respect top safe-area (status bar); let body handle the bottom
        bottom: false,
        child: Stack(
          // Allow orbs to bleed slightly outside the stack bounds
          clipBehavior: Clip.none,
          children: [
            // ── Orb 1 (top-right) ────────────────────────────────────────
            Positioned(
              right: -w * 0.14,
              top: 6,
              child: IgnorePointer(
                child: Container(
                  width: w * 0.58,
                  height: w * 0.58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
            ),
            // ── Orb 2 (left-mid) ─────────────────────────────────────────
            Positioned(
              left: -w * 0.22,
              top: 72,
              child: IgnorePointer(
                child: Container(
                  width: w * 0.42,
                  height: w * 0.42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.035),
                  ),
                ),
              ),
            ),
            // ── Visible content (sits on top of orbs) ────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(coName, w),
                _buildWelcomeCard(coName),
                const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final w      = MediaQuery.sizeOf(context).width;
    final coName = Provider.of<CommonCompanyYearSelectionProvider>(
            context, listen: false)
        .co_name;
    final sType  = Provider.of<CommonCompanyYearSelectionProvider>(
            context, listen: false)
        .sType;

    return Scaffold(
      backgroundColor: _pageBg,
      // ── Outer Column: fixed header on top, scrollable body below ──────────
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ① PINNED HEADER — stays put while user scrolls
          _buildFixedHeader(coName, w),

          // ② SCROLLABLE BODY — only this part moves
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // ── Today's Rates ────────────────────────────────────────
                  _buildSectionHeader(
                    "Today's Rates",
                    'Gold & Silver reference for your session',
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedRateBox(
                      todayGoldRate: todayGoldRate,
                      todaySilverRate: todaySilverRate,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Quick Actions ─────────────────────────────────────────
                  _buildSectionHeader(
                    'Quick Actions',
                    'Shortcuts to your daily tools',
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionsGrid(context),

                  const SizedBox(height: 18),

                  // ── Cash on Hand (conditional) ────────────────────────────
                  if (sType != "B" && sType != "S") ...[
                    CashOnHandBox(cashAmount: cashOnHandAmount),
                    const SizedBox(height: 18),
                  ],

                  // ── Reports ───────────────────────────────────────────────
                  _buildSectionHeader(
                    'Reports',
                    'Financial & inventory insights',
                  ),
                  const SizedBox(height: 12),
                  _buildReportsList(context),

                  SizedBox(
                    height: math.max(
                        28, MediaQuery.of(context).padding.bottom + 20),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showUpgradeRequiredDialog  –  UNCHANGED
// ─────────────────────────────────────────────────────────────────────────────

void showUpgradeRequiredDialog(BuildContext context) {
  final cta = AppColor.PRIMARY_COLOR ?? const Color(0xFF1565C0);
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Upgrade required',
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return Transform.scale(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ).value,
        child: Opacity(
          opacity: animation.value,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Upgrade required',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: const Color(0xFF0F172A),
              ),
            ),
            content: Text(
              'This feature is only available in a higher version of the software. '
              'Please upgrade to access this functionality.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.45,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
