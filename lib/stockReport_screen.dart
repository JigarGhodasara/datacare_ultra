import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/stockZoomingReport.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class StockreportScreen extends StatefulWidget {
  const StockreportScreen({Key? key}) : super(key: key);

  @override
  State<StockreportScreen> createState() => _StockreportScreenState();
}

class _StockreportScreenState extends State<StockreportScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);

  Color get _cta => _brand;

  final sqlConnection = SqlConnection.getInstance();
  String StkType = '';
  String ItType = '';
  List<dynamic> stockReport = [];
  List<dynamic> searchStockReport = [];

  /// Whether the totals card is expanded to the full movement breakdown.
  /// Collapsed by default so the card costs one line until it is asked for.
  bool _summaryOpen = false;
  late LoadingProvider loadingProvider;
  List<dynamic> groupData = [
    {"GR_CODE": "", "GR_NAME": "Select Group"}
  ];
  List<dynamic> itemData = [
    {"IT_NAME": "Select Item"}
  ];
  List<dynamic> productData = [
    {"PR_CODE": "", "PR_NAME": "Select Product"}
  ];
  List<dynamic> tableNameData = [
    {"TABLE_CODE": "", "TABLE_NAME": "Select Table"}
  ];
  dynamic selectedGroupCode = {"GR_CODE": "", "GR_NAME": "Select Group"};
  dynamic selectedItemCode = {"IT_NAME": "Select Item"};
  dynamic selectedProductCode = {"PR_CODE": "", "PR_NAME": "Select Product"};
  dynamic selectedTableCode = {"TABLE_CODE": "", "TABLE_NAME": "Select Table"};
  String selectedItemName = "";
  String co_code = "";
  String year = "";
  String lc_code = "";
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    year =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_year;
    lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update your state here
      getStockReport();
    });
    getFilterData();
  }

  void getStockReport() async {
    loadingProvider.startLoading();
    setState(() {});
    try {
      String grpCode = "";
      String itmCode = "";
      String prCode = "";
      String tblCode = "";
      if (selectedGroupCode["GR_NAME"] != "Select Group") {
        groupData.forEach((action) {
          if (action["GR_NAME"] == selectedGroupCode["GR_NAME"]) {
            grpCode = action["GR_CODE"];
          }
        });
        print("grpCode ${grpCode}");
      }

      if (selectedItemCode["IT_NAME"] != "Select Item") {
        itemData.forEach((action) {
          if (action["IT_NAME"] == selectedItemCode["IT_NAME"]) {
            itmCode = action["IT_NAME"];
          }
        });
        print("itmCode ${itmCode}");
      }

      if (selectedProductCode["PR_NAME"] != "Select Product") {
        productData.forEach((action) {
          if (action["PR_NAME"] == selectedProductCode["PR_NAME"]) {
            prCode = action["PR_CODE"];
          }
        });
        print("prCode ${prCode}");
      }

      if (selectedTableCode["TABLE_NAME"] != "Select Table") {
        tableNameData.forEach((action) {
          if (action["TABLE_NAME"] == selectedProductCode["TABLE_NAME"]) {
            tblCode = action["TABLE_CODE"];
          }
        });
        print("tblCode ${tblCode}");
      }

      if (Platform.isAndroid) {
        String query =
            "SELECT B.IT_CODE AS ItCode ,B.IT_NAME AS ItName,B.IT_TYPE As ItType, SUM(CASE WHEN A.VCH_DATE <  '$fromDate' THEN (CASE WHEN ITM_SIGN = '+' THEN  A.ITM_PCS ELSE  -A.ITM_PCS END) ELSE 0 END) AS OpPcs,SUM(CASE WHEN A.VCH_DATE <  '$fromDate' THEN (CASE WHEN ITM_SIGN = '+' THEN A.ITM_NWT ELSE -A.ITM_NWT END) ELSE 0 END) AS OpWt,SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate'  THEN (CASE WHEN ITM_SIGN = '+' AND TR_TYPE = 'P' THEN A.ITM_PCS ELSE 0 END) ELSE 0 END) AS PrPcs,SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate'  THEN (CASE WHEN ITM_SIGN = '+' AND TR_TYPE = 'P' THEN A.ITM_NWT ELSE 0 END) ELSE 0 END) AS PrWt,SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate'  THEN (CASE WHEN ITM_SIGN = '+' AND TR_TYPE = 'I' THEN A.ITM_PCS ELSE 0 END) ELSE 0 END) AS InPcs,SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate'  THEN (CASE WHEN ITM_SIGN = '+' AND TR_TYPE = 'I' THEN A.ITM_NWT ELSE 0 END) ELSE 0 END) AS InWt, SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate'  THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'O' THEN A.ITM_PCS ELSE 0 END) ELSE 0 END) AS OutPcs,SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate'  THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'O' THEN A.ITM_NWT ELSE 0 END) ELSE 0 END) AS OutWt,SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate'  THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'S' THEN A.ITM_PCS ELSE 0 END) ELSE 0 END) AS SlPcs,SUM(CASE WHEN A.VCH_DATE >= '$fromDate' AND A.VCH_DATE <= '$toDate'  THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'S' THEN A.ITM_NWT ELSE 0 END) ELSE 0 END) AS SlWt,SUM(CASE WHEN A.VCH_DATE <=  '$toDate' THEN(CASE WHEN ITM_SIGN = '+' THEN A.ITM_PCS ELSE -A.ITM_PCS END) ELSE 0 END) AS ClPcs,SUM(CASE WHEN A.VCH_DATE <=  '$toDate' THEN(CASE WHEN ITM_SIGN = '+' THEN A.ITM_NWT ELSE -A.ITM_NWT END) ELSE 0 END) AS ClWt FROM MAIN_STOCK AS A LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE WHERE A.CO_CODE = '$co_code' AND A.LC_CODE = '$lc_code' AND A.CO_YEAR = '$year'";

        if (ItType != "") {
          query += "AND B.IT_TYPE = '" + ItType + "' ";
        }
        if ("I" == StkType) {
          query += "AND A.TAG_NO ='N' ";
        }
        if ("T" == StkType) {
          // "AND A.TAG_NO <> 'N' '\(self.SStk)' "
          query += "AND A.TAG_NO <> 'N' ";
        }

        // use for fillters

        if (grpCode != "") {
          query += "AND B.GR_CODE = '" + grpCode + "' ";
        }

        if (itmCode != "") {
          query += "AND B.IT_NAME = '$itmCode' ";
        }

        if (prCode != "") {
          query += "AND B.PR_CODE = '$prCode' ";
        }

        if (tblCode != "") {
          query += "AND B.TBL_CODE <> '$tblCode' ";
        }
        // if !self.Stable.isEmpty {
        // strappend += "AND B.TBL_CODE <> '\(self.Stable)' "
        // }

        query += "GROUP BY B.IT_CODE,B.IT_NAME,B.IT_TYPE ORDER BY B.IT_NAME";
        log("Stock report data $query");

        dynamic result = await sqlConnection.queryDatabase(query);

        log("Stock report data $result");
        stockReport = jsonDecode(result);
        searchStockReport = jsonDecode(result);
      } else {
        dynamic result = await MySQLService().getStockReport(
            coCode: co_code,
            lcCode: lc_code,
            year: year,
            fromDate: DateFormat("yyyy-MM-dd").format(DateTime.now()),
            toDate: DateFormat("yyyy-MM-dd").format(DateTime.now()),
            itType: ItType,
            stkType: StkType,
            grpCode: grpCode,
            itmCode: itmCode,
            prdCode: prCode,
            tblCode: tblCode);
        print("Reee $result");
        stockReport = result[0];
        searchStockReport = result[0];
      }
    } catch (e) {
      stockReport = [];
      searchStockReport = [];
      if (mounted) {
        showAppToast(context, "Could not load stock report. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  void getFilterData() async {
    if (Platform.isAndroid) {
      var groupQuery =
          "SELECT GR_CODE,GR_NAME FROM GROUP_MAST WHERE CO_CODE='" +
              co_code +
              "'";
      dynamic groupQueryResult = await sqlConnection.queryDatabase(groupQuery);
      print("groupQueryResult ${groupQueryResult}");
      List<dynamic> groupResultData = jsonDecode(groupQueryResult);
      groupData.addAll(groupResultData);

      var itemQuery =
          "SELECT IT_NAME FROM ITEM_MAST WHERE CO_CODE ='" + co_code + "'";
      dynamic itemQueryResult = await sqlConnection.queryDatabase(itemQuery);
      print("itemQueryResult ${itemQueryResult}");
      List<dynamic> itemResultData = jsonDecode(itemQueryResult);
      itemData.addAll(itemResultData);
      print("itemQueryResult ${itemData}");

      var productQuery =
          "SELECT PR_CODE,PR_NAME FROM PRODUCT_MAST WHERE CO_CODE ='" +
              co_code +
              "'";
      dynamic productQueryResult =
          await sqlConnection.queryDatabase(productQuery);
      print("productQueryResult ${productQueryResult}");
      List<dynamic> productResultData = jsonDecode(productQueryResult);
      productData.addAll(productResultData);

      var tableQuery =
          "SELECT TABLE_CODE,TABLE_NAME FROM TABLE_MAST WHERE CO_CODE='" +
              co_code +
              "' AND LC_CODE ='" +
              lc_code +
              "' ";
      dynamic tableQueryResult = await sqlConnection.queryDatabase(tableQuery);
      print("tableQueryResult ${tableQueryResult}");
      List<dynamic> tableResultData = jsonDecode(tableQueryResult);
      tableNameData.addAll(tableResultData);
    } else {
      dynamic grpResult = await MySQLService().getStockFilterGrpData(co_code);
      print("grpResult $grpResult");
      groupData.addAll(grpResult[0]);
      dynamic itmResult = await MySQLService().getStockFilterItmData(co_code);
      print("itmResult $itmResult");
      itemData.addAll(itmResult[0]);

      dynamic prdResult = await MySQLService().getStockFilterPrdData(co_code);
      print("prdResult $prdResult");
      productData.addAll(prdResult[0]);

      dynamic tblResult =
          await MySQLService().getStockFilterTblData(co_code, lc_code);
      print("tblResult $tblResult");
      tableNameData.addAll(tblResult[0]);
    }
  }

  fillterData(
      {required DateTime todate,
      required DateTime fromdate,
      required String stockType,
      required String itType,
      required dynamic selectGrp,
      required dynamic selectItem,
      required dynamic selectProduct,
      required dynamic selectTable}) {
    int selectedOption = itType == "G"
        ? 2
        : itType == "s"
            ? 3
            : 1;
    print("selectedOption $itType");
    print(selectedOption);
    String selectedItType = itType;
    int selectedStkOption = stockType == ""
        ? 1
        : stockType == "I"
            ? 2
            : 3;
    String selectedStkType = stockType;
    dynamic selectedGroupvalue = selectGrp;
    dynamic selectedItemvalue = selectItem;
    dynamic selectedProductvalue = selectProduct;
    dynamic selectedTablevalue = selectTable;
    DateTime from = fromdate;
    DateTime to = todate;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        final safeBottom = MediaQuery.of(context).padding.bottom;
        final maxSheetH = MediaQuery.of(context).size.height * 0.92;

        final sheetDropStyle = DropdownStyleData(
          maxHeight: 260,
          elevation: 3,
          offset: const Offset(0, -4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: _border.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: _cta.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
        );
        final sheetButtonStyle = ButtonStyleData(
          padding: const EdgeInsets.only(left: 16, right: 10),
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border.withValues(alpha: 0.85)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
        );
        final sheetIconStyle = IconStyleData(
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _cta, size: 22),
        );
        final sheetMenuItemStyle = const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        );

        Widget filterLabel(String lbl) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_cta, _cta.withValues(alpha: 0.55)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  lbl,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final radioTheme = Theme.of(context).copyWith(
          radioTheme: RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) return _cta;
              return _border;
            }),
          ),
        );

        void applyFilters() {
          selectedGroupCode = selectedGroupvalue;
          selectedItemCode = selectedItemvalue;
          selectedProductCode = selectedProductvalue;
          selectedTableCode = selectedTablevalue;
          ItType = selectedItType;
          StkType = selectedStkType;
          fromDate = from;
          toDate = to;
          getStockReport();
          Navigator.pop(context);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetH),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color.lerp(Colors.white, _pageBg, 0.22)!,
                    ],
                  ),
                  border: Border.all(color: _cta.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: _cta.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, -8),
                      spreadRadius: -8,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Theme(
                    data: radioTheme,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(20, 10, 20, safeBottom + 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _border,
                                      _border.withValues(alpha: 0.4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _pageBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              _border.withValues(alpha: 0.65),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: _textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Filters',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.45,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: _cta,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: _cta.withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    selectedGroupCode = {
                                      "GR_CODE": "",
                                      "GR_NAME": "Select Group"
                                    };
                                    selectedItemCode = {
                                      "IT_NAME": "Select Item"
                                    };
                                    selectedProductCode = {
                                      "PR_CODE": "",
                                      "PR_NAME": "Select Product"
                                    };
                                    selectedTableCode = {
                                      "TABLE_CODE": "",
                                      "TABLE_NAME": "Select Table"
                                    };
                                    ItType = '';
                                    StkType = '';
                                    fromDate = DateTime.now();
                                    toDate = DateTime.now();
                                    getStockReport();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Clear all',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: _border.withValues(alpha: 0.65),
                            ),
                            const SizedBox(height: 18),
                            filterLabel('Date range'),
                            Row(
                              children: [
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () async {
                                        DateTime? dat =
                                            await _selectDate(context, from);
                                        from = dat!;
                                        setModalState(() {});
                                      },
                                      child: Ink(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFFFFF),
                                              Color(0xFFF8FAFC),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _cta.withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded,
                                                size: 18, color: _cta),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                DateFormat('dd-MM-yyyy')
                                                    .format(from),
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: _cta,
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () async {
                                        DateTime? dat =
                                            await _selectDate(context, to);
                                        to = dat!;
                                        setModalState(() {});
                                      },
                                      child: Ink(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFFFFF),
                                              Color(0xFFF8FAFC),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _cta.withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded,
                                                size: 18, color: _cta),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                DateFormat('dd-MM-yyyy')
                                                    .format(to),
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: _cta,
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            filterLabel('Item type'),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Radio<int>(
                                      value: 1,
                                      activeColor: _cta,
                                      groupValue: selectedOption,
                                      onChanged: (value) {
                                        setModalState(() {
                                          selectedOption = value!;
                                          selectedItType = "";
                                          print(
                                              "Button value: $selectedOption");
                                        });
                                      },
                                    ),
                                    Text(
                                      'All',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Radio<int>(
                                      value: 2,
                                      activeColor: _cta,
                                      groupValue: selectedOption,
                                      onChanged: (value) {
                                        setModalState(() {
                                          selectedOption = value!;
                                          selectedItType = 'G';
                                          print("Button value: $value");
                                        });
                                      },
                                    ),
                                    Text(
                                      'Gold',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Radio<int>(
                                      value: 3,
                                      activeColor: _cta,
                                      groupValue: selectedOption,
                                      onChanged: (value) {
                                        setModalState(() {
                                          selectedOption = value!;
                                          selectedItType = 'S';
                                          print("Button value: $value");
                                        });
                                      },
                                    ),
                                    Text(
                                      'Silver',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            filterLabel('Stock type'),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Radio<int>(
                                      value: 1,
                                      activeColor: _cta,
                                      groupValue: selectedStkOption,
                                      onChanged: (value) {
                                        setModalState(() {
                                          selectedStkOption = value!;
                                          selectedStkType = "";
                                          print(
                                              "Button value: $selectedOption");
                                        });
                                      },
                                    ),
                                    Text(
                                      'All',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Radio<int>(
                                      value: 2,
                                      activeColor: _cta,
                                      groupValue: selectedStkOption,
                                      onChanged: (value) {
                                        setModalState(() {
                                          selectedStkOption = value!;
                                          selectedStkType = 'I';
                                          print("Button value: $value");
                                        });
                                      },
                                    ),
                                    Text(
                                      'Item',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Radio<int>(
                                      value: 3,
                                      activeColor: _cta,
                                      groupValue: selectedStkOption,
                                      onChanged: (value) {
                                        setModalState(() {
                                          selectedStkOption = value!;
                                          selectedStkType = 'T';
                                          print("Button value: $value");
                                        });
                                      },
                                    ),
                                    Text(
                                      'Tag',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            filterLabel('Group'),
                            DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Colors.white,
                                ),
                                child: DropdownButton2(
                                  buttonStyleData: sheetButtonStyle,
                                  iconStyleData: sheetIconStyle,
                                  menuItemStyleData: sheetMenuItemStyle,
                                  dropdownStyleData: sheetDropStyle,
                                  isExpanded: true,
                                  value: selectedGroupvalue["GR_NAME"],
                                  items: groupData.map((dynamic items) {
                                    return DropdownMenuItem(
                                      value: items["GR_NAME"],
                                      child: Text(
                                        items["GR_NAME"],
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    selectedGroupvalue = {
                                      "GR_CODE": "",
                                      "GR_NAME": value
                                    };
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            filterLabel('Item'),
                            DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Colors.white,
                                ),
                                child: DropdownButton2(
                                  buttonStyleData: sheetButtonStyle,
                                  iconStyleData: sheetIconStyle,
                                  menuItemStyleData: sheetMenuItemStyle,
                                  dropdownStyleData: sheetDropStyle,
                                  isExpanded: true,
                                  value: selectedItemvalue["IT_NAME"],
                                  items: itemData.map((dynamic items) {
                                    print("data $items ");
                                    return DropdownMenuItem(
                                      value: items["IT_NAME"],
                                      child: Text(
                                        items["IT_NAME"],
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    selectedItemvalue = {"IT_NAME": "${value}"};
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            filterLabel('Product'),
                            DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Colors.white,
                                ),
                                child: DropdownButton2(
                                  buttonStyleData: sheetButtonStyle,
                                  iconStyleData: sheetIconStyle,
                                  menuItemStyleData: sheetMenuItemStyle,
                                  dropdownStyleData: sheetDropStyle,
                                  isExpanded: true,
                                  value: selectedProductvalue["PR_NAME"],
                                  items: productData.map((dynamic items) {
                                    return DropdownMenuItem(
                                      value: items["PR_NAME"],
                                      child: Text(
                                        items["PR_NAME"],
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    selectedProductvalue = {
                                      "PR_CODE": "",
                                      "PR_NAME": value
                                    };
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            filterLabel('Table name'),
                            DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Colors.white,
                                ),
                                child: DropdownButton2(
                                  buttonStyleData: sheetButtonStyle,
                                  iconStyleData: sheetIconStyle,
                                  menuItemStyleData: sheetMenuItemStyle,
                                  dropdownStyleData: sheetDropStyle,
                                  isExpanded: true,
                                  value: selectedTablevalue["TABLE_NAME"],
                                  items: tableNameData.map((dynamic items) {
                                    return DropdownMenuItem(
                                      value: items["TABLE_NAME"],
                                      child: Text(
                                        items["TABLE_NAME"],
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    selectedTablevalue = {
                                      "TABLE_CODE": "",
                                      "TABLE_NAME": value.toString()
                                    };
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    _cta.withValues(alpha: 0.35),
                                    _cta.withValues(alpha: 0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _cta.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(1.25),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _cta,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14.75),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: applyFilters,
                                    child: Text(
                                      'Apply filters',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        letterSpacing: 0.2,
                                      ),
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
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _metricLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 12,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                height: 1.25,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              ':',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _border,
              ),
            ),
          ),
          Expanded(
            flex: 13,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtWt(dynamic v) {
    if (v == null || v == 0) return '';
    return double.parse(v.toString()).toStringAsFixed(3);
  }

  String _fmtPcs(dynamic v) {
    if (v == null || v == 0) return '';
    return v.toString();
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime init) async {
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      // builder: (BuildContext context, Widget child) {
      //   return Theme(
      //     data: ThemeData.dark().copyWith(
      //       colorScheme: ColorScheme.dark(
      //         primary: Colors.deepPurple,
      //         onPrimary: Colors.white,
      //         surface: Colors.blueGrey,
      //         onSurface: Colors.yellow,
      //       ),
      //       dialogBackgroundColor: Colors.blue[500],
      //     ),
      //     child: child,
      //   );
      // }
    );

    // if (newSelectedDate != null) {
    return newSelectedDate;
    // _selectedDate = newSelectedDate;
    // _textEditingController
    //   ..text = DateFormat.yMMMd().format(_selectedDate)
    //   ..selection = TextSelection.fromPosition(TextPosition(
    //       offset: _textEditingController.text.length,
    //       affinity: TextAffinity.upstream));
    // }
  }

  double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

  double _sum(String column) =>
      searchStockReport.fold(0.0, (t, r) => t + _num(r[column]));

  /// Describes what the totals cover, so a filtered figure is never mistaken
  /// for the whole shop.
  ///
  /// The filters narrow the same query rather than changing it, so the totals
  /// follow whichever of group / product / item is set — and the label says
  /// which, in the order the user applied them.
  String get _summaryScope {
    final parts = <String>[];
    final group = '${selectedGroupCode["GR_NAME"] ?? ''}'.trim();
    final product = '${selectedProductCode["PR_NAME"] ?? ''}'.trim();
    final item = '${selectedItemCode["IT_NAME"] ?? ''}'.trim();
    if (group.isNotEmpty && group != "Select Group") parts.add("Group: $group");
    if (product.isNotEmpty && product != "Select Product") {
      parts.add("Product: $product");
    }
    if (item.isNotEmpty && item != "Select Item") parts.add("Item: $item");
    return parts.isEmpty ? "All stock" : parts.join("  ·  ");
  }

  /// One-tap totals for the rows currently on screen.
  Widget _summaryCard() {
    if (searchStockReport.isEmpty) return const SizedBox.shrink();
    final closingPcs = _sum("ClPcs");
    final closingWt = _sum("ClWt");

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _summaryOpen = !_summaryOpen),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _brand,
                  Color.lerp(_brand, const Color(0xFF0D47A1), 0.35)!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _summaryScope,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                    Text(
                      "${searchStockReport.length} "
                      "${searchStockReport.length == 1 ? 'item' : 'items'}",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _summaryOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.expand_more_rounded,
                          size: 19, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                        child: _summaryStat(
                            "Closing pieces", closingPcs.toStringAsFixed(0))),
                    Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.25)),
                    Expanded(
                        child: _summaryStat("Closing weight",
                            "${closingWt.toStringAsFixed(3)} gm")),
                  ],
                ),
                if (_summaryOpen) ...[
                  const SizedBox(height: 11),
                  Container(
                      height: 1, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 10),
                  _summaryLine("Opening", "OpPcs", "OpWt"),
                  _summaryLine("Purchase", "PrPcs", "PrWt"),
                  _summaryLine("In", "InPcs", "InWt"),
                  _summaryLine("Out", "OutPcs", "OutWt"),
                  _summaryLine("Sold", "SlPcs", "SlWt"),
                  _summaryLine("Closing", "ClPcs", "ClWt", last: true),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
      ],
    );
  }

  Widget _summaryLine(String label, String pcsCol, String wtCol,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85))),
          ),
          SizedBox(
            width: 70,
            child: Text(_sum(pcsCol).toStringAsFixed(0),
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          SizedBox(
            width: 92,
            child: Text("${_sum(wtCol).toStringAsFixed(3)} gm",
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _cta,
              size: 22,
            ),
          ),
        ),
        title: Text(
          'Stock report',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            color: _cta,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: _border.withValues(alpha: 0.65),
          ),
        ),
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                fillterData(
                    todate: toDate,
                    fromdate: fromDate,
                    stockType: StkType,
                    itType: ItType,
                    selectGrp: selectedGroupCode,
                    selectItem: selectedItemCode,
                    selectProduct: selectedProductCode,
                    selectTable: selectedTableCode);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: Icon(
                  Icons.tune_rounded,
                  color: _cta,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        _cta.withValues(alpha: 0.2),
                        _cta.withValues(alpha: 0.06),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _cta.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(1.25),
                  child: TextFormField(
                    readOnly: false,
                    cursorColor: _cta,
                    keyboardType: TextInputType.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by item name',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: _textSecondary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.75),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.75),
                        borderSide: BorderSide(
                          color: _border.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.75),
                        borderSide: BorderSide(color: _cta, width: 1.5),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 6),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                _cta.withValues(alpha: 0.18),
                                _cta.withValues(alpha: 0.06),
                              ],
                            ),
                          ),
                          child:
                              Icon(Icons.search_rounded, color: _cta, size: 22),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != "") {
                        searchStockReport = stockReport
                            .where((text) =>
                                text.containsKey("ItName") &&
                                text["ItName"]
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.trim().toLowerCase()))
                            .toList();
                        setState(() {});
                      } else {
                        searchStockReport.clear();
                        searchStockReport.addAll(stockReport);
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              loadingProvider.isLoading
                  ? Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: _cta),
                      ),
                    )
                  : searchStockReport.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 56,
                                  color: _textSecondary.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No records found',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: Column(
                            children: [
                              _summaryCard(),
                              Expanded(
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 4, 0, 24),
                                  itemCount: searchStockReport.length,
                                  itemBuilder: (context, index) {
                                    final r = searchStockReport[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: index ==
                                                searchStockReport.length - 1
                                            ? 6
                                            : 10,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    StockzoomingReport(
                                                  ItCOode: r['ItCode'],
                                                  fromDate: fromDate.toString(),
                                                  toDate: toDate.toString(),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  _cta.withValues(alpha: 0.4),
                                                  _cta.withValues(alpha: 0.08),
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _cta.withValues(
                                                      alpha: 0.12),
                                                  blurRadius: 22,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(1.25),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      16, 16, 16, 14),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20.75),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x060F172A),
                                                    blurRadius: 12,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          '${r['ItName']}',
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                            color: _cta,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 16,
                                                            letterSpacing: -0.3,
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons
                                                            .chevron_right_rounded,
                                                        color: _textSecondary
                                                            .withValues(
                                                                alpha: 0.65),
                                                        size: 26,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Divider(
                                                    height: 1,
                                                    thickness: 1,
                                                    color: _border.withValues(
                                                        alpha: 0.65),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  LayoutBuilder(
                                                    builder: (context, c) {
                                                      final twoCol =
                                                          c.maxWidth >= 320;
                                                      final pcs = [
                                                        _metricLine(
                                                            'Op Pcs',
                                                            _fmtPcs(
                                                                r['OpPcs'])),
                                                        _metricLine(
                                                            'Pr Pcs',
                                                            _fmtPcs(
                                                                r['PrPcs'])),
                                                        _metricLine(
                                                            'In Pcs',
                                                            _fmtPcs(
                                                                r['InPcs'])),
                                                        _metricLine(
                                                            'Out Pcs',
                                                            _fmtPcs(
                                                                r['OutPcs'])),
                                                        _metricLine(
                                                            'Sl Pcs',
                                                            _fmtPcs(
                                                                r['SlPcs'])),
                                                        _metricLine(
                                                            'Cl Pcs',
                                                            _fmtPcs(
                                                                r['ClPcs'])),
                                                      ];
                                                      final wt = [
                                                        _metricLine('Op Weight',
                                                            _fmtWt(r['OpWt'])),
                                                        _metricLine('Pr Weight',
                                                            _fmtWt(r['PrWt'])),
                                                        _metricLine('In Weight',
                                                            _fmtWt(r['InWt'])),
                                                        _metricLine(
                                                            'Out Weight',
                                                            _fmtWt(r['OutWt'])),
                                                        _metricLine('Sl Weight',
                                                            _fmtWt(r['SlWt'])),
                                                        _metricLine('Cl Weight',
                                                            _fmtWt(r['ClWt'])),
                                                      ];
                                                      if (!twoCol) {
                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            Text(
                                                              'Pieces',
                                                              style: GoogleFonts
                                                                  .plusJakartaSans(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                letterSpacing:
                                                                    0.8,
                                                                color:
                                                                    _textSecondary,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            ...pcs,
                                                            const SizedBox(
                                                                height: 14),
                                                            Text(
                                                              'Weight',
                                                              style: GoogleFonts
                                                                  .plusJakartaSans(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                letterSpacing:
                                                                    0.8,
                                                                color:
                                                                    _textSecondary,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            ...wt,
                                                          ],
                                                        );
                                                      }
                                                      return Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                Text(
                                                                  'Pieces',
                                                                  style: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                    letterSpacing:
                                                                        0.8,
                                                                    color:
                                                                        _textSecondary,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 8),
                                                                ...pcs,
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 14),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                Text(
                                                                  'Weight',
                                                                  style: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                    letterSpacing:
                                                                        0.8,
                                                                    color:
                                                                        _textSecondary,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 8),
                                                                ...wt,
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
            ],
          ),
        ],
      ),
    );
  }
}
