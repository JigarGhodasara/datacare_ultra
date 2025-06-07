import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class LedgerreportScreen extends StatefulWidget {
  const LedgerreportScreen({Key? key}) : super(key: key);

  @override
  State<LedgerreportScreen> createState() => _LedgerreportScreenState();
}

class _LedgerreportScreenState extends State<LedgerreportScreen> {
  final sqlConnection = SqlConnection.getInstance();
  List<dynamic> ledgerReport = [];
  List<dynamic> searchFillteredLedgerReport = [];
  List<dynamic> accountGroup = [
    {"AC_GR": "", "AC_GR_NAME": "Select Group"}
  ];
  dynamic selectedGroup = {"AC_GR": "", "AC_GR_NAME": "Select Group"};
  List<dynamic> accountCity = [
     "Select City"
  ];
  dynamic selectedCity = "Select City";
  List<dynamic> accountArea = [
    "Select Area"
  ];
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
    if(Platform.isAndroid) {
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
      accountCity.addAll(jsonDecode(accountCityData).map((e) => e['AC_CITY'] as String));
      dynamic accountAreaData =
      await sqlConnection.queryDatabase(accountAreaQuery);
      accountArea.addAll(jsonDecode(accountAreaData).map((e) => e['AC_AREA'] as String));

      log("Result1 ${accountGroupData}");
      log("Result2 ${accountCityData}");
      log("Result3 ${accountAreaData}");
    }else{
      dynamic grp = await MySQLService().getGroup(co_code);
      dynamic city = await MySQLService().getCity(co_code,lc_code);
      dynamic area = await MySQLService().getArea(co_code,lc_code);
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
    if (Platform.isAndroid) {
      String query = "";

      query = "Select ROW_NUMBER() OVER (ORDER BY B.AC_NAME) AS SrNo,A.AC_CODE,B.AC_NAME,B.AC_ADD1,B.AC_MOBILE,B.AC_REF_NAME As AC_REFBY,B.AC_CITY,B.AC_KHATA_NO,  Case When SUM(A.CR_AMT-A.DR_AMT) < 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End As DrAmt,  Case WHEN SUM(A.CR_AMT-A.DR_AMT) > 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End As CrAmt,  Case WHEN SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As DrGold,  Case When SUM(Case When A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As CrGold,  Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As DrSilver,  Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As CrSilver  FROM AC_DATA AS A LEFT JOIN AC_MAST AS B ON A.CO_CODE = B.CO_CODE And A.AC_CODE = B.AC_CODE WHERE A.CO_CODE = '" +
            co_code +
            "' AND A.LC_CODE = '" +
            lc_code +
            "' and A.VCH_DATE <= '" +
            DateFormat("MM/dd/yyyy").format(DateTime.now()) +
            "'";


      if(selectedGroup["AC_GR_NAME"] != "Select Group") {
        var grpCode = "";

        accountGroup.forEach((it){
          if(it["AC_GR_NAME"] == selectedGroup["AC_GR_NAME"]){
            grpCode = it["AC_GR"];
          }
        });
        if(grpCode != ""){
          query += "AND B.AC_GR = '"+grpCode+"' ";
        }
      }

      if(selectedCity != "Select City") {
        var cityCode = "";

        // accountCity.forEach((it){
        //   if(it == selectedCity){
        //     cityCode = it;
        //   }
        // });
        if(selectedCity != "" && selectedCity != "Select City"){
          query += "AND B.AC_CITY = '"+selectedCity+"' ";
        }
      }


      if(selectedArea != "Select Area") {
        // accountCity.forEach((it){
        //   if(it == selectedCity){
        //     cityCode = it;
        //   }
        // });
        if(selectedArea != "" && selectedArea != "Select Area"){
          query += "AND B.AC_AREA = '"+selectedArea+"' ";
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


      if(checkBox){
        query += "GROUP BY A.AC_CODE,B.AC_NAME,B.AC_ADD1,B.AC_MOBILE,B.AC_REF_NAME,B.AC_CITY,B.AC_KHATA_NO ORDER BY B.AC_NAME";
      }else{
        query += "GROUP BY A.AC_CODE,B.AC_NAME,B.AC_ADD1,B.AC_MOBILE,B.AC_REF_NAME,B.AC_CITY,B.AC_KHATA_NO  HAVING (round(Case When SUM(A.CR_AMT-A.DR_AMT) < 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End,2)) +  (round(Case WHEN SUM(A.CR_AMT-A.DR_AMT) > 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End,2)) +  (format(Case WHEN SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.000')) +  (format(Case When SUM(Case When A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.000')) +  (format(Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.00'))+  (format(Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.00')) <> 0  ORDER BY B.AC_NAME ";
      }
      print(query);
      dynamic result = await sqlConnection.queryDatabase(query);
      log("Result ${result}");
      ledgerReport = jsonDecode(result);
      searchFillteredLedgerReport = jsonDecode(result);
    } else {

      var grp = "";
      var city = "";
      var area = "";

      if(selectedGroup["AC_GR_NAME"] != "Select Group") {
        accountGroup.forEach((it){
          if(it["AC_GR_NAME"] == selectedGroup["AC_GR_NAME"]){
            grp = it["AC_GR"];
          }
        });
      }

      if(selectedCity != "Select City" && selectedCity != "") {


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
          checkBox,grp,city,area);
      ledgerReport = ledgerReportData[0];
      searchFillteredLedgerReport = ledgerReportData[0];
    }

    setState(() {});
    loadingProvider.stopLoading();
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
        builder: (context) => StatefulBuilder(builder: (context,setStateModal){
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 5),
                  child: Row(
                    children: [
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.close)),
                      Spacer(),
                      GestureDetector(
                        onTap: (){
                           selectedGroup = {"AC_GR": "", "AC_GR_NAME": "Select Group"};
                           selectedCity = "Select City";
                           selectedArea =  "Select Area";

                           getLedgerData();
                           Navigator.pop(context);

                        },
                        child: Text(
                          "Clear All",
                          style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF006EB7),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      GestureDetector(
                        onTap: (){
                          selectedGroup = selectedGrp;
                          selectedCity = selectedCt;
                          selectedArea = selectedAr;

                          getLedgerData();
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Apply Filter",
                          style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF006EB7),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(),
                SizedBox(
                  height: 20,
                ),
                Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Account Group",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF006EB7),
                                fontWeight: FontWeight.w600),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                                color: Color(0xFFe7edeb),
                                borderRadius: BorderRadius.circular(8.0)),
                            child: DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Color(0xfff1f1f1),
                                ),
                                child: DropdownButton2(
                                    dropdownStyleData: DropdownStyleData(),
                                    isExpanded: true,
                                    value: selectedGrp["AC_GR_NAME"],
                                    items: group.map((dynamic items) {
                                      return DropdownMenuItem(
                                        value: items["AC_GR_NAME"],
                                        child: Text(items["AC_GR_NAME"]),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      selectedGrp = {
                                        "AC_GR": "",
                                        "AC_GR_NAME": "$value"
                                      };
                                      setStateModal(() {});
                                    }),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Account City",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF006EB7),
                                fontWeight: FontWeight.w600),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                                color: Color(0xFFe7edeb),
                                borderRadius: BorderRadius.circular(8.0)),
                            child: DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Color(0xfff1f1f1),
                                ),
                                child: DropdownButton2(
                                    dropdownStyleData: DropdownStyleData(),
                                    isExpanded: true,
                                    value: selectedCt,
                                    items: city.map((dynamic items) {
                                      log(items);
                                      return DropdownMenuItem(
                                        value: items,
                                        child: Text(items),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      selectedCt = value.toString();
                                      setStateModal(() {});
                                    }),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Account Area",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF006EB7),
                                fontWeight: FontWeight.w600),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                                color: Color(0xFFe7edeb),
                                borderRadius: BorderRadius.circular(8.0)),
                            child: DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Color(0xfff1f1f1),
                                ),
                                child: DropdownButton2(
                                    dropdownStyleData: DropdownStyleData(),
                                    isExpanded: true,
                                    value: selectedAr,
                                    items: area.map((dynamic items) {
                                      return DropdownMenuItem(
                                        value: items,
                                        child: Text(items),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      selectedAr = value;
                                      setStateModal(() {});
                                    }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
              ],
            ),
          );
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ledger Report",
          style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF006EB7)),
        ),
        centerTitle: true,
