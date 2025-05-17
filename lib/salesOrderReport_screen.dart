import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/colors.dart';
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

import 'mySql_services.dart';

class SalesOrderReportScreen extends StatefulWidget {
  const SalesOrderReportScreen({Key? key}) : super(key: key);

  @override
  State<SalesOrderReportScreen> createState() => _SalesOrderReportScreenState();
}

class _SalesOrderReportScreenState extends State<SalesOrderReportScreen> {
  final sqlConnection = SqlConnection.getInstance();
  List<dynamic> salesOrderReport = [];
  List<dynamic> searchSalesOrderReport = [];
  List<dynamic> bookData = ["Select book"];
  String selectedBook = "Select book";
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
      getSalesOrderReportData();
    });
    getFillterBookData();
  }

  getSalesOrderReportData() async {
    loadingProvider.startLoading();
    setState(() {
    });
    print("object");
    if (Platform.isAndroid) {
      var query =
          "SELECT A.AC_NAME As AC_NAME,A.MOBILE As AC_MOBILE,A.VCH_DATE AS VCH_DATE,A.VCH_NO As VCH_NO,A.TOT_AMT As TotAmt,A.ADV_AMT As AdvAmt,A.ADV_AMT-A.TOT_AMT As PandingAmt,A.DEL_DATE As DeliveryDt FROM SL_ORD_DATA AS A  WHERE A.CO_CODE = '" +
              co_code +
              "' AND A.LC_CODE = '" +
              lc_code +
              "' AND A.VCH_DATE >= '" +
              DateFormat("MM/dd/yyyy").format(fromDate) +
              "' AND A.VCH_DATE <= '" +
              DateFormat("MM/dd/yyyy").format(toDate) +
              "'";
      if (selectedBook != "Select book") {
        query += "AND A.CO_BOOK = '" + selectedBook.split("-")[0] + "' ";
      }

      query += "ORDER BY A.VCH_DATE DESC,A.VCH_NO";
      log("Query $query");
      dynamic saleOrderData = await sqlConnection.queryDatabase(query);
      print("result $saleOrderData");
      salesOrderReport = jsonDecode(saleOrderData);
      searchSalesOrderReport = jsonDecode(saleOrderData);
    } else {
      dynamic result = await MySQLService().getSalesOrderReport(
          co_code, lc_code,selectedBook, DateFormat("MM/dd/yyyy").format(fromDate),DateFormat("MM/dd/yyyy").format(toDate));
      // print("Here value $result");
      salesOrderReport = result[0];
      searchSalesOrderReport = result[0];
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
                              getSalesOrderReportData();
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
                              getSalesOrderReportData();
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
          "Sales Order Report",
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
              fillterData(fromD: fromDate, toD: toDate, bookList: bookData, selectedBookValue: selectedBook);
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
                    searchSalesOrderReport = salesOrderReport
                        .where((text) =>
                            text.containsKey("AC_NAME") &&
                            text["AC_NAME"]
                                .toString()
                                .toLowerCase()
                                .contains(value.trim().toLowerCase()))
                        .toList();
                    setState(() {});
                  } else {
                    searchSalesOrderReport.clear();
                    searchSalesOrderReport.addAll(salesOrderReport);
                    setState(() {});
                  }
                }),
          ),
          loadingProvider.isLoading ? SizedBox() :
          searchSalesOrderReport.length == 0
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
                      itemCount: searchSalesOrderReport.length,
                      itemBuilder: (context, index) => Padding(
                            padding: EdgeInsets.only(
                                top: 15.0,
                                left: 15,
                                right: 15,
                                bottom:
                                    index == searchSalesOrderReport.length - 1
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
                                  Row(
                                    children: [
                                      Text(
                                        searchSalesOrderReport[index]
                                            ["AC_NAME"],
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                      Spacer(),
                                      Text(
                                        "Order No. : ${searchSalesOrderReport[index]["VCH_NO"]}",
                                        style: GoogleFonts.nunito(
                                            // color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16),
                                      ),
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
                                            "Order Date",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Order Amount",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Advance Amount",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Pending Amount",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Delivery Date",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          // SizedBox(
                                          //   height: 3.5,
                                          // ),
                                          // Text(
                                          //   "Order Status",
                                          //   style: GoogleFonts.nunito(
                                          //       color: Color(0xFF006EB7),
                                          //       fontWeight: FontWeight.w500,
                                          //       fontSize: 15),
                                          // ),
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
                                          // SizedBox(
                                          //   height: 3.5,
                                          // ),
                                          // Text(
                                          //   ":",
                                          //   style: GoogleFonts.nunito(
                                          //       fontWeight: FontWeight.w500,
                                          //       fontSize: 15),
                                          // ),
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
                                            searchSalesOrderReport[index]
                                                ["AC_MOBILE"],
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            searchSalesOrderReport[index]
                                                ["VCH_DATE"],
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            double.parse(searchSalesOrderReport[
                                                        index]["TotAmt"]
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
                                            double.parse(searchSalesOrderReport[
                                                        index]["AdvAmt"]
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
                                            double.parse(searchSalesOrderReport[
                                                        index]["PandingAmt"]
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
                                            searchSalesOrderReport[index]
                                                    ["DeliveryDt"] ??
                                                "-",
                                            style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          // SizedBox(
                                          //   height: 3.5,
                                          // ),
                                          // Text(
                                          //   "searchSalesOrderReport[index]",
                                          //   style: GoogleFonts.nunito(
                                          //       fontWeight: FontWeight.w500,
                                          //       fontSize: 15),
                                          // ),
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
                                                  '+91${searchSalesOrderReport[index]["AC_MOBILE"]}',
                                              text:
                                                  "Your Order is Redy Please Collect Your Order \n Order No : ${searchSalesOrderReport[index]["VCH_NO"]} \n Order Date : ${searchSalesOrderReport[index]["VCH_DATE"]} \n Order Amount : ${double.parse(searchSalesOrderReport[index]["TotAmt"].toString()).toStringAsFixed(2)} \n Advance Amount : ${double.parse(searchSalesOrderReport[index]["AdvAmt"].toString()).toStringAsFixed(2)} \n DATACARE SOFTECH");
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
                                              "tel://+91${searchSalesOrderReport[index]["AC_MOBILE"]}");
                                        },
                                        child: Image.asset(
                                          AppImage.telephone,
                                          scale: 18,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          launchUrlString(
                                              'sms:+91${searchSalesOrderReport[index]["AC_MOBILE"]}?body=Your Order is Redy Please Collect Your Order \n Order No : ${searchSalesOrderReport[index]["VCH_NO"]} \n Order Date : ${searchSalesOrderReport[index]["VCH_DATE"]} \n Order Amount : ${double.parse(searchSalesOrderReport[index]["TotAmt"].toString()).toStringAsFixed(2)} \n Advance Amount : ${double.parse(searchSalesOrderReport[index]["AdvAmt"].toString()).toStringAsFixed(2)} \n DATACARE SOFTECH');
                                        },
                                        child: Image.asset(
                                          AppImage.chat,
                                          scale: 18,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Share.share(
                                              "Your Order is Redy Please Collect Your Order \n Order No : ${searchSalesOrderReport[index]["VCH_NO"]} \n Order Date : ${searchSalesOrderReport[index]["VCH_DATE"]} \n Order Amount : ${double.parse(searchSalesOrderReport[index]["TotAmt"].toString()).toStringAsFixed(2)} \n Advance Amount : ${double.parse(searchSalesOrderReport[index]["AdvAmt"].toString()).toStringAsFixed(2)} \n DATACARE SOFTECH");
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
