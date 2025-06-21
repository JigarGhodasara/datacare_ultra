import 'dart:convert';
import 'dart:io';

import 'package:DataCareUltra/dailyRate_screen.dart';
import 'package:DataCareUltra/ledgerReport_screen.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/phoneBook_screen.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/qrCode_screen.dart';
import 'package:DataCareUltra/salesOrderReport_screen.dart';
import 'package:DataCareUltra/salesReport_screen.dart';
import 'package:DataCareUltra/stockReport_screen.dart';
import 'package:DataCareUltra/tagEstimate_screen.dart';
import 'package:DataCareUltra/tagImage_screen.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/whSalesReport_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final sqlConnection = SqlConnection.getInstance();

  String todayGoldRate = '';
  String todaySilverRate = '';
  List report = [
    {"name": "Ledger Report", "image": AppImage.notebook},
    {"name": "Stock Report", "image": AppImage.databaseGif},
    {"name": "Sales Report", "image": AppImage.statistics},
    {"name": "Tag Image", "image": AppImage.notebook},
    {"name": "PhoneBook", "image": AppImage.contactBook},
    {"name": "Estimate", "image": AppImage.costBook}
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getGoldSilverRate();
  }

  void getGoldSilverRate() async {
    String co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    String lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    if (Platform.isAndroid) {
      dynamic result = await sqlConnection.queryDatabase(
          "SELECT FINE_GL_RATE,FINE_SL_RATE,A.VCH_DATE FROM RATE_MAST AS A INNER JOIN GROUP_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.GR_CODE = B.GR_CODE WHERE A.CO_CODE = '" +
              co_code +
              "' AND A.LC_CODE = '" +
              lc_code +
              "' AND A.VCH_DATE <= '" +
              DateFormat("MM/dd/yyyy").format(DateTime.now()) +
              "' AND B.RATE_DISPLAY = 'Y' GROUP BY FINE_GL_RATE,FINE_SL_RATE,A.VCH_DATE ORDER BY A.VCH_DATE DESC ");
      print("result for rate $result");
      if(jsonDecode(result).length != 0){
        todayGoldRate = jsonDecode(result)[0]['FINE_GL_RATE'].toString();
        todaySilverRate = jsonDecode(result)[0]['FINE_SL_RATE'].toString();
      }
      dynamic resultOfweb = await sqlConnection.queryDatabase(
          "SELECT WEB_IMAGE,WEB_PATH FROM CO_SET_NEW WHERE CO_CODE ='" +
              co_code +
              "' ");
      print("resultofWeb $resultOfweb");
      print("resultofWeb ${jsonDecode(resultOfweb)[0]["WEB_IMAGE"]}");
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeWebImage(jsonDecode(resultOfweb)[0]["WEB_IMAGE"]);
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeWebPath(jsonDecode(resultOfweb)[0]["WEB_PATH"]);

      //calculate rate
      dynamic rateSetting = await sqlConnection.queryDatabase(
          "SELECT SL_AMT_TYPE FROM CO_SET WHERE CO_CODE ='" +
              co_code +
              "' ");
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeAmountType(jsonDecode(rateSetting)[0]["SL_AMT_TYPE"]);
      print("RateSetting result ${ Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).amountType}");
    } else {
      dynamic result = await MySQLService().getRates(
          co_code, lc_code, DateFormat("dd/MM/yyyy").format(DateTime.now()));
      print("Here value $result");
      if(result[0].length != 0){
        todayGoldRate = result[0][0]['FINE_GL_RATE'].toString();
        todaySilverRate = result[0][0]['FINE_SL_RATE'].toString();
      }
      dynamic image = await MySQLService().getForImage(co_code);
      print("IMagesss $image");
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeWebImage(image[0][0]["WEB_IMAGE"]);
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeWebPath(image[0][0]["WEB_PATH"]);
      dynamic rateSetting = await MySQLService().getRateSetting(co_code);
      Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
          .changeAmountType(rateSetting[0][0]["SL_AMT_TYPE"]);
    }

    setState(() {});
  }

  Widget rateContainer(
      {required String title, required String rate, required image}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>DailyrateScreen()));
        },
        child: Container(
          decoration: BoxDecoration(color: AppColor.blueColor,borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColor.goldenColor,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(18),bottomLeft: Radius.circular(18))
                ),
                child: Center(
                  child: Image.asset(
                    image,
                    height: 50,
                    width: 50,

                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    Text(rate,
                        style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Image.asset(AppImage.goldChart,color: Colors.white,height: 60,width: 60,),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget quickMenuItem({required String tittle,required String image,required GestureTapCallback ontap}){
    return GestureDetector(
      onTap: ontap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        height: 70,
        // width: 70,
        decoration: BoxDecoration(
          color: AppColor.blueColor,
          borderRadius: BorderRadius.circular(14)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(image,width: 20,height: 20,color: Colors.white,),
        SizedBox(height: 3,),
        Text(
          tittle,
          style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13),)
          ],
        ),
      ),
    );
  }

  Widget reportItem({required String icon, required String title, required GestureTapCallback ontap,required bool isLast}){
    return GestureDetector(
      onTap: ontap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColor.blueColor,
          borderRadius: BorderRadius.circular(18)
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(icon,color: Colors.white,height: 40,width: 40,),
             SizedBox(
               width: isLast ? 15 : 0,
             ),
             isLast ?
             Column(
               crossAxisAlignment: CrossAxisAlignment.center,
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text(title,
                     style: GoogleFonts.nunito(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 15)),
                 Text("Report",
                     style: GoogleFonts.nunito(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 15)),
               ],
             ) : Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text("Report",
                        style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
              .co_name,
          style: TextStyle(color: Color(0xFF006EB7)),
        ),
        centerTitle: true,
// elevation: 5,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "Today's Rate",
                style: GoogleFonts.nunito(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800]),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            rateContainer(title: 'Gold Rate${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).CoSname == "UAE"?"(AED)":""}', rate: todayGoldRate, image: AppImage.gold),
            SizedBox(
              height: 15,
            ),
            rateContainer(title: 'Silver Rate${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).CoSname == "UAE"?"(AED)":""}', rate: todaySilverRate, image: AppImage.silver),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "Quick Menu",
                style: GoogleFonts.nunito(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800]),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                // spacing: ,
                children: [
                  Expanded(child: quickMenuItem(tittle: "Scan", image: AppImage.qr, ontap: ()async{

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => QRViewExample(isFromTagScreen: false,)));

                  })),
                  SizedBox(
                    width: 5,
                  ),
                  Expanded(child: quickMenuItem(tittle: "Tag", image: AppImage.tag, ontap: (){                          Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TagimageScreen()));})),
                  SizedBox(
                    width: 5,
                  ),
                  Expanded(child: quickMenuItem(tittle: "Estimate", image: AppImage.calculation, ontap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TagestimateScreen()));
                  })),
                  SizedBox(
                    width: 5,
                  ),
                  Expanded(child: quickMenuItem(tittle: "PhoneBook", image: AppImage.phonebook, ontap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PhonebookScreen()));
                  })),
        
                ],
              ),
            ),
            // Container(
            //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            //   margin: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(12),
            //       color: Color(0xFF006EB7),
            //       boxShadow: [
            //         BoxShadow(
            //             color: Colors.blue[400]!,
            //             blurRadius: 12,
            //             spreadRadius: -5,
            //             offset: Offset(0, 5))
            //       ]),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: Row(
            //           children: [
            //             Image.asset(
            //               AppImage.gold,
            //               scale: 15,
            //             ),
            //             Expanded(
            //               child: Column(
            //                 children: [
            //                   Text(
            //                     "Today's Gold Rate",
            //                     style: GoogleFonts.nunito(
            //                         color: Colors.white,
            //                         fontWeight: FontWeight.bold,
            //                         fontSize: 12),
            //                   ),
            //                   Text(
            //                     todayGoldRate,
            //                     style: GoogleFonts.nunito(
            //                         color: Colors.white,
            //                         fontWeight: FontWeight.bold,
            //                         fontSize: 18),
            //                   ),
            //                 ],
            //               ),
            //             )
            //           ],
            //         ),
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.symmetric(horizontal: 5.0),
            //         child: Container(
            //           height: 60,
            //           width: 5,
            //           decoration: BoxDecoration(
            //               color: Colors.white,
            //               borderRadius: BorderRadius.circular(18)),
            //         ),
            //       ),
            //       Expanded(
            //         child: Row(
            //           children: [
            //             Image.asset(
            //               AppImage.gold,
            //               scale: 15,
            //             ),
            //             Expanded(
            //               child: Column(
            //                 children: [
            //                   Text(
            //                     "Today's Silver Rate",
            //                     style: GoogleFonts.nunito(
            //                         color: Colors.white,
            //                         fontWeight: FontWeight.bold,
            //                         fontSize: 12),
            //                   ),
            //                   Text(
            //                     todaySilverRate,
            //                     style: GoogleFonts.nunito(
            //                         color: Colors.white,
            //                         fontWeight: FontWeight.bold,
            //                         fontSize: 18),
            //                   ),
            //                 ],
            //               ),
            //             )
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "Reports",
                style: GoogleFonts.nunito(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800]),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(child: reportItem(icon: AppImage.ledger, title: "Ledger", ontap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const LedgerreportScreen()));
                  }, isLast: false)),
                  SizedBox(width: 10,),
                  Expanded(child: reportItem(icon: AppImage.stock, title: "Stock", ontap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const StockreportScreen()));
                  }, isLast: false)),
                ],
              ),
            ),SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(child: reportItem(icon: AppImage.sales, title: "Sales", ontap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SalesReportScreen()));
                  }, isLast: false)),
                  SizedBox(width: 10,),
                  Expanded(child: reportItem(icon: AppImage.tag, title: "Tag", ontap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TagimageScreen()));
                  }, isLast: false)),
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(child: reportItem(icon: AppImage.whSales, title: "WH Sales", ontap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WhsalesreportScreen()));
                  }, isLast: false)),
                  SizedBox(width: 10,),
                  Expanded(child: reportItem(icon: AppImage.salesOrder, title: "Sales Order", ontap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SalesOrderReportScreen()));
                  }, isLast: false)),
                ],
              ),
            ),
            // SizedBox(
            //   height: 10,
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
            //   child: Row(
            //     children: [
            //       Expanded(child: reportItem(icon: AppImage.sales, title: "Scheme", ontap: (){
            //         Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //                 builder: (context) => SalesReportScreen()));
            //       }, isLast: true)),
            //       // SizedBox(width: 15,),
            //       // Expanded(child: reportItem(icon: AppImage.tag, title: "Sales Order", ontap: (){
            //       //   Navigator.push(
            //       //       context,
            //       //       MaterialPageRoute(
            //       //           builder: (context) => TagimageScreen()));
            //       // })),
            //     ],
            //   ),
            // ),
            SizedBox(
              height: 50,
            ),
            // Expanded(
            //   child: Container(
            //       padding: EdgeInsets.symmetric(horizontal: 15.0),
            //       child: GridView.builder(
            //         itemCount: report.length,
            //         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //             crossAxisCount: 2,
            //             crossAxisSpacing: 8.0,
            //             mainAxisSpacing: 10.0,
            //             mainAxisExtent: 60),
            //         itemBuilder: (BuildContext context, int index) {
            //           return GestureDetector(
            //             onTap: () {
            //               if (index == 0) {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                         builder: (context) =>
            //                             const LedgerreportScreen()));
            //               } else if (index == 1) {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                         builder: (context) =>
            //                             const StockreportScreen()));
            //               } else if (index == 2) {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                         builder: (context) => SalesReportScreen()));
            //               } else if (index == 3) {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                         builder: (context) => TagimageScreen()));
            //               } else if (index == 4) {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                         builder: (context) => PhonebookScreen()));
            //               } else if (index == 5) {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                         builder: (context) => TagestimateScreen()));
            //               }
            //             },
            //             child: Container(
            //               padding: EdgeInsets.symmetric(horizontal: 10),
            //               decoration: BoxDecoration(
            //                   color: Color(0xFF006EB7),
            //                   borderRadius: BorderRadius.circular(12)),
            //               child: Row(
            //                 children: [
            //                   Image.asset(
            //                     report[index]['image'],
            //                     scale: 15,
            //                   ),
            //                   Text(
            //                     report[index]['name'],
            //                     style: GoogleFonts.nunito(
            //                         color: Colors.white,
            //                         fontWeight: FontWeight.bold,
            //                         fontSize: 16),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           );
            //         },
            //       )),
            // ),
          ],
        ),
      ),
    );
  }
}