// elevation: 5,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.keyboard_arrow_left_rounded,
            color: Color(0xFF006EB7),
            size: 45,
          ),
        ),
        actions: [
          Checkbox(
              value: checkBox,
              activeColor: Color(0xFF006EB7),
              onChanged: (newValue) {
                checkBox = newValue!;
                print(newValue);
                setState(() {});
                getLedgerData();
              }),
          GestureDetector(
            onTap: () {
              fillterData(
                  group: accountGroup,
                  selectGroup: selectedGroup,
                  city: accountCity,
                  selectCity: selectedCity,
                  area: accountArea,
                  selectArea: selectedArea);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.filter_list_alt,
                color: Color(0xFF006EB7),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 15,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: TextFormField(
                readOnly: false,
                cursorColor: Color(0xFF006EB7),
                keyboardType: TextInputType.text,
                // inputFormatters: formatters,
                // textCapitalization: textCapitalization ?? TextCapitalization.none,
                // maxLength: maxLength,
                decoration: InputDecoration(
                  hintText: "Search with accout name",
                  counterText: '',
                  contentPadding: EdgeInsets.only(left: 8, top: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        width: 2, color: Color(0xFF006EB7)), //<-- SEE HERE
                  ),
                  prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 8, right: 8),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(5)),
                        child: Icon(
                          Icons.search,
                          color: Colors.orange,
                        ),
                      )),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        width: 2, color: Color(0xFF006EB7)), //<-- SEE HERE
                  ),
                ),
                onChanged: (value) {
                  if (value != "") {
                    searchFillteredLedgerReport = ledgerReport
                        .where((text) =>
                            text.containsKey("AC_NAME") &&
                            text["AC_NAME"]
                                .toString()
                                .toLowerCase()
                                .contains(value.trim().toLowerCase()))
                        .toList();
                    setState(() {});
                  } else {
                    searchFillteredLedgerReport.clear();
                    searchFillteredLedgerReport.addAll(ledgerReport);
                    setState(() {});
                  }
                }),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: searchFillteredLedgerReport.length,
                  itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                            top: 15.0,
                            left: 15,
                            right: 15,
                            bottom:
                                searchFillteredLedgerReport.length - 1 == index
                                    ? 15
                                    : 0),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 10,
                                    spreadRadius: -10,
                                    offset: Offset(2, 3))
                              ]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                searchFillteredLedgerReport[index]['AC_NAME'],
                                style: GoogleFonts.nunito(
                                    color: Color(0xFF006EB7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Divider(
                                height: 2,
                                color: Colors.grey,
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Amount",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Gold Fine",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Silver Fine",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Mobile",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "City",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 28,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        ":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        ":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        ":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        ":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 28,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        searchFillteredLedgerReport[index]
                                                    ['CrAmt'] ==
                                                0
                                            ? searchFillteredLedgerReport[index]
                                                        ['DrAmt'] ==
                                                    0
                                                ? ""
                                                : double.parse(searchFillteredLedgerReport[
                                        index]['DrAmt']
                                            .toString()).toStringAsFixed(2) +
                                                    ' Dr'
                                            : double.parse(searchFillteredLedgerReport[index]
                                        ['CrAmt']
                                            .toString()).toStringAsFixed(2) +
                                                ' Cr',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: searchFillteredLedgerReport[
                                                        index]['CrAmt'] ==
                                                    0
                                                ? Colors.red
                                                : Colors.green),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchFillteredLedgerReport[index]
                                                    ['CrGold'] ==
                                                0
                                            ? searchFillteredLedgerReport[index]
                                                        ['DrGold'] ==
                                                    0
                                                ? ""
                                                : double.parse(searchFillteredLedgerReport[
                                        index]['DrGold'].toString()).toStringAsFixed(3)
                                            +
                                                    ' Dr'
                                            : double.parse(searchFillteredLedgerReport[index]
                                        ['CrGold']
                                            .toString()).toStringAsFixed(3) +
                                                ' Cr',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: searchFillteredLedgerReport[
                                                        index]['CrGold'] ==
                                                    0
                                                ? Colors.red
                                                : Colors.green),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchFillteredLedgerReport[index]
                                                    ['CrSilver'] ==
                                                0
                                            ? searchFillteredLedgerReport[index]
                                                        ['DrSilver'] ==
                                                    0
                                                ? ""
                                                : double.parse(searchFillteredLedgerReport[
                                        index]['DrSilver']
                                            .toString()).toStringAsFixed(3) +
                                                    ' Dr'
                                            : double.parse(searchFillteredLedgerReport[index]
                                        ['CrSilver']
                                            .toString()).toStringAsFixed(3) +
                                                ' Cr',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold,
                                            color: searchFillteredLedgerReport[
                                            index]['CrSilver'] ==
                                                0
                                                ? Colors.red
                                                : Colors.green,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchFillteredLedgerReport[index]
                                            ['AC_MOBILE'],
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchFillteredLedgerReport[index]
                                            ['AC_CITY'],
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              Divider(
                                height: 2,
                                color: Colors.grey,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      if (searchFillteredLedgerReport[index]
                                              ['AC_MOBILE'] !=
                                          '') {
                                        final link = WhatsAppUnilink(
                                            phoneNumber:
                                                '+91${searchFillteredLedgerReport[index]['AC_MOBILE']}',
                                            text:
                                                "Amount : ${searchFillteredLedgerReport[index]['CrAmt'] == 0 ? searchFillteredLedgerReport[index]['DrAmt'] == 0 ? "" : double.parse(searchFillteredLedgerReport[index]['DrAmt'].toString()).toStringAsFixed(2) + ' Dr' : double.parse(searchFillteredLedgerReport[index]['CrAmt'].toString()).toStringAsFixed(2) + ' Cr'} \n Gold : ${searchFillteredLedgerReport[index]['CrGold'] == 0 ? searchFillteredLedgerReport[index]['DrGold'] == 0 ? "" : double.parse(searchFillteredLedgerReport[index]['DrGold'].toString()).toStringAsFixed(3) + ' Dr' : double.parse(searchFillteredLedgerReport[index]['CrGold'].toString()).toStringAsFixed(3) + ' Cr'} \n Silver : ${searchFillteredLedgerReport[index]['CrSilver'] == 0 ? searchFillteredLedgerReport[index]['DrSilver'] == 0 ? "" : double.parse(searchFillteredLedgerReport[index]['DrGold'].toString()).toStringAsFixed(3) + ' Dr' : double.parse(searchFillteredLedgerReport[index]['CrGold'].toString()).toStringAsFixed(3) + ' Cr'} \n ${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).co_name}");
                                        await launchUrlString('$link');
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              "Mobile Number is not exits"),
                                        ));
                                      }

                                      // Convert the WhatsAppUnilink instance to a Uri.
                                      // The "launch" method is part of "url_launcher".
                                    },
                                    child: Image.asset(
                                      AppImage.whatsapp,
                                      scale: 18,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (searchFillteredLedgerReport[index]
                                              ['AC_MOBILE'] !=
                                          '') {
                                        launchUrlString("tel://+91${searchFillteredLedgerReport[index]['AC_MOBILE']}");
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              "Mobile Number is not exits"),
                                        ));
                                      }
                                    },
                                    child: Image.asset(
                                      AppImage.telephone,
                                      scale: 18,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      launchUrlString(
                                          'sms:+91${searchFillteredLedgerReport[index]['AC_MOBILE']}?body=Amount : ${searchFillteredLedgerReport[index]['CrAmt'] == 0 ? searchFillteredLedgerReport[index]['DrAmt'] == 0 ? "" : double.parse(searchFillteredLedgerReport[index]['DrAmt'].toString()).toStringAsFixed(2) + ' Dr' : double.parse(searchFillteredLedgerReport[index]['CrAmt'].toString()).toStringAsFixed(2) + ' Cr'} \n Gold : ${searchFillteredLedgerReport[index]['CrGold'] == 0 ? searchFillteredLedgerReport[index]['DrGold'] == 0 ? "" : double.parse(searchFillteredLedgerReport[index]['DrGold'].toString()).toStringAsFixed(3) + ' Dr' : double.parse(searchFillteredLedgerReport[index]['CrGold'].toString()).toStringAsFixed(3) + ' Cr'} \n Silver : ${searchFillteredLedgerReport[index]['CrSilver'] == 0 ? searchFillteredLedgerReport[index]['DrSilver'] == 0 ? "" : double.parse(searchFillteredLedgerReport[index]['DrGold'].toString()).toStringAsFixed(3) + ' Dr' : double.parse(searchFillteredLedgerReport[index]['CrGold'].toString()).toStringAsFixed(3) + ' Cr'} \n ${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).co_name}');
                                    },
                                    child: Image.asset(
                                      AppImage.chat,
                                      scale: 18,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Share.share(
                                          'Amount : ${searchFillteredLedgerReport[index]['CrAmt'] == 0 ? searchFillteredLedgerReport[index]['DrAmt'] == 0 ? "" : double.parse(searchFillteredLedgerReport[index]['DrAmt'].toString()).toStringAsFixed(2) + ' Dr' : double.parse(searchFillteredLedgerReport[index]['CrAmt'].toString()).toStringAsFixed(2) + ' Cr'} \n Gold : ${searchFillteredLedgerReport[index]['CrGold'] == 0 ? searchFillteredLedgerReport[index]['DrGold'] == 0 ? "" : double.parse(searchFillteredLedgerReport[index]['DrGold'].toString()).toStringAsFixed(3) + ' Dr' : double.parse(searchFillteredLedgerReport[index]['CrGold'].toString()).toStringAsFixed(3) + ' Cr'} \n Silver : ${searchFillteredLedgerReport[index]['CrSilver'] == 0 ? searchFillteredLedgerReport[index]['DrSilver'] == 0 ? "" : double.parse(searchFillteredLedgerReport[index]['DrGold'].toString()).toStringAsFixed(3) + ' Dr' : double.parse(searchFillteredLedgerReport[index]['CrGold'].toString()).toStringAsFixed(3) + ' Cr'} \n ${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).co_name}');
                                    },
                                    child: Image.asset(
                                      AppImage.share,
                                      scale: 18,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      )))
        ],
      ),
    );
  }
}
