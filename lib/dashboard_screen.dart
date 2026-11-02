import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/dailyRate_screen.dart';
import 'package:DataCareUltra/dayBook_screen.dart';
import 'package:DataCareUltra/graphReports_screen.dart';
import 'package:DataCareUltra/ledgerReport_screen.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/outstanding_screen.dart';
import 'package:DataCareUltra/phoneBook_screen.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/utils/quick_action_grid.dart';
import 'package:DataCareUltra/qrCode_screen.dart';
import 'package:DataCareUltra/reminder_screen.dart';
import 'package:DataCareUltra/salesOrderReport_screen.dart';
import 'package:DataCareUltra/salesReport_screen.dart';
import 'package:DataCareUltra/stockReport_screen.dart';
import 'package:DataCareUltra/tagEstimate_screen.dart';
import 'package:DataCareUltra/tagImage_screen.dart';
import 'package:DataCareUltra/utils/cashonhand.dart';
import 'package:DataCareUltra/tagStockReport_screen.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/edition.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/ratebox_screen.dart';
import 'package:DataCareUltra/whSalesReport_screen.dart';
import 'package:DataCareUltra/whTagEstimate_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardScreen
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── Design tokens ─────────────────────────────────────────────────────────
  // Shared with every report screen so the app reads as one product.
  static const Color _brand = Color(0xFF006EB7);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  // Accent palette for report tiles
  static const Color _accentPurple = Color(0xFF7C3AED);
  static const Color _accentGreen = Color(0xFF059669);
  static const Color _accentAmber = Color(0xFFD97706);
  static const Color _accentCyan = Color(0xFF0891B2);
  static const Color _accentRed = Color(0xFFDC2626);

  static const Color _hairline = Color(0xFFEEF2F6);

  /// Whether the Tag Stock Report appears under Reports. The screen is
  /// finished; it is simply not being offered to customers yet. Set to true
  /// to put the tile back — nothing else needs to change.
  static const bool _showTagStockReport = false;

  Color get _ctaFill => _brand;

  /// One soft, neutral shadow for every raised surface.
  ///
  /// Colour-tinted shadows with a wide blur and no negative spread were
  /// bleeding well past the card and reading as a visible coloured square
  /// behind it. Colour now lives in the fill only; the shadow stays neutral
  /// and pulled in tight so it reads as depth, not as a box.
  static List<BoxShadow> get _cardShadow => [
        BoxShadow(
          color: _textPrimary.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
          spreadRadius: -3,
        ),
      ];

  /// Slightly deeper version for the hero card, same neutral treatment.
  static List<BoxShadow> get _heroShadow => [
        BoxShadow(
          color: _textPrimary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -8,
        ),
      ];

  // ── State ─────────────────────────────────────────────────────────────────
  final sqlConnection = SqlConnection.getInstance();
  String todayGoldRate = '';
  String todaySilverRate = '';
  String cashOnHandAmount = '';

  /// Shown in place of a rate that hasn't loaded, so the card never renders
  /// a blank space that looks like a layout bug.
  String get _goldRate => todayGoldRate.trim().isEmpty ? '—' : todayGoldRate;
  String get _silverRate =>
      todaySilverRate.trim().isEmpty ? '—' : todaySilverRate;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    // One after the other: both query over the same shared SQL connection, so
    // running them together risked the rate box or cash-on-hand coming back
    // empty for no visible reason.
    await getGoldSilverRate();
    await getHdd();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUSINESS LOGIC  –  UNCHANGED
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> getGoldSilverRate() async {
    // Captured before the first await: reading a Provider off `context` after
    // an async gap is unsafe once this screen can be popped mid-request.
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    String co_code = provider.co_code;
    String lc_code = provider.lc_code;
    try {
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
          todayGoldRate = jsonDecode(result)[0]['FINE_GL_RATE'].toString();
          todaySilverRate = jsonDecode(result)[0]['FINE_SL_RATE'].toString();
        }
        dynamic resultOfweb = await sqlConnection.queryDatabase(
            "SELECT WEB_IMAGE,WEB_PATH FROM CO_SET_NEW WHERE CO_CODE ='" +
                co_code +
                "' ");
        print("resultofWeb $resultOfweb");
        print("resultofWeb ${jsonDecode(resultOfweb)[0]["WEB_IMAGE"]}");
        provider.changeWebImage(jsonDecode(resultOfweb)[0]["WEB_IMAGE"]);
        provider.changeWebPath(jsonDecode(resultOfweb)[0]["WEB_PATH"]);
        // Record the host we are actually connected to, so a WEB_PATH that
        // names the shop's own LAN address can be re-pointed at it.
        provider.changeServerHost(await Preffrance().getString(Keys.HOST));
        dynamic rateSetting = await sqlConnection.queryDatabase(
            "SELECT SL_AMT_TYPE FROM CO_SET WHERE CO_CODE ='" + co_code + "' ");
        provider.changeAmountType(jsonDecode(rateSetting)[0]["SL_AMT_TYPE"]);
        String cashOnHandQuery =
            "Select Sum(A.CR_AMT-A.DR_AMT) as BalAmt FROM AC_DATA AS A LEFT JOIN AC_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.AC_CODE = B.AC_CODE WHERE A.CO_CODE = '$co_code' and A.LC_CODE = '$lc_code'  AND A.AC_CODE = '00001' and VCH_DATE <= '${DateFormat("MM/dd/yyyy").format(DateTime.now())}'";
        dynamic resultOfCashonHand =
            await sqlConnection.queryDatabase(cashOnHandQuery);
        log("Query $resultOfCashonHand");
        cashOnHandAmount =
            jsonDecode(resultOfCashonHand)[0]['BalAmt'].toString();
        print("RateSetting result ${provider.amountType}");
      } else {
        dynamic result = await MySQLService().getRates(
            co_code, lc_code, DateFormat("MM/dd/yyyy").format(DateTime.now()));
        print("Here value $result");
        if (result[0].length != 0) {
          todayGoldRate = result[0][0]['FINE_GL_RATE'].toString();
          todaySilverRate = result[0][0]['FINE_SL_RATE'].toString();
        }
        dynamic image = await MySQLService().getForImage(co_code);
        print("IMagesss $image");
        provider.changeWebImage(image[0][0]["WEB_IMAGE"]);
        provider.changeWebPath(image[0][0]["WEB_PATH"]);
        // Record the host we are actually connected to, so a WEB_PATH that
        // names the shop's own LAN address can be re-pointed at it.
        provider.changeServerHost(await Preffrance().getString(Keys.HOST));
        dynamic rateSetting = await MySQLService().getRateSetting(co_code);
        provider.changeAmountType(rateSetting[0][0]["SL_AMT_TYPE"]);
        dynamic cashonhandResult = await MySQLService().getCashOnHand(
            co_code,
            lc_code,
            DateFormat("MM/dd/yyyy").format(DateTime.now()).toString());
        cashOnHandAmount = cashonhandResult[0][0]['BalAmt'].toString();
      }
    } catch (e) {
      log('Error loading dashboard rates: $e');
      if (mounted) {
        showAppToast(context, "Could not load today's rates. Pull to refresh.");
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> getHdd() async {
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    try {
      if (Platform.isAndroid) {
        dynamic result =
            await sqlConnection.queryDatabase("SELECT * FROM HDD_MAST");
        if (jsonDecode(result).length != 0) {
          provider.changedHdd(jsonDecode(result)[0]['REF_NO']);
        }
      } else {
        dynamic result = await MySQLService().getHdd("SELECT * FROM HDD_MAST");
        if (result[0].length != 0) {
          provider.changedHdd(result[0][0]['REF_NO']);
        }
      }
    } catch (e) {
      // Non-fatal: the HDD reference is only used for licensing display.
      log('Error loading HDD reference: $e');
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    final now = DateTime.now();
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
          border: Border.all(color: _hairline),
          boxShadow: _heroShadow,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _hairline),
                boxShadow: _cardShadow,
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
  /// One tile in the Quick Actions grid: icon above its label.
  ///
  /// The icon used to sit beside the label, with "Tap to open" under it and a
  /// chevron after it. Between them those three took around 83 of the 126dp a
  /// half-width tile has on a 360dp phone, leaving the label too little to fit
  /// "Tag Estimate" — so it broke mid-word and made that tile taller than its
  /// neighbour. Stacking gives the label the tile's whole width, and the two
  /// decorations it was competing with said nothing a grid of tappable cards
  /// does not already say.
  ///
  /// Size comes from [quickActionTileWidth] and [quickActionTileHeight], the
  /// same for every tile, so the grid stays square whatever the labels read.
  Widget _premiumActionTile({
    required String title,
    required String image,
    required Color accent,
    required double width,
    required GestureTapCallback ontap,
  }) {
    return SizedBox(
      width: width,
      height: quickActionTileHeight(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: ontap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              // Width named so the height sum in quick_action_grid.dart and
              // the border drawn here cannot drift apart again.
              border: Border.all(
                  color: _hairline, width: kQuickActionBorderWidth),
              boxShadow: _cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: kQuickActionVerticalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: kQuickActionIconSize,
                    height: kQuickActionIconSize,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.black, 0.22)!,
                        ],
                      ),
                    ),
                    child: Image.asset(image,
                        color: Colors.white, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: kQuickActionIconGap),
                  // Two lines are reserved whether or not the label fills
                  // them, so "Scan" and "WH Tag Estimate" are the same height.
                  SizedBox(
                    height: quickActionLabelHeight(),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: kQuickActionLabelLines,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: kQuickActionLabelSize,
                        height: kQuickActionLabelLeading,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Quick-actions grid ──────────────────────────────────────────────────────
  /// Every quick action, in the order they appear.
  ///
  /// They were previously spelled out inside the layout, which is why the
  /// fifth one ended up spanning the full width: there was no pair left to put
  /// it beside. Keeping them as data lets the grid place however many there
  /// are, at whatever column count the screen allows.
  List<({String title, String image, Color accent, GestureTapCallback ontap})>
      _quickActions(BuildContext context) {
    CommonCompanyYearSelectionProvider edition() =>
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);

    void open(Widget screen) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => screen));
    }

    return [
      (
        title: 'Scan',
        image: AppImage.qr,
        accent: _ctaFill,
        ontap: () {
          final sType = edition().sType;
          if (sType == "B" || sType == "S") {
            showUpgradeRequiredDialog(context);
          } else {
            open(QRViewExample(isFromTagScreen: false));
          }
        },
      ),
      (
        title: 'Tag Estimate',
        image: AppImage.tag,
        accent: _accentPurple,
        ontap: () => open(TagestimateScreen()),
      ),
      (
        title: 'Reminder',
        image: AppImage.bell,
        accent: _accentAmber,
        ontap: () {
          // The licence lives on sType when there is one, and falls back to
          // dType only when sType has not been set at all.
          final sType = edition().sType;
          if (sType == "E" || sType == "A") {
            open(ReminderScreen());
          } else if (sType != "") {
            showUpgradeRequiredDialog(context);
          } else {
            final dType = edition().dType;
            if (dType == "E" || dType == "A") {
              open(ReminderScreen());
            } else {
              showUpgradeRequiredDialog(context);
            }
          }
        },
      ),
      (
        title: 'Phone Book',
        image: AppImage.phonebook,
        accent: _accentGreen,
        ontap: () => open(PhonebookScreen()),
      ),
      (
        title: 'WH Tag Estimate',
        image: AppImage.tag,
        accent: _accentCyan,
        ontap: () => open(WhTagestimateScreen()),
      ),
      // Setting the day's rate is the first thing done every morning, and both
      // estimate tiles above price from it. Until now the only way in was
      // tapping the rate display, which gives no hint that it opens anything;
      // that tap still works, this is the one people can find.
      (
        title: 'Daily Rate',
        image: AppImage.gold,
        accent: _accentRed,
        ontap: () => open(const DailyrateScreen()),
      ),
    ];
  }

  /// Quick Actions as a grid of identical tiles, as many across as the screen
  /// takes.
  ///
  /// The old 2 + 2 + 1 arrangement was fixed regardless of the device, so a
  /// narrow phone squeezed the labels until they broke mid-word while a tablet
  /// stretched five cards across half a metre. A [Wrap] of fixed-size tiles
  /// handles both, and leaves any short last row aligned to the left where a
  /// grid's last row belongs — rather than stretching one tile to fill it.
  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = _quickActions(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = quickActionColumns(constraints.maxWidth,
              itemCount: actions.length);
          final width = quickActionTileWidth(constraints.maxWidth, columns);
          return Wrap(
            spacing: kQuickActionGap,
            runSpacing: kQuickActionGap,
            children: [
              for (final action in actions)
                _premiumActionTile(
                  title: action.title,
                  image: action.image,
                  accent: action.accent,
                  width: width,
                  ontap: action.ontap,
                ),
            ],
          );
        },
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
              border: Border.all(color: _hairline),
              boxShadow: _cardShadow,
            ),
            // The accent bar is a clipped child rather than a one-sided
            // Border: BoxDecoration asserts a uniform border whenever a
            // borderRadius is set, so `Border(left: ...)` threw in debug and
            // silently drew an unrounded line in release.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accent),
                    Expanded(
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
                  ],
                ),
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
          // Day Book first: it is the "how did today go" summary an owner
          // opens most, and it links onward into the detailed reports.
          _premiumReportTile(
            icon: AppImage.statistics,
            title: 'Day Book',
            subtitle: "Today's sales, orders & cash at a glance",
            accent: _accentGreen,
            ontap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DayBookScreen()));
            },
          ),
          _premiumReportTile(
            icon: AppImage.goldChart,
            title: 'Graph Reports',
            subtitle: 'Sales trends & stock at a glance',
            accent: _accentPurple,
            ontap: () {
              // Full editions only (E / U / P / A).
              final licence = Provider.of<CommonCompanyYearSelectionProvider>(
                  context,
                  listen: false);
              if (!hasFullEdition(licence.sType, licence.dType)) {
                showUpgradeRequiredDialog(context);
                return;
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GraphReportsScreen()));
            },
          ),
          // Built and working, but held back from the menu until it is
          // switched on by hand — flip [_showTagStockReport].
          if (_showTagStockReport)
            _premiumReportTile(
              icon: AppImage.tag,
              title: 'Tag Stock Report',
              subtitle: 'Tags in, tags out & stock with photos',
              accent: _accentCyan,
              ontap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TagStockReportScreen()));
              },
            ),
          _premiumReportTile(
            icon: AppImage.ledger,
            title: 'Outstanding',
            subtitle: 'Who owes you, with one-tap reminders',
            accent: _accentRed,
            ontap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OutstandingScreen()));
            },
          ),
          _premiumReportTile(
            icon: AppImage.ledger,
            title: 'Ledger Report',
            subtitle: 'Account balances & transactions',
            accent: _ctaFill,
            ontap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LedgerreportScreen()));
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
                      builder: (context) => const StockreportScreen()));
            },
          ),
          // Sales
          _premiumReportTile(
            icon: AppImage.sales,
            title: 'Sales Report',
            subtitle: 'Sales performance & analytics',
            accent: _accentGreen,
            ontap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SalesReportScreen()));
            },
          ),
          // Tag Image
          _premiumReportTile(
            icon: AppImage.tag,
            title: 'Tag Image',
            subtitle: 'Product tag images & management',
            accent: _accentAmber,
            ontap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => TagimageScreen()));
            },
          ),
          // WH Sales
          _premiumReportTile(
            icon: AppImage.whSales,
            title: 'WH Sales Report',
            subtitle: 'Wholesale sales & distribution',
            accent: _accentCyan,
            ontap: () {
              if (Provider.of<CommonCompanyYearSelectionProvider>(context,
                              listen: false)
                          .sType ==
                      "B" ||
                  Provider.of<CommonCompanyYearSelectionProvider>(context,
                              listen: false)
                          .sType ==
                      "S") {
                showUpgradeRequiredDialog(context);
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WhsalesreportScreen()));
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
              if (Provider.of<CommonCompanyYearSelectionProvider>(context,
                              listen: false)
                          .sType ==
                      "B" ||
                  Provider.of<CommonCompanyYearSelectionProvider>(context,
                              listen: false)
                          .sType ==
                      "S") {
                showUpgradeRequiredDialog(context);
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SalesOrderReportScreen()));
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
    final w = MediaQuery.sizeOf(context).width;
    final coName =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_name;
    final sType =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
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
            child: RefreshIndicator(
              color: _ctaFill,
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics()),
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
                        todayGoldRate: _goldRate,
                        todaySilverRate: _silverRate,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DailyrateScreen()),
                        ),
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
  const cta = Color(0xFF006EB7);
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
