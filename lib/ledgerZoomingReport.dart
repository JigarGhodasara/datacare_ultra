import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';
// 103.49.124.187
// SONIMETHEW@8612
class Ledgerzoomingreport extends StatefulWidget {
  String name;
  String acCode;
  Ledgerzoomingreport({super.key,required this.name,required this.acCode});

  @override
  State<Ledgerzoomingreport> createState() => _LedgerzoomingreportState();
}

class _LedgerzoomingreportState extends State<Ledgerzoomingreport> {
  final sqlConnection = SqlConnection.getInstance();
  late LoadingProvider loadingProvider;
  List<dynamic> ledgerZoomingReport = [];
  String co_code = "";
  String lc_code = "";

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
      getLedegerZoomingReport();
    });
  }

  getLedegerZoomingReport()async{
    loadingProvider.startLoading();
    if(Platform.isAndroid){
      String query = "SELECT B.BOOK_NAME,A.CO_BOOK,A.VCH_NO,A.VCH_DATE,B.MAIN_BOOK,Case When SUM(A.CR_AMT-A.DR_AMT)<0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End As DrAmt,Case When SUM(A.CR_AMT-A.DR_AMT)>0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End As CrAmt,SUM(Case When SUM(A.CR_AMT-A.DR_AMT)>0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End-Case When SUM(A.CR_AMT-A.DR_AMT)<0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End)OVER(ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO)AS BalAmt,Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As DrGold,Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As CrGold,SUM(Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end-Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end)OVER(ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO)as BalGold,Case WHEN SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As DrSilver,Case WHEN SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As CrSilver,SUM(Case When SUM(Case When A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end-Case When SUM(Case When A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end)OVER(ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO)as BalSilver FROM(AC_DATA AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE=B.CO_CODE AND A.LC_CODE=B.LC_CODE AND A.CO_BOOK=B.CO_BOOK)LEFT JOIN AC_MAST AS C ON A.CO_CODE=C.CO_CODE And A.AC_CODE=C.AC_CODE WHERE A.CO_CODE='$co_code' AND A.LC_CODE='$lc_code' AND A.AC_CODE='${widget.acCode}' GROUP BY B.BOOK_NAME,A.CO_BOOK,A.VCH_NO,A.VCH_DATE,B.MAIN_BOOK ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO";

      log(query);
      dynamic result = await sqlConnection.queryDatabase(query);
      log("Result ${result}");
      ledgerZoomingReport.addAll(jsonDecode(result));
    }else{
      dynamic grp = await MySQLService().getZoomingLedgerReport(co_code,lc_code,widget.acCode);
      ledgerZoomingReport.addAll(grp[0]);
    }
    loadingProvider.stopLoading();
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.name}",
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
      body: ListView.builder(
          itemCount: ledgerZoomingReport.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
                top: 15.0,
                left: 15,
                right: 15,
                bottom: index == ledgerZoomingReport.length - 1
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
                        "Book : ",
                        style: GoogleFonts.nunito(
                            color: Color(0xFF006EB7),
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      Text(
                        '${ledgerZoomingReport[index]['BOOK_NAME']}',
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
                                    "VchNo",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                    "Cr Amt",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                    "Cr Gold",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                    "Cr Silver",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
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
                                   '${ledgerZoomingReport[index]['VCH_NO']}',
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                   '${ledgerZoomingReport[index]['CrAmt']}',
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                   '${ledgerZoomingReport[index]['CrGold']}',
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                   '${ledgerZoomingReport[index]['CrSilver']}',
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w500,
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
                                    "Date",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                    "Dr Amt",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                    "Dr Gold",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                    "Dr Silver",
                                    style: GoogleFonts.nunito(
                                        color: Color(0xFF006EB7),
                                        fontWeight: FontWeight.bold,
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
                                   '${ledgerZoomingReport[index]['VCH_DATE']}',
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                   '${ledgerZoomingReport[index]['DrAmt']}',
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                   '${ledgerZoomingReport[index]['DrGold']}',
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 3.5,
                                  ),
                                  Text(
                                   '${ledgerZoomingReport[index]['DrSilver']}',
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w500,
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
          )),
    );
  }
}
