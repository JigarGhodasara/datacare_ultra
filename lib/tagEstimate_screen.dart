import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:DataCareUltra/image_screen.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/qrCode_screen.dart';
import 'package:http/http.dart' as http;
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/dashboard_screen.dart'
    show showUpgradeRequiredDialog;
import 'package:DataCareUltra/estimate_cart_screen.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/estimate_cart_provider.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/edition.dart';
import 'package:DataCareUltra/photo_review_screen.dart';
import 'package:DataCareUltra/utils/image_check.dart';
import 'package:DataCareUltra/utils/other_details_qty.dart';
import 'package:DataCareUltra/utils/share_tag_image.dart';
import 'package:DataCareUltra/utils/image_prepare.dart';
import 'package:DataCareUltra/utils/image_url.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:pdf/widgets.dart' as pw;

class TagestimateScreen extends StatefulWidget {
  // dynamic? product;
  String? productImage;
  String? tagNo;
  String? VchSrNo;
  TagestimateScreen({Key? key, this.productImage, this.tagNo, this.VchSrNo})
      : super(key: key);

  @override
  State<TagestimateScreen> createState() => _TagestimateScreenState();
}

class _TagestimateScreenState extends State<TagestimateScreen> {
  TextEditingController searchController = TextEditingController();
  String productImage = "";
  final sqlConnection = SqlConnection.getInstance();
  dynamic productDetail;
  dynamic printingLable;
  int selectedOpt = 2;
  String selectedItType = 'N';
  late LoadingProvider loadingProvider;
  late CommonCompanyYearSelectionProvider commonCompanyYearSelectionProvider;
  String? co_code;
  String? year;
  String? lc_code;
  String itemRate = "";
  String itemAmount = "";
  String lbrPrc = "";
  String lbrRate = "";
  String lbrAmmount = "";
  String othAmmount = "";
  String mrp = "";
  String netAmmount = "";
  String gstTax = "";
  String totalAmount = "";

  String fillterItemRate = "";
  String fillterLbrPrc = "";
  String fillterLbrRate = "";
  String fillterLbrCharges = "";
  String fillterGst = "3.00";
  String hddNo = "";
  bool selectedGST = true;

  /// Whether the ghat (wastage) lines appear on the POS receipt.
  ///
  /// Each is independent, because a shop may quote the percentage without
  /// showing the derived weight, or the other way round. Both default on so
  /// the section appears as soon as a tag carries ghat, and each line is still
  /// skipped when its own value is zero — the same rule the labour lines use,
  /// so a tag with no ghat prints nothing extra either way.
  /// How the Other Details table reports a stone's quantity.
  ///
  /// Defaults to auto: a stone is entered either by piece or by carat, and
  /// printing both columns put a meaningless "0" against whichever one the
  /// operator left blank.
  OtherQtyMode otherQtyMode = OtherQtyMode.auto;

  bool showGhatWt = false;
  bool showGhatPrc = false;
  bool printImageInPdf = true;

