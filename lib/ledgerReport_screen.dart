import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/ledgerZoomingReport.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class LedgerreportScreen extends StatefulWidget {
  const LedgerreportScreen({Key? key}) : super(key: key);

  @override
  State<LedgerreportScreen> createState() => _LedgerreportScreenState();
}

class _LedgerreportScreenState extends State<LedgerreportScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  Color get _cta => _brand;

  final sqlConnection = SqlConnection.getInstance();
  List<dynamic> ledgerReport = [];
  List<dynamic> searchFillteredLedgerReport = [];
  List<dynamic> accountGroup = [
    {"AC_GR": "", "AC_GR_NAME": "Select Group"}
  ];
  dynamic selectedGroup = {"AC_GR": "", "AC_GR_NAME": "Select Group"};
  List<dynamic> accountCity = ["Select City"];
  dynamic selectedCity = "Select City";
  List<dynamic> accountArea = ["Select Area"];
  dynamic selectedArea = "Select Area";
  bool checkBox = false;
  String co_code = "";
  String lc_code = "";
  late LoadingProvider loadingProvider;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update your state here
      getLedgerData();
    });
    getFilterData();
  }

  getFilterData() async {
    if (Platform.isAndroid) {
      String accountGroupQuery =
          "SELECT AC_GR,AC_GR_NAME FROM AC_GROUP WHERE CO_CODE='" +
              co_code +
              "' ORDER BY AC_GR";
      String accountCityQuery =
          "Select AC_CITY FROM AC_MAST WHERE CO_CODE = '$co_code' AND LC_CODE = '$lc_code' AND AC_CITY<> '' GROUP BY AC_CITY";
      String accountAreaQuery =
          "Select AC_AREA FROM AC_MAST WHERE CO_CODE = '$co_code' AND LC_CODE = '$lc_code' AND AC_AREA<> '' GROUP BY AC_AREA";
      dynamic accountGroupData =
          await sqlConnection.queryDatabase(accountGroupQuery);
      accountGroup.addAll(jsonDecode(accountGroupData));
      dynamic accountCityData =
          await sqlConnection.queryDatabase(accountCityQuery);
      accountCity.addAll(
          jsonDecode(accountCityData).map((e) => e['AC_CITY'] as String));
      dynamic accountAreaData =
          await sqlConnection.queryDatabase(accountAreaQuery);
      accountArea.addAll(
          jsonDecode(accountAreaData).map((e) => e['AC_AREA'] as String));

      log("Result1 ${accountGroupData}");
      log("Result2 ${accountCityData}");
      log("Result3 ${accountAreaData}");
    } else {
      dynamic grp = await MySQLService().getGroup(co_code);
      dynamic city = await MySQLService().getCity(co_code, lc_code);
      dynamic area = await MySQLService().getArea(co_code, lc_code);
      accountGroup.addAll(grp[0]);
      accountCity.addAll(city[0].map((e) => e['AC_CITY'] as String));
      accountArea.addAll(area[0].map((e) => e['AC_AREA'] as String));
      log("Result1 ${grp}");
      log("Result2 ${city}");
      log("Result3 ${area}");
    }
  }

  getLedgerData() async {
    loadingProvider.startLoading();
    try {
      if (Platform.isAndroid) {
        String query = "";

        query =
            "Select ROW_NUMBER() OVER (ORDER BY B.AC_NAME) AS SrNo,A.AC_CODE,B.AC_NAME,B.AC_ADD1,B.AC_MOBILE,B.AC_REF_NAME As AC_REFBY,B.AC_CITY,B.AC_KHATA_NO,  Case When SUM(A.CR_AMT-A.DR_AMT) < 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End As DrAmt,  Case WHEN SUM(A.CR_AMT-A.DR_AMT) > 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End As CrAmt,  Case WHEN SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As DrGold,  Case When SUM(Case When A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As CrGold,  Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As DrSilver,  Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As CrSilver  FROM AC_DATA AS A LEFT JOIN AC_MAST AS B ON A.CO_CODE = B.CO_CODE And A.AC_CODE = B.AC_CODE WHERE A.CO_CODE = '$co_code' AND A.LC_CODE = '$lc_code' and A.VCH_DATE <= '${DateFormat("MM/dd/yyyy").format(DateTime.now())}'";

        if (selectedGroup["AC_GR_NAME"] != "Select Group") {
          var grpCode = "";

          accountGroup.forEach((it) {
            if (it["AC_GR_NAME"] == selectedGroup["AC_GR_NAME"]) {
              grpCode = it["AC_GR"];
            }
          });
          if (grpCode != "") {
            query += "AND B.AC_GR = '" + grpCode + "' ";
          }
        }

        if (selectedCity != "Select City") {
          var cityCode = "";

          // accountCity.forEach((it){
          //   if(it == selectedCity){
          //     cityCode = it;
          //   }
          // });
          if (selectedCity != "" && selectedCity != "Select City") {
            query += "AND B.AC_CITY = '" + selectedCity + "' ";
          }
        }

        if (selectedArea != "Select Area") {
          // accountCity.forEach((it){
          //   if(it == selectedCity){
          //     cityCode = it;
          //   }
          // });
          if (selectedArea != "" && selectedArea != "Select Area") {
            query += "AND B.AC_AREA = '" + selectedArea + "' ";
          }
        }
        // if(selectedArea["CityL"] != "Select Area") {
        //   var cityCode = "";
        //
        //   accountCity.forEach((it){
        //     if(it["CityL"] == selectedCity["CityL"]){
        //       cityCode = it["CodeL"];
        //     }
        //   });
        //   if(cityCode != ""){
        //     query += "AND B.AC_AREA = '\(LArea)' ";
        //   }
        // }
        //
        // if !LAcCode.isEmpty {
        // strappend += "AND A.AC_CODE = '\(LAcCode)' "
        // }
        //

        if (checkBox) {
          query +=
              "GROUP BY A.AC_CODE,B.AC_NAME,B.AC_ADD1,B.AC_MOBILE,B.AC_REF_NAME,B.AC_CITY,B.AC_KHATA_NO ORDER BY B.AC_NAME";
        } else {
          query +=
              "GROUP BY A.AC_CODE,B.AC_NAME,B.AC_ADD1,B.AC_MOBILE,B.AC_REF_NAME,B.AC_CITY,B.AC_KHATA_NO  HAVING (round(Case When SUM(A.CR_AMT-A.DR_AMT) < 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End,2)) +  (round(Case WHEN SUM(A.CR_AMT-A.DR_AMT) > 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End,2)) +  (format(Case WHEN SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.000')) +  (format(Case When SUM(Case When A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.000')) +  (format(Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.00'))+  (format(Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.00')) <> 0  ORDER BY B.AC_NAME ";
        }
        log(query);
        dynamic result = await sqlConnection.queryDatabase(query);
        log("Result ${result}");
        ledgerReport = jsonDecode(result);
        searchFillteredLedgerReport = jsonDecode(result);
      } else {
        var grp = "";
        var city = "";
        var area = "";

        if (selectedGroup["AC_GR_NAME"] != "Select Group") {
          accountGroup.forEach((it) {
            if (it["AC_GR_NAME"] == selectedGroup["AC_GR_NAME"]) {
              grp = it["AC_GR"];
            }
          });
        }

        if (selectedCity != "Select City" && selectedCity != "") {
          // accountCity.forEach((it){
          //   if(it["CityL"] == selectedCity["CityL"]){
          //     city = it["CityL"];
          //   }
          // });
          city = selectedCity;
        }

        // if(selectedArea["CityL"] != "Select Area") {
        //   var cityCode = "";
        //
        //   accountCity.forEach((it){
        //     if(it["CityL"] == selectedCity["CityL"]){
        //       cityCode = it["CodeL"];
        //     }
        //   });
        //   if(cityCode != ""){
        //     query += "AND B.AC_AREA = '\(LArea)' ";
        //   }
        // }
        //
        // if !LAcCode.isEmpty {
        // strappend += "AND A.AC_CODE = '\(LAcCode)' "
        // }
        //

        dynamic ledgerReportData = await MySQLService().getLedgerReportData(
            co_code,
            lc_code,
            DateFormat("MM/dd/yyyy").format(DateTime.now()),
            checkBox,
            grp,
            city,
            area);
        ledgerReport = ledgerReportData[0];
        searchFillteredLedgerReport = ledgerReportData[0];
      }
    } catch (e) {
      ledgerReport = [];
      searchFillteredLedgerReport = [];
      if (mounted) _toast("Could not load ledger report. Please try again.");
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  fillterData(
      {required List<dynamic> group,
      required dynamic selectGroup,
      required List<dynamic> city,
      required dynamic selectCity,
      required List<dynamic> area,
      required dynamic selectArea}) {
    dynamic selectedGrp = selectGroup;
    dynamic selectedCt = selectCity;
    dynamic selectedAr = selectArea;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (context) =>
            StatefulBuilder(builder: (context, setStateModal) {
              final viewInsets = MediaQuery.of(context).viewInsets.bottom;
              final safeBottom = MediaQuery.of(context).padding.bottom;
              final maxSheetH = MediaQuery.of(context).size.height * 0.88;

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
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: _cta, size: 22),
              );
              final sheetMenuItemStyle = const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              );

              Widget filterLabel(String text) {
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
                          boxShadow: [
                            BoxShadow(
                              color: _cta.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
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
                        border: Border.all(
                          color: _cta.withValues(alpha: 0.1),
                          width: 1,
                        ),
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
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              10,
                              20,
                              safeBottom + 16,
                            ),
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
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _border.withValues(
                                                  alpha: 0.65),
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
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: _cta.withValues(alpha: 0.35),
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        selectedGroup = {
                                          "AC_GR": "",
                                          "AC_GR_NAME": "Select Group"
                                        };
                                        selectedCity = "Select City";
                                        selectedArea = "Select Area";
                                        getLedgerData();
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
                                filterLabel('Account group'),
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
                                      value: selectedGrp["AC_GR_NAME"],
                                      items: group.map((dynamic items) {
                                        return DropdownMenuItem(
                                          value: items["AC_GR_NAME"],
                                          child: Text(
                                            items["AC_GR_NAME"],
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        selectedGrp = {
                                          "AC_GR": "",
                                          "AC_GR_NAME": "$value"
                                        };
                                        setStateModal(() {});
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                filterLabel('Account city'),
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
                                      value: selectedCt,
                                      items: city.map((dynamic items) {
                                        log(items);
                                        return DropdownMenuItem(
                                          value: items,
                                          child: Text(
                                            items.toString(),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        selectedCt = value.toString();
                                        setStateModal(() {});
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                filterLabel('Account area'),
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
                                      value: selectedAr,
                                      items: area.map((dynamic items) {
                                        return DropdownMenuItem(
                                          value: items,
                                          child: Text(
                                            items.toString(),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        selectedAr = value;
                                        setStateModal(() {});
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
                                        onPressed: () {
                                          selectedGroup = selectedGrp;
                                          selectedCity = selectedCt;
                                          selectedArea = selectedAr;
                                          getLedgerData();
                                          Navigator.pop(context);
                                        },
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
              );
            }));
  }

  Widget _detailLine(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 102,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                height: 1.3,
              ),
            ),
          ),
          Text(
            ': ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _border,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: valueColor ?? _textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({required VoidCallback onTap, required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _pageBg,
            border: Border.all(color: _border.withValues(alpha: 0.65)),
          ),
          child: child,
        ),
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _mobile(dynamic data) => '${data['AC_MOBILE'] ?? ''}'.trim();

  String _amountLine(dynamic data) {
    final cr = double.tryParse('${data['CrAmt'] ?? 0}') ?? 0;
    final dr = double.tryParse('${data['DrAmt'] ?? 0}') ?? 0;
    if (cr != 0) return '${cr.toStringAsFixed(2)} Cr';
    if (dr != 0) return '${dr.toStringAsFixed(2)} Dr';
    return '-';
  }

  String _goldLine(dynamic data) {
    final cr = double.tryParse('${data['CrGold'] ?? 0}') ?? 0;
    final dr = double.tryParse('${data['DrGold'] ?? 0}') ?? 0;
    if (cr != 0) return '${cr.toStringAsFixed(3)} Cr';
    if (dr != 0) return '${dr.toStringAsFixed(3)} Dr';
    return '-';
  }

  String _silverLine(dynamic data) {
    final cr = double.tryParse('${data['CrSilver'] ?? 0}') ?? 0;
    final dr = double.tryParse('${data['DrSilver'] ?? 0}') ?? 0;
    if (cr != 0) return '${cr.toStringAsFixed(3)} Cr';
    if (dr != 0) return '${dr.toStringAsFixed(3)} Dr';
    return '-';
  }

  String _ledgerMessage(dynamic data) {
    final companyName =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_name;
    final buffer = StringBuffer();
    buffer.writeln('Dear ${data['AC_NAME'] ?? ''},');
    buffer.writeln();
    buffer.writeln('Account statement summary:');
    buffer.writeln('Amount : ${_amountLine(data)}');
    buffer.writeln('Gold   : ${_goldLine(data)}');
    buffer.writeln('Silver : ${_silverLine(data)}');
    buffer.writeln();
    buffer.write('Regards, $companyName');
    return buffer.toString();
  }

  Future<void> _sendWhatsApp(dynamic data) async {
    final mobile = _mobile(data);
    if (mobile.isEmpty) {
      _toast('Mobile number does not exist');
      return;
    }
    final link = WhatsAppUnilink(
      phoneNumber: '+91$mobile',
      text: _ledgerMessage(data),
    );
    await launchUrlString('$link', mode: LaunchMode.externalApplication);
  }

  Future<void> _makeCall(dynamic data) async {
    final mobile = _mobile(data);
    if (mobile.isEmpty) {
      _toast('Mobile number does not exist');
      return;
    }
    await launchUrlString('tel:+91$mobile');
  }

  Future<void> _sendSms(dynamic data) async {
    final mobile = _mobile(data);
    if (mobile.isEmpty) {
      _toast('Mobile number does not exist');
      return;
    }
    final body = Uri.encodeComponent(_ledgerMessage(data));
    await launchUrlString('sms:+91$mobile?body=$body');
  }

  Future<void> _shareMessage(dynamic data) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _ledgerMessage(data),
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
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
          'Ledger report',
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
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Theme(
              data: Theme.of(context).copyWith(
                checkboxTheme: CheckboxThemeData(
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _cta;
                    }
                    return null;
                  }),
                  side: BorderSide(color: _border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              child: Checkbox(
                value: checkBox,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (newValue) {
                  checkBox = newValue!;
                  print(newValue);
                  setState(() {});
                  getLedgerData();
                },
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                fillterData(
                    group: accountGroup,
                    selectGroup: selectedGroup,
                    city: accountCity,
                    selectCity: selectedCity,
                    area: accountArea,
                    selectArea: selectedArea);
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
      body: Column(
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
                  hintText: 'Search by account name or mobile',
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
                      child: Icon(Icons.search_rounded, color: _cta, size: 22),
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != "") {
                    searchFillteredLedgerReport = ledgerReport
                        .where((text) =>
                            (text.containsKey("AC_NAME") &&
                                text["AC_NAME"]
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.trim().toLowerCase())) ||
                            (text.containsKey("AC_MOBILE") &&
                                text["AC_MOBILE"]
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.trim().toLowerCase())))
                        .toList();
                    setState(() {});
                  } else {
                    searchFillteredLedgerReport.clear();
                    searchFillteredLedgerReport.addAll(ledgerReport);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<LoadingProvider>(
              builder: (context, loading, _) {
                if (loading.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: _cta),
                  );
                }
                if (searchFillteredLedgerReport.isEmpty) {
                  return _emptyState();
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: searchFillteredLedgerReport.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == searchFillteredLedgerReport.length - 1
                          ? 0
                          : 12,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Ledgerzoomingreport(
                                        name:
                                            "${searchFillteredLedgerReport[index]['AC_NAME']}",
                                        acCode:
                                            "${searchFillteredLedgerReport[index]['AC_CODE']}",
                                      )));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
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
                                color: _cta.withValues(alpha: 0.12),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(1.25),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.75),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x060F172A),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        searchFillteredLedgerReport[index]
                                            ['AC_NAME'],
                                        style: GoogleFonts.plusJakartaSans(
                                          color: _cta,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                          height: 1.25,
                                          letterSpacing: -0.35,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: _textSecondary.withValues(
                                          alpha: 0.65),
                                      size: 26,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: _border.withValues(alpha: 0.65),
                                ),
                                const SizedBox(height: 12),
                                _detailLine(
                                  'Amount',
                                  searchFillteredLedgerReport[index]['CrAmt'] ==
                                          0
                                      ? searchFillteredLedgerReport[index]
                                                  ['DrAmt'] ==
                                              0
                                          ? ''
                                          : '${double.parse(searchFillteredLedgerReport[index]['DrAmt'].toString()).toStringAsFixed(2)} Dr'
                                      : '${double.parse(searchFillteredLedgerReport[index]['CrAmt'].toString()).toStringAsFixed(2)} Cr',
                                  valueColor: searchFillteredLedgerReport[index]
                                              ['CrAmt'] ==
                                          0
                                      ? _danger
                                      : _success,
                                ),
                                _detailLine(
                                  'Gold fine',
                                  searchFillteredLedgerReport[index]
                                              ['CrGold'] ==
                                          0
                                      ? searchFillteredLedgerReport[index]
                                                  ['DrGold'] ==
                                              0
                                          ? ''
                                          : '${double.parse(searchFillteredLedgerReport[index]['DrGold'].toString()).toStringAsFixed(3)} Dr'
                                      : '${double.parse(searchFillteredLedgerReport[index]['CrGold'].toString()).toStringAsFixed(3)} Cr',
                                  valueColor: searchFillteredLedgerReport[index]
                                              ['CrGold'] ==
                                          0
                                      ? _danger
                                      : _success,
                                ),
                                _detailLine(
                                  'Silver fine',
                                  searchFillteredLedgerReport[index]
                                              ['CrSilver'] ==
                                          0
                                      ? searchFillteredLedgerReport[index]
                                                  ['DrSilver'] ==
                                              0
                                          ? ''
                                          : '${double.parse(searchFillteredLedgerReport[index]['DrSilver'].toString()).toStringAsFixed(3)} Dr'
                                      : '${double.parse(searchFillteredLedgerReport[index]['CrSilver'].toString()).toStringAsFixed(3)} Cr',
                                  valueColor: searchFillteredLedgerReport[index]
                                              ['CrSilver'] ==
                                          0
                                      ? _danger
                                      : _success,
                                ),
                                _detailLine(
                                  'Mobile',
                                  '${searchFillteredLedgerReport[index]['AC_MOBILE']}',
                                ),
                                _detailLine(
                                  'City',
                                  '${searchFillteredLedgerReport[index]['AC_CITY']}',
                                ),
                                const SizedBox(height: 6),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: _border.withValues(alpha: 0.65),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: _actionChip(
                                          onTap: () => _sendWhatsApp(
                                              searchFillteredLedgerReport[
                                                  index]),
                                          child: Image.asset(
                                            AppImage.whatsapp,
                                            scale: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: _actionChip(
                                          onTap: () => _makeCall(
                                              searchFillteredLedgerReport[
                                                  index]),
                                          child: Image.asset(
                                            AppImage.telephone,
                                            scale: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: _actionChip(
                                          onTap: () => _sendSms(
                                              searchFillteredLedgerReport[
                                                  index]),
                                          child: Image.asset(
                                            AppImage.chat,
                                            scale: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: _actionChip(
                                          onTap: () => _shareMessage(
                                              searchFillteredLedgerReport[
                                                  index]),
                                          child: Image.asset(
                                            AppImage.share,
                                            scale: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cta.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 46,
              color: _cta.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No ledger records found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filters or search',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
