import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class DailyrateScreen extends StatefulWidget {
  const DailyrateScreen({Key? key}) : super(key: key);

  @override
  State<DailyrateScreen> createState() => _DailyrateScreenState();
}

class _DailyrateScreenState extends State<DailyrateScreen> {
  final sqlConnection = SqlConnection.getInstance();
  String co_code = "";
  String lc_code = "";
  String year = "";
  List<dynamic> dailyRate = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    year =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_year;
    getWHSalesReportData();
  }

  getWHSalesReportData() async {
    print("object");
    if (Platform.isAndroid) {
      var query =
          "SELECT A.GR_CODE,B.GR_NAME,A.GR_TOUCH,A.GR_RATE,A.GR_TAX_RATE,A.GR_TAX_PRC FROM RATE_MAST AS A " +
              "LEFT JOIN GROUP_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.GR_CODE = B.GR_CODE " +
              "WHERE A.CO_CODE='"+ co_code +"' AND A.LC_CODE='"+ lc_code +"' AND VCH_DATE = '"+ DateFormat("dd/MM/yyyy").format(DateTime.now()) +"'\n";
      log("Query $query");
      dynamic dRate = await sqlConnection.queryDatabase(query);
      print("result $dRate");
      dailyRate = jsonDecode(dRate);
      // searchWhSalesReport = jsonDecode(whSaleData);
    } else {
      dynamic result = await MySQLService().getDailyRates(
          co_code, lc_code,DateFormat("dd/MM/yyyy").format(DateTime.now()));
      // print("Here value $result");
      dailyRate = result[0];
      // searchWhSalesReport = result[0];
    }
    setState(() {});
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DAILY RATE",
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
      ),
      body: Column(
        children: [
          SizedBox(
            height: 15,
          ),
          dailyRate.length == 0 ? Expanded(child: Center(child: Text("No record Found"),)) : Expanded(
              child: ListView.builder(
                  itemCount: dailyRate.length,
                  itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                            top: 15.0,
                            left: 15,
                            right: 15,
                            bottom: dailyRate.length - 1 == index ? 15 : 0),
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
                                    dailyRate[index]["GR_NAME"] ?? "-:-",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  Spacer(),
                                  Text(
                                    double.parse(dailyRate[index]["GR_RATE"].toString()).toStringAsFixed(2) ?? "-:-",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
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
                                        "Group Code",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Touch %",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Rate 10gm",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Tax %",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Tax Rate",
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
                                        dailyRate[index]["GR_CODE"] ?? "-:-",
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        double.parse(dailyRate[index]["GR_TOUCH"].toString()).toStringAsFixed(2) ?? "-:-",                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        double.parse(dailyRate[index]["GR_TAX_RATE"].toString()).toStringAsFixed(2) ?? "-:-",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                          dailyRate[index]["GR_TAX_PRC"] == 0 ? "-:-" :dailyRate[index]["GR_TAX_PRC"].toString() ?? "-:-",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                          double.parse(dailyRate[index]["GR_TAX_RATE"].toString()).toStringAsFixed(2) ?? "-:-",
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
                            ],
                          ),
                        ),
                      )))
        ],
      ),
    );
  }
}
