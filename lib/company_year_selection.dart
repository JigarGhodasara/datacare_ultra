import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:DataCareUltra/utils/edition.dart';
import 'package:DataCareUltra/dashboard_screen.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/book_picker.dart';
import 'package:DataCareUltra/tagEstimate_screen.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class CompanyYearSelection extends StatefulWidget {
  const CompanyYearSelection({Key? key}) : super(key: key);

  @override
  State<CompanyYearSelection> createState() => _CompanyYearSelectionState();
}

class _CompanyYearSelectionState extends State<CompanyYearSelection> {
  static const Color _brand = Color(0xFF1565C0);
  static const Color _brandDark = Color(0xFF0D47A1);
  static const Color _sheetSurface = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  final sqlConnection = SqlConnection.getInstance();

  // Each list is keyed by the database code (CO_CODE, LC_CODE, CO_YEAR), so a
  // selection is always exactly one row and the label can hold anything,
  // dashes included.
  List<PickerOption> _companies = const [];
  List<PickerOption> _locations = const [];
  List<PickerOption> _years = const [];

  /// Full and short company names by company code, for the provider.
  final Map<String, String> _companyNames = {};
  final Map<String, String> _shortNames = {};

  String selectedCompany = '';
  String selectedLocation = '';
  String selectedYear = '';
  String get sName => _shortNames[selectedCompany] ?? '';

  /// True while the branch and year lists are being fetched for the chosen
  /// company. Those two fields are disabled and show a spinner meanwhile.
  bool _loadingDetails = false;

  /// Lets a late reply for a company the user has since moved away from be
  /// ignored instead of overwriting the newer lists.
  int _detailsRequest = 0;

