import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/categoryProduct_screen.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/image_url.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class TagimageScreen extends StatefulWidget {
  const TagimageScreen({super.key});

  @override
  State<TagimageScreen> createState() => _TagimageScreenState();
}

class _TagimageScreenState extends State<TagimageScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _hairline = Color(0xFFEEF2F6);

  Color get _cta => _brand;

  final sqlConnection = SqlConnection.getInstance();
  final TextEditingController _searchController = TextEditingController();

  /// Net stock weight range, in grams. Null means that end is open, so the
  /// filter can be used as "above 50 gm" without inventing an upper bound.
  double? _minWeight;
  double? _maxWeight;

  bool get _weightFilterOn => _minWeight != null || _maxWeight != null;

  int selectedOption = 2;
  String ItType = 'G';
  List<dynamic> category = [];
  List<dynamic> searchCategory = [];

  /// PR_CODE -> image URL of the last piece shown in that category.
  ///
  /// Lets the grid be scanned by picture instead of read label by label,
  /// which is the whole point of this screen.
  Map<String, String> _previews = {};

  late LoadingProvider loadingProvider;

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getProductCategory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> getProductCategory() async {
    loadingProvider.startLoading();
    setState(() {});
    String co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;

    try {
      if (Platform.isAndroid) {
        String qery =
            // NetWt is the net stock weight of the category, signed so that
            // sold pieces are taken back out — it drives the weight filter.
            "SELECT B.PR_CODE,C.PR_NAME,"
                    "SUM(CASE WHEN A.ITM_SIGN='+' THEN A.ITM_NWT ELSE -A.ITM_NWT END) AS NetWt "
                    "FROM (MAIN_STOCK AS A INNER JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE) "
                    "INNER JOIN PRODUCT_MAST AS C ON B.CO_CODE = C.CO_CODE AND B.PR_CODE = C.PR_CODE WHERE A.CO_CODE = '" +
                co_code +
                "' AND A.TAG_NO <> 'N' ";
        if (ItType != '') {
          qery += " AND B.IT_TYPE = '" + ItType + "'";
        }
        qery += " GROUP BY B.PR_CODE,C.PR_NAME ORDER BY PR_NAME";
        dynamic result = await sqlConnection.queryDatabase(qery);

        category = jsonDecode(result);
        searchCategory = jsonDecode(result);
      } else {
        dynamic result =
            await MySQLService().getProductCategory(co_code, ItType);
        category = result[0];
        searchCategory = result[0];
      }
      _applySearch();
    } catch (e) {
      log('category load failed: $e');
      category = [];
      searchCategory = [];
      if (mounted) {
        showAppToast(context, "Could not load categories. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }

    // Thumbnails are loaded after the grid is already on screen: they are a
    // nicety, and waiting on a second query before showing anything would make
    // the screen feel slower than it does today.
    await _loadPreviews(co_code);
  }

  /// WEB_IMAGE / WEB_PATH are loaded by the dashboard, but this screen can be
  /// reached before that finishes. Without them no URL can be built, so fetch
  /// them here if they are still blank — the same fallback the tag estimate
  /// screen does.
  Future<void> _ensureWebSettings(String coCode) async {
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    if (provider.webImage.isNotEmpty && provider.webPath.isNotEmpty) return;
    try {
      if (Platform.isAndroid) {
        final q =
            "SELECT WEB_IMAGE,WEB_PATH FROM CO_SET_NEW WHERE CO_CODE ='$coCode' ";
        final row = jsonDecode(await sqlConnection.queryDatabase(q))[0];
        provider.changeWebImage('${row["WEB_IMAGE"] ?? ''}');
        provider.changeWebPath('${row["WEB_PATH"] ?? ''}');
        // Record the host we are actually connected to, so a WEB_PATH that
        // names the shop's own LAN address can be re-pointed at it.
        provider.changeServerHost(await Preffrance().getString(Keys.HOST));
      } else {
        final data = await MySQLService().getForImage(coCode);
        provider.changeWebImage('${data[0][0]["WEB_IMAGE"] ?? ''}');
        provider.changeWebPath('${data[0][0]["WEB_PATH"] ?? ''}');
        // Record the host we are actually connected to, so a WEB_PATH that
        // names the shop's own LAN address can be re-pointed at it.
        provider.changeServerHost(await Preffrance().getString(Keys.HOST));
      }
    } catch (e) {
      log('web settings fetch failed: $e');
    }
  }

  Future<void> _loadPreviews(String coCode) async {
    await _ensureWebSettings(coCode);
    if (!mounted) return;
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    final lcCode = provider.lc_code;
    final year = provider.co_year;
    log('preview: webImage="${provider.webImage}" webPath="${provider.webPath}"');
    if (!tagImagesEnabled(provider.webImage)) {
      log('preview: tag images disabled for this company, using placeholders');
      return;
    }

    try {
      List<dynamic> rows;
      if (Platform.isAndroid) {
        // The category grid lists ORDER BY A.TAG_NO DESC, so its *last* card is
        // the lowest tag number — hence ASC here, with ROW_NUMBER picking that
        // single row per category instead of returning every tag in the shop.
        // The GROUP BY/HAVING mirrors the grid's in-stock filter so the preview
        // can never come from a piece the grid does not actually show.
        final inner =
            "SELECT D.PR_CODE, C.DESIGN_IMG_ID AS DesignImgId, A.TAG_NO AS TagNo, C.VCH_SRNO, "
            "ROW_NUMBER() OVER (PARTITION BY D.PR_CODE ORDER BY A.TAG_NO ASC, C.VCH_SRNO ASC) AS rn "
            "FROM ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE AND A.TAG_NO = C.TAG_NO AND A.VCH_SRNO = C.VCH_SRNO AND A.IT_CODE = C.IT_CODE) "
            "LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE) "
            "LEFT JOIN PRODUCT_MAST AS D ON B.CO_CODE = D.CO_CODE AND B.PR_CODE = D.PR_CODE "
            "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' AND A.CO_YEAR = '$year' AND A.TAG_NO <> 'N' "
            "${ItType.isEmpty ? '' : "AND B.IT_TYPE = '$ItType' "}"
            "GROUP BY D.PR_CODE, C.DESIGN_IMG_ID, A.TAG_NO, C.VCH_SRNO "
            "HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0 ";
        final query =
            "SELECT PR_CODE, DesignImgId, TagNo, VCH_SRNO FROM ($inner) T WHERE rn = 1";
        rows = jsonDecode(await sqlConnection.queryDatabase(query));
      } else {
        final result = await MySQLService().getCategoryPreview(coCode, ItType);
        rows = result[0] as List;
      }

      final map = <String, String>{};
      for (final r in rows) {
        final prCode = '${r["PR_CODE"] ?? ''}'.trim();
        if (prCode.isEmpty) continue;
        // Same filename rule the product grid uses: a design image when the
        // piece has one, otherwise the tag's own photo.
        final designId = '${r["DesignImgId"] ?? ''}'.trim();
        final String fileName;
        if (designId.isNotEmpty && designId != 'N') {
          fileName = '$designId.jpg';
        } else {
          final tag = '${r["TagNo"] ?? ''}'.trim();
          if (tag.isEmpty) continue;
          // Interpolating the raw value yields "1.0" for a numeric column,
          // which builds a filename the server does not have. The product
          // grid uses BigInt for the same reason.
          final srNo = num.tryParse('${r["VCH_SRNO"] ?? ''}')?.toInt();
          if (srNo == null) continue;
          fileName = '${tag}_$srNo.jpg';
        }
        final url = buildTagImageUrl(provider.webPath, fileName,
            serverHost: provider.serverHost);
        if (url.isNotEmpty) map[prCode] = url;
      }
      log('preview: ${rows.length} rows -> ${map.length} thumbnails'
          '${map.isEmpty ? '' : ', sample ${map.values.first}'}');
      _previews = map;
      if (mounted) setState(() {});
    } catch (e) {
      // Non-fatal: the grid simply falls back to the placeholder icon.
      log('category preview load failed: $e');
    }
  }

  double _netWeightOf(dynamic c) => double.tryParse('${c["NetWt"] ?? ''}') ?? 0;

  void _applySearch() {
    final term = _searchController.text.trim().toLowerCase();
    searchCategory = category.where((c) {
      if (term.isNotEmpty &&
          !'${c["PR_NAME"] ?? ''}'.toLowerCase().contains(term)) {
        return false;
      }
      if (!_weightFilterOn) return true;
      final wt = _netWeightOf(c);
      if (_minWeight != null && wt < _minWeight!) return false;
      if (_maxWeight != null && wt > _maxWeight!) return false;
      return true;
    }).toList();
  }

  /// Weight range picker.
  ///
  /// Offered as presets plus a free range because a shop thinks in bands —
  /// "light pieces under 10 gm", "heavy bangles above 50" — rather than in
  /// exact gram boundaries.
  Future<void> _pickWeightRange() async {
    final minController =
        TextEditingController(text: _minWeight?.toStringAsFixed(0) ?? '');
    final maxController =
        TextEditingController(text: _maxWeight?.toStringAsFixed(0) ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Filter by weight",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary)),
                const SizedBox(height: 4),
                Text("Net stock weight of the category",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final band in const [
                      ('Under 10 gm', null, 10.0),
                      ('10 – 25 gm', 10.0, 25.0),
                      ('25 – 50 gm', 25.0, 50.0),
                      ('Above 50 gm', 50.0, null),
                    ])
                      GestureDetector(
                        onTap: () {
                          _minWeight = band.$2;
                          _maxWeight = band.$3;
                          _applySearch();
                          setState(() {});
                          Navigator.pop(sheetContext);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                (_minWeight == band.$2 && _maxWeight == band.$3)
                                    ? _cta
                                    : const Color(0xFFEEF2F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(band.$1,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: (_minWeight == band.$2 &&
                                          _maxWeight == band.$3)
                                      ? Colors.white
                                      : _textSecondary)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _weightField("Min gm", minController)),
                    const SizedBox(width: 12),
                    Expanded(child: _weightField("Max gm", maxController)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _minWeight = null;
                          _maxWeight = null;
                          _applySearch();
                          setState(() {});
                          Navigator.pop(sheetContext);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSecondary,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                        ),
                        child: Text("Clear",
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          // Blank means "open end", not zero — otherwise
                          // clearing the max would hide everything.
                          _minWeight =
                              double.tryParse(minController.text.trim());
                          _maxWeight =
                              double.tryParse(maxController.text.trim());
                          _applySearch();
                          setState(() {});
                          Navigator.pop(sheetContext);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _cta,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                        ),
                        child: Text("Apply",
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    minController.dispose();
    maxController.dispose();
  }

  Widget _weightField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12.5, fontWeight: FontWeight.w600, color: _textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _cta, width: 1.6),
        ),
      ),
    );
  }

  /// Label for the active weight filter, or null when it is off.
  String? get _weightChipLabel {
    if (!_weightFilterOn) return null;
    final min = _minWeight;
    final max = _maxWeight;
    if (min != null && max != null) {
      return "${min.toStringAsFixed(0)} – ${max.toStringAsFixed(0)} gm";
    }
    if (min != null) return "Above ${min.toStringAsFixed(0)} gm";
    return "Under ${max!.toStringAsFixed(0)} gm";
  }

  void _selectType(int option, String type) {
    if (selectedOption == option) return;
    selectedOption = option;
    ItType = type;
    _previews = {};
    setState(() {});
    getProductCategory();
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
          _typeSelector(),
          Expanded(
            child: Consumer<LoadingProvider>(
              builder: (context, loading, _) {
                if (loading.isLoading) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: _cta, strokeWidth: 2.6));
                }
                if (searchCategory.isEmpty) return _emptyState();
                return RefreshIndicator(
                  color: _cta,
                  onRefresh: getProductCategory,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      // Taller than wide: the thumbnail gets the space and the
                      // name sits under it without being cramped.
                      childAspectRatio: 0.78,
                    ),
                    itemCount: searchCategory.length,
                    itemBuilder: (context, index) =>
                        _categoryCard(searchCategory[index]),
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
                Text("Tag Image",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(
                    "${searchCategory.length} ${searchCategory.length == 1 ? 'category' : 'categories'}",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(child: _searchBox()),
              const SizedBox(width: 10),
              _filterButton(),
            ],
          ),
        ),
        if (_weightChipLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: _cta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.scale_rounded, size: 13, color: _cta),
                      const SizedBox(width: 5),
                      Text(_weightChipLabel!,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _cta)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          _minWeight = null;
                          _maxWeight = null;
                          _applySearch();
                          setState(() {});
                        },
                        child: Icon(Icons.close_rounded, size: 14, color: _cta),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                    "${searchCategory.length} "
                    "${searchCategory.length == 1 ? 'category' : 'categories'}",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary)),
              ],
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _filterButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickWeightRange,
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: _weightFilterOn ? _cta : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _weightFilterOn ? _cta : _border),
          ),
          child: Icon(Icons.tune_rounded,
              size: 21, color: _weightFilterOn ? Colors.white : _cta),
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _searchController,
        cursorColor: _cta,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w500, color: _textPrimary),
        decoration: InputDecoration(
          hintText: "Search with product name",
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
                    _applySearch();
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
          _applySearch();
          setState(() {});
        },
      ),
    );
  }

  Widget _typeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hairline),
        ),
        child: Row(
          children: [
            _typeTab("All", 1, ''),
            _typeTab("Gold", 2, 'G'),
            _typeTab("Silver", 3, 'S'),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String label, int option, String type) {
    final selected = selectedOption == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectType(option, type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? _cta : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(dynamic data) {
    final prCode = '${data["PR_CODE"] ?? ''}'.trim();
    final name = '${data["PR_NAME"] ?? ''}'.trim();
    final previewUrl = _previews[prCode];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryproductScreen(
              screenName: name,
              prCode: prCode,
              ItType: ItType,
            ),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _hairline),
            boxShadow: [
              BoxShadow(
                color: _textPrimary.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: _pageBg,
                      child: _preview(previewUrl),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: _cta,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thumbnail, falling back to the generic icon whenever there is no image —
  /// no photo configured, none uploaded for that category, or a failed load.
  Widget _preview(String? url) {
    if (url == null || url.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) => Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _cta),
        ),
      ),
      errorWidget: (context, _, __) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Image.asset(AppImage.ring, fit: BoxFit.contain),
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
            child: Icon(Icons.category_rounded, color: _cta, size: 34),
          ),
          const SizedBox(height: 16),
          Text("No categories found",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text("Try a different metal type or search term",
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
