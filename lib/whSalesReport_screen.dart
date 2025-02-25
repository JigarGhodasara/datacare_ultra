import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class WhsalesreportScreen extends StatefulWidget {
  const WhsalesreportScreen({Key? key}) : super(key: key);

  @override
  State<WhsalesreportScreen> createState() => _WhsalesreportScreenState();
}

class _WhsalesreportScreenState extends State<WhsalesreportScreen> {
  final sqlConnection = SqlConnection.getInstance();
  List<dynamic> whSalesReport = [];
  List<dynamic> searchWhSalesReport = [];
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String co_code = "";
  String lc_code = "";
  String year = "";
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
    year =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update your state here
      getWHSalesReportData();
    });
  }

  getWHSalesReportData() async {
    loadingProvider.startLoading();
    setState(() {
    });
    print("object");
    if (Platform.isAndroid) {
      var query =
          "SELECT A.CO_CODE,A.CO_YEAR,(convert(varchar(50),A.VCH_DATE,105)) as VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_SNAME,C.AC_CODE,C.AC_NAME,C.AC_MOBILE, SUM(ITM_PCS) As Pcs,Sum(A.ITM_GWT) As Gwt,SUM(A.ITM_NWT) As Nwt, (Select D.TOT_FINE_DR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As TotDrFine, (Select D.KSR_FINE_CR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As KasarFine, (Select D.TOT_FINE_CR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As TotRecFine, (Select D.TOT_FINE_DR-D.KSR_FINE_CR- D.TOT_FINE_CR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As OsFine, (Select E.DR_AMT+E.SL_LBR_AMT+E.SL_OTH_AMT+E.SL_ITM_AMT From RATE_CUT_DATA AS E Where A.CO_CODE = E.CO_CODE AND A.CO_YEAR = E.CO_YEAR AND A.CO_BOOK = E.CO_BOOK  AND A.VCH_NO = E.VCH_NO ) As NetAmt, (Select H.SL_CHQ_AMT+H.SL_CARD_AMT+SL_CASH_AMT+SL_KASAR_AMT From RATE_CUT_DATA AS H Where A.CO_CODE = H.CO_CODE AND A.CO_YEAR = H.CO_YEAR AND A.CO_BOOK = H.CO_BOOK  AND A.VCH_NO = H.VCH_NO ) As TotRcvAmt, (Select M.SL_BILL_OS From RATE_CUT_DATA AS M Where A.CO_CODE = M.CO_CODE AND A.CO_YEAR = M.CO_YEAR AND A.CO_BOOK = M.CO_BOOK  AND A.VCH_NO = M.VCH_NO ) As BillOs from (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) LEFT JOIN AC_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.AC_CODE = C.AC_CODE WHERE A.CO_CODE = '" +
              co_code +
              "' AND A.LC_CODE = '" +
              lc_code +
              "' AND A.CO_YEAR = '" +
              year +
              "' AND A.ITM_SIGN = '-' AND A.VCH_DATE >= '" +
              DateFormat("MM/dd/yyyy").format(fromDate) +
              "' AND A.VCH_DATE <= '" +
              DateFormat("MM/dd/yyyy").format(toDate) +
              "' AND B.MAIN_BOOK IN ('WH SALES','TOUR SALES') GROUP BY A.CO_CODE,A.CO_YEAR,A.VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_SNAME,C.AC_CODE,C.AC_NAME,C.AC_MOBILE ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO";
      log("Query $query");
      dynamic whSaleData = await sqlConnection.queryDatabase(query);
      print("result $whSaleData");
      whSalesReport = jsonDecode(whSaleData);
      searchWhSalesReport = jsonDecode(whSaleData);
    } else {
      dynamic result = await MySQLService().getWhSalesReport(
          co_code, lc_code, year,DateFormat("MM/dd/yyyy").format(fromDate),DateFormat("MM/dd/yyyy").format(toDate));
      print("Here value $result");
      whSalesReport = result[0];
      searchWhSalesReport = result[0];
    }
    loadingProvider.stopLoading();
    setState(() {});
  }

  fillterData({required DateTime fromD, required DateTime toD}) {
    DateTime from = fromD;
    DateTime to = toD;
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
                              fromDate = DateTime.now();
                              toDate = DateTime.now();
                              getWHSalesReportData();
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
                              fromDate = from;
                              toDate = to;
                              getWHSalesReportData();
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
                                          Text(DateFormat("MM/dd/yyyy")
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
                                          Text(DateFormat("MM/dd/yyyy")
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.blueColor, // <-- SEE HERE
              onPrimary: Colors.white, // <-- SEE HERE
              // onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
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
          "WH Sales Report",
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
              fillterData(fromD: fromDate, toD: toDate);
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
                  hintText: "Search Name or Mobile No",
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
                    searchWhSalesReport = whSalesReport
                        .where((text) => ((text.containsKey("AC_NAME") &&
                                text["AC_NAME"]
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.trim().toLowerCase())) ||
                            (text.containsKey("AC_MOBILE") &&
                                text["AC_MOBILE"]
                                    .toString()
                                    .contains(value.trim()))))
                        .toList();
                    setState(() {});
                  } else {
                    searchWhSalesReport.clear();
                    searchWhSalesReport.addAll(whSalesReport);
                    setState(() {});
                  }
                }),
          ),
          loadingProvider.isLoading ? SizedBox() :
          searchWhSalesReport.length == 0
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
                      itemCount: searchWhSalesReport.length,
                      itemBuilder: (context, index) => Padding(
                            padding: EdgeInsets.only(
                                top: 15.0,
                                left: 15,
                                right: 15,
                                bottom: index == searchWhSalesReport.length - 1
                                    ? 15
                                    : 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 15),
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
                                  Row(
                                    children: [
                                      Text(
                                        searchWhSalesReport[index]["AC_NAME"],
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      Spacer(),
                                      Text(
                                        "Vch No: ${searchWhSalesReport[index]["VCH_NO"]}",
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
                                                "Mobile",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Book",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Gr Wt",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Isu Fine",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Rec Fine",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Os Fine",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
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
                                                searchWhSalesReport[index]
                                                    ["AC_MOBILE"],
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                searchWhSalesReport[index]
                                                    ["BOOK_SNAME"],
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                double.parse(
                                                  searchWhSalesReport[index]
                                                          ["Gwt"]
                                                      .toString(),
                                                ).toStringAsFixed(3),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                searchWhSalesReport[index]
                                                        ["TotDrFine"]
                                                    .toString(),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    color: AppColor.red),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                searchWhSalesReport[index]
                                                        ["TotRecFine"]
                                                    .toString(),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    color: AppColor.green),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                searchWhSalesReport[index]
                                                        ["OsFine"]
                                                    .toString(),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    color: AppColor.red),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Expanded(
                                          child: Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Vch Date",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Pcs",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Net Wt",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Isu Amt",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Rec Amt",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                "Os Amt",
                                                style: GoogleFonts.nunito(
                                                    color: Color(0xFF006EB7),
                                                    fontWeight: FontWeight.bold,
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
                                            width: 5,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                searchWhSalesReport[index]
                                                    ["VCH_DATE"],
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                searchWhSalesReport[index]
                                                        ["Pcs"]
                                                    .toString(),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                double.parse(
                                                  searchWhSalesReport[index]
                                                          ["Nwt"]
                                                      .toString(),
                                                ).toStringAsFixed(3),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                double.parse(
                                                        searchWhSalesReport[
                                                                index]["NetAmt"]
                                                            .toString())
                                                    .toStringAsFixed(2),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    color: AppColor.red),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                double.parse(
                                                        searchWhSalesReport[
                                                                    index]
                                                                ["TotRcvAmt"]
                                                            .toString())
                                                    .toStringAsFixed(2),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    color: AppColor.green),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                double.parse(
                                                        searchWhSalesReport[
                                                                index]["BillOs"]
                                                            .toString())
                                                    .toStringAsFixed(2),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    color: AppColor.red),
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
                                  Divider(
                                    height: 2,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          final link = WhatsAppUnilink(
                                              phoneNumber:
                                                  '+91${searchWhSalesReport[index]["AC_MOBILE"]}',
                                              text:
                                                  "Thanks For Buying Ornaments");
                                          // Convert the WhatsAppUnilink instance to a Uri.
                                          // The "launch" method is part of "url_launcher".
                                          await launchUrlString('$link');
                                        },
                                        child: Image.asset(
                                          AppImage.whatsapp,
                                          scale: 18,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          launchUrlString(
                                              "tel://+91${searchWhSalesReport[index]["AC_MOBILE"]}");
                                        },
                                        child: Image.asset(
                                          AppImage.telephone,
                                          scale: 18,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          launchUrlString(
                                              'sms:+91${searchWhSalesReport[index]["AC_MOBILE"]}?body=Thanks For Buying Ornaments');
                                        },
                                        child: Image.asset(
                                          AppImage.chat,
                                          scale: 18,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Share.share(
                                              "Thanks For Buying Ornaments");
                                        },
                                        child: Image.asset(
                                          AppImage.share,
                                          scale: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )))
        ],
      ),
    );
  }
}