  late LoadingProvider loadingProvider;

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getData();
    });
  }

  // ---------------------------------------------------------------- data ---

  static String _text(dynamic v) => v == null ? '' : v.toString().trim();

  Future<List<dynamic>> _companyRows() async {
    if (Platform.isAndroid) {
      final raw = await sqlConnection.queryDatabase(
          "SELECT CO_CODE As CoCode,CO_NAME as NameT,CO_SNAME FROM CO_MAST ORDER BY CO_CODE");
      return jsonDecode(raw) as List<dynamic>;
    }
    final res = await MySQLService().getCompanyData();
    return res[0] as List<dynamic>;
  }

  Future<List<dynamic>> _locationRows(String coCode) async {
    if (Platform.isAndroid) {
      final raw = await sqlConnection.queryDatabase(
          "SELECT LC_CODE,LC_NAME FROM LOCT_MAST WHERE CO_CODE = '$coCode' AND LC_CODE <> '' ORDER BY LC_CODE");
      return jsonDecode(raw) as List<dynamic>;
    }
    final res = await MySQLService().getCompanyLocation(coCode);
    return res[0] as List<dynamic>;
  }

  Future<List<dynamic>> _yearRows(String coCode) async {
    if (Platform.isAndroid) {
      final raw = await sqlConnection.queryDatabase(
          "SELECT CO_YEAR As Year,OP_DATE,CL_DATE FROM YEAR_MAST WHERE CO_CODE = '$coCode' ORDER BY CO_YEAR desc");
      return jsonDecode(raw) as List<dynamic>;
    }
    final res = await MySQLService().getYears(coCode);
    return res[0] as List<dynamic>;
  }

  Future<void> getData() async {
    loadingProvider.startLoading();
    try {
      final rows = await _companyRows();
      _companyNames.clear();
      _shortNames.clear();
      final options = <PickerOption>[];
      for (final r in rows) {
        final code = _text(r['CoCode']);
        if (code.isEmpty) continue;
        final name = _text(r['NameT']);
        _companyNames[code] = name;
        _shortNames[code] = _text(r['CO_SNAME']);
        options.add(PickerOption(code, '$code-$name'));
      }
      _companies = distinctOptions(options);
      selectedCompany = pickSelected(_companies, selectedCompany);
      if (!mounted) return;
      setState(() {});
      if (selectedCompany.isNotEmpty) {
        await _loadCompanyDetails(selectedCompany);
      }
    } catch (e, s) {
      log('Error loading company data', error: e, stackTrace: s);
      if (mounted) {
        showAppToast(
            context, "Could not load company details. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  /// Loads the branches and financial years that belong to [coCode]. Both
  /// depend on the company, so both are refreshed whenever it changes.
  Future<void> _loadCompanyDetails(String coCode) async {
    final request = ++_detailsRequest;
    setState(() => _loadingDetails = true);
    try {
      final locRows = await _locationRows(coCode);
      final yearRows = await _yearRows(coCode);
      if (!mounted || request != _detailsRequest) return;

      _locations = distinctOptions([
        for (final r in locRows)
          if (_text(r['LC_CODE']).isNotEmpty)
            PickerOption(_text(r['LC_CODE']),
                '${_text(r['LC_CODE'])}-${_text(r['LC_NAME'])}'),
      ]);
      _years = distinctOptions([
        for (final r in yearRows)
          if (_text(r['Year']).isNotEmpty)
            PickerOption(_text(r['Year']), _text(r['Year'])),
      ]);
      selectedLocation = pickSelected(_locations, selectedLocation);
      selectedYear = pickSelected(_years, selectedYear);
    } catch (e, s) {
      log('Error loading branches/years for $coCode', error: e, stackTrace: s);
      if (mounted && request == _detailsRequest) {
        showAppToast(context,
            "Could not load branches and years for this company. Please try again.");
      }
    } finally {
      if (mounted && request == _detailsRequest) {
        setState(() => _loadingDetails = false);
      }
    }
  }

  // ------------------------------------------------------------- pickers ---

  Future<void> _pickCompany() async {
    final picked = await showOptionPicker(
      context: context,
      options: _companies,
      selected: selectedCompany,
      title: 'Select company',
      searchHint: 'Search company',
      emptyText: 'No company found',
    );
    if (picked == null || !mounted || picked == selectedCompany) return;
    HapticFeedback.selectionClick();
    setState(() => selectedCompany = picked);
    await _loadCompanyDetails(picked);
  }

  Future<void> _pickLocation() async {
    final picked = await showOptionPicker(
      context: context,
      options: _locations,
      selected: selectedLocation,
      title: 'Select branch',
      searchHint: 'Search branch',
      emptyText: 'No branch found',
    );
    if (picked == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() => selectedLocation = picked);
  }

  Future<void> _pickYear() async {
    final picked = await showOptionPicker(
      context: context,
      options: _years,
      selected: selectedYear,
      title: 'Select financial year',
      searchHint: 'Search year',
      emptyText: 'No year found',
    );
    if (picked == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() => selectedYear = picked);
  }

  static String _labelOf(List<PickerOption> options, String value) {
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return '';
  }

  Color get _ctaFill => AppColor.PRIMARY_COLOR ?? _brand;

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
      ),
    );
  }

  /// One selection row: leading icon plus the tappable field. The field opens
  /// a bottom-sheet list rather than an anchored menu, so the lowest field on
  /// a small phone is just as usable as the top one.
  Widget _pickerRow({
    required String asset,
    required List<PickerOption> options,
    required String value,
    required String placeholder,
    required String emptyText,
    required bool loading,
    required VoidCallback onTap,
  }) {
    final label = _labelOf(options, value);
    final String shown;
    if (label.isNotEmpty) {
      shown = label;
    } else if (loading) {
      shown = 'Loading…';
    } else if (options.isEmpty) {
      shown = emptyText;
    } else {
      shown = placeholder;
    }
    final enabled = !loading && options.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _FieldLeadingIcon(asset: asset, tint: _ctaFill),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: enabled ? onTap : null,
              child: Container(
                height: 52,
                padding: const EdgeInsets.only(left: 14, right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shown,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              label.isNotEmpty ? _textPrimary : _textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (loading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _ctaFill,
                        ),
                      )
                    else
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: enabled
                            ? _textSecondary
                            : _textSecondary.withValues(alpha: 0.4),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- submit ---

  Future<void> _onSubmit() async {
    if (selectedCompany.isEmpty ||
        selectedLocation.isEmpty ||
        selectedYear.isEmpty) {
      showAppToast(context, "Please select company, branch and year.");
      return;
    }
    if (_loadingDetails) {
      showAppToast(context, "Please wait, loading branches and years.");
      return;
    }

    String? host = await Preffrance().getString(Keys.HOST);
    String? userName = await Preffrance().getString(Keys.USERNAME);
    String? password = await Preffrance().getString(Keys.PASSWORD);

    // Database per year: "Next" + the two-digit year ("2024-25" -> "Next24")
    // or the last four characters of a single-year label.
    String yearPart;
    if (selectedYear.contains("-")) {
      final a = selectedYear.split('-')[0];
      yearPart = a.length >= 2 ? a.substring(a.length - 2) : a;
    } else {
      yearPart = selectedYear.length >= 4
          ? selectedYear.substring(selectedYear.length - 4)
          : selectedYear;
    }
    final String dataBaseName = "Next$yearPart";
    log("Database Name $dataBaseName");
    Preffrance().setString(Keys.DATABASE, dataBaseName);
    String? db = await Preffrance().getString(Keys.DATABASE);
    dynamic connectionStatus;
    if (Platform.isAndroid) {
      sqlConnection.disconnect();
      connectionStatus = sqlConnection
          .connect(
              ip: host!.contains(":") ? host.split(":")[0].toString() : host,
              port: host.contains(":") ? host.split(":")[1].toString() : "1433",
              databaseName: db!,
              username: userName!,
              password: password!)
          .catchError((onError) {
        _showSnack("Database can't find please select another year..");
        return false;
      });
    } else {
      connectionStatus = MySQLService().connectToDatabase();
    }

    if (await connectionStatus) {
      if (!mounted) return;
      final provider =
          Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
      provider.changeCO_name(_companyNames[selectedCompany] ?? '');
      provider.changeCO_code(selectedCompany);
      provider.changeLC_code(selectedLocation);
      provider.changeCO_year(selectedYear);
      provider.changeCoSName(sName);

      dynamic SoftTypedata;
      if (Platform.isAndroid) {
        String softTypeQuery =
            "SELECT SUBSTRING(REF_NO,7,1) As SoftType,SUBSTRING(REF_NO,1,1) AS DemoType FROM HDD_MAST";
        log(softTypeQuery);
        dynamic result = await sqlConnection.queryDatabase(softTypeQuery);
        SoftTypedata = jsonDecode(result);
      } else {
        dynamic sTypeData = await MySQLService().getSOftType();
        SoftTypedata = sTypeData[0];
      }

      // Grade the licence across every HDD_MAST row, trimmed and upper-cased.
      // The old code read row [0] only and compared raw, so a second row in
      // HDD_MAST, a lowercase letter, or CHAR padding shifting the substring
      // all showed "upgrade required" to a valid Enterprise customer.
      final EditionKey key = readEdition(SoftTypedata);
      final String sType = key.sType;
      final String dType = key.dType;
      if (!mounted) return;
      provider.changesType(sType);
      provider.changedType(dType);
      log("edition: sType='$sType' dType='$dType' -> ${key.edition.name} "
          "(from ${SoftTypedata is List ? SoftTypedata.length : 0} HDD_MAST row(s))");

      void openApp() {
        final String userType = provider.userType;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                userType == "A" ? DashboardScreen() : TagestimateScreen(),
          ),
        );
      }

      if (key.edition == Edition.full) {
        openApp();
      } else if (key.edition == Edition.limited && Platform.isAndroid) {
        // Basic/Standard open on Android only; iOS is full-edition only.
        openApp();
      } else {
        showUpgradeRequiredDialog(context);
      }
    } else {
      _showSnack("Database can't find please select another year..");
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- build ---

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final padH = w < 360 ? 20.0 : math.min(28.0, w * 0.065);
    final maxW = math.min(w - 2 * padH, 440.0);
    final logoDim = (w * 0.19).clamp(72.0, h < 700 ? 88.0 : 96.0);

    // Local theme so this screen is not overridden by app-wide Material 2 defaults.
    return Theme(
      data: Theme.of(context).copyWith(
        useMaterial3: true,
        splashFactory: InkSparkle.splashFactory,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: _brandDark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _CompanyYearBackdrop(height: h, width: w),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(8, 8, 16, w < 400 ? 12 : 16),
                    child: SizedBox(
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(context);
                                },
                                customBorder: const CircleBorder(),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: w < 360 ? 17 : 19,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'COMPANY & YEAR SELECTION',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: w < 340 ? 14 : 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            _sheetSurface,
                          ],
                          stops: const [0.0, 0.32],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x280F172A),
                            blurRadius: 36,
                            offset: Offset(0, -8),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _border.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Expanded(
                              child: _companies.isEmpty
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: _ctaFill,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      physics: const ClampingScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(
                                          padH, 20, padH, 28),
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: SizedBox(
                                          width: maxW,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Center(
                                                child: _SelectionLogoFrame(
                                                  size: logoDim,
                                                  brandTint: _ctaFill,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              _sectionIntro(),
                                              const SizedBox(height: 22),
                                              _fieldLabel('Company'),
                                              const SizedBox(height: 8),
                                              _pickerRow(
                                                asset: AppImage.businessAndTrade,
                                                options: _companies,
                                                value: selectedCompany,
                                                placeholder: 'Select company',
                                                emptyText: 'No company found',
                                                loading: false,
                                                onTap: _pickCompany,
                                              ),
                                              const SizedBox(height: 18),
                                              _fieldLabel('Branch / location'),
                                              const SizedBox(height: 8),
                                              _pickerRow(
                                                asset: AppImage.branch,
                                                options: _locations,
                                                value: selectedLocation,
                                                placeholder: 'Select branch',
                                                emptyText: 'No branch found',
                                                loading: _loadingDetails,
                                                onTap: _pickLocation,
                                              ),
                                              const SizedBox(height: 18),
                                              _fieldLabel('Financial year'),
                                              const SizedBox(height: 8),
                                              _pickerRow(
                                                asset: AppImage.calendar,
                                                options: _years,
                                                value: selectedYear,
                                                placeholder: 'Select year',
                                                emptyText: 'No year found',
                                                loading: _loadingDetails,
                                                onTap: _pickYear,
                                              ),
                                              const SizedBox(height: 28),
                                              FilledButton(
                                                onPressed: () async {
                                                  await HapticFeedback
                                                      .lightImpact();
                                                  await _onSubmit();
                                                },
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: _ctaFill,
                                                  foregroundColor: Colors.white,
                                                  elevation: 2,
                                                  shadowColor: _ctaFill
                                                      .withValues(alpha: 0.4),
                                                  minimumSize: Size(
                                                    double.infinity,
                                                    math.max(
                                                        52.0, 48 + w * 0.01),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 24,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Submit',
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    const Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 22,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _brand.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            'WORKSPACE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              height: 1,
              color: _brand,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your selections',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick the company, branch, and year to open your session.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.45,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, thickness: 1, color: _border),
      ],
    );
  }
}

class _FieldLeadingIcon extends StatelessWidget {
  const _FieldLeadingIcon({
    required this.asset,
    required this.tint,
  });

  final String asset;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Image.asset(
        asset,
        width: 22,
        height: 22,
        color: tint,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _CompanyYearBackdrop extends StatelessWidget {
  const _CompanyYearBackdrop({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D47A1),
                Color(0xFF1565C0),
                Color(0xFF1976D2),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          right: -width * 0.12,
          top: height * 0.06,
          child: IgnorePointer(
            child: Container(
              width: width * 0.65,
              height: width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
        ),
        Positioned(
          left: -width * 0.2,
          top: height * 0.18,
          child: IgnorePointer(
            child: Container(
              width: width * 0.5,
              height: width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionLogoFrame extends StatelessWidget {
  const _SelectionLogoFrame({
    required this.size,
    required this.brandTint,
  });

  final double size;
  final Color brandTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: brandTint.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: brandTint.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Image.asset(
        AppImage.appLogo,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
