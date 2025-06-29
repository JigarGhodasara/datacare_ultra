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

class SalesZoomingReport extends StatefulWidget {
  String vchNo;
  String coBook;
  String bookName;
   SalesZoomingReport({super.key,required this.vchNo,required this.coBook,required this.bookName});

  @override
  State<SalesZoomingReport> createState() => _SalesZoomingReportState();
}

class _SalesZoomingReportState extends State<SalesZoomingReport> {
  final sqlConnection = SqlConnection.getInstance();
  late LoadingProvider loadingProvider;
  String co_code = "";
  String year = "";
  String lc_code = "";
  dynamic invoiceDetail;
  dynamic productDetail;

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
      getInvoiceDetail();

    });
  }


  void getInvoiceDetail()async{
    if(Platform.isAndroid){
      // GET INVOICE DETAIL
      String query = "SELECT VCH_NO,VCH_DATE,MOBILE,NET_AMT,DISC_AMT,TOT_AMT,OLD_GL_AMT,CASH_AMT,KASAR_AMT,OS_ADJ_AMT,AC_NAME FROM SL_DATA WHERE CO_CODE='$co_code' AND LC_CODE='$lc_code' AND VCH_NO='${widget.vchNo}' AND CO_BOOK='${widget.coBook}'";
      log("QUERY $query");
      dynamic result = await sqlConnection.queryDatabase(query);
      invoiceDetail = jsonDecode(result)[0];
      setState(() {
      });
      print(jsonDecode(result));

      //GET INVOICE PRODUCT DETAILS
      String productQuery = "SELECT IT_CODE,ITM_REMARK,TAG_NO,ITM_PCS,ITM_GWT,ITM_OTH_WT,ITM_NWT,ITM_RATE,ITM_AMT,LBR_PRC,LBR_RATE,LBR_AMT,OTH_AMT,ITM_MRP,TOT_AMT FROM SL_DETL WHERE CO_CODE = '$co_code' AND LC_CODE = '$lc_code' AND CO_BOOK = '${widget.coBook}' AND VCH_NO = '${widget.vchNo}' ORDER BY SR_NO ";
      log("QUERY $productQuery");
      dynamic productResult = await sqlConnection.queryDatabase(productQuery);
      productDetail = jsonDecode(productResult);
      setState(() {
      });
      print("pr result ${jsonDecode(productResult)}");

    }else {
      dynamic result = await MySQLService().getZoomingSalesInvoiceDetails(
          coCode: co_code,
          lcCode: lc_code,
         vchNo: widget.vchNo,
        coBook: widget.coBook
      );
      invoiceDetail = result[0][0];


      dynamic productResult = await MySQLService().getZoomingSalesProductDetails(
          coCode: co_code,
          lcCode: lc_code,
          vchNo: widget.vchNo,
          coBook: widget.coBook
      );
      productDetail = productResult[0];
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontWeight: FontWeight.w500);
    const valueStyle = TextStyle(color: Colors.black87);
    const greenText =
        TextStyle(color: Colors.green, fontWeight: FontWeight.bold);
    const redText = TextStyle(color: Colors.red, fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        title: Text("SALES DETAIL REPORT",
            style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF006EB7))),
        centerTitle: true,
        elevation: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Customer Info Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoiceDetail != null ?invoiceDetail['AC_NAME']:'',
                        style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF006EB7))),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: Text("Mobile No.   : ${invoiceDetail != null ? invoiceDetail['MOBILE']:""}",
                                style: valueStyle)),
                        Expanded(
                            child:
                                Text("Bookname : ${widget.bookName}", style: valueStyle)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                            child:
                                Text("Invoice No. : ${invoiceDetail != null ? invoiceDetail['VCH_NO']:""}", style: valueStyle)),
                        Expanded(
                            child: Text("Invoice Date : ${invoiceDetail != null ? invoiceDetail['VCH_DATE']:""}",
                                style: valueStyle)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Item Detail Card
            ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: productDetail != null ? productDetail.length:0,
                itemBuilder: (context,index){
              return Padding(
                padding:  EdgeInsets.only(top: index!=0?8.0:0),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(productDetail != null ? productDetail[index]['ITM_REMARK']:'',
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF006EB7)))),
                            Text(productDetail != null ? productDetail[index]['TAG_NO']:'',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Divider(color: Colors.grey,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Pcs",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("Less Wt",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("Itm Rate",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("Lbr Prc",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("Lbr Amt",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("MRP",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(productDetail != null ? productDetail[index]['ITM_PCS'].toString():'',
                                        style: GoogleFonts.nunito(
                                        )),
                                    Text('',
                                        style: GoogleFonts.nunito(
                                        )),
                                    Text(productDetail != null ? productDetail[index]['ITM_RATE'].toStringAsFixed(2):'',
                                        style: GoogleFonts.nunito(
                                        )),
                                    Text(productDetail != null ? productDetail[index]['LBR_PRC'].toStringAsFixed(2):'',
                                        style: GoogleFonts.nunito(
                                        )),
                                    Text(productDetail != null ? productDetail[index]['LBR_AMT'].toStringAsFixed(2):'',
                                        style: GoogleFonts.nunito(
                                        )),
                                    Text(productDetail != null ? productDetail[index]['ITM_MRP'].toStringAsFixed(2):'',
                                        style: GoogleFonts.nunito(
                                        )),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Gross Wt",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("Net Wt",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("Itm Amt",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("Lbr Rate",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("Oth Amt",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text("Total Amt",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(":",
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(productDetail != null ? productDetail[index]['ITM_GWT'].toStringAsFixed(3):'',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(productDetail != null ? productDetail[index]['ITM_NWT'].toStringAsFixed(3):'',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(productDetail != null ? productDetail[index]['ITM_AMT'].toStringAsFixed(2):'',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(productDetail != null ? productDetail[index]['LBR_RATE'].toStringAsFixed(2):'',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(productDetail != null ? productDetail[index]['OTH_AMT'].toStringAsFixed(2):'',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                    Text(productDetail != null ? productDetail[index]['TOT_AMT'].toStringAsFixed(2):'',
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Summary Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildSummaryRow("Net Amount", invoiceDetail != null ?invoiceDetail['NET_AMT'].toStringAsFixed(2) :'0.00', greenText),
                    _buildSummaryRow("Discount Amount", invoiceDetail != null ?invoiceDetail['DISC_AMT'].toStringAsFixed(2) :'0.00', redText),
                    _buildSummaryRow("Total Amount", invoiceDetail != null ?invoiceDetail['TOT_AMT'].toStringAsFixed(2) :'0.00', valueStyle),
                    const Divider(color: Colors.grey,),
                    const SizedBox(height: 8),
                    _buildSummaryRow("Old Gold Amount", invoiceDetail != null ?invoiceDetail['OLD_GL_AMT'].toStringAsFixed(2) :'0.00', valueStyle),
                    _buildSummaryRow("Cash Amount", invoiceDetail != null ?invoiceDetail['CASH_AMT'].toStringAsFixed(2) :'0.00', valueStyle),
                    _buildSummaryRow("Kasar Amount", invoiceDetail != null ?invoiceDetail['KASAR_AMT'].toStringAsFixed(2) :'0.00', valueStyle),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Outstanding Amount",
                            style:
                                GoogleFonts.nunito(fontWeight: FontWeight.w900,color: Color(0xFF006EB7))),
                        Text(invoiceDetail != null ?invoiceDetail['OS_ADJ_AMT'].toStringAsFixed(2) :'0.00',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: style),
        ],
      ),
    );
  }

}
