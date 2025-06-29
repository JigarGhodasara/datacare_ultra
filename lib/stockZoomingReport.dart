import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

import 'mySql_services.dart';

class StockzoomingReport extends StatefulWidget {
  String ItCOode;
  String fromDate;
  String toDate;
  StockzoomingReport({super.key, required this.ItCOode,required this.fromDate,required this.toDate});

  @override
  State<StockzoomingReport> createState() => _StockzoomingreportState();
}

class _StockzoomingreportState extends State<StockzoomingReport> {
  final sqlConnection = SqlConnection.getInstance();
  late LoadingProvider loadingProvider;
  String co_code = "";
  String year = "";
  String lc_code = "";
  int _selectedValue = 0;
  List<dynamic> stockReportZooming = [];

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
      getStockZoomingReport();
    });
  }

  void getStockZoomingReport() async {
    loadingProvider.startLoading();

    if (Platform.isAndroid) {
      String query =
          "SELECT A.IT_CODE,B.IT_NAME,A.CO_BOOK,A.VCH_NO,A.VCH_DATE,A.BOOK_NAME,A.TAG_NO,A.ITM_PCS,A.ITM_GWT,A.ITM_NWT,A.ITM_SIGN \nFROM MAIN_STOCK AS A LEFT JOIN ITEM_MAST AS B ON A.CO_CODE =B.CO_CODE AND A.IT_CODE =B.IT_CODE \nWHERE A.CO_CODE='$co_code' AND A.LC_CODE='$lc_code' AND A.IT_CODE ='${widget.ItCOode}' AND A.VCH_DATE BETWEEN '${widget.fromDate}' AND '${widget.toDate}'";

      if (_selectedValue == 1) {
        query += "AND A.ITM_SIGN = '+' ";
      }
      if (_selectedValue == 2) {
        query += "AND A.ITM_SIGN = '-' ";
      }

      log("STOCK/ZOOMING QUERY ${query}");
      dynamic result = await sqlConnection.queryDatabase(query);
      log("STOCK/ZOOMING result ${result}");
      stockReportZooming = jsonDecode(result);
      setState(() {});
    }else {
      dynamic result = await MySQLService().getZoomingStockReport(
          coCode: co_code,
          lcCode: lc_code,
          itCode: year,
          fromDate: widget.fromDate,
          toDate: widget.toDate,
        selectedValue: _selectedValue.toString()
      );
      stockReportZooming = result[0];
      setState(() {
      });
    }
    loadingProvider.stopLoading();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ITEM IN OUT",
          style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF006EB7)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.keyboard_arrow_left_rounded,
            color: Color(0xFF006EB7),
            size: 45,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 15,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  Radio<int>(
                    value: 0,
                    groupValue: _selectedValue,
                    activeColor: const Color(0xFF006EB7),
                    onChanged: (value) {
                      setState(() {
                        _selectedValue = value!;
                      });
                      getStockZoomingReport();
                    },
                  ),
                  Text(
                    "ALL",
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006EB7)),
                  ),
                ],
              ),
              SizedBox(width: 16),
              Row(
                children: [
                  Radio<int>(
                    value: 1,
                    groupValue: _selectedValue,
                    activeColor: const Color(0xFF006EB7),
                    onChanged: (value) {
                      setState(() {
                        _selectedValue = value!;
                      });
                      getStockZoomingReport();
                    },
                  ),
                  Text(
                    "In Stock",
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF006EB7)),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Radio<int>(
                    value: 2,
                    groupValue: _selectedValue,
                    activeColor: const Color(0xFF006EB7),
                    onChanged: (value) {
                      setState(() {
                        _selectedValue = value!;
                      });
                      getStockZoomingReport();
                    },
                  ),
                  Text(
                    "Out Stock",
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF006EB7)),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
              child: stockReportZooming.isEmpty
                  ? Center(
                      child: Text(
                        "No Data Found",
                        style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF006EB7)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: stockReportZooming.length,
                      itemBuilder: (context, index) => Padding(
                            padding: EdgeInsets.only(
                                top: 15.0,
                                left: 15,
                                right: 15,
                                bottom: index == stockReportZooming.length - 1
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
                                        "Name : ",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      Text(
                                        stockReportZooming[index]['IT_NAME'],
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                      ),
                                      Spacer(),
                                      stockReportZooming[index]["ITM_SIGN"] ==
                                              "-"
                                          ? const Icon(
                                              Icons.arrow_downward_rounded,
                                              color: Colors.red,
                                            )
                                          : const Icon(
                                              Icons.arrow_upward_rounded,
                                              color: Colors.green,
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
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Vch No",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
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
                                            "Book Name",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Tag No",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Item Pcs",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Gross Weight",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Net Weight",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: 3.5,
                                          ),
                                          Text(
                                            "Sign",
                                            style: GoogleFonts.nunito(
                                                color: Color(0xFF006EB7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 40,
                                      ),
                                      Row(
                                        children: [
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
                                            width: 30,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                stockReportZooming[index]
                                                    ["VCH_NO"],
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                stockReportZooming[index]
                                                    ["VCH_DATE"],
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                stockReportZooming[index]
                                                    ["BOOK_NAME"],
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                stockReportZooming[index]
                                                    ["TAG_NO"],
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                stockReportZooming[index]
                                                        ["ITM_PCS"]
                                                    .toString(),
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 3.5,
                                              ),
                                              Text(
                                                double.parse(stockReportZooming[
                                                            index]["ITM_GWT"]
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
                                                double.parse(stockReportZooming[
                                                            index]["ITM_NWT"]
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
                                                stockReportZooming[index]
                                                    ["ITM_SIGN"],
                                                style: GoogleFonts.nunito(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 20,
                                                    color: stockReportZooming[
                                                                    index]
                                                                ["ITM_SIGN"] ==
                                                            "-"
                                                        ? Colors.red
                                                        : Colors.green),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 8,
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
