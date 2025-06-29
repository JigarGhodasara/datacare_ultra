import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/stockZoomingReport.dart';
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

class StockreportScreen extends StatefulWidget {
  const StockreportScreen({Key? key}) : super(key: key);

  @override
  State<StockreportScreen> createState() => _StockreportScreenState();
}

class _StockreportScreenState extends State<StockreportScreen> {
  final sqlConnection = SqlConnection.getInstance();
  String StkType = '';
  String ItType = '';
  List<dynamic> stockReport = [];
  List<dynamic> searchStockReport = [];
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

    loadingProvider.stopLoading();
    setState(() {});
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
        builder: (context) =>
            StatefulBuilder(builder: (context, setModalState) {
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
                            onTap: () {
                              selectedGroupCode = {
                                "GR_CODE": "",
                                "GR_NAME": "Select Group"
                              };
                              selectedItemCode = {"IT_NAME": "Select Item"};
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
                            onTap: () {
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
                            "From To Date",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF006EB7),
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    DateTime? dat =
                                        await _selectDate(context, from);
                                    from = dat!;
                                    setModalState(() {});
                                  },
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 15),
                                    margin: EdgeInsets.only(right: 7.5),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Color(0xFF006EB7))),
                                    child: SizedBox(
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Text(DateFormat("dd-MM-yyyy")
                                              .format(from)),
                                          Spacer(),
                                          Icon(Icons.keyboard_arrow_down)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    DateTime? dat =
                                        await _selectDate(context, to);
                                    to = dat!;
                                    setModalState(() {});
                                  },
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 15),
                                    margin: EdgeInsets.only(left: 7.5),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Color(0xFF006EB7))),
                                    child: SizedBox(
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Text(DateFormat("dd-MM-yyyy")
                                              .format(to)),
                                          Spacer(),
                                          Icon(Icons.keyboard_arrow_down)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Item Type",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF006EB7),
                                fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 1,
                                    activeColor: Color(0xFF006EB7),
                                    groupValue: selectedOption,
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedOption = value!;
                                        selectedItType = "";
                                        print("Button value: $selectedOption");
                                      });
                                    },
                                  ),
                                  Text("All"),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 2,
                                    activeColor: Color(0xFF006EB7),
                                    groupValue: selectedOption,
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedOption = value!;
                                        selectedItType = 'G';
                                        print("Button value: $value");
                                      });
                                    },
                                  ),
                                  Text("Gold"),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 3,
                                    activeColor: Color(0xFF006EB7),
                                    groupValue: selectedOption,
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedOption = value!;
                                        selectedItType = 'S';
                                        print("Button value: $value");
                                      });
                                    },
                                  ),
                                  Text("Silver"),
                                ],
                              )
                            ],
                          ),
                          Text(
                            "Stock Type",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF006EB7),
                                fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 1,
                                    activeColor: Color(0xFF006EB7),
                                    groupValue: selectedStkOption,
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedStkOption = value!;
                                        selectedStkType = "";
                                        print("Button value: $selectedOption");
                                      });
                                    },
                                  ),
                                  Text("All"),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 2,
                                    activeColor: Color(0xFF006EB7),
                                    groupValue: selectedStkOption,
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedStkOption = value!;
                                        selectedStkType = 'I';
                                        print("Button value: $value");
                                      });
                                    },
                                  ),
                                  Text("Item"),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 3,
                                    activeColor: Color(0xFF006EB7),
                                    groupValue: selectedStkOption,
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedStkOption = value!;
                                        selectedStkType = 'T';
                                        print("Button value: $value");
                                      });
                                    },
                                  ),
                                  Text("Tag"),
                                ],
                              )
                            ],
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Group",
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
                                    value: selectedGroupvalue["GR_NAME"],
                                    items: groupData.map((dynamic items) {
                                      return DropdownMenuItem(
                                        value: items["GR_NAME"],
                                        child: Text(items["GR_NAME"]),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      selectedGroupvalue = {
                                        "GR_CODE": "",
                                        "GR_NAME": value
                                      };
                                      setModalState(() {});
                                    }),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Item",
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
                                    value: selectedItemvalue["IT_NAME"],
                                    items: itemData.map((dynamic items) {
                                      print("data $items ");
                                      return DropdownMenuItem(
                                        value: items["IT_NAME"],
                                        child: Text(items["IT_NAME"]),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      selectedItemvalue = {
                                        "IT_NAME": "${value}"
                                      };
                                      setModalState(() {});
                                    }),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Product",
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
                                    value: selectedProductvalue["PR_NAME"],
                                    items: productData.map((dynamic items) {
                                      return DropdownMenuItem(
                                        value: items["PR_NAME"],
                                        child: Text(items["PR_NAME"]),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      selectedProductvalue = {
                                        "PR_CODE": "",
                                        "PR_NAME": value
                                      };
                                      setModalState(() {});
                                    }),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Table Name",
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
                                    value: selectedTablevalue["TABLE_NAME"],
                                    items: tableNameData.map((dynamic items) {
                                      return DropdownMenuItem(
                                        value: items["TABLE_NAME"],
                                        child: Text(items["TABLE_NAME"]),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      selectedTablevalue = {
                                        "TABLE_CODE": "",
                                        "TABLE_NAME": value.toString()
                                      };
                                      setModalState(() {});
                                    }),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                          ),
                        ],
                      ),
                    ))
                  ],
                ),
              );
            }));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Stock Report",
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
          GestureDetector(
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
                  hintText: "Search with item name",
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
                }),
          ),
          loadingProvider.isLoading
              ? SizedBox()
              : searchStockReport.length == 0
                  ? Expanded(
                      child: Center(
                      child: Text(
                        "No record found",
                        style: GoogleFonts.nunito(
                            color: Color(0xFF006EB7),
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ))
                  : Expanded(
                      child: ListView.builder(
                          itemCount: searchStockReport.length,
                          itemBuilder: (context, index) => InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              StockzoomingReport(
                                                ItCOode:
                                                    searchStockReport[index]
                                                        ['ItCode'],
                                                fromDate: fromDate.toString(),
                                                toDate: toDate.toString(),
                                              )));
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top: 15.0,
                                      left: 15,
                                      right: 15,
                                      bottom:
                                          index == searchStockReport.length - 1
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "Name : ",
                                              style: GoogleFonts.nunito(
                                                  color: Color(0xFF006EB7),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              searchStockReport[index]
                                                  ["ItName"],
                                              style: GoogleFonts.nunito(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15),
                                            )
                                          ],
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
                                            Expanded(
                                                child: Row(
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Op Pcs",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "Pr Pcs",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "In Pcs",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "Out Pcs",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "Sl Pcs",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "Cl Pcs",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 5,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["OpPcs"] ==
                                                              0
                                                          ? ""
                                                          : searchStockReport[
                                                                      index]
                                                                  ["OpPcs"]
                                                              .toString(),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["PrPcs"] ==
                                                              0
                                                          ? ""
                                                          : searchStockReport[
                                                                      index]
                                                                  ["PrPcs"]
                                                              .toString(),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["InPcs"] ==
                                                              0
                                                          ? ""
                                                          : searchStockReport[
                                                                      index]
                                                                  ["InPcs"]
                                                              .toString(),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["OutPcs"] ==
                                                              0
                                                          ? ""
                                                          : searchStockReport[
                                                                      index]
                                                                  ["OutPcs"]
                                                              .toString(),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["SlPcs"] ==
                                                              0
                                                          ? ""
                                                          : searchStockReport[
                                                                      index]
                                                                  ["SlPcs"]
                                                              .toString(),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["ClPcs"] ==
                                                              0
                                                          ? ""
                                                          : searchStockReport[
                                                                      index]
                                                                  ["ClPcs"]
                                                              .toString(),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )),
                                            Expanded(
                                                child: Row(
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Op Weight",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "Pr Weight",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "In Weight",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "Out Weight",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "Sl Weight",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      "Cl Weight",
                                                      style: GoogleFonts.nunito(
                                                          color:
                                                              Color(0xFF006EB7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      ":",
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 5,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["OpWt"] ==
                                                              0
                                                          ? ""
                                                          : double.parse(searchStockReport[
                                                                          index]
                                                                      ["OpWt"]
                                                                  .toString())
                                                              .toStringAsFixed(
                                                                  3),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["PrWt"] ==
                                                              0
                                                          ? ""
                                                          : double.parse(searchStockReport[
                                                                          index]
                                                                      ["PrWt"]
                                                                  .toString())
                                                              .toStringAsFixed(
                                                                  3),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["InWt"] ==
                                                              0
                                                          ? ""
                                                          : double.parse(searchStockReport[
                                                                          index]
                                                                      ["InWt"]
                                                                  .toString())
                                                              .toStringAsFixed(
                                                                  3),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["OutWt"] ==
                                                              0
                                                          ? ""
                                                          : double.parse(searchStockReport[
                                                                          index]
                                                                      ["OutWt"]
                                                                  .toString())
                                                              .toStringAsFixed(
                                                                  3),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["SlWt"] ==
                                                              0
                                                          ? ""
                                                          : double.parse(searchStockReport[
                                                                          index]
                                                                      ["SlWt"]
                                                                  .toString())
                                                              .toStringAsFixed(
                                                                  3),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                    SizedBox(
                                                      height: 3.5,
                                                    ),
                                                    Text(
                                                      searchStockReport[index]
                                                                  ["ClWt"] ==
                                                              0
                                                          ? ""
                                                          : double.parse(searchStockReport[
                                                                          index]
                                                                      ["ClWt"]
                                                                  .toString())
                                                              .toStringAsFixed(
                                                                  3),
                                                      style: GoogleFonts.nunito(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )))
        ],
      ),
    );
  }
}