  static final Color _cta = AppColor.blueColor;
  static const Color _pageBg = Color(0xFFF4F6FA);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF059669);

  TextStyle _pjSans({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? _textPrimary,
      height: 1.35,
    );
  }

  TextStyle _specRowStyle() =>
      _pjSans(size: 12, weight: FontWeight.w700, color: _textPrimary);

  TextStyle _accentAmountStyle() =>
      _pjSans(size: 16, weight: FontWeight.w800, color: _success);

  TextStyle _ctaButtonTextStyle() => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: Colors.white,
      );

  BoxDecoration _modalSectionCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        colors: [
          Colors.white,
          Color.lerp(Colors.white, _pageBg, 0.1)!,
        ],
      ),
      border: Border.all(color: _cta.withValues(alpha: 0.14)),
      boxShadow: [
        BoxShadow(
          color: _cta.withValues(alpha: 0.08),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  InputDecoration _modalFilterFieldDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: _pjSans(
        size: 14,
        weight: FontWeight.w500,
        color: _textSecondary.withValues(alpha: 0.7),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _border.withValues(alpha: 0.9),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _cta, width: 1.75),
      ),
    );
  }

  /// The shop's own name for a ghat column, from COL_MAST.
  ///
  /// The on-screen detail already renders these labels via COL_NEW_NAME, so
  /// the receipt uses the same source and a shop that calls it "Wastage" sees
  /// that word here too. Falls back to [fallback] when the column is not
  /// configured — the receipt row is driven by the filter toggle, so it must
  /// still be printable without a COL_MAST entry.
  String _ghatLabel(String colName, String fallback) {
    try {
      final match = printingLable.firstWhere(
        (e) =>
            '${e["COL_NAME"] ?? ''}'.trim().toLowerCase() ==
                colName.toLowerCase() &&
            '${e["YES_NO"] ?? ''}'.trim().toUpperCase() == 'Y',
      );
      final name = '${match["COL_NEW_NAME"] ?? ''}'.trim();
      return name.isEmpty ? fallback : name;
    } catch (_) {
      return fallback;
    }
  }

  /// Checkbox row used by the ghat options on the estimate filter sheet.
  ///
  /// Styled to match the GST row above it rather than using a Switch, so the
  /// sheet reads as one set of controls.
  Widget _ghatToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _cta.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cta.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return _cta;
                  return _border;
                }),
              ),
            ),
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: _pjSans(size: 14, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRadioChip(bool selected, Widget radio, String label) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  _cta.withValues(alpha: 0.2),
                  _cta.withValues(alpha: 0.07),
                ],
              )
            : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? _cta.withValues(alpha: 0.38)
              : _border.withValues(alpha: 0.9),
          width: selected ? 1.2 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: _cta.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          radio,
          Flexible(
            child: Text(
              label,
              style: _pjSans(
                size: 13,
                weight: FontWeight.w700,
                color: selected ? _cta : _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Premium design helpers ----------

  Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_cta, _cta.withValues(alpha: 0.55)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _cta.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _cta, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool accent = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: _border.withValues(alpha: 0.6),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  label,
                  style: _pjSans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: accent
                      ? _pjSans(
                          size: 15.5,
                          weight: FontWeight.w800,
                          color: _cta,
                        )
                      : _pjSans(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _cta.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _cta, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: _pjSans(
              size: 12,
              weight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pjSans(
              size: 16,
              weight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: _pjSans(
                size: 12.5,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    getImage();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    commonCompanyYearSelectionProvider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update your state here
      if (widget.tagNo != null) {
        // Opened from the dashboard scanner: show what was read.
        searchController.text = widget.tagNo!;
        getProductDetail();
      }
      getPrintLable();
    });
    hddNo =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .hdd;

    print("HDD NO $hddNo");
    // if(widget.productImage != null && widget.tagNo != null && widget.VchSrNo != null){
    // }
  }

  void getImage() async {
    if (Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .webImage
            .isEmpty &&
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .webPath
            .isEmpty) {
      if (Platform.isAndroid) {
        dynamic resultOfweb = await sqlConnection.queryDatabase(
            "SELECT WEB_IMAGE,WEB_PATH FROM CO_SET_NEW WHERE CO_CODE ='" +
                co_code! +
                "' ");
        print("resultofWeb $resultOfweb");
        print("resultofWeb ${jsonDecode(resultOfweb)[0]["WEB_IMAGE"]}");
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .changeWebImage(jsonDecode(resultOfweb)[0]["WEB_IMAGE"]);
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .changeWebPath(jsonDecode(resultOfweb)[0]["WEB_PATH"]);
      } else {
        dynamic image = await MySQLService().getForImage(co_code!);
        print("IMagesss $image");
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .changeWebImage(image[0][0]["WEB_IMAGE"]);
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .changeWebPath(image[0][0]["WEB_PATH"]);
      }
      // Record the host we are actually connected to, so a WEB_PATH that names
      // the shop's own LAN address can be re-pointed at it.
      if (mounted) {
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .changeServerHost(await Preffrance().getString(Keys.HOST));
      }
    }
  }

  getPrintLable() async {
    String query = "";
    if (Platform.isAndroid) {
      query =
           "SELECT * FROM COL_MAST WHERE CO_CODE = '${co_code!}' AND BOOK_NAME = 'SALES' AND YES_NO = 'Y'";

      log("query $query");
      dynamic result = await sqlConnection.queryDatabase(query);
      if (jsonDecode(result).length != 0) {
        print("result");
        log(result);
        setState(() {
          printingLable = jsonDecode(result);
        });
      }
    } else {
      dynamic res = await MySQLService().getPrintLable(
              "SELECT * FROM COL_MAST WHERE CO_CODE = '${co_code!}' AND BOOK_NAME = 'SALES' AND YES_NO = 'Y'");
      print("result");
      print("result $res");
      if (res[0].length != 0) {
        setState(() {
          printingLable = res[0];
        });
      }
    }
  }

  getProductDetail() async {
    loadingProvider.startLoading();
    setState(() {});
    String query = "";
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    year =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_year;
    lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    if (Platform.isAndroid) {
      // String a = "SELECT * FROM ITEM_MAST AS B WHERE B.CO_CODE = '" + co_code! + "'";
      // dynamic b = await sqlConnection.queryDatabase(a);
      // print("b");
      // print(b);
      if (widget.VchSrNo == null || widget.VchSrNo == "") {
        query = "SELECT B.IT_NAME,A.TAG_NO,A.IT_CODE,C.LBR_TYPE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_WEST_PRC,C.ITM_PCS,C.ITM_GWT,C.VCH_SRNO,B.PR_CODE,B.GR_CODE,B.IT_WEST,B.ITM_FIX_WEST_PRC,(D.GR_RATE/10) As Rate,C.ITM_NWT AS TagNwt,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT as ITM_GHAT,C.ITM_MRP, C.LBR_RATE,C.VCH_DATE  from ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE AND A.TAG_NO = C.TAG_NO AND A.VCH_SRNO = C.VCH_SRNO AND A.IT_CODE = C.IT_CODE)LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE)LEFT JOIN GROUP_MAST AS D ON B.CO_CODE = D.CO_CODE AND B.GR_CODE = D.GR_CODE WHERE A.CO_CODE = '" +
            co_code! +
            "'  AND A.LC_CODE = '" +
            lc_code! +
            "' AND A.CO_YEAR = '" +
            year! +
            "' AND A.TAG_NO = '" +
            widget.tagNo! +
            "'  GROUP BY A.TAG_NO,A.IT_CODE,C.LBR_TYPE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_WEST_PRC,C.ITM_PCS,C.ITM_GWT,C.ITM_NWT,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.VCH_SRNO,B.PR_CODE,B.IT_NAME,B.GR_CODE,B.IT_WEST,B.ITM_FIX_WEST_PRC,D.GR_RATE,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT,C.ITM_MRP, C.LBR_RATE,C.VCH_DATE HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0 ORDER BY C.VCH_DATE DESC";
      } else {
        query = "SELECT B.IT_NAME,A.TAG_NO,A.IT_CODE,C.LBR_TYPE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_WEST_PRC,C.ITM_PCS,C.ITM_GWT,C.VCH_SRNO,B.PR_CODE,B.GR_CODE,B.IT_WEST,B.ITM_FIX_WEST_PRC,(D.GR_RATE/10) As Rate,C.ITM_FINE,C.ITM_NWT AS TagNwt,C.LBR_AMT,C.OTH_AMT,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT as ITM_GHAT,C.ITM_MRP, C.LBR_RATE  from ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE AND A.TAG_NO = C.TAG_NO AND A.VCH_SRNO = C.VCH_SRNO AND A.IT_CODE = C.IT_CODE)LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE)LEFT JOIN GROUP_MAST AS D ON B.CO_CODE = D.CO_CODE AND B.GR_CODE = D.GR_CODE WHERE A.CO_CODE = '" +
            co_code! +
            "'  AND A.LC_CODE = '" +
            lc_code! +
            "' AND A.CO_YEAR = '" +
            year! +
            "' AND A.TAG_NO = '" +
            widget.tagNo! +
            "'  AND A.VCH_SRNO = '" +
            widget.VchSrNo! +
            "'  GROUP BY A.TAG_NO,A.IT_CODE,C.LBR_TYPE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_WEST_PRC,C.ITM_PCS,C.ITM_GWT,C.ITM_NWT,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.VCH_SRNO,B.PR_CODE,B.IT_NAME,B.GR_CODE,B.IT_WEST,B.ITM_FIX_WEST_PRC,D.GR_RATE,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT,C.ITM_MRP, C.LBR_RATE HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0 ";
      }
      log("query ${query}");




      dynamic result = await sqlConnection.queryDatabase(query);
      if (jsonDecode(result).length == 0) {
        productDetail = null;
        productImage = "";
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Tag Not Found"),
        ));
        loadingProvider.stopLoading();
      } else {
        setState(() {
          productDetail = jsonDecode(result)[0];
        });
      }
      log("Resuult ${result}");
    } else {
      dynamic productData = await MySQLService().getTagEstimateData(
          co_code!, lc_code!, year!, widget.tagNo!, widget.VchSrNo ?? "");
      // productDetail = productData[0][0];
      List<dynamic> aa = productData[0];
      if (aa.isEmpty) {
        productDetail = null;
        productImage = "";
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Tag Not Found"),
        ));
        loadingProvider.stopLoading();
      } else {
        setState(() {
          productDetail = productData[0][0];

        });
      }
    }

    setLableValue();

    if (widget.productImage == null) {
      final imgProvider = Provider.of<CommonCompanyYearSelectionProvider>(
          context,
          listen: false);
      if (tagImagesEnabled(imgProvider.webImage)) {
        final tag = '${productDetail["TAG_NO"] ?? ''}'.trim();
        final srNo = BigInt.from(productDetail["VCH_SRNO"]);
        productImage = buildTagImageUrl(imgProvider.webPath, '${tag}_$srNo.jpg',
            serverHost: imgProvider.serverHost);
        print("Product Image $productImage");
      }
    } else {
      productImage = widget.productImage ?? "";
      print("Product Image $productImage");
    }
    loadingProvider.stopLoading();
    setState(() {});
  }

  void saveToDb(XFile image) async {
    loadingProvider.startLoading();
    if (mounted) setState(() {});
    try {
      // image_picker already downscales to 1080px and re-encodes at quality 85
      // (maxWidth/maxHeight/imageQuality at the call sites), so a second pass
      // through FlutterImageCompress bought very little — and re-encoding was
      // a prime suspect for the all-black frames some uploads produced.
      final Uint8List picked = await File(image.path).readAsBytes();
      if (picked.isEmpty) {
        _showImageMessage('Could not process the image. Please try again.');
        return;
      }

      // Photos taken with the phone held any way but "normal" carry their
      // rotation in an EXIF tag rather than in the pixels. FlutterImageCompress
      // used to bake that in as a side effect; with it gone the rotation has to
      // be applied explicitly, or the photo lands sideways in the ERP software
      // (which does not read the tag).
      final Uint8List imageBytes =
          await ImagePrepare.uprightOrientation(picked);

      // A failed camera capture yields a perfectly valid JPEG that happens to
      // be a solid black frame, which then sits in the database looking like
      // corruption. Catch it here rather than letting it be stored.
      final quality = await inspectImage(imageBytes);
      final rejection = rejectionMessage(quality);
      if (rejection != null) {
        log('rejected picked image: $quality (${imageBytes.length} bytes)');
        _showImageMessage(rejection);
        return;
      }

      // Offer the touch-ups on the real photo before it is uploaded. The
      // review runs outside the loading overlay, since the user is looking at
      // and deciding on the picture rather than waiting for us.
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
      if (!mounted) return;
      final Uint8List? reviewed = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoReviewScreen(original: imageBytes),
        ),
      );
      // Backed out of the review — no upload, and no error to report.
      if (reviewed == null) return;
      loadingProvider.startLoading();
      if (mounted) setState(() {});

      final String base64String = base64Encode(reviewed);

      final String? host = await Preffrance().getString(Keys.HOST);
      final String? userName = await Preffrance().getString(Keys.USERNAME);
      final String? password = await Preffrance().getString(Keys.PASSWORD);
      const String imageDb = "NextImage";

      if (host == null || userName == null || password == null) {
        _showImageMessage(
            'Server settings are missing. Please check Settings.');
        return;
      }

      if (Platform.isAndroid) {
        sqlConnection.disconnect();
        final bool connectionStatus = await sqlConnection.connect(
          // Host must be split the same way the login screen does — passing
          // the whole "ip:port" string as the ip left the port doubled up.
          ip: host.contains(":") ? host.split(":")[0].toString() : host,
          port: host.contains(":") ? host.split(":")[1].toString() : "1433",
          databaseName: imageDb,
          username: userName,
          password: password,
        );
        if (!connectionStatus) {
          _showImageMessage('Could not connect to the image server.');
          return;
        }
        final String queryDelete =
            "DELETE FROM TAG_IMAGE_DATA WHERE CO_CODE = '${co_code!}' AND LC_CODE = '${lc_code!}' AND TAG_NO = '${widget.tagNo!}' AND VCH_SRNO = '${widget.VchSrNo!}'";
        await sqlConnection.updateData(queryDelete);
        final String insertImage =
            "INSERT INTO TAG_IMAGE_DATA(CO_CODE,LC_CODE,TAG_NO,VCH_SRNO,IMAGE_TYPE,MOB_IMAGE) VALUES('${co_code!}','${lc_code!}','${widget.tagNo!}','${widget.VchSrNo!}','T','$base64String')";
        await sqlConnection.updateData(insertImage);
        productImage = image.path;
      } else {
        final dynamic isConnect =
            await MySQLService().connectToDatabase(dbName: imageDb);
        if (isConnect == false || isConnect == null) {
          _showImageMessage('Could not connect to the image server.');
          return;
        }
        await MySQLService()
            .deleteImage(co_code!, lc_code!, widget.tagNo!, widget.VchSrNo!);
        await MySQLService().insertImage(
            co_code!, lc_code!, widget.tagNo!, widget.VchSrNo!, base64String);
        productImage = image.path;
      }
      _showImageMessage('Image saved successfully.');
    } catch (e, s) {
      log('saveToDb failed', error: e, stackTrace: s);
      _showImageMessage('Failed to save the image: $e');
    } finally {
      // Always return to the main database so later screens keep working,
      // even if the image upload failed midway.
      await _reconnectMainDb();
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  void _showImageMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool get _hasTagSelected =>
      productDetail != null &&
      widget.tagNo != null &&
      widget.tagNo!.trim().isNotEmpty;

  bool _ensureTagSelected() {
    if (_hasTagSelected) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _cta,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(14),
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please select a tag number first, then add an image.',
                  style: _pjSans(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    return false;
  }

  Future<void> _reconnectMainDb() async {
    try {
      final String? host = await Preffrance().getString(Keys.HOST);
      final String? userName = await Preffrance().getString(Keys.USERNAME);
      final String? password = await Preffrance().getString(Keys.PASSWORD);
      final String? db = await Preffrance().getString(Keys.DATABASE);
      if (host == null || userName == null || password == null || db == null) {
        return;
      }
      if (Platform.isAndroid) {
        sqlConnection.disconnect();
        await sqlConnection.connect(
          // Host must be split the same way the login screen does — passing
          // the whole "ip:port" string as the ip left the port doubled up.
          ip: host.contains(":") ? host.split(":")[0].toString() : host,
          port: host.contains(":") ? host.split(":")[1].toString() : "1433",
          databaseName: db,
          username: userName,
          password: password,
        );
      } else {
        await MySQLService().connectToDatabase();
      }
    } catch (e, s) {
      log('reconnect main db failed', error: e, stackTrace: s);
    }
  }

  fillterData({
    required String filterItemRate,
    required String filterLbrPrc,
    required String filterLbrRate,
    required String filterLbrCharges,
    required int selectOption,
    required String selectType,
    required String filterGst,
    required bool selectedCheckbox,
    required bool ghatWtOn,
    required bool ghatPrcOn,
    required OtherQtyMode qtyMode,
  }) {
    print("object $selectOption");
    int selectedOption = selectOption;
    bool checkBox = selectedCheckbox;
    // Edited on the sheet's own state and only copied back on Apply, so
    // dismissing the sheet leaves the receipt settings untouched.
    bool ghatWtCheck = ghatWtOn;
    bool ghatPrcCheck = ghatPrcOn;
    OtherQtyMode qtyChoice = qtyMode;
    print("object $selectType");

    String selectedType = selectType;
    TextEditingController lbrPerCntorller =
        TextEditingController(text: filterLbrPrc);
    TextEditingController lbrRateCntorller =
        TextEditingController(text: filterLbrRate);
    TextEditingController lbrChargeCntorller =
        TextEditingController(text: filterLbrCharges);
    TextEditingController lbrDiscountPerCntorller = TextEditingController();
    TextEditingController itemRateCntorller =
        TextEditingController(text: filterItemRate);
    TextEditingController gstRateCntorller =
        TextEditingController(text: filterGst);
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(
          maxHeight: double.infinity,
        ),
        scrollControlDisabledMaxHeightRatio: 0.8,
        useSafeArea: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        context: context,
        isScrollControlled: true,
        builder: (context) =>
            StatefulBuilder(builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                  color: _pageBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [
                    BoxShadow(
                      color: _cta.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  style: IconButton.styleFrom(
                                    foregroundColor: _textSecondary,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                                Expanded(
                                  child: Text(
                                    'Estimate filters',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      color: _cta,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    fillterItemRate = '';
                                    fillterLbrPrc = '';
                                    fillterLbrRate = '';
                                    fillterLbrCharges = '';
                                    fillterGst = '3.00';
                                    selectedItType = 'N';
                                    selectedOpt = 1;
                                    selectedGST = true;
                                    showGhatWt = true;
                                    showGhatPrc = true;
                                    otherQtyMode = OtherQtyMode.auto;
                                    setLableValue();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Clear all',
                                    style: _pjSans(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _cta,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    shadowColor: _cta.withValues(alpha: 0.35),
                                  ),
                                  onPressed: () {
                                    fillterItemRate = itemRateCntorller.text;
                                    fillterLbrPrc = lbrPerCntorller.text;
                                    fillterLbrRate = lbrRateCntorller.text;
                                    fillterLbrCharges = lbrChargeCntorller.text;
                                    fillterGst = gstRateCntorller.text;
                                    selectedItType = selectedType;
                                    selectedOpt = selectedOption;
                                    selectedGST = checkBox;
                                    showGhatWt = ghatWtCheck;
                                    showGhatPrc = ghatPrcCheck;
                                    otherQtyMode = qtyChoice;
                                    setLableValue();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Apply',
                                    style: _pjSans(
                                      size: 14,
                                      weight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: _border.withValues(alpha: 0.65),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _modalSectionCardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.handyman_outlined,
                                            size: 20, color: _cta),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            commonCompanyYearSelectionProvider
                                                        .CoSname ==
                                                    'UAE'
                                                ? 'Making charges'
                                                : 'Labour',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                              color: _cta,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: lbrPerCntorller,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            style: _pjSans(
                                                size: 14,
                                                weight: FontWeight.w600),
                                            onChanged: (vlaue) {
                                              lbrRateCntorller.clear();
                                              lbrChargeCntorller.clear();
                                              setModalState(() {});
                                            },
                                            decoration:
                                                _modalFilterFieldDecoration(
                                                    'Lbr %'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: lbrRateCntorller,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            style: _pjSans(
                                                size: 14,
                                                weight: FontWeight.w600),
                                            onChanged: (value) {
                                              lbrPerCntorller.clear();
                                              lbrChargeCntorller.clear();
                                              setModalState(() {});
                                            },
                                            decoration:
                                                _modalFilterFieldDecoration(
                                                    'Lbr rate'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: lbrChargeCntorller,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: _pjSans(
                                          size: 14, weight: FontWeight.w600),
                                      onChanged: (value) {
                                        lbrRateCntorller.clear();
                                        lbrPerCntorller.clear();
                                        setModalState(() {});
                                      },
                                      decoration: _modalFilterFieldDecoration(
                                          'Lbr charge'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _modalSectionCardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.scale_rounded,
                                            size: 20, color: _cta),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${commonCompanyYearSelectionProvider.CoSname == 'UAE' ? 'Making' : 'Labour'} basis',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                              color: _cta,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        radioTheme: RadioThemeData(
                                          fillColor:
                                              WidgetStateProperty.resolveWith(
                                                  (states) {
                                            if (states.contains(
                                                WidgetState.selected)) {
                                              return _cta;
                                            }
                                            return _border;
                                          }),
                                        ),
                                      ),
                                      child: RadioGroup<int>(
                                        groupValue: selectedOption,
                                        onChanged: (int? value) {
                                          if (value == null) return;
                                          setModalState(() {
                                            selectedOption = value;
                                            selectedType =
                                                value == 1 ? 'G' : 'N';
                                            print('Button value: $value');
                                          });
                                        },
                                        child: Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            _filterRadioChip(
                                              selectedOption == 1,
                                              Radio<int>(
                                                value: 1,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              'Gross weight',
                                            ),
                                            _filterRadioChip(
                                              selectedOption == 2,
                                              Radio<int>(
                                                value: 2,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              'Net weight',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _modalSectionCardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.payments_outlined,
                                            size: 20, color: _cta),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Item rate (per gram)',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                            color: _cta,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: itemRateCntorller,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: _pjSans(
                                          size: 14, weight: FontWeight.w600),
                                      decoration: _modalFilterFieldDecoration(
                                          'Enter item rate'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _modalSectionCardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.receipt_long_rounded,
                                            size: 20, color: _cta),
                                        const SizedBox(width: 8),
                                        Text(
                                          'GST tax',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                            color: _cta,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _cta.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _cta.withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Theme(
                                            data: Theme.of(context).copyWith(
                                              checkboxTheme: CheckboxThemeData(
                                                fillColor: WidgetStateProperty
                                                    .resolveWith((states) {
                                                  if (states.contains(
                                                      WidgetState.selected)) {
                                                    return _cta;
                                                  }
                                                  return _border;
                                                }),
                                              ),
                                            ),
                                            child: Checkbox(
                                              value: checkBox,
                                              onChanged: (newValue) {
                                                checkBox = newValue!;
                                                print(newValue);
                                                setModalState(() {});
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Apply GST on estimate',
                                              style: _pjSans(
                                                size: 14,
                                                weight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: gstRateCntorller,
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true),
                                              textAlign: TextAlign.end,
                                              style: _pjSans(
                                                size: 14,
                                                weight: FontWeight.w700,
                                              ),
                                              decoration:
                                                  _modalFilterFieldDecoration(
                                                      'GST %'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _ghatToggleRow(
                                      label: 'Show ghat weight on POS print',
                                      value: ghatWtCheck,
                                      onChanged: (v) {
                                        ghatWtCheck = v;
                                        setModalState(() {});
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _ghatToggleRow(
                                      label: 'Show ghat % on POS print',
                                      value: ghatPrcCheck,
                                      onChanged: (v) {
                                        ghatPrcCheck = v;
                                        setModalState(() {});
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _cta.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color:
                                                _cta.withValues(alpha: 0.12)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Other details quantity',
                                            style: _pjSans(
                                                size: 14,
                                                weight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              for (final mode
                                                  in OtherQtyMode.values)
                                                GestureDetector(
                                                  onTap: () {
                                                    qtyChoice = mode;
                                                    setModalState(() {});
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 13,
                                                        vertical: 7),
                                                    decoration: BoxDecoration(
                                                      color: qtyChoice == mode
                                                          ? _cta
                                                          : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                          color:
                                                              qtyChoice == mode
                                                                  ? _cta
                                                                  : _border),
                                                    ),
                                                    child: Text(
                                                      mode.label,
                                                      style: _pjSans(
                                                        size: 13,
                                                        weight: FontWeight.w700,
                                                        color: qtyChoice == mode
                                                            ? Colors.white
                                                            : _textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }));
  }

  setLableValue() {
    print("Hello");
    // print("Hello lbr ${productDetail["LBR_RATE"]}");

    widget.VchSrNo = BigInt.from(productDetail["VCH_SRNO"]).toString();
    var temRate = 0.0;
    var intLbrPRC = productDetail["LBR_PRC"];
    fillterLbrRate = double.parse(productDetail["LBR_RATE"].toString()) != 0.0
        ? double.parse(productDetail["LBR_RATE"].toString()).toStringAsFixed(2)
        : "";
    print("lbr ${fillterLbrRate}");
    var intOthAmount = productDetail["OTH_AMT"];
    if (fillterItemRate.isNotEmpty && fillterItemRate != "0") {
      // convert into 10 gram rate
      temRate = double.parse(fillterItemRate) ?? 0.0;
    } else {
      // temRate = productDetail["Rate"] / 10;
      temRate = productDetail["Rate"];
    }
    var itmRate = 0.0;
    if (temRate > 0.0) {
      print(temRate);
      // itmRate = temRate / 10;
      itmRate = temRate;
    }
    var tempGwtNwt = selectedItType == "G"
        ? productDetail["ITM_GWT"]
        : productDetail["TagNwt"];
    var intLbrGhat = 0.0;
    if (productDetail["ITM_GHAT"] != 0) {
      intLbrGhat = productDetail["ITM_GHAT"];
    }
    var itAmount = 0.0;
    if (Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .amountType ==
        "N") {
      itAmount = itmRate *
          (productDetail["TagNwt"] +
              double.parse(intLbrGhat.toStringAsFixed(3)));
    } else if (Provider.of<CommonCompanyYearSelectionProvider>(context,
                listen: false)
            .amountType ==
        "G") {
      itAmount = itmRate * productDetail["ITM_GWT"];
    } else if (Provider.of<CommonCompanyYearSelectionProvider>(context,
                listen: false)
            .amountType ==
        "F") {
      itAmount = itmRate * productDetail["ITM_FINE"]; // other users
      // itAmount = itmRate * (productDetail["TagNwt"]+((productDetail["TagNwt"]*16)/100)); // For only Ganda user vijaywada customer
    } else {
      itAmount = itmRate *
          (productDetail["TagNwt"] +
              double.parse(intLbrGhat.toStringAsFixed(3)));
    }
    var LbrRate = 0.0;
    var LbrAmt = 0.0;
    var intLbrAmount = productDetail["LBR_AMT"];
    print("LBR AMT $intLbrAmount");
    var intMRP = productDetail["ITM_MRP"];
    if (fillterLbrPrc.isNotEmpty && fillterLbrPrc != "0") {
      print("ABCD 3");
      LbrRate = (itmRate * double.parse(fillterLbrPrc)) / 100;
      LbrAmt = LbrRate * (tempGwtNwt + intLbrGhat);
      intLbrPRC = double.parse(fillterLbrPrc);
    } else if (fillterLbrRate.isNotEmpty && fillterLbrRate != "0") {
      LbrAmt = productDetail['LBR_TYPE'] == "P"
          ? double.parse(fillterLbrRate) * productDetail['ITM_PCS']
          : double.parse(fillterLbrRate) * (tempGwtNwt + intLbrGhat);
      LbrRate = double.parse(fillterLbrRate);
      intLbrPRC = 0.0;
    } else if (fillterLbrCharges.isNotEmpty && fillterLbrCharges != "0") {
      print("ABCD 1");
      LbrAmt = double.parse(fillterLbrCharges);
      LbrRate = 0.0;
      intLbrPRC = 0.0;
    } else {
      print("ABCD");
      if (intLbrPRC != 0.0) {
        LbrRate = ((itmRate * intLbrPRC) / 100);
        LbrAmt = LbrRate.round().toDouble() * (tempGwtNwt + intLbrGhat);
        print("Lab rate ${LbrRate}");
        print("Lab rate ${tempGwtNwt}");
        print("Lab rate ${intLbrGhat}");
        print("Lab AMT ${LbrAmt}");
      } else {
        print("Labbb AMT ");
        LbrAmt = intLbrAmount;
      }
    }

    // var intAmount = itmRate * (productDetail["TagNwt"] + intLbrGhat);
    var intNetAmount;
    if (intMRP != 0) {
      intNetAmount = intMRP;
    } else {
      intNetAmount = LbrAmt + intOthAmount + itAmount;
    }
    print("Labbb AMT ");
    itemRate = itmRate.toString();
    itemAmount = itAmount.round().toStringAsFixed(2);
    lbrPrc = intLbrPRC.toString();
    lbrRate = LbrRate.round().toStringAsFixed(2);
    lbrAmmount = LbrAmt.round().toStringAsFixed(2);
    othAmmount = intOthAmount.toString();
    mrp = intMRP.toString();
    netAmmount = double.parse(intNetAmount.toString()).round().toString();
    var TaxAmount = 0.0;
    if (selectedGST && fillterGst.isNotEmpty && fillterGst != "0") {
      if (commonCompanyYearSelectionProvider.CoSname == "UAE") {
        TaxAmount = (intNetAmount * double.parse("5")) / 100;
      } else {
        TaxAmount = (intNetAmount * double.parse(fillterGst)) / 100;
      }
    }
    gstTax = TaxAmount.round().toString();
    totalAmount =
        double.parse((intNetAmount + TaxAmount).toString()).round().toString();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print("III $productImage");
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        automaticallyImplyLeading: false,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white.withValues(alpha: 0.96),
                _pageBg,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: IconButton(
            splashRadius: 26,
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _cta,
              size: 22,
            ),
          ),
        ),
        title: Text(
          'Tag estimate',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            color: _cta,
          ),
        ),
        actions: [
          IconButton(
            splashRadius: 26,
            onPressed: () {
              fillterData(
                filterItemRate: fillterItemRate,
                filterLbrPrc: fillterLbrPrc,
                filterLbrRate: fillterLbrRate,
                filterLbrCharges: fillterLbrCharges,
                selectOption: selectedOpt,
                selectType: selectedItType,
                filterGst: fillterGst,
                selectedCheckbox: selectedGST,
                ghatWtOn: showGhatWt,
                ghatPrcOn: showGhatPrc,
                qtyMode: otherQtyMode,
              );
            },
            icon: Icon(Icons.tune_rounded, color: _cta, size: 26),
            tooltip: 'Filters',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: _border.withValues(alpha: 0.65),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFEEF2F7),
                    _pageBg,
                    _pageBg,
                  ],
                  stops: const [0.0, 0.22, 1.0],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 8.0,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 0.0),
                          child: TextFormField(
                            controller: searchController,
                            readOnly: false,
                            // onTap: () {
                            //   if (data == "BaddPolicy") {
                            //     Navigation.PushNavigation(context: context, screen: Business_source());
                            //   } else {
                            //     if (isCustomerFiled) {
                            //       Navigation.PushNavigation(
                            //           context: context,
                            //           screen: SearchCustomerPage(
                            //             title: 'Search Customer',
                            //             type: data!,
                            //           ));
                            //     }
                            //   }
                            // },
                            onChanged: (value) {
                              if (value.length == 7 || value.length == 8) {
                                widget.tagNo = value;
                                widget.VchSrNo = null;
                                widget.productImage = null;
                                getProductDetail();
                              }
                            },
                            style: _pjSans(size: 14, weight: FontWeight.w600),
                            cursorColor: _cta,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              UpperCaseTextFormatter(),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Search tag no',
                              hintStyle: _pjSans(
                                size: 14,
                                weight: FontWeight.w500,
                                color: _textSecondary.withValues(alpha: 0.75),
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: _textSecondary.withValues(alpha: 0.8),
                                size: 22,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: _border, width: 1.25),
                              ),
                              suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  QRViewExample(
                                                    isFromTagScreen: true,
                                                  ))).then((onValue) {
                                        // Null when the scanner was closed
                                        // without scanning anything.
                                        if (onValue is! List ||
                                            onValue.isEmpty ||
                                            !mounted) {
                                          return;
                                        }
                                        widget.tagNo = onValue[0];
                                        widget.VchSrNo = null;
                                        widget.productImage = null;
                                        searchController.text = onValue[0];
                                        setState(() {});
                                        getProductDetail();
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _cta.withValues(alpha: 0.14),
                                            _cta.withValues(alpha: 0.06),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.qr_code_scanner_rounded,
                                        color: _cta,
                                        size: 22,
                                      ),
                                    ),
                                  )),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: _cta, width: 1.75),
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          widget.tagNo = searchController.text;
                          widget.VchSrNo = null;
                          widget.productImage = null;
                          getProductDetail();
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          margin: const EdgeInsets.only(right: 12, left: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _cta.withValues(alpha: 0.22),
                                _cta.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _cta.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _cta.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: _cta,
                            size: 28,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                  child: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (productImage != "") {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ImageScreen(
                                            url: productImage,
                                            TagNo: widget.tagNo!,
                                            gWeight: double.parse(
                                                    productDetail["ITM_GWT"]
                                                        .toString())
                                                .toStringAsFixed(3),
                                            nWeight: double.parse(
                                                    productDetail["TagNwt"]
                                                        .toString())
                                                .toStringAsFixed(3),
                                          )));
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: _border, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.08),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(5),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: productImage == ""
                                    ? Image.asset(AppImage.placeHolder,
                                        fit: BoxFit.cover)
                                    : productImage
                                            .toLowerCase()
                                            .contains("http")
                                        ? Image.network(productImage,
                                            fit: BoxFit.cover,
                                            cacheWidth: 1080,
                                            errorBuilder: (context, _, t) =>
                                                Image(
                                                  image: AssetImage(
                                                      AppImage.placeHolder),
                                                  fit: BoxFit.cover,
                                                ))
                                        : Image.file(
                                            File(productImage),
                                            fit: BoxFit.cover,
                                            cacheWidth: 1080,
                                            errorBuilder: (context, _, __) =>
                                                Image(
                                              image: AssetImage(
                                                  AppImage.placeHolder),
                                              fit: BoxFit.cover,
                                            ),
                                          )),
                          ),
                        ),
                        Positioned(
                          bottom: 18,
                          left: 24,
                          right: 24,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _imageActionButton(
                                icon: Icons.photo_camera_rounded,
                                label: 'Camera',
                                onTap: () async {
                                  if (!_ensureTagSelected()) return;
                                  final ImagePicker picker = ImagePicker();
                                  // Downscale at capture time so full-resolution
                                  // camera photos don't run low-RAM devices out
                                  // of memory before we ever compress them.
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.camera,
                                    maxWidth: 1080,
                                    maxHeight: 1080,
                                    imageQuality: 85,
                                  );
                                  if (image != null) {
                                    saveToDb(image);
                                  }
                                },
                              ),
                              _imageActionButton(
                                icon: Icons.photo_library_rounded,
                                label: 'Gallery',
                                onTap: () async {
                                  if (!_ensureTagSelected()) return;
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1080,
                                    maxHeight: 1080,
                                    imageQuality: 85,
                                  );
                                  if (image != null) {
                                    saveToDb(image);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        if (productDetail == null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                margin:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              _cta.withValues(alpha: 0.22),
                                              _cta.withValues(alpha: 0.08),
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.qr_code_2_rounded,
                                          color: _cta,
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No tag selected',
                                        style: _pjSans(
                                          size: 16,
                                          weight: FontWeight.w800,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Search or scan a tag number to\nview its estimate and add images.',
                                        textAlign: TextAlign.center,
                                        style: _pjSans(
                                          size: 12.5,
                                          weight: FontWeight.w600,
                                          color: _textSecondary,
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
                    _sectionCard(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        children: [
                          _statTile(
                            Icons.widgets_rounded,
                            'Pieces',
                            productDetail == null
                                ? '—'
                                : productDetail["ITM_PCS"].toString(),
                          ),
                          Container(
                            height: 52,
                            width: 1,
                            color: _border.withValues(alpha: 0.85),
                          ),
                          _statTile(
                            Icons.scale_rounded,
                            'Net Weight',
                            productDetail == null
                                ? '—'
                                : productDetail["TagNwt"] == ''
                                    ? '-'
                                    : double.parse(productDetail["TagNwt"]
                                                .toString())
                                            .toStringAsFixed(3) ??
                                        '—',
                          ),
                          Container(
                            height: 52,
                            width: 1,
                            color: _border.withValues(alpha: 0.85),
                          ),
                          _statTile(
                            Icons.payments_rounded,
                            commonCompanyYearSelectionProvider.CoSname == 'UAE'
                                ? 'AED'
                                : 'Amount',
                            productDetail == null
                                ? '—'
                                : double.parse(totalAmount)
                                        .toStringAsFixed(2) ??
                                    '—',
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                              Icons.diamond_rounded, 'PRODUCT SPECIFICATION'),
                          const SizedBox(height: 4),
                          _infoRow(
                            "Item Name",
                            productDetail == null
                                ? "—"
                                : productDetail["IT_NAME"] == ""
                                    ? "—"
                                    : productDetail["IT_NAME"],
                            showDivider: false,
                          ),
                          _infoRow(
                            "Tag No",
                            productDetail == null
                                ? "—"
                                : productDetail["TAG_NO"] == ""
                                    ? "—"
                                    : productDetail["TAG_NO"],
                          ),
                          _infoRow(
                            "Item Pcs",
                            productDetail == null
                                ? "—"
                                : productDetail["ITM_PCS"].toString(),
                          ),
                          if (productDetail != null &&
                              productDetail["DESIGN_NO"] != "")
                            _infoRow(
                              "Design",
                              productDetail["DESIGN_NO"] ?? "—",
                            ),
                          _infoRow(
                            "Size",
                            productDetail == null
                                ? "—"
                                : productDetail["ITM_SIZE"] == ""
                                    ? "—"
                                    : (productDetail["ITM_SIZE"] ?? "—"),
                          ),
                          _infoRow(
                            "Gross Weight",
                            productDetail == null
                                ? "—"
                                : productDetail["ITM_GWT"] == ""
                                    ? "—"
                                    : double.parse(
                                            productDetail["ITM_GWT"].toString())
                                        .toStringAsFixed(3),
                          ),
                          _infoRow(
                            "Net Weight",
                            productDetail == null
                                ? "—"
                                : productDetail["TagNwt"] == ""
                                    ? "—"
                                    : double.parse(
                                            productDetail["TagNwt"].toString())
                                        .toStringAsFixed(3),
                          ),

                           if(printingLable != null &&
                              printingLable.any(
                                    (e) =>
                                e["COL_NAME"].toString().toLowerCase() == "ght%" &&
                                    e["YES_NO"] == "Y",
                              ))
                               _infoRow(
                            "${printingLable.firstWhere((e) => e["COL_NAME"].toString().toLowerCase() == "ght%" && e["YES_NO"] == "Y")["COL_NEW_NAME"]}",
                            "${(double.tryParse(productDetail?["ITM_GHT_PRC"].toString() ?? "0") ?? 0).toStringAsFixed(2)}%",
                          ),
                              // : const SizedBox(),

                           if(printingLable != null &&
                              printingLable.any(
                                    (e) =>
                                e["COL_NAME"].toString().toLowerCase() == "ghtwt" &&
                                    e["YES_NO"] == "Y",
                              ))
                             _infoRow(
                               "${printingLable.firstWhere((e) => e["COL_NAME"].toString().toLowerCase() == "ghtwt" && e["YES_NO"] == "Y")["COL_NEW_NAME"]}",
                               "${(double.tryParse(productDetail?["ITM_GHAT"].toString() ?? "0") ?? 0).toStringAsFixed(3)}",
                             ),

                              // : const SizedBox(),

                          //
                          // productDetail == null || productDetail["ITM_GHAT"] == 0
                          //     ? SizedBox()
                          //     : Padding(
                          //         padding: const EdgeInsets.only(
                          //             right: 12.0, left: 12.0, top: 8),
                          //         child: Row(
                          //           children: [
                          //             Text(
                          //               "Ghat Weight :",
                          //               style: GoogleFonts.nunito(
                          //                   fontWeight: FontWeight.w900,
                          //                   fontSize: 12),
                          //             ),
                          //             Spacer(),
                          //             Text(
                          //               productDetail == null
                          //                   ? "-:-" : double.parse(productDetail["ITM_GHAT"]
                          //                       .toString())
                          //                   .toStringAsFixed(3),
                          //               style: GoogleFonts.nunito(
                          //                   fontWeight: FontWeight.w900,
                          //                   fontSize: 12),
                          //             ),
                          //           ],
                          //         ),
                          //       ),

                          // For ganda user below

                          // Padding(
                          //   padding: const EdgeInsets.only(
                          //       right: 12.0, left: 12.0, top: 8),
                          //   child: Row(
                          //     children: [
                          //       Text(
                          //         "West% :",
                          //         style: GoogleFonts.nunito(
                          //             fontWeight: FontWeight.w900, fontSize: 12),
                          //       ),
                          //       Spacer(),
                          //       Text(
                          //         productDetail == null
                          //             ? "-:-"
                          //             : productDetail["ITM_WEST_PRC"] == ""
                          //             ? "-"
                          //             : "${double.parse(productDetail["ITM_WEST_PRC"].toString()).toStringAsFixed(2)}%"??
                          //             "-:-",
                          //         style: GoogleFonts.nunito(
                          //             fontWeight: FontWeight.w900, fontSize: 12),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          if (productDetail != null &&
                              Provider.of<CommonCompanyYearSelectionProvider>(
                                          context,
                                          listen: false)
                                      .amountType ==
                                  "F")
                            _infoRow(
                              "Fine Weight",
                              productDetail["ITM_FINE"] == ""
                                  ? "—"
                                  : double.parse(
                                          productDetail["ITM_FINE"].toString())
                                      .toStringAsFixed(3),
                            ),
                          if (printingLable != null &&
                              hddNo == "VK289NEPH" &&
                              (printingLable?.any(
                                    (e) =>
                                        e["COL_NAME"]
                                                .toString()
                                                .toLowerCase() ==
                                            "ght%" &&
                                        e["YES_NO"] == "Y",
                                  ) ??
                                  false))
                            _infoRow(
                              "Total Weight",
                              productDetail == null
                                  ? "—"
                                  : double.parse((productDetail["TagNwt"] +
                                              ((productDetail["TagNwt"] *
                                                      productDetail[
                                                          "ITM_GHT_PRC"]) /
                                                  100))
                                          .toString())
                                      .toStringAsFixed(3),
                            ),
                          _infoRow(
                            "Item Rate",
                            productDetail == null
                                ? "—"
                                : itemRate == ""
                                    ? "—"
                                    : double.parse(itemRate.toString())
                                        .toStringAsFixed(2),
                          ),
                          _infoRow(
                            commonCompanyYearSelectionProvider.CoSname == "UAE"
                                ? "Metal Value (AED)"
                                : "Item Amount",
                            productDetail == null
                                ? "—"
                                : itemAmount == ""
                                    ? "—"
                                    : double.parse(itemAmount.toString())
                                        .toStringAsFixed(2),
                          ),
                          _infoRow(
                            "${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Making" : "Labour"} Prc%",
                            productDetail == null
                                ? "—"
                                : double.parse(lbrPrc.toString())
                                    .toStringAsFixed(2),
                          ),
                          _infoRow(
                            "${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Making" : "Labour"} Rate",
                            productDetail == null
                                ? "—"
                                : double.parse(lbrRate.toString())
                                    .toStringAsFixed(2),
                          ),
                          _infoRow(
                            commonCompanyYearSelectionProvider.CoSname == "UAE"
                                ? "Making Charges(AED)"
                                : "Labour Amount",
                            productDetail == null
                                ? "—"
                                : double.parse(lbrAmmount.toString())
                                    .toStringAsFixed(2),
                          ),
                          _infoRow(
                            "Other ${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Charges(AED)" : "Amount"}",
                            productDetail == null
                                ? "—"
                                : double.parse(othAmmount.toString())
                                    .toStringAsFixed(2),
                          ),
                          if (commonCompanyYearSelectionProvider.CoSname !=
                              "UAE")
                            _infoRow(
                              "MRP",
                              productDetail == null
                                  ? "—"
                                  : double.parse(mrp.toString())
                                      .toStringAsFixed(2),
                            ),
                          _infoRow(
                            "Net ${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Value(AED)" : "Amount"}",
                            productDetail == null
                                ? "—"
                                : double.parse(netAmmount).toStringAsFixed(2),
                            accent: true,
                          ),
                          _infoRow(
                            commonCompanyYearSelectionProvider.CoSname == "UAE"
                                ? "VAT 5% (AED)"
                                : "GST Tax",
                            productDetail == null
                                ? "—"
                                : double.parse(gstTax).toStringAsFixed(2),
                          ),
                          _infoRow(
                            "Total ${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Value (AED)" : "Amount"}",
                            productDetail == null
                                ? "—"
                                : double.parse(totalAmount).toStringAsFixed(2),
                            accent: true,
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: _border.withValues(alpha: 0.6),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    checkboxTheme: CheckboxThemeData(
                                      fillColor:
                                          WidgetStateProperty.resolveWith((s) {
                                        if (s.contains(WidgetState.selected)) {
                                          return _cta;
                                        }
                                        return _border;
                                      }),
                                    ),
                                  ),
                                  child: Checkbox(
                                    value: printImageInPdf,
                                    onChanged: (value) {
                                      setState(() {
                                        printImageInPdf = value ?? true;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Print item image in estimate',
                                    style: _pjSans(
                                        size: 14, weight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (productDetail == null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("Please Search Tag"),
                                  ));
                                  return;
                                }
                                try {
                                  await createPDF();
                                } catch (e, s) {
                                  log('create pdf failed',
                                      error: e, stackTrace: s);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text("Failed to create PDF: $e"),
                                  ));
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _cta,
                                      Color.lerp(_cta, Colors.black, 0.12)!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _cta.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.picture_as_pdf_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text("Create PDF",
                                        style: _ctaButtonTextStyle()),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (productDetail == null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("Please Search Tag"),
                                  ));
                                  return;
                                }
                                if (productImage.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content:
                                        Text("No image available to share"),
                                  ));
                                  return;
                                }
                                try {
                                  await _processAndShareImage(productImage);
                                } catch (e, s) {
                                  log('share tag failed',
                                      error: e, stackTrace: s);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text("Failed to share tag: $e"),
                                  ));
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: _cta.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _cta.withValues(alpha: 0.45),
                                      width: 1.4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.ios_share_rounded,
                                        color: _cta, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Share Tag",
                                      style: _pjSans(
                                        size: 15,
                                        weight: FontWeight.w800,
                                        color: _cta,
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
                    // ── Combined estimate ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (productDetail == null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("Please Search Tag"),
                                  ));
                                  return;
                                }
                                if (!_combinedEstimateAllowed()) return;
                                await _addToEstimate();
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: _cta.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _cta.withValues(alpha: 0.45),
                                      width: 1.4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.playlist_add_rounded,
                                        color: _cta, size: 19),
                                    const SizedBox(width: 8),
                                    Text("Add to estimate",
                                        style: _pjSans(
                                            size: 15,
                                            weight: FontWeight.w800,
                                            color: _cta)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Consumer<EstimateCartProvider>(
                            builder: (context, cart, _) => Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (!_combinedEstimateAllowed()) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const EstimateCartScreen()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: _cta,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.receipt_long_rounded,
                                            color: Colors.white, size: 19),
                                        const SizedBox(width: 7),
                                        Text('${cart.count}',
                                            style: _pjSans(
                                                size: 15,
                                                weight: FontWeight.w800,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                                // Clearing has to be reachable from here too:
                                // after printing a combined estimate the count
                                // stays, and the next customer must start from
                                // an empty list without a detour through the
                                // cart screen. Hidden while the cart is empty.
                                if (!cart.isEmpty) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _confirmClearEstimate(cart),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 13, vertical: 15),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: const Color(0xFFDC2626)
                                                .withValues(alpha: 0.5),
                                            width: 1.4),
                                      ),
                                      child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFFDC2626),
                                          size: 20),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── POS receipt ────────────────────────────────────────
                    // Full width on its own row rather than a third button in
                    // the row above, which would squeeze all three labels on
                    // narrow phones.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: GestureDetector(
                        onTap: () async {
                          if (productDetail == null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Please Search Tag"),
                            ));
                            return;
                          }
                          try {
                            await createPOSPDF();
                          } catch (e, s) {
                            log('create pos pdf failed',
                                error: e, stackTrace: s);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Failed to create POS print: $e"),
                            ));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _cta.withValues(alpha: 0.45),
                                width: 1.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  color: _cta, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "POS Print (58mm)",
                                style: _pjSans(
                                  size: 15,
                                  weight: FontWeight.w800,
                                  color: _cta,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ))
            ],
          ),
        ],
      ),
    );
  }

  /// Loads the BAR_IDTL charges for the current tag.
  ///
  /// Kept separate from the PDF builders so adding a tag to the combined
  /// estimate does not depend on generating a document first.
  Future<List<Map<String, dynamic>>> _loadOtherDetailsRows() async {
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    try {
      dynamic rows;
      if (Platform.isAndroid) {
        final q =
            "SELECT * FROM BAR_IDTL WHERE CO_CODE='${provider.co_code}' AND LC_CODE='${provider.lc_code}' AND TAG_NO='${widget.tagNo}' AND VCH_SRNO=${productDetail["VCH_SRNO"]}";
        rows = jsonDecode(await sqlConnection.queryDatabase(q));
      } else {
        final data = await MySQLService().getOtherDetails(
          provider.co_code,
          provider.lc_code,
          widget.tagNo!,
          productDetail["VCH_SRNO"].toString(),
        );
        rows = data[0];
      }
      return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      log('other details load failed: $e');
      return const [];
    }
  }

  /// Confirms before wiping the combined estimate.
  ///
  /// Same guard as the cart screen: a multi-tag quotation is real work and a
  /// stray tap should not discard it.
  Future<void> _confirmClearEstimate(EstimateCartProvider cart) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Clear estimate?",
            style: _pjSans(size: 17, weight: FontWeight.w700)),
        content: Text(
            "All ${cart.count} items in this quotation will be removed.",
            style: _pjSans(size: 14, weight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel",
                style: _pjSans(size: 14, weight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Clear",
                style: _pjSans(
                    size: 14, weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      cart.clear();
      showAppToast(context, "Estimate cleared");
    }
  }

  /// The combined (multi-tag) estimate is a full-edition feature: E / U / P / A
  /// only. Returns false and shows the upgrade dialog otherwise.
  bool _combinedEstimateAllowed() {
    final licence =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    if (hasFullEdition(licence.sType, licence.dType)) return true;
    showUpgradeRequiredDialog(context);
    return false;
  }

  /// Snapshots the currently calculated tag into the combined estimate.
  Future<void> _addToEstimate() async {
    double n(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;
    final cart = Provider.of<EstimateCartProvider>(context, listen: false);
    final others = await _loadOtherDetailsRows();
    if (!mounted) return;
    final tag = '${widget.tagNo ?? ''}'.trim();
    // The photo is captured now, honouring the same "Print item image"
    // toggle the single-tag PDF uses, so the combined document does not have
    // to re-fetch anything at print time.
    Uint8List? image;
    if (printImageInPdf && productImage.trim().isNotEmpty) {
      image = await getByteCode(productImage);
    }
    if (!mounted) return;
    cart.add(EstimateItem(
      tagNo: tag,
      itemName: '${productDetail?["IT_NAME"] ?? ''}'.trim(),
      designNo: '${productDetail?["DESIGN_NO"] ?? ''}'.trim(),
      pcs: '${productDetail?["ITM_PCS"] ?? '0'}',
      grossWt: n(productDetail?["ITM_GWT"]),
      netWt: n(productDetail?["TagNwt"]),
      rate: n(itemRate),
      itemAmount: n(itemAmount),
      labourPrc: n(lbrPrc),
      labourRate: n(lbrRate),
      labourAmount: n(lbrAmmount),
      otherAmount: n(othAmmount),
      netAmount: n(netAmmount),
      gstTax: n(gstTax),
      totalAmount: n(totalAmount),
      otherDetails: others,
      imageBytes: image,
    ));
    if (!mounted) return;
    showAppToast(context, "$tag added to the estimate (${cart.count} items)");
  }

  /// True when a numeric string holds a value above zero.
  ///
  /// Used to hide receipt lines that would otherwise print "0.00" — a labour
  /// percentage of zero means labour was charged as a flat amount, not that
  /// the rate is genuinely zero.
  bool _isPositive(dynamic value) =>
      (double.tryParse(value?.toString() ?? "") ?? 0) > 0;

  /// Sum of the other-details charges, so the receipt shows what they add up
  /// to rather than leaving the reader to total the lines by hand.
  double _otherDetailsTotal(dynamic rows) {
    double total = 0;
    for (final d in rows) {
      total += double.tryParse(d["IT_NET_AMT"]?.toString() ?? "") ?? 0;
    }
    return total;
  }

  /// Builds the estimate for a 58mm thermal roll (POS counter printer).
  ///
  /// Kept separate from [createPDF] on purpose: that one is an A4 sheet meant
  /// for WhatsApp and email. Feeding an A4 page to a 58mm roll makes the
  /// printer scale the whole layout down to fit the paper, which is why the
  /// text came out tiny. A receipt needs its own page size and its own
  /// single-column layout, not a shrunk copy of the A4 one.
  Future<void> createPOSPDF() async {
    final pdf = pw.Document();
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    final bool isUae = provider.CoSname == "UAE";

    dynamic companyDetails;
    if (Platform.isAndroid) {
      String companyData =
          "SELECT CO_NAME,CO_ADD1,CO_ADD2,CO_ADD3,CO_CITY,CO_PIN,CO_MOBILE FROM CO_MAST WHERE CO_CODE = ${provider.co_code}";
      dynamic dataofCompany = await sqlConnection.queryDatabase(companyData);
      companyDetails = jsonDecode(dataofCompany)[0];
    } else {
      dynamic companyData = await MySQLService().getCompanyDetail(co_code!);
      companyDetails = companyData[0][0];
    }

    dynamic otherDetailsData;
    if (Platform.isAndroid) {
      String otherDetailsQuery =
          "SELECT * FROM BAR_IDTL WHERE CO_CODE='${provider.co_code}' AND LC_CODE='${provider.lc_code}' AND TAG_NO='${widget.tagNo}' AND VCH_SRNO=${productDetail["VCH_SRNO"]}";
      dynamic rawData = await sqlConnection.queryDatabase(otherDetailsQuery);
      otherDetailsData = jsonDecode(rawData);
    } else {
      dynamic data = await MySQLService().getOtherDetails(
        provider.co_code!,
        provider.lc_code!,
        widget.tagNo!,
        productDetail["VCH_SRNO"].toString(),
      );
      otherDetailsData = data[0];
    }

    final blockedHddList = [
      "VK289NEPH",
      "VK103NEVK",
      "VK061NEVK",
      "HM208NEPK",
      "AB000NEAB"
    ];

    // Courier is a built-in PDF font, so it needs no asset and its fixed width
    // keeps the value column aligned down the receipt.
    final mono = pw.Font.courier();
    final monoBold = pw.Font.courierBold();

    String fmt(dynamic v, int d) {
      final parsed = double.tryParse(v?.toString() ?? "");
      return parsed == null ? "-" : parsed.toStringAsFixed(d);
    }

    pw.Widget rule() => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child:
              pw.Divider(height: 0.5, thickness: 0.5, color: PdfColors.black),
        );

    pw.Widget row(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Text(label,
                  style: pw.TextStyle(
                      font: bold ? monoBold : mono,
                      fontSize: bold ? 8 : 7,
                      color: PdfColors.black)),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Text(value,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      font: bold ? monoBold : mono,
                      fontSize: bold ? 8 : 7,
                      color: PdfColors.black)),
            ),
          ],
        ),
      );
    }

    // Cell for the other-details table. 6pt is the smallest size that stays
    // legible on a 203dpi thermal head; headers drop to 5.5 because they are
    // words rather than figures the customer has to read precisely.
    pw.Widget cell(String text, {bool header = false, bool right = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 1.5),
          child: pw.Text(
            text,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
                font: header ? monoBold : mono,
                fontSize: header ? 5.5 : 6,
                color: PdfColors.black),
          ),
        );

    pw.Widget centered(String text, double size, {bool bold = false}) =>
        pw.Container(
          width: double.infinity,
          child: pw.Text(text,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  font: bold ? monoBold : mono,
                  fontSize: size,
                  color: PdfColors.black)),
        );

    final String itemName = '${productDetail?["IT_NAME"] ?? ''}'.trim();
    final String designNo = '${productDetail?["DESIGN_NO"] ?? ''}'.trim();
    final String currency = isUae ? "AED " : "";

    pdf.addPage(
      pw.Page(
        // roll57 is 57mm wide with 5mm margins and an unbounded height, so the
        // receipt runs as one continuous strip instead of being paginated.
        pageFormat: PdfPageFormat.roll57,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            if (!blockedHddList.contains(hddNo)) ...[
              centered('${companyDetails["CO_NAME"]}', 9, bold: true),
              pw.SizedBox(height: 2),
              centered(
                  '${companyDetails["CO_ADD1"]}, ${companyDetails["CO_ADD2"]}',
                  6),
              centered(
                  '${companyDetails["CO_ADD3"]}, ${companyDetails["CO_CITY"]}-${companyDetails["CO_PIN"]}',
                  6),
              centered('Mo: ${companyDetails["CO_MOBILE"]}', 6),
              pw.SizedBox(height: 3),
            ],
            rule(),
            centered("ESTIMATE", 9, bold: true),
            rule(),
            row("Date", DateFormat("dd/MM/yyyy").format(DateTime.now())),
            row("Tag No", '${widget.tagNo ?? ''}'),
            if (itemName.isNotEmpty) row("Item", itemName),
            if (designNo.isNotEmpty && designNo != "null")
              row("Design", designNo),
            rule(),
            row("Pcs", '${productDetail?["ITM_PCS"] ?? '-'}'),
            row("Gross Wt", fmt(productDetail?["ITM_GWT"], 3)),
            row("Net Wt", fmt(productDetail?["TagNwt"], 3)),
            // Ghat (wastage), each line switchable from the estimate filter
            // sheet. ITM_GHAT and ITM_GHT_PRC are the same two values the
            // on-screen detail and the A4 estimate print, so the receipt
            // cannot disagree with them. A zero value is skipped even when
            // the option is on, matching how the labour lines behave.
            if (showGhatWt && _isPositive(productDetail?["ITM_GHAT"]))
              row(_ghatLabel("GhtWt", "Ghat Wt"),
                  fmt(productDetail?["ITM_GHAT"], 3)),
            if (showGhatPrc && _isPositive(productDetail?["ITM_GHT_PRC"]))
              row(_ghatLabel("Ght%", "Ghat %"),
                  "${fmt(productDetail?["ITM_GHT_PRC"], 2)} %"),
            rule(),
            row("Rate 1 gm", currency + fmt(itemRate, 2)),
            row("Item Amt", currency + fmt(itemAmount, 2)),
            // Labour breakdown. The percentage and the per-gram rate only
            // exist when labour is charged by weight; a flat labour amount
            // leaves both at zero, so they are hidden rather than printed as
            // a misleading "0.00". The amount always prints.
            if (_isPositive(lbrPrc))
              row(isUae ? "Making %" : "Labour %", "${fmt(lbrPrc, 2)} %"),
            if (_isPositive(lbrRate))
              row(isUae ? "Making Rate" : "Labour Rate",
                  currency + fmt(lbrRate, 2)),
            row(isUae ? "Making Amt" : "Labour Amt",
                currency + fmt(lbrAmmount, 2)),
            if (_isPositive(othAmmount))
              row("Other Amt", currency + fmt(othAmmount, 2)),
            // Other details — hallmark, real stone, diamond and the like, each
            // carrying its own charge. Column names match the A4 estimate's
            // table (BAR_IDTL): IT_CODE / IT_PCS / IT_GWT / IT_RATE /
            // IT_NET_AMT. A five-column table will not fit 47mm, so each entry
            // prints as a name+amount line with an indented breakdown under it.
            if (otherDetailsData != null && otherDetailsData.isNotEmpty) ...[
              rule(),
              centered("OTHER DETAILS", 7.5, bold: true),
              pw.SizedBox(height: 3),
              // Four columns rather than five: the quantity is reported once,
              // as whatever the operator entered. Dropping the always-empty
              // second measure also buys width back on a 47mm roll, so Rate
              // and Amount no longer have to crowd.
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.4),
                columnWidths: const {
                  0: pw.FlexColumnWidth(6), // Stone
                  1: pw.FlexColumnWidth(5), // Qty (pcs or carat)
                  2: pw.FlexColumnWidth(7), // Rate
                  3: pw.FlexColumnWidth(6), // Net Amount
                },
                children: [
                  pw.TableRow(children: [
                    cell("Stone", header: true),
                    cell(otherQtyHeader(otherQtyMode),
                        header: true, right: true),
                    cell("Rate", header: true, right: true),
                    cell("Amount", header: true, right: true),
                  ]),
                  for (final d in otherDetailsData)
                    pw.TableRow(children: [
                      cell('${d["IT_CODE"] ?? d["IT_NAME"] ?? "-"}'.trim()),
                      cell(otherQtyText(d, otherQtyMode), right: true),
                      cell(fmt(d["IT_RATE"], 2), right: true),
                      cell(fmt(d["IT_NET_AMT"], 2), right: true),
                    ]),
                ],
              ),
              pw.SizedBox(height: 2),
              row("Other Total",
                  currency + fmt(_otherDetailsTotal(otherDetailsData), 2)),
            ],
            rule(),
            row("Net Amt", currency + fmt(netAmmount, 2)),
            if (selectedGST && double.tryParse(gstTax) != 0)
              row("GST Tax", currency + fmt(gstTax, 2)),
            rule(),
            row("TOTAL", currency + fmt(totalAmount, 2), bold: true),
            rule(),
            pw.SizedBox(height: 4),
            centered("Thank you, visit again", 6),
            // Blank tail so the cutter does not slice through the last line.
            pw.SizedBox(height: 12),
          ],
        ),
      ),
    );

    await sharePDF(await pdf.save(), "tag_estimate_pos");
  }

  createPDF() async {
    final pdf = pw.Document();
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    dynamic companyDetails;
    if (Platform.isAndroid) {
      String companyData =
          "SELECT CO_NAME,CO_ADD1,CO_ADD2,CO_ADD3,CO_CITY,CO_PIN,CO_MOBILE FROM CO_MAST WHERE CO_CODE = ${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).co_code}";
      dynamic dataofCompany = await sqlConnection.queryDatabase(companyData);
      companyDetails = jsonDecode(dataofCompany)[0];
      print("companyDetail");
      print(companyDetails);
    } else {
      dynamic companyData = await MySQLService().getCompanyDetail(co_code!);
      companyDetails = companyData[0][0];
    }
    dynamic otherDetailsData;

    if (Platform.isAndroid) {
      String otherDetailsQuery =
          "SELECT * FROM BAR_IDTL WHERE CO_CODE='${provider.co_code}' AND LC_CODE='${provider.lc_code}' AND TAG_NO='${widget.tagNo}' AND VCH_SRNO=${productDetail["VCH_SRNO"]}";

      dynamic rawData = await sqlConnection.queryDatabase(otherDetailsQuery);
      otherDetailsData = jsonDecode(rawData);
      log("otherDetail $otherDetailsData");
    } else {
      dynamic data = await MySQLService().getOtherDetails(
        provider.co_code!,
        provider.lc_code!,
        widget.tagNo!,
        productDetail["VCH_SRNO"].toString(),
      );

      otherDetailsData = data[0];
    }
    Uint8List? byteForImage;
    if (printImageInPdf && productImage.trim().isNotEmpty) {
      byteForImage = await getByteCode(productImage);
    }
    final blockedHddList = [
      "VK289NEPH",
      "VK103NEVK",
      "VK061NEVK",
      "HM208NEPK",
      "AB000NEAB"
    ];
    final PdfColor accent = PdfColor.fromInt(0xFF006EB7);
    final PdfColor accentDark = PdfColor.fromInt(0xFF00456F);
    final PdfColor lineClr = PdfColor.fromInt(0xFFD5DEE8);
    final PdfColor textClr = PdfColor.fromInt(0xFF1E2A36);
    final PdfColor mutedClr = PdfColor.fromInt(0xFF5B6B7B);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        build: (context) => [
          pw.Center(
            child: pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(maxWidth: double.infinity),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  blockedHddList.contains(hddNo)
                      ? pw.SizedBox()
                      : pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.only(bottom: 10),
                          margin: const pw.EdgeInsets.only(bottom: 4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(color: accent, width: 1.5),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(
                                "${companyDetails["CO_NAME"]}",
                                style: pw.TextStyle(
                                    fontSize: 20,
                                    fontWeight: pw.FontWeight.bold,
                                    color: accentDark),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                "${companyDetails["CO_ADD1"]}, ${companyDetails["CO_ADD2"]}",
                                style:
                                    pw.TextStyle(fontSize: 9, color: mutedClr),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.Text(
                                "${companyDetails["CO_ADD3"]}, ${companyDetails["CO_CITY"]}-${companyDetails["CO_PIN"]}",
                                style:
                                    pw.TextStyle(fontSize: 9, color: mutedClr),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.Text(
                                "Mo: ${companyDetails["CO_MOBILE"]}",
                                style:
                                    pw.TextStyle(fontSize: 9, color: mutedClr),
                                textAlign: pw.TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "ESTIMATE",
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              letterSpacing: 1),
                        ),
                        pw.Text(
                          "Date: ${DateFormat("dd/MM/yyyy").format(DateTime.now())}",
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "${productDetail["IT_NAME"]}",
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: textClr),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 12),
                  byteForImage != null
                      ? pw.Container(
                          height: 170,
                          width: 170,
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: lineClr, width: 1),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Image(
                            pw.MemoryImage(byteForImage),
                            fit: pw.BoxFit.contain,
                          ),
                        )
                      : pw.SizedBox(),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder(
                      left: pw.BorderSide(color: lineClr, width: 0.5),
                      right: pw.BorderSide(color: lineClr, width: 0.5),
                      top: pw.BorderSide(color: lineClr, width: 0.5),
                      bottom: pw.BorderSide(color: lineClr, width: 0.5),
                      horizontalInside:
                          pw.BorderSide(color: lineClr, width: 0.5),
                      verticalInside: pw.BorderSide(color: lineClr, width: 0.5),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            pw.Expanded(
                                child: pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Padding(
                                  padding: pw.EdgeInsets.only(right: 10),
                                  child: pw.Text(
                                    "Tag No :",
                                    style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                        color: textClr),
                                  )),
                            )),
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerLeft,
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: pw.Text(
                                        widget.tagNo.toString(),
                                        style: pw.TextStyle(
                                            fontSize: 11,
                                            fontWeight: pw.FontWeight.bold,
                                            color: textClr),
                                      ),
                                    )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Padding(
                                        padding: pw.EdgeInsets.only(right: 10),
                                        child: pw.Text(
                                          "Pcs :",
                                          style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: textClr),
                                        )))),
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerLeft,
                                    child: pw.Padding(
                                        padding: pw.EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 5),
                                        child: pw.Text(
                                          productDetail["ITM_PCS"].toString(),
                                          style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: textClr),
                                        ))))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            productDetail == null ||
                                    productDetail["DESIGN_NO"] == ""
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerRight,
                                        child: pw.Padding(
                                          padding:
                                              pw.EdgeInsets.only(right: 10),
                                          child: pw.Text(
                                            "Design :",
                                            style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                                color: textClr),
                                          ),
                                        ))),
                            productDetail == null ||
                                    productDetail["DESIGN_NO"] == ""
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerLeft,
                                        child: pw.Padding(
                                          padding: pw.EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 5),
                                          child: pw.Text(
                                            productDetail == null
                                                ? "-:-"
                                                : productDetail["DESIGN_NO"] ==
                                                        ""
                                                    ? "-"
                                                    : productDetail[
                                                            "DESIGN_NO"] ??
                                                        "-:-",
                                            style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                                color: textClr),
                                          ),
                                        )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Padding(
                                        padding: pw.EdgeInsets.only(right: 10),
                                        child: pw.Text(
                                          "Gr Wt :",
                                          style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: textClr),
                                        )))),
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerLeft,
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: pw.Text(
                                        double.parse(productDetail["ITM_GWT"]
                                                .toString())
                                            .toStringAsFixed(3),
                                        style: pw.TextStyle(
                                            fontSize: 11,
                                            fontWeight: pw.FontWeight.bold,
                                            color: textClr),
                                      ),
                                    )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Padding(
                                        padding: pw.EdgeInsets.only(right: 10),
                                        child: pw.Text(
                                          "Nt Wt :",
                                          style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: textClr),
                                        )))),
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerLeft,
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: pw.Text(
                                        double.parse(productDetail["TagNwt"]
                                                .toString())
                                            .toStringAsFixed(3),
                                        style: pw.TextStyle(
                                            fontSize: 11,
                                            fontWeight: pw.FontWeight.bold,
                                            color: textClr),
                                      ),
                                    )))
                          ]),

                      // For gaNDA USER ONLY

                      // pw.TableRow(
                      //     verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      //     children: [
                      //       productDetail == null || provider.amountType != "F"
                      //           ? pw.SizedBox()
                      //           : pw.Expanded(
                      //           child: pw.Align(
                      //               alignment: pw.Alignment.centerRight,
                      //               child: pw.Padding(
                      //                   padding:
                      //                   pw.EdgeInsets.only(right: 10),
                      //                   child: pw.Text(
                      //                     "West% :",
                      //                     style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textClr),
                      //                   )))),
                      //       productDetail == null || provider.amountType != "F"
                      //           ? pw.SizedBox()
                      //           : pw.Expanded(
                      //           child: pw.Align(
                      //               alignment: pw.Alignment.centerLeft,
                      //               child: pw.Padding(
                      //                 padding: pw.EdgeInsets.symmetric(
                      //                     horizontal: 20, vertical: 5),
                      //                 child: pw.Text(
                      //                   productDetail == null
                      //                       ? "-:-"
                      //                       : productDetail["ITM_WEST_PRC"] == ""
                      //                       ? "-"
                      //                       : "${double.parse(productDetail["ITM_WEST_PRC"].toString()).toStringAsFixed(2)}%" ??
                      //                       "-:-",
                      //                   style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textClr),
                      //                 ),
                      //               )))
                      //     ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            productDetail == null || provider.amountType != "F"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerRight,
                                        child: pw.Padding(
                                            padding:
                                                pw.EdgeInsets.only(right: 10),
                                            child: pw.Text(
                                              "Fine Weight :",
                                              style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: textClr),
                                            )))),
                            productDetail == null || provider.amountType != "F"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerLeft,
                                        child: pw.Padding(
                                          padding: pw.EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 5),
                                          child: pw.Text(
                                            productDetail == null
                                                ? "-:-"
                                                : productDetail["ITM_FINE"] ==
                                                        ""
                                                    ? "-"
                                                    : double.parse(((productDetail[
                                                                            "TagNwt"] *
                                                                        16) /
                                                                    100)
                                                                .toString())
                                                            .toStringAsFixed(
                                                                3) ??
                                                        "-:-",
                                            style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                                color: textClr),
                                          ),
                                        )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            printingLable == null
                                ? pw.SizedBox()
                                : ((printingLable?.any(
                                          (e) =>
                                              e["COL_NAME"]
                                                      .toString()
                                                      .toLowerCase() ==
                                                  "ght%" &&
                                              e["YES_NO"] == "Y",
                                        ) ??
                                        false)
                                    ? pw.Expanded(
                                        child: pw.Align(
                                          alignment: pw.Alignment.centerRight,
                                          child: pw.Padding(
                                            padding: const pw.EdgeInsets.only(
                                                right: 10),
                                            child: pw.Text(
                                              "${printingLable.where((e) => e["COL_NAME"] == "Ght%" && e["YES_NO"] == "Y").first["COL_NEW_NAME"]}",
                                              style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: textClr),
                                            ),
                                          ),
                                        ),
                                      )
                                    : pw.SizedBox()),
                            printingLable == null
                                ? pw.SizedBox()
                                : ((printingLable?.any(
                                          (e) =>
                                              e["COL_NAME"]
                                                      .toString()
                                                      .toLowerCase() ==
                                                  "ght%" &&
                                              e["YES_NO"] == "Y",
                                        ) ??
                                        false)
                                    ? pw.Expanded(
                                        child: pw.Align(
                                            alignment: pw.Alignment.centerLeft,
                                            child: pw.Padding(
                                              padding: pw.EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 5),
                                              child: pw.Text(
                                                productDetail == null
                                                    ? "-:-"
                                                    : "${double.parse(productDetail["ITM_GHT_PRC"].toString()).toStringAsFixed(2)}%",
                                                style: pw.TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: textClr),
                                              ),
                                            )))
                                    : pw.SizedBox())
                          ]),

                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            printingLable == null
                                ? pw.SizedBox()
                                : ((printingLable?.any(
                                          (e) =>
                                              e["COL_NAME"]
                                                      .toString()
                                                      .toLowerCase() ==
                                                  "ghtwt" &&
                                              e["YES_NO"] == "Y",
                                        ) ??
                                        false)
                                    ? pw.Expanded(
                                        child: pw.Align(
                                          alignment: pw.Alignment.centerRight,
                                          child: pw.Padding(
                                            padding: const pw.EdgeInsets.only(
                                                right: 10),
                                            child: pw.Text(
                                              "${printingLable.where((e) => e["COL_NAME"] == "GhtWt" && e["YES_NO"] == "Y").first["COL_NEW_NAME"]} :",
                                              style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: textClr),
                                            ),
                                          ),
                                        ),
                                      )
                                    : pw.SizedBox()),
                            printingLable == null
                                ? pw.SizedBox()
                                : ((printingLable?.any(
                                          (e) =>
                                              e["COL_NAME"]
                                                      .toString()
                                                      .toLowerCase() ==
                                                  "ght%" &&
                                              e["YES_NO"] == "Y",
                                        ) ??
                                        false)
                                    ? pw.Expanded(
                                        child: pw.Align(
                                            alignment: pw.Alignment.centerLeft,
                                            child: pw.Padding(
                                              padding: pw.EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 5),
                                              child: pw.Text(
                                                double.parse(productDetail[
                                                            "ITM_GHAT"]
                                                        .toString())
                                                    .toStringAsFixed(3),
                                                style: pw.TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: textClr),
                                              ),
                                            )))
                                    : pw.SizedBox())
                          ]),

                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            printingLable == null
                                ? pw.SizedBox()
                                : hddNo != "VK289NEPH"
                                    ? pw.SizedBox()
                                    : ((printingLable?.any(
                                              (e) =>
                                                  e["COL_NAME"]
                                                          .toString()
                                                          .toLowerCase() ==
                                                      "ghtwt" &&
                                                  e["YES_NO"] == "Y",
                                            ) ??
                                            false)
                                        ? pw.Expanded(
                                            child: pw.Align(
                                              alignment:
                                                  pw.Alignment.centerRight,
                                              child: pw.Padding(
                                                padding:
                                                    const pw.EdgeInsets.only(
                                                        right: 10),
                                                child: pw.Text(
                                                  "Total Weight :",
                                                  style: pw.TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                      color: textClr),
                                                ),
                                              ),
                                            ),
                                          )
                                        : pw.SizedBox()),
                            printingLable == null
                                ? pw.SizedBox()
                                : hddNo != "VK289NEPH"
                                    ? pw.SizedBox()
                                    : ((printingLable?.any(
                                              (e) =>
                                                  e["COL_NAME"]
                                                          .toString()
                                                          .toLowerCase() ==
                                                      "ght%" &&
                                                  e["YES_NO"] == "Y",
                                            ) ??
                                            false)
                                        ? pw.Expanded(
                                            child: pw.Align(
                                                alignment:
                                                    pw.Alignment.centerLeft,
                                                child: pw.Padding(
                                                  padding:
                                                      pw.EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 5),
                                                  child: pw.Text(
                                                    double.parse((productDetail[
                                                                    "TagNwt"] +
                                                                ((productDetail[
                                                                            "TagNwt"] *
                                                                        productDetail[
                                                                            "ITM_GHT_PRC"]) /
                                                                    100))
                                                            .toString())
                                                        .toStringAsFixed(3),
                                                    style: pw.TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color: textClr),
                                                  ),
                                                )))
                                        : pw.SizedBox())
                          ]),

                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Padding(
                                        padding: pw.EdgeInsets.only(right: 10),
                                        child: pw.Text(
                                          "Rate 1 Gm :",
                                          style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: textClr),
                                        )))),
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerLeft,
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: pw.Text(
                                        double.parse(itemRate.toString())
                                            .toStringAsFixed(2),
                                        style: pw.TextStyle(
                                            fontSize: 11,
                                            fontWeight: pw.FontWeight.bold,
                                            color: textClr),
                                      ),
                                    )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Padding(
                                        padding: pw.EdgeInsets.only(right: 10),
                                        child: pw.Text(
                                          commonCompanyYearSelectionProvider
                                                      .CoSname ==
                                                  "UAE"
                                              ? "Metal Value (AED)"
                                              : "Item Amt :",
                                          style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: textClr),
                                        )))),
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerLeft,
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: pw.Text(
                                        double.parse(itemAmount.toString())
                                                .toStringAsFixed(2) ??
                                            "-:-",
                                        style: pw.TextStyle(
                                            fontSize: 11,
                                            fontWeight: pw.FontWeight.bold,
                                            color: textClr),
                                      ),
                                    )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            lbrPrc == "0.0"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerRight,
                                        child: pw.Padding(
                                            padding:
                                                pw.EdgeInsets.only(right: 10),
                                            child: pw.Text(
                                              "${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Making" : "Lbr"} prc % :",
                                              style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: textClr),
                                            )))),
                            lbrPrc == "0.0"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerLeft,
                                        child: pw.Padding(
                                          padding: pw.EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 5),
                                          child: pw.Text(
                                            double.parse(lbrPrc.toString())
                                                    .toStringAsFixed(2) ??
                                                "-:-",
                                            style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                                color: textClr),
                                          ),
                                        )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            lbrRate == "0.00"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerRight,
                                        child: pw.Padding(
                                            padding:
                                                pw.EdgeInsets.only(right: 10),
                                            child: pw.Text(
                                              "${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Making" : "Lbr"} Rate :",
                                              style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: textClr),
                                            )))),
                            lbrRate == "0.00"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerLeft,
                                        child: pw.Padding(
                                          padding: pw.EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 5),
                                          child: pw.Text(
                                            double.parse(lbrRate.toString())
                                                    .toStringAsFixed(2) ??
                                                "-:-",
                                            style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                                color: textClr),
                                          ),
                                        )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            lbrAmmount == "0.0"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerRight,
                                        child: pw.Padding(
                                            padding: pw.EdgeInsets.only(
                                                right: 10, left: 3),
                                            child: pw.Text(
                                              "${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Making" : "Lbr"} ${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Charges(AED)" : "Amt"} :",
                                              style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: textClr),
                                            )))),
                            lbrAmmount == "0.0"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerLeft,
                                        child: pw.Padding(
                                          padding: pw.EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 5),
                                          child: pw.Text(
                                            double.parse(lbrAmmount.toString())
                                                    .toStringAsFixed(2) ??
                                                "-:-",
                                            style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                                color: textClr),
                                          ),
                                        )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            othAmmount == "0.0"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerRight,
                                        child: pw.Padding(
                                            padding: pw.EdgeInsets.only(
                                                right: 10, left: 3),
                                            child: pw.Text(
                                              "Oth ${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Charges(AED)" : "Amt"} :",
                                              style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: textClr),
                                            )))),
                            othAmmount == "0.0"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerLeft,
                                        child: pw.Padding(
                                          padding:
                                              const pw.EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 5),
                                          child: pw.Text(
                                            double.parse(othAmmount.toString())
                                                    .toStringAsFixed(2) ??
                                                "-:-",
                                            style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                                color: textClr),
                                          ),
                                        )))
                          ]),

                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            mrp == "0.0"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerRight,
                                        child: pw.Padding(
                                            padding: pw.EdgeInsets.only(
                                                right: 10, left: 3),
                                            child: pw.Text(
                                              "${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "AED" : "MRP"} :",
                                              style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: textClr),
                                            )))),
                            mrp == "0.0"
                                ? pw.SizedBox()
                                : pw.Expanded(
                                    child: pw.Align(
                                        alignment: pw.Alignment.centerLeft,
                                        child: pw.Padding(
                                          padding: pw.EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 5),
                                          child: pw.Text(
                                            double.parse(mrp.toString())
                                                    .toStringAsFixed(2) ??
                                                "-:-",
                                            style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                                color: textClr),
                                          ),
                                        )))
                          ]),

                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Padding(
                                        padding: pw.EdgeInsets.only(right: 10),
                                        child: pw.Text(
                                          "Net ${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Value(AED)" : "Amt"} :",
                                          style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: textClr),
                                        )))),
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerLeft,
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: pw.Text(
                                        double.parse(netAmmount)
                                                .toStringAsFixed(2) ??
                                            "-:-",
                                        style: pw.TextStyle(
                                            fontSize: 11,
                                            fontWeight: pw.FontWeight.bold,
                                            color: textClr),
                                      ),
                                    )))
                          ]),
                      pw.TableRow(
                          verticalAlignment:
                              pw.TableCellVerticalAlignment.middle,
                          children: [
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Padding(
                                        padding: pw.EdgeInsets.only(right: 10),
                                        child: pw.Text(
                                          commonCompanyYearSelectionProvider
                                                      .CoSname ==
                                                  "UAE"
                                              ? "Vat(AED) :"
                                              : "Gst Tax :",
                                          style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: textClr),
                                        )))),
                            pw.Expanded(
                                child: pw.Align(
                                    alignment: pw.Alignment.centerLeft,
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: pw.Text(
                                        double.parse(gstTax)
                                                .toStringAsFixed(2) ??
                                            "-:-",
                                        style: pw.TextStyle(
                                            fontSize: 11,
                                            fontWeight: pw.FontWeight.bold,
                                            color: textClr),
                                      ),
                                    )))
                          ]),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: accentDark,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Total ${commonCompanyYearSelectionProvider.CoSname == "UAE" ? "Value (AED)" : "Amount"}",
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white),
                        ),
                        pw.Text(
                          double.parse(totalAmount).toStringAsFixed(2),
                          style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white),
                        ),
                      ],
                    ),
                  ),
                  if (otherDetailsData != null &&
                      otherDetailsData.isNotEmpty) ...[
                    pw.SizedBox(height: 16),
                    pw.Row(children: [
                      pw.Container(
                        width: 3,
                        height: 14,
                        color: accent,
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        "Other Details",
                        style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: accentDark),
                      ),
                    ]),
                    pw.SizedBox(height: 8),
                    pw.Wrap(spacing: 0, runSpacing: 0, children: [
                      // Quantity is reported once — see otherQtyMode. The
                      // always-blank second measure used to print a "0" the
                      // customer had to interpret.
                      pw.Table(
                        border: pw.TableBorder.all(color: lineClr, width: 0.5),
                        columnWidths: {
                          0: pw.FlexColumnWidth(2),
                          1: pw.FlexColumnWidth(1.8),
                          2: pw.FlexColumnWidth(2),
                          3: pw.FlexColumnWidth(2),
                        },
                        children: [
                          // Header row
                          pw.TableRow(
                            decoration: pw.BoxDecoration(color: accent),
                            children: [
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text("Stone",
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 9,
                                          color: PdfColors.white))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(otherQtyHeader(otherQtyMode),
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 9,
                                          color: PdfColors.white))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text("Rate",
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 9,
                                          color: PdfColors.white))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text("Net Amount",
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 9,
                                          color: PdfColors.white))),
                            ],
                          ),

                          // Dynamic rows
                          ...otherDetailsData.map<pw.TableRow>((row) {
                            final String qty = otherQtyText(row, otherQtyMode);

                            String rate = row["IT_RATE"] != null
                                ? (double.tryParse(row["IT_RATE"].toString())
                                        ?.toStringAsFixed(2) ??
                                    "0.00")
                                : "0.00";

                            String netAmt = row["IT_NET_AMT"] != null
                                ? (double.tryParse(row["IT_NET_AMT"].toString())
                                        ?.toStringAsFixed(2) ??
                                    "0.00")
                                : "0.00";

                            return pw.TableRow(children: [
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(row["IT_CODE"] ?? "-",
                                      style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold,
                                          color: textClr))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(qty,
                                      style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold,
                                          color: textClr))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(rate,
                                      style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold,
                                          color: textClr))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  // Printed in full. This used to chop the
                                  // last three characters off the formatted
                                  // string to drop the paise, which left the
                                  // amount column disagreeing with the Rate
                                  // column beside it and with the POS receipt.
                                  child: pw.Text(netAmt,
                                      style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold,
                                          color: textClr))),
                            ]);
                          }).toList(),
                        ],
                      ),
                    ])
                  ],
                  pw.SizedBox(height: 16),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.only(top: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: lineClr, width: 0.5),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        "Thank you! Visit Again",
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: mutedClr),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );

    sharePDF(await pdf.save(), "tag_pdf");
  }

  Future<void> sharePDF(Uint8List pdfData, String fileName) async {
    // Get the temporary directory
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName.pdf';

    // Save the PDF file
    final file = File(filePath);
    await file.writeAsBytes(pdfData);

    if (!mounted) return;
    // Share the file (sharePositionOrigin is required on iPad and
    // avoids the iOS share sheet silently failing to present).
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/pdf')],
      text: 'Here is the PDF file I generated!',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  Future<Uint8List?> generateQRCodeImage(String data) async {
    final qrValidation = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );

    if (qrValidation.status == QrValidationStatus.valid) {
      final qrCode = qrValidation.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        gapless: true,
      );

      final image = await painter.toImage(300); // Size of QR code
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }
    return null;
  }

  Future<Uint8List?> getByteCode(String url) async {
    try {
      if (url.trim().isEmpty) return null;
      if (url.toLowerCase().contains("http")) {
        final response = await http.get(
          Uri.parse(url),
          headers: const {'User-Agent': 'Mozilla/5.0'},
        );
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          log('getByteCode http ${response.statusCode} for $url');
          return null;
        }
        return response.bodyBytes;
      } else {
        final file = File(url);
        if (!await file.exists()) return null;
        return await file.readAsBytes();
      }
    } catch (e, s) {
      log('getByteCode failed', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> _processAndShareImage(String url) async {
    final Uint8List? bytes = await getByteCode(url);
    if (bytes == null) {
      throw Exception('No image available for this tag');
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final ui.Image originalImage = frame.image;

    String fmt(dynamic v, int d) {
      final parsed = double.tryParse(v?.toString() ?? "");
      return parsed == null ? "-" : parsed.toStringAsFixed(d);
    }

    final bool isUae = commonCompanyYearSelectionProvider.CoSname == "UAE";
    final String itemName = productDetail?["IT_NAME"]?.toString() ?? "";

    // Split by how the values behave, not by meaning: the tag number and the
    // item name vary in length and get the full width, while the six figures
    // are short and pair up two to a line. That halves the panel's height, so
    // the photo keeps most of the frame.
    final List<List<String>> fullWidthRows = [
      ["Tag No", "${widget.tagNo}"],
      if (itemName.trim().isNotEmpty) ["Item", itemName.trim()],
    ];
    final List<List<String>> pairedRows = [
      ["Pcs", "${productDetail?["ITM_PCS"] ?? "-"}"],
      ["Gr Wt", fmt(productDetail?["ITM_GWT"], 3)],
      ["Nt Wt", fmt(productDetail?["TagNwt"], 3)],
      ["Rate", fmt(itemRate, 2)],
      [isUae ? "Net Val" : "Net Amt", fmt(netAmmount, 2)],
      ["Total", fmt(totalAmount, 2)],
    ];

    final Uint8List? composed = await ShareTagImage.compose(
      photo: originalImage,
      fullWidthRows: fullWidthRows,
      pairedRows: pairedRows,
    );
    if (composed == null) {
      throw Exception('Could not build the image to share');
    }

    // Save the image to a file
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/shared_image.png';
    final file = File(filePath);
    await file.writeAsBytes(composed);

    // Share the image
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'image/png')],
      text: '',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.toUpperCase();
    return newValue.copyWith(text: newText, selection: newValue.selection);
  }
}
