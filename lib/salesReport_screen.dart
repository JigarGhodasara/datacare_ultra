import 'dart:convert';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  State<SalesReportScreen> createState() => _SalesreportScreenState();
}

class _SalesreportScreenState extends State<SalesReportScreen> {
  final sqlConnection = SqlConnection.getInstance();
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  late LoadingProvider loadingProvider;
  List<dynamic> salesReport = [];
  List<dynamic> searchSalesReport = [];
  List<dynamic> bookData = ["Select book"];
  String selectedBook = "Select book";
  String co_code = "";
  String lc_code = "";
  String year = "";

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
      getSalesReport();
    });
    getFillterBookData();
  }

  getSalesReport() async {
    loadingProvider.startLoading();
    setState(() {
    });
    if (Platform.isAndroid) {
      var query =
          "SELECT A.CO_CODE,A.LC_CODE,A.CO_YEAR,(convert(varchar(50),A.VCH_DATE,105)) as VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_NAME,C.AC_NAME,C.AC_MOBILE, A.MAIN_USER, SUM(ITM_PCS) As Pcs,Sum(A.ITM_GWT) As Gwt,SUM(A.ITM_NWT) As Nwt,SUM(A.ITM_FINE) As Fine, (Select D.TOT_AMT From SL_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.LC_CODE = D.LC_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As NetAmt, (Select E.BILL_OS From SL_DATA AS E Where A.CO_CODE = E.CO_CODE AND A.LC_CODE = E.LC_CODE AND A.CO_YEAR = E.CO_YEAR AND A.CO_BOOK = E.CO_BOOK  AND A.VCH_NO = E.VCH_NO ) As OsAmt from (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) LEFT JOIN AC_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.AC_CODE = C.AC_CODE WHERE A.CO_CODE = '" +
              co_code +
              "' AND A.LC_CODE = '" +
              lc_code +
              "' AND A.CO_YEAR = '" +
              year +
              "' AND A.ITM_SIGN = '-' AND A.VCH_DATE >= '" +
              DateFormat("MM/dd/yyyy").format(fromDate) +
              "' AND A.VCH_DATE <= '" +
              DateFormat("MM/dd/yyyy").format(toDate) +
              "' AND B.MAIN_BOOK IN ('SALES','SALES RETURN') ";

      // is for fillter

      if (selectedBook != "Select book") {
        query += "AND A.CO_BOOK = '" + selectedBook.split("-")[0] + "' ";
      }

      query +=
          "GROUP BY A.CO_CODE,A.LC_CODE,A.CO_YEAR,A.VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_NAME,C.AC_NAME,C.AC_MOBILE,A.MAIN_USER ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO";
      print("query ${query}");
      dynamic result = await sqlConnection.queryDatabase(query);
      print("data ${result}");
      salesReport = jsonDecode(result);
      searchSalesReport = jsonDecode(result);

      print("searchSalesReport $searchSalesReport");
    } else {
      dynamic salesData = await MySQLService().getSalesReport(
          co_code,
          lc_code,
          year,
          DateFormat("MM/dd/yyyy").format(fromDate),
          DateFormat("MM/dd/yyyy").format(toDate),
          selectedBook);
      salesReport = salesData[0];
      searchSalesReport = salesData[0];
    }

    loadingProvider.stopLoading();
    setState(() {});
  }

  getFillterBookData() async {
    if (Platform.isAndroid) {
      var query = "SELECT CO_BOOK,BOOK_NAME FROM BOOK_DATA WHERE CO_CODE = '" +
          co_code +
          "' AND LC_CODE='" +
          lc_code +
          "' AND MAIN_BOOK in ('SALES','WHSALES') AND CUR_USE='Y'";

      dynamic bookResult = await sqlConnection.queryDatabase(query);
      print("Book Data ${bookResult}");
      List<dynamic> data = jsonDecode(bookResult);
      data.forEach((action) {
        bookData.add("${action["CO_BOOK"]}-${action["BOOK_NAME"]}");
      });
    } else {
      dynamic salesFilterData = await MySQLService().getSalesFilterData(
        co_code,
        lc_code,
      );
      salesFilterData[0].forEach((action) {
        bookData.add("${action["CO_BOOK"]}-${action["BOOK_NAME"]}");
      });
      print("Saleeee $salesFilterData");
    }
  }

  fillterData(
      {required List<dynamic> bookList,
      required String selectedBookValue,
      required DateTime fromD,
      required DateTime toD}) {
    String selectedbook = selectedBookValue;
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
                              selectedBook = "Select book";
                              getSalesReport();
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
                              selectedBook = selectedbook;
                              getSalesReport();
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
                                          Text(DateFormat("dd/MM/yyyy")
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
                                          Text(DateFormat("dd/MM/yyyy")
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
                            "Book",
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
                                    value: selectedbook,
                                    items: bookList.map((dynamic items) {
                                      return DropdownMenuItem(
                                        value: items,
                                        child: Text(items),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      print(value);
                                      selectedbook = value.toString();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.blueColor, // <-- SEE HERE
              onPrimary: Colors.white, // <-- SEE HERE
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
          "Sales Report",
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
                  bookList: bookData,
                  selectedBookValue: selectedBook,
                  fromD: fromDate,
                  toD: toDate);
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
                  hintText: "Search with account name",
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
                    searchSalesReport = salesReport
                        .where((text) =>
                            text.containsKey("AC_NAME") &&
                            text["AC_NAME"]
                                .toString()
                                .toLowerCase()
                                .contains(value.trim().toLowerCase()))
                        .toList();
                    setState(() {});
                  } else {
                    searchSalesReport.clear();
                    searchSalesReport.addAll(salesReport);
                    setState(() {});
                  }
                }),
          ),
          loadingProvider.isLoading ? SizedBox() :
          searchSalesReport.length == 0
              ? Expanded(
                  child: Center(
                    child: Text(
                      "No record found",
                      style: GoogleFonts.nunito(
                          color: Color(0xFF006EB7),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                      itemCount: searchSalesReport.length,
                      itemBuilder: (context, index) => Padding(
                            padding: EdgeInsets.only(
                                top: 15.0,
                                left: 15,
                                right: 15,
                                bottom: index == searchSalesReport.length - 1
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
                                    searchSalesReport[index]["AC_NAME"],
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
                                            "Invoice Date",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Book Name",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Sales Weight",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Sales Amount",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Os Amount",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Entry User",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 40,
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
                                          Text(
                                            ":",
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 40,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            searchSalesReport[index]
                                                ["AC_MOBILE"],
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            searchSalesReport[index]
                                                ["VCH_DATE"],
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            searchSalesReport[index]
                                                ["BOOK_NAME"],
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            searchSalesReport[index]["Nwt"] == 0
                                                ? ""
                                                : double.parse(
                                                        searchSalesReport[index]
                                                                ["Nwt"]
                                                            .toString())
                                                    .toStringAsFixed(3),
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            searchSalesReport[index]
                                                        ["NetAmt"] ==
                                                    null
                                                ? ""
                                                : searchSalesReport[index]
                                                            ["NetAmt"] ==
                                                        0
                                                    ? ""
                                                    : double.parse(
                                                            searchSalesReport[
                                                                        index]
                                                                    ["NetAmt"]
                                                                .toString())
                                                        .toStringAsFixed(2),
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            searchSalesReport[index]["OsAmt"] ==
                                                    null
                                                ? ""
                                                : searchSalesReport[index]
                                                            ["OsAmt"] ==
                                                        0
                                                    ? ""
                                                    : double.parse(
                                                            searchSalesReport[
                                                                        index]
                                                                    ["OsAmt"]
                                                                .toString())
                                                        .toStringAsFixed(2),
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            searchSalesReport[index]
                                                ["MAIN_USER"],
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
                                          final link = WhatsAppUnilink(
                                              phoneNumber:
                                                  '+91${searchSalesReport[index]["AC_MOBILE"]}',
                                              text:
                                                  "*Thanks For Buying Ornaments* \n Invoice No : ${searchSalesReport[index]["VCH_NO"]} \n Invoice Date : ${searchSalesReport[index]["VCH_DATE"]} \n Sales Amount : ${searchSalesReport[index]["NetAmt"] == 0 ? "" : double.parse(searchSalesReport[index]["NetAmt"].toString()).toStringAsFixed(2)} \n Os Amount :  ${searchSalesReport[index]["OsAmt"] == 0 ? "" : double.parse(searchSalesReport[index]["OsAmt"].toString()).toStringAsFixed(2)} \n ${searchSalesReport[index]["AC_NAME"]}");
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
                                              "tel://+91${searchSalesReport[index]["AC_MOBILE"]}");
                                        },
                                        child: Image.asset(
                                          AppImage.telephone,
                                          scale: 18,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          launchUrlString(
                                              'sms:+91${searchSalesReport[index]["AC_MOBILE"]}?body=*Thanks For Buying Ornaments* \n Invoice No : ${searchSalesReport[index]["VCH_NO"]} \n Invoice Date : ${searchSalesReport[index]["VCH_DATE"]} \n Sales Amount : ${searchSalesReport[index]["NetAmt"] == 0 ? "" : double.parse(searchSalesReport[index]["NetAmt"].toString()).toStringAsFixed(2)} \n Os Amount :  ${searchSalesReport[index]["OsAmt"] == 0 ? "" : double.parse(searchSalesReport[index]["OsAmt"].toString()).toStringAsFixed(2)} \n ${searchSalesReport[index]["AC_NAME"]}');
                                        },
                                        child: Image.asset(
                                          AppImage.chat,
                                          scale: 18,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Share.share(
                                              "*Thanks For Buying Ornaments* \n Invoice No : ${searchSalesReport[index]["VCH_NO"]} \n Invoice Date : ${searchSalesReport[index]["VCH_DATE"]} \n Sales Amount : ${searchSalesReport[index]["NetAmt"] == 0 ? "" : double.parse(searchSalesReport[index]["NetAmt"].toString()).toStringAsFixed(2)} \n Os Amount :  ${searchSalesReport[index]["OsAmt"] == 0 ? "" : double.parse(searchSalesReport[index]["OsAmt"].toString()).toStringAsFixed(2)} \n ${searchSalesReport[index]["AC_NAME"]}");
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
