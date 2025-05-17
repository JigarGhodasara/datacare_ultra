import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:DataCareUltra/image_screen.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/qrCode_screen.dart';
import 'package:http/http.dart' as http;
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:pdf/widgets.dart' as pw;

class TagestimateScreen extends StatefulWidget {
  // dynamic? product;
  String? productImage;
  String? tagNo;
  String? VchSrNo;
  TagestimateScreen({Key? key, this.productImage, this.tagNo, this.VchSrNo})
      : super(key: key);

  @override
  State<TagestimateScreen> createState() => _TagestimateScreenState();
}

class _TagestimateScreenState extends State<TagestimateScreen> {
  TextEditingController searchController = TextEditingController();
  String productImage = "";
  final sqlConnection = SqlConnection.getInstance();
  dynamic productDetail;
  dynamic printingLable;
  int selectedOpt = 1;
  String selectedItType = 'G';
  late LoadingProvider loadingProvider;
  late CommonCompanyYearSelectionProvider commonCompanyYearSelectionProvider;
  String? co_code;
  String? year;
  String? lc_code;
  String itemRate = "";
  String itemAmount = "";
  String lbrPrc = "";
  String lbrRate = "";
  String lbrAmmount = "";
  String othAmmount = "";
  String mrp = "";
  String netAmmount = "";
  String gstTax = "";
  String totalAmount = "";

  String fillterItemRate = "";
  String fillterLbrPrc = "";
  String fillterLbrRate = "";
  String fillterLbrCharges = "";
  String fillterGst = "3.00";
  bool selectedGST = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    commonCompanyYearSelectionProvider = Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update your state here
      if (widget.tagNo != null) {
        getProductDetail();
      }
      getPrintLable();
    });

    // if(widget.productImage != null && widget.tagNo != null && widget.VchSrNo != null){
    // }
  }

  getPrintLable() async{
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    String query = "";
    if (Platform.isAndroid) {
      query = "SELECT * FROM COL_MAST WHERE CO_CODE = '${co_code!}' AND BOOK_NAME = 'SALES' AND YES_NO = 'Y'";
      }
      log("query $query");
      dynamic result = await sqlConnection.queryDatabase(query);
      if (jsonDecode(result).length != 0) {
        print("result");
        print(result);
printingLable = result;
      }
    }
  getProductDetail() async {
    loadingProvider.startLoading();
    setState(() {});
    String query = "";
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    year =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_year;
    lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    if (Platform.isAndroid) {
      if (widget.VchSrNo == null || widget.VchSrNo == "") {
        query = "SELECT B.IT_NAME,A.TAG_NO,A.IT_CODE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.VCH_SRNO,B.PR_CODE,B.GR_CODE,(D.GR_RATE/10) As Rate,C.ITM_NWT AS TagNwt,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT as ITM_GHAT,C.ITM_MRP, C.LBR_RATE,C.VCH_DATE  from ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE AND A.TAG_NO = C.TAG_NO AND A.VCH_SRNO = C.VCH_SRNO AND A.IT_CODE = C.IT_CODE)LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE)LEFT JOIN GROUP_MAST AS D ON B.CO_CODE = D.CO_CODE AND B.GR_CODE = D.GR_CODE WHERE A.CO_CODE = '" +
            co_code! +
            "'  AND A.LC_CODE = '" +
            lc_code! +
            "' AND A.CO_YEAR = '" +
            year! +
            "' AND A.TAG_NO = '" +
            widget.tagNo! +
            "'  GROUP BY A.TAG_NO,A.IT_CODE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.ITM_NWT,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.VCH_SRNO,B.PR_CODE,B.IT_NAME,B.GR_CODE,D.GR_RATE,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT,C.ITM_MRP, C.LBR_RATE,C.VCH_DATE HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0 ORDER BY C.VCH_DATE DESC";
      } else {
        query = "SELECT B.IT_NAME,A.TAG_NO,A.IT_CODE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.VCH_SRNO,B.PR_CODE,B.GR_CODE,(D.GR_RATE/10) As Rate,C.ITM_FINE,C.ITM_NWT AS TagNwt,C.LBR_AMT,C.OTH_AMT,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT as ITM_GHAT,C.ITM_MRP, C.LBR_RATE  from ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE AND A.TAG_NO = C.TAG_NO AND A.VCH_SRNO = C.VCH_SRNO AND A.IT_CODE = C.IT_CODE)LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE)LEFT JOIN GROUP_MAST AS D ON B.CO_CODE = D.CO_CODE AND B.GR_CODE = D.GR_CODE WHERE A.CO_CODE = '" +
            co_code! +
            "'  AND A.LC_CODE = '" +
            lc_code! +
            "' AND A.CO_YEAR = '" +
            year! +
            "' AND A.TAG_NO = '" +
            widget.tagNo! +
            "'  AND A.VCH_SRNO = '" +
            widget.VchSrNo! +
            "'  GROUP BY A.TAG_NO,A.IT_CODE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.ITM_NWT,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.VCH_SRNO,B.PR_CODE,B.IT_NAME,B.GR_CODE,D.GR_RATE,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT,C.ITM_MRP, C.LBR_RATE HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0 ";
      }
      log("query ${query}");
      dynamic result = await sqlConnection.queryDatabase(query);
      if (jsonDecode(result).length == 0) {
        productDetail = null;
        productImage = "";
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Tag Not Found"),
        ));
        loadingProvider.stopLoading();
      } else {
        productDetail = jsonDecode(result)[0];
      }
      log("Resuult ${result}");
    } else {
      dynamic productData = await MySQLService().getTagEstimateData(
          co_code!, lc_code!, year!, widget.tagNo!, widget.VchSrNo ?? "");
      // productDetail = productData[0][0];
      List<dynamic> aa = productData[0];
      if (aa.isEmpty) {
        productDetail = null;
        productImage = "";
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Tag Not Found"),
        ));
        loadingProvider.stopLoading();
      } else {
        productDetail = productData[0][0];
      }
    }

    setLableValue();

    if (widget.productImage == null) {
      if (Provider.of<CommonCompanyYearSelectionProvider>(context,
                  listen: false)
              .webImage
              .toLowerCase() ==
          "y") {
        productImage =
            "${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).webPath}${productDetail["TAG_NO"]}_${BigInt.from(productDetail["VCH_SRNO"])}.jpg";
        print("Product Image $productImage");
      }
    } else {
      productImage = widget.productImage ?? "";
      print("Product Image $productImage");
    }
    loadingProvider.stopLoading();
    setState(() {});
  }

  void saveToDb(XFile image) async {
    dynamic a = await image.readAsBytes();
    String base64String = base64Encode(a);
    sqlConnection.disconnect();
    String? host = await Preffrance().getString(Keys.HOST);
    String? userName = await Preffrance().getString(Keys.USERNAME);
    String? password = await Preffrance().getString(Keys.PASSWORD);
    String? db = "NextImage";

    if (Platform.isAndroid) {
      var connectionStatus = await sqlConnection.connect(
        ip: host!,
        port: host.contains(":") ? host.split(":")[1].toString() : "1433",
        databaseName: db,
        username: userName!,
        password: password!,
      );
      if (connectionStatus) {
        String queryDelete = "DELETE FROM TAG_IMAGE_DATA WHERE CO_CODE = '" +
            co_code! +
            "' AND LC_CODE = '" +
            lc_code! +
            "' AND  TAG_NO = '" +
            widget.tagNo! +
            "' AND VCH_SRNO = '" +
            widget.VchSrNo! +
            "'";
        print("deletedQuery ${queryDelete}");
        String deleteImage = await sqlConnection.updateData(queryDelete);
        print("deletedImage ${deleteImage}");
        String insertImage =
            "INSERT INTO TAG_IMAGE_DATA(CO_CODE,LC_CODE,TAG_NO,VCH_SRNO,IMAGE_TYPE,MOB_IMAGE) VALUES('" +
                co_code! +
                "','" +
                lc_code! +
                "','" +
                widget.tagNo! +
                "','" +
                widget.VchSrNo! +
                "','T','" +
                base64String +
                "')";
        print("insertImage ${insertImage}");
        await sqlConnection.updateData(insertImage).then((data) async {
          print("Data ${data}");
          sqlConnection.disconnect();
          String? host = await Preffrance().getString(Keys.HOST);
          String? userName = await Preffrance().getString(Keys.USERNAME);
          String? password = await Preffrance().getString(Keys.PASSWORD);
          String? db = await Preffrance().getString(Keys.DATABASE);
          dynamic databaseCon = await sqlConnection.connect(
            ip: host!,
            port: host.contains(":") ? host.split(":")[1].toString() : "1433",
            databaseName: db!,
            username: userName!,
            password: password!,
          );

          if (databaseCon) {
            productImage = image.path;
          }
        });

        setState(() {});
        // sqlConnection.disconnect();
        // String? pastDb = await Preffrance().getString(Keys.DATABASE);
        // // var connectionStatus =
        // await sqlConnection.connect(
        //   ip: host,
        //   port: '1433',
        //   databaseName: pastDb!,
        //   username: userName,
        //   password: password,
        // );
      }
    } else {
      dynamic isConnect = MySQLService().connectToDatabase(dbName: db);
      if (await isConnect) {
        await MySQLService()
            .deleteImage(co_code!, lc_code!, widget.tagNo!, widget.VchSrNo!);
        await MySQLService().insertImage(
            co_code!, lc_code!, widget.tagNo!, widget.VchSrNo!, base64String);
        dynamic isConnect2 = await MySQLService().connectToDatabase();
        if (isConnect2) {
          print("ImagePath ${image.path}");
          productImage = image.path;
        }
      }
      setState(() {});
    }
  }

  fillterData({
    required String filterItemRate,
    required String filterLbrPrc,
    required String filterLbrRate,
    required String filterLbrCharges,
    required int selectOption,
    required String selectType,
    required String filterGst,
    required bool selectedCheckbox,
  }) {
    print("object $selectOption");
    int selectedOption = selectOption;
    bool checkBox = selectedCheckbox;
    String selectedType = selectType;
    TextEditingController lbrPerCntorller =
        TextEditingController(text: filterLbrPrc);
    TextEditingController lbrRateCntorller =
        TextEditingController(text: filterLbrRate);
    TextEditingController lbrChargeCntorller =
        TextEditingController(text: filterLbrCharges);
    TextEditingController lbrDiscountPerCntorller = TextEditingController();
    TextEditingController itemRateCntorller =
        TextEditingController(text: filterItemRate);
    TextEditingController gstRateCntorller =
        TextEditingController(text: filterGst);
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
        isScrollControlled: true,
        builder: (context) =>
            StatefulBuilder(builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: SizedBox(
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
                                fillterItemRate = "";
                                fillterLbrPrc = "";
                                fillterLbrRate = "";
                                fillterLbrCharges = "";
                                fillterGst = "3.00";
                                selectedItType = "G";
                                selectedOpt = 1;
                                selectedGST = true;

                                setLableValue();
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
                                fillterItemRate = itemRateCntorller.text;
                                fillterLbrPrc = lbrPerCntorller.text;
                                fillterLbrRate = lbrRateCntorller.text;
                                fillterLbrCharges = lbrChargeCntorller.text;
                                fillterGst = gstRateCntorller.text;
                                selectedItType = selectedType;
                                selectedOpt = selectedOption;
                                selectedGST = checkBox;
                                setLableValue();
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
                              commonCompanyYearSelectionProvider.CoSname == "UAE"?"Making":"Labour",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF006EB7),
                                  fontWeight: FontWeight.w600),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 7.5),
                                    child: TextField(
                                      controller: lbrPerCntorller,
                                      onChanged: (vlaue) {
                                        lbrRateCntorller.clear();
                                        lbrChargeCntorller.clear();
                                        setModalState(() {});
                                      },
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            left: 10, top: 15, bottom: 15),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: BorderSide(
                                              color: Color(0xFF006EB7),
                                              width: 4),
                                        ), // Outline InputBorder
                                        filled: true,
                                        fillColor: Color(0xFFe7edeb),
                                        hintText: "Lbr%",
                                        hintStyle: TextStyle(fontSize: 20),
                                      ), // InputDecoration
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 7.5),
                                    child: TextField(
                                      controller: lbrRateCntorller,
                                      onChanged: (value) {
                                        lbrPerCntorller.clear();
                                        lbrChargeCntorller.clear();
                                        setModalState(() {});
                                      },
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            left: 10, top: 15, bottom: 15),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: BorderSide(
                                              color: Color(0xFF006EB7)),
                                        ), // Outline InputBorder
                                        filled: true,
                                        fillColor: Color(0xFFe7edeb),
                                        hintText: "Lbr Rate",
                                        hintStyle: TextStyle(fontSize: 20),
                                      ), // InputDecoration
                                    ),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 7.5),
                                    child: TextField(
                                      controller: lbrChargeCntorller,
                                      onChanged: (value) {
                                        lbrRateCntorller.clear();
                                        lbrPerCntorller.clear();
                                        setModalState(() {});
                                      },
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            left: 10, top: 15, bottom: 15),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: BorderSide(
                                              color: Color(0xFF006EB7)),
                                        ), // Outline InputBorder
                                        filled: true,
                                        fillColor: Color(0xFFe7edeb),
                                        hintText: "Lbr Charge",
                                        hintStyle: TextStyle(fontSize: 20),
                                      ), // InputDecoration
                                    ),
                                  ),
                                ),
                                Expanded(child: SizedBox())
                                // Expanded(
                                //   child: Padding(
                                //     padding: const EdgeInsets.only(left: 7.5),
                                //     child: TextField(
                                //       controller: lbrDiscountPerCntorller,
                                //       decoration: InputDecoration(
                                //         contentPadding: EdgeInsets.only(
                                //             left: 10, top: 15, bottom: 15),
                                //         border: OutlineInputBorder(
                                //           borderRadius:
                                //               BorderRadius.circular(12.0),
                                //           borderSide: BorderSide(
                                //               color: Color(0xFF006EB7)),
                                //         ), // Outline InputBorder
                                //         filled: true,
                                //         fillColor: Color(0xFFe7edeb),
                                //         hintText: "Lbr Discount %",
                                //         hintStyle: TextStyle(fontSize: 20),
                                //       ), // InputDecoration
                                //     ),
                                //   ),
                                // )
                              ],
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Text(
                              "${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Making":"Labour"} Type",
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
                                          selectedType = 'G';
                                          print("Button value: $value");
                                        });
                                      },
                                    ),
                                    Text("Gross Weight"),
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
                                          selectedType = 'N';
                                          print("Button value: $value");
                                        });
                                      },
                                    ),
                                    Text("Net Weight"),
                                  ],
                                )
                              ],
                            ),
                            Text(
                              "Item Rate (Pr Gram)",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF006EB7),
                                  fontWeight: FontWeight.w600),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            TextField(
                              controller: itemRateCntorller,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(
                                    left: 10, top: 15, bottom: 15),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide:
                                      BorderSide(color: Color(0xFF006EB7)),
                                ), // Outline InputBorder
                                filled: true,
                                fillColor: Color(0xFFe7edeb),
                                hintText: "Item Rate",
                                hintStyle: TextStyle(fontSize: 20),
                              ), // InputDecoration
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Text(
                              "GST Tax",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF006EB7),
                                  fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                Checkbox(
                                    value: checkBox,
                                    activeColor: Color(0xFF006EB7),
                                    onChanged: (newValue) {
                                      checkBox = newValue!;
                                      print(newValue);
                                      setModalState(() {});
                                    }),
                                Text(
                                  "GST",
                                  style: TextStyle(
                                      fontSize: 15,
                                      // color: Color(0xFF006EB7),
                                      fontWeight: FontWeight.w600),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 90.0, left: 30.0),
                                    child: TextField(
                                      controller: gstRateCntorller,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            left: 10, top: 15, bottom: 15),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: BorderSide(
                                              color: Color(0xFF006EB7)),
                                        ), // Outline InputBorder
                                        filled: true,
                                        fillColor: Color(0xFFe7edeb),
                                        hintText: "Item Rate",
                                        hintStyle: TextStyle(fontSize: 20),
                                      ), // InputDecoration
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 40,
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              );
            }));
  }

  setLableValue() {
    print("Hello");
    widget.VchSrNo = BigInt.from(productDetail["VCH_SRNO"]).toString();
    var temRate = 0.0;
    var intLbrPRC = productDetail["LBR_PRC"];
    var intOthAmount = productDetail["OTH_AMT"];
    if (fillterItemRate.isNotEmpty && fillterItemRate != "0") {
      // convert into 10 gram rate
      temRate = double.parse(fillterItemRate) ?? 0.0;
    } else {
      // temRate = productDetail["Rate"] / 10;
      temRate = productDetail["Rate"];
    }
    var itmRate = 0.0;
    if (temRate > 0.0) {
      print(temRate);
      // itmRate = temRate / 10;
      itmRate = temRate;
    }
    var tempGwtNwt = selectedItType == "G"
        ? productDetail["ITM_GWT"]
        : productDetail["TagNwt"];
    var intLbrGhat = 0.0;
    if (productDetail["ITM_GHAT"] != 0) {
      intLbrGhat = productDetail["ITM_GHAT"];
    }
    var itAmount = 0.0;
    if (Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .amountType ==
        "N") {
      itAmount = itmRate * (productDetail["TagNwt"] + intLbrGhat);
    } else if (Provider.of<CommonCompanyYearSelectionProvider>(context,
                listen: false)
            .amountType ==
        "G") {
      itAmount = itmRate * productDetail["ITM_GWT"];
    } else if (Provider.of<CommonCompanyYearSelectionProvider>(context,
                listen: false)
            .amountType ==
        "F") {
      itAmount = itmRate * productDetail["ITM_FINE"];
    } else {
      itAmount = itmRate * (productDetail["TagNwt"] + intLbrGhat);
    }
    var LbrRate = 0.0;
    var LbrAmt = 0.0;
    var intLbrAmount = productDetail["LBR_AMT"];
    var intMRP = productDetail["ITM_MRP"];
    if (fillterLbrPrc.isNotEmpty && fillterLbrPrc != "0") {
      LbrRate = (itmRate * double.parse(fillterLbrPrc)) / 100;
      LbrAmt = LbrRate * (tempGwtNwt + intLbrGhat);
      intLbrPRC = double.parse(fillterLbrPrc);
    } else if (fillterLbrRate.isNotEmpty && fillterLbrRate != "0") {
      LbrAmt = double.parse(fillterLbrRate) * (tempGwtNwt + intLbrGhat);
      LbrRate = double.parse(fillterLbrRate);
      intLbrPRC = 0.0;
    } else if (fillterLbrCharges.isNotEmpty && fillterLbrCharges != "0") {
      LbrAmt = double.parse(fillterLbrCharges);
      LbrRate = 0.0;
      intLbrPRC = 0.0;
    } else {
      if (intLbrPRC != 0.0) {
        LbrRate = ((itmRate * intLbrPRC) / 100);
        LbrAmt = LbrRate.round().toDouble() * (tempGwtNwt + intLbrGhat);
        print("Lab rate ${LbrRate}");
        print("Lab rate ${tempGwtNwt}");
        print("Lab rate ${intLbrGhat}");
        print("Lab AMT ${LbrAmt}");
      } else {
        LbrAmt = intLbrAmount;
      }
    }

    // var intAmount = itmRate * (productDetail["TagNwt"] + intLbrGhat);
    var intNetAmount;
    if (intMRP != 0) {
      intNetAmount = intMRP;
    } else {
      intNetAmount = LbrAmt + intOthAmount + itAmount;
    }

    itemRate = itmRate.toString();
    itemAmount = itAmount.round().toStringAsFixed(2);
    lbrPrc = intLbrPRC.toString();
    lbrRate = LbrRate.round().toStringAsFixed(2);
    lbrAmmount = LbrAmt.round().toStringAsFixed(2);
    othAmmount = intOthAmount.toString();
    mrp = intMRP.toString();
    netAmmount = double.parse(intNetAmount.toString()).round().toString();
    var TaxAmount = 0.0;
    if (selectedGST && fillterGst.isNotEmpty && fillterGst != "0") {
      if(commonCompanyYearSelectionProvider.CoSname == "UAE"){
        TaxAmount = (intNetAmount * double.parse("5")) / 100;
      }else{
        TaxAmount = (intNetAmount * double.parse(fillterGst)) / 100;
      }
    }
    gstTax = TaxAmount.round().toString();
    totalAmount =
        double.parse((intNetAmount + TaxAmount).toString()).round().toString();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          "TAG ESTIMATE",
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
                  filterItemRate: fillterItemRate,
                  filterLbrPrc: fillterLbrPrc,
                  filterLbrRate: fillterLbrRate,
                  filterLbrCharges: fillterLbrCharges,
                  selectOption: selectedOpt,
                  selectType: selectedItType,
                  filterGst: fillterGst,
                  selectedCheckbox: selectedGST);
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: SizedBox(
              height: 50,
              child: Row(
                children: [
                  SizedBox(
                    width: 8.0,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0.0),
                      child: TextFormField(
                        controller: searchController,
                        readOnly: false,
                        // onTap: () {
                        //   if (data == "BaddPolicy") {
                        //     Navigation.PushNavigation(context: context, screen: Business_source());
                        //   } else {
                        //     if (isCustomerFiled) {
                        //       Navigation.PushNavigation(
                        //           context: context,
                        //           screen: SearchCustomerPage(
                        //             title: 'Search Customer',
                        //             type: data!,
                        //           ));
                        //     }
                        //   }
                        // },
                        onChanged: (value) {
                          if (value.length == 7 || value.length == 8) {
                            widget.tagNo = value;
                            widget.VchSrNo = null;
                            widget.productImage = null;
                            getProductDetail();
                          }
                        },
                        cursorColor: Color(0xFF006EB7),
                        keyboardType: TextInputType.text,
                        // inputFormatters: formatters,
                        // textCapitalization: textCapitalization ?? TextCapitalization.none,
                        // maxLength: maxLength,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: "Search Tag no",
                          counterText: '',
                          contentPadding: EdgeInsets.only(left: 8, top: 0),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                width: 2,
                                color: Color(0xFF006EB7)), //<-- SEE HERE
                          ),
                          suffixIcon: Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => QRViewExample(
                                                isFromTagScreen: true,
                                              ))).then((onValue) {
                                    print("DDDD ${onValue}");
                                    widget.tagNo = onValue[0];
                                    widget.VchSrNo = null;
                                    widget.productImage = null;
                                    setState(() {});
                                    getProductDetail();
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(5)),
                                  child: Icon(
                                    Icons.qr_code_scanner_outlined,
                                    color: Colors.orange,
                                  ),
                                ),
                              )),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                width: 2,
                                color: Color(0xFF006EB7)), //<-- SEE HERE
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.tagNo = searchController.text;
                      widget.VchSrNo = null;
                      widget.productImage = null;
                      getProductDetail();
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Color(0xFF006EB7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5)),
                      child: Icon(
                        Icons.search,
                        color: Color(0xFF006EB7),
                        size: 35,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
              child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (productImage != "") {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ImageScreen(
                                        url: productImage,
                                        TagNo: widget.tagNo!,
                                        gWeight: double.parse(
                                                productDetail["ITM_GWT"]
                                                    .toString())
                                            .toStringAsFixed(3),
                                        nWeight: double.parse(
                                                productDetail["TagNwt"]
                                                    .toString())
                                            .toStringAsFixed(3),
                                      )));
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        height: 300,
                        width: double.infinity,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: productImage == ""
                                ? Image.asset(AppImage.placeHolder)
                                : productImage.toLowerCase().contains("http")
                                    ? Image.network(productImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, _, t) => Image(
                                              image: AssetImage(
                                                  AppImage.placeHolder),
                                              // height: 120,
                                              // width: 120,
                                              fit: BoxFit.cover,
                                            ))
                                    : Image.file(
                                        File(productImage),
                                        fit: BoxFit.cover,
                                      )),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 15,
                      child: GestureDetector(
                        onTap: () async {
                          final ImagePicker picker = ImagePicker();
// Pick an image.
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.camera);
                          if (image != null) {
                            saveToDb(image!);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4)),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 15,
                      child: GestureDetector(
                        onTap: () async {
                          final ImagePicker picker = ImagePicker();
// Pick an image.
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          print("Image ${image?.name}");
                          print("Image ${image?.path}");
                          if (image != null) {
                            saveToDb(image);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4)),
                          child: Icon(
                            Icons.photo_camera_back_sharp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 10,
                            spreadRadius: -10,
                            offset: Offset(2, 3))
                      ]),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Column(
                            children: [
                              Text(
                                "Pcs",
                                style: GoogleFonts.nunito(
                                    color: Color(0xFF006EB7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                productDetail == null
                                    ? "-:-"
                                    : productDetail["ITM_PCS"].toString(),
                                style: GoogleFonts.nunito(
                                    color: Color(0xFF006EB7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 60,
                        width: 2,
                        decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Column(
                            children: [
                              Text(
                                "Weight",
                                style: GoogleFonts.nunito(
                                    color: Color(0xFF006EB7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                productDetail == null
                                    ? "-:-"
                                    : productDetail["TagNwt"] == ""
                                        ? "-"
                                        : double.parse(productDetail["TagNwt"]
                                                    .toString())
                                                .toStringAsFixed(3) ??
                                            "-:-",
                                style: GoogleFonts.nunito(
                                    color: Color(0xFF006EB7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 60,
                        width: 2,
                        decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Column(
                            children: [
                              Text(
                                commonCompanyYearSelectionProvider.CoSname == "UAE"?"AED":"Amount",
                                style: GoogleFonts.nunito(
                                    color: Color(0xFF006EB7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                productDetail == null
                                    ? "-:-"
                                    : double.parse(totalAmount)
                                            .toStringAsFixed(2) ??
                                        "-:-",
                                style: GoogleFonts.nunito(
                                    color: Color(0xFF006EB7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 10,
                            spreadRadius: -10,
                            offset: Offset(2, 3))
                      ]),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 8,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.ac_unit,
                            color: Colors.orange,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            "PRODUCT SPECIFICATION",
                            style: GoogleFonts.nunito(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Icons.ac_unit,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Item Name :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : productDetail["IT_NAME"] == ""
                                      ? "-"
                                      : productDetail["IT_NAME"],
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Tag No :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : productDetail["TAG_NO"] == ""
                                      ? "-"
                                      : productDetail["TAG_NO"],
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Item Pcs :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : productDetail["ITM_PCS"].toString(),
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      productDetail == null || productDetail["DESIGN_NO"] == ""
                          ? SizedBox()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  right: 12.0, left: 12.0, top: 8),
                              child: Row(
                                children: [
                                  Text(
                                    "Design :",
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12),
                                  ),
                                  Spacer(),
                                  Text(
                                    productDetail == null
                                        ? "-:-"
                                        : productDetail["DESIGN_NO"] == ""
                                            ? "-"
                                            : productDetail["DESIGN_NO"] ??
                                                "-:-",
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Size :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : productDetail["ITM_SIZE"] == ""
                                      ? "-"
                                      : productDetail["ITM_SIZE"] ?? "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Gross Weight :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : productDetail["ITM_GWT"] == ""
                                      ? "-"
                                      : double.parse(productDetail["ITM_GWT"]
                                                  .toString())
                                              .toStringAsFixed(3) ??
                                          "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Net Weight :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : productDetail["TagNwt"] == ""
                                      ? "-"
                                      : double.parse(productDetail["TagNwt"]
                                                  .toString())
                                              .toStringAsFixed(3) ??
                                          "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // printingLable == null ? SizedBox():
                      //     printingLable.where((e) => e["COL_NAME"] == "Ght%" && e["YES_NO"] == "Y") != null ? Padding(
                      //       padding: const EdgeInsets.only(
                      //           right: 12.0, left: 12.0, top: 8),
                      //       child: Row(
                      //         children: [
                      //           Text(
                      //             "${printingLable.where((e) => e["COL_NAME"] == "Ght%" && e["YES_NO"] == "Y").first["COL_NEW_NAME"]} :",
                      //             style: GoogleFonts.nunito(
                      //                 fontWeight: FontWeight.w900,
                      //                 fontSize: 12),
                      //           ),
                      //           Spacer(),
                      //           Text(
                      //             productDetail == null
                      //                 ? "-:-" : productDetail["ITM_GHT_PRC"].toString() ,
                      //             style: GoogleFonts.nunito(
                      //                 fontWeight: FontWeight.w900,
                      //                 fontSize: 12),
                      //           ),
                      //         ],
                      //       ),
                      //     ) : SizedBox(),
                      // productDetail == null || productDetail["ITM_GHT_PRC"] == 0
                      //     ? SizedBox()
                      //     : Padding(
                      //         padding: const EdgeInsets.only(
                      //             right: 12.0, left: 12.0, top: 8),
                      //         child: Row(
                      //           children: [
                      //             Text(
                      //               "${printingLable.map((e){e["COL_NAME"] == "Ght%" ? e["COL_NEW_NAME"]:"";})} :",
                      //               style: GoogleFonts.nunito(
                      //                   fontWeight: FontWeight.w900,
                      //                   fontSize: 12),
                      //             ),
                      //             Spacer(),
                      //             Text(
                      //               productDetail["ITM_GHT_PRC"].toString(),
                      //               style: GoogleFonts.nunito(
                      //                   fontWeight: FontWeight.w900,
                      //                   fontSize: 12),
                      //             ),
                      //           ],
                      //         ),
                      //       ),

                      // printingLable == null ? SizedBox():
                      // printingLable.where((e) => e["COL_NAME"] == "GhtWt" && e["YES_NO"] == "Y") != null ? Padding(
                      //   padding: const EdgeInsets.only(
                      //       right: 12.0, left: 12.0, top: 8),
                      //   child: Row(
                      //     children: [
                      //       Text(
                      //         "${printingLable.where((e) => e["COL_NAME"] == "GhtWt" && e["YES_NO"] == "Y").first["COL_NEW_NAME"]} :",
                      //         style: GoogleFonts.nunito(
                      //             fontWeight: FontWeight.w900,
                      //             fontSize: 12),
                      //       ),
                      //       Spacer(),
                      //       Text(
                      //         productDetail == null
                      //             ? "-:-" : double.parse(productDetail["ITM_GHAT"]
                      //             .toString())
                      //             .toStringAsFixed(3),                              style: GoogleFonts.nunito(
                      //             fontWeight: FontWeight.w900,
                      //             fontSize: 12),
                      //       ),
                      //     ],
                      //   ),
                      // ) : SizedBox(),
                      //
                      // productDetail == null || productDetail["ITM_GHAT"] == 0
                      //     ? SizedBox()
                      //     : Padding(
                      //         padding: const EdgeInsets.only(
                      //             right: 12.0, left: 12.0, top: 8),
                      //         child: Row(
                      //           children: [
                      //             Text(
                      //               "Ghat Weight :",
                      //               style: GoogleFonts.nunito(
                      //                   fontWeight: FontWeight.w900,
                      //                   fontSize: 12),
                      //             ),
                      //             Spacer(),
                      //             Text(
                      //               productDetail == null
                      //                   ? "-:-" : double.parse(productDetail["ITM_GHAT"]
                      //                       .toString())
                      //                   .toStringAsFixed(3),
                      //               style: GoogleFonts.nunito(
                      //                   fontWeight: FontWeight.w900,
                      //                   fontSize: 12),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      productDetail == null ||
                              Provider.of<CommonCompanyYearSelectionProvider>(
                                          context,
                                          listen: false)
                                      .amountType !=
                                  "F"
                          ? SizedBox()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  right: 12.0, left: 12.0, top: 8),
                              child: Row(
                                children: [
                                  Text(
                                    "Fine Weight :",
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12),
                                  ),
                                  Spacer(),
                                  Text(
                                    productDetail == null
                                        ? "-:-"
                                        : productDetail["ITM_FINE"] == ""
                                            ? "-"
                                            : double.parse(productDetail[
                                                            "ITM_FINE"]
                                                        .toString())
                                                    .toStringAsFixed(3) ??
                                                "-:-",
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Item Rate :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : itemRate == ""
                                      ? "-"
                                      : double.parse(itemRate.toString())
                                              .toStringAsFixed(2) ??
                                          "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              commonCompanyYearSelectionProvider.CoSname == "UAE"?"Metal Value (AED) :": "Item Amount :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : itemAmount == ""
                                      ? "-"
                                      : double.parse(itemAmount.toString())
                                              .toStringAsFixed(2) ??
                                          "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Making":"Labour"} Prc% :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : double.parse(lbrPrc.toString())
                                          .toStringAsFixed(2) ??
                                      "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Making":"Labour"} Rate :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : double.parse(lbrRate.toString())
                                          .toStringAsFixed(2) ??
                                      "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              commonCompanyYearSelectionProvider.CoSname == "UAE"?"Making Charges(AED) :":"Labour Amount :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : double.parse(lbrAmmount.toString())
                                          .toStringAsFixed(2) ??
                                      "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Other ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Charges(AED)":"Amount"} :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : double.parse(othAmmount.toString())
                                          .toStringAsFixed(2) ??
                                      "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      commonCompanyYearSelectionProvider.CoSname == "UAE" ?SizedBox():
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "MRP :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : double.parse(mrp.toString())
                                          .toStringAsFixed(2) ??
                                      "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Net ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Value(AED)":"Amount"} :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : double.parse(netAmmount)
                                          .toStringAsFixed(2) ??
                                      "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF009603)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8),
                        child: Row(
                          children: [
                            Text(
                            commonCompanyYearSelectionProvider.CoSname == "UAE" ? "VAT 5% (AED) :" :"GST Tax :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : double.parse(gstTax).toStringAsFixed(2) ??
                                      "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, left: 12.0, top: 8, bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              "Total ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Value (AED)":"Amount"} :",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            Spacer(),
                            Text(
                              productDetail == null
                                  ? "-:-"
                                  : double.parse(totalAmount)
                                          .toStringAsFixed(2) ??
                                      "-:-",
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF009603)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (productDetail != null) {
                              createPDF();
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("Please Search Tag"),
                              ));
                            }
                          },
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 15),
                              decoration: BoxDecoration(
                                  color: Color(0xFF006EB7),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                  child: Text(
                                "Create PDF",
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: Colors.white),
                              ))),
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (productDetail != null) {
                              await _processAndShareImage(productImage);
                            }
                          },
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 15),
                              decoration: BoxDecoration(
                                  color: Color(0xFF006EB7),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                  child: Text(
                                "Share Tag",
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: Colors.white),
                              ))),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ))
        ],
      ),
    );
  }

  createPDF() async {
    final pdf = pw.Document();
    final qrCodeImage = await generateQRCodeImage(widget.tagNo ?? "");
    dynamic companyDetails;
    if (Platform.isAndroid) {
      String companyData =
          "SELECT CO_NAME,CO_ADD1,CO_ADD2,CO_ADD3,CO_CITY,CO_PIN,CO_MOBILE FROM CO_MAST WHERE CO_CODE = ${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).co_code}";
      dynamic dataofCompany = await sqlConnection.queryDatabase(companyData);
      companyDetails = jsonDecode(dataofCompany)[0];
      print("companyDetail");
      print(companyDetails);
    } else {
      dynamic companyData = await MySQLService().getCompanyDetail(co_code!);
      companyDetails = companyData[0][0];
    }

    pdf.addPage(pw.Page(
        build: (contexts) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "${companyDetails["CO_NAME"]}",
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                      "${companyDetails["CO_ADD1"]},${companyDetails["CO_ADD2"]}",
                      style: pw.TextStyle(
                        fontSize: 18,
                      ),
                      textAlign: pw.TextAlign.center),
                  pw.Text(
                    "${companyDetails["CO_ADD3"]},${companyDetails["CO_CITY"]}-${companyDetails["CO_PIN"]}",
                    style: pw.TextStyle(fontSize: 18),
                  ),
                  pw.Text(
                    "Mo: ${companyDetails["CO_MOBILE"].toString()}",
                    style: pw.TextStyle(fontSize: 18),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Date : ${DateFormat("dd/MM/yyyy").format(DateTime.now())}",
                    style: pw.TextStyle(fontSize: 18),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "${productDetail["IT_NAME"].toString()}",
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Center(
                    child: pw.Table(
                        border: pw.TableBorder(
                            left: pw.BorderSide(),
                            right: pw.BorderSide(),
                            top: pw.BorderSide(),
                            bottom: pw.BorderSide(),
                            horizontalInside: pw.BorderSide(),
                            verticalInside: pw.BorderSide()),

                        tableWidth: pw.TableWidth.min,
                        children: [
                          pw.TableRow(
                              verticalAlignment: pw.TableCellVerticalAlignment.middle,
                              children: [
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child:  pw.Padding(padding: pw.EdgeInsets.only(right: 10,left: 80),child: pw.Text(
                                "Tag No :",
                                style: pw.TextStyle(fontSize: 18),
                              )),
                            ),
                            pw.Align(alignment: pw.Alignment.centerRight,
                              child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                widget.tagNo.toString(),
                                style: pw.TextStyle(fontSize: 18),
                              ),)
                            )

                          ]),
                          pw.TableRow(
                              verticalAlignment: pw.TableCellVerticalAlignment.middle,
                              children: [
                                pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:pw.Text(
                                  "Pcs :",
                                  style: pw.TextStyle(fontSize: 18),
                                ) )),
                            pw.Align(alignment: pw.Alignment.centerRight,
                              child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                productDetail["ITM_PCS"].toString(),
                                style: pw.TextStyle(fontSize: 18),
                              ) )
                            )

                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            productDetail == null || productDetail["DESIGN_NO"] == ""
                                ?pw.SizedBox():
                                pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                                  "Design :",
                                  style: pw.TextStyle(fontSize: 18),
                                ),)),

                            productDetail == null || productDetail["DESIGN_NO"] == ""
                                ?pw.SizedBox():
                                pw.Align(alignment: pw.Alignment.centerRight,
                                  child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child: pw.Text(
                                    productDetail == null
                                        ? "-:-"
                                        : productDetail["DESIGN_NO"] == ""
                                        ? "-"
                                        : productDetail["DESIGN_NO"] ?? "-:-",
                                    style: pw.TextStyle(fontSize: 18),
                                  ),)
                                )

                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                              "Gr Wt :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                              child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                double.parse(productDetail["ITM_GWT"].toString())
                                    .toStringAsFixed(3),
                                style: pw.TextStyle(fontSize: 18),
                              ),)
                            )

                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                              "Nt Wt :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  double.parse(productDetail["TagNwt"].toString())
                                      .toStringAsFixed(3),
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )
                          ]),
                          // pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                          //   printingLable.where((e) => e["COL_NAME"] == "Ght%" && e["YES_NO"] == "Y") == null
                          //       ? pw.SizedBox():
                          //   pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                          //     "${printingLable.where((e) => e["COL_NAME"] == "Ght%" && e["YES_NO"] == "Y").first['COL_NEW_NAME']} :",
                          //     style: pw.TextStyle(fontSize: 18),
                          //   ))),
                          //   printingLable.where((e) => e["COL_NAME"] == "Ght%" && e["YES_NO"] == "Y") == null
                          //       ? pw.SizedBox():
                          //   pw.Align(alignment: pw.Alignment.centerRight,
                          //       child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                          //         productDetail["ITM_GHT_PRC"]
                          //             .toString(),
                          //         style: pw.TextStyle(fontSize: 18),
                          //       ),)
                          //   )
                          //
                          // ]),
                          // pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                          //   printingLable.where((e) => e["COL_NAME"] == "GhtWt" && e["YES_NO"] == "Y") == null
                          //       ? pw.SizedBox():
                          //   pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                          //     "${printingLable.where((e) => e["COL_NAME"] == "GhtWt" && e["YES_NO"] == "Y").first['COL_NEW_NAME']} :",
                          //     style: pw.TextStyle(fontSize: 18),
                          //   ))),
                          //   printingLable.where((e) => e["COL_NAME"] == "GhtWt" && e["YES_NO"] == "Y") == null
                          //       ? pw.SizedBox():
                          //   pw.Align(alignment: pw.Alignment.centerRight,
                          //       child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                          //         double.parse(productDetail["ITM_GHAT"]
                          //             .toString())
                          //             .toStringAsFixed(3) ,
                          //         style: pw.TextStyle(fontSize: 18),
                          //       ),)
                          //   )
                          // ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            productDetail == null || Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).amountType != "F"?pw.SizedBox():
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                              "Fine Weight :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),

                            productDetail == null || Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).amountType != "F"?pw.SizedBox():

                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  productDetail == null
                                      ? "-:-"
                                      : productDetail["ITM_FINE"] == ""
                                      ? "-"
                                      : double.parse(productDetail["ITM_FINE"]
                                      .toString())
                                      .toStringAsFixed(3) ??
                                      "-:-",
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )

                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                              "Rate 1 Gm :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  double.parse(itemRate.toString())
                                      .toStringAsFixed(2),
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )
                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                               commonCompanyYearSelectionProvider.CoSname == "UAE"? "Metal Value (AED)": "Item Amt :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  double.parse(itemAmount.toString())
                                      .toStringAsFixed(2) ??
                                      "-:-",
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )
                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                              "${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Making":"Lbr"} prc % :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  double.parse(lbrPrc.toString())
                                      .toStringAsFixed(2) ??
                                      "-:-",
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )

                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                              "${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Making":"Lbr"} Rate :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  double.parse(lbrRate.toString())
                                      .toStringAsFixed(2) ??
                                      "-:-",
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )

                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10,left: 3),child:  pw.Text(
                              "${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Making":"Lbr"} ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Charges(AED)":"Amt"} :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  double.parse(lbrAmmount.toString())
                                      .toStringAsFixed(2) ??
                                      "-:-",
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )

                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10,left: 3),child:  pw.Text(
                              "Oth ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Charges(AED)":"Amt"} :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  double.parse(othAmmount.toString())
                                      .toStringAsFixed(2) ??
                                      "-:-",
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )
                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                              "Net ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Value(AED)":"Amt"} :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  double.parse(netAmmount).toStringAsFixed(2) ??
                                      "-:-",
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )
                          ]),
                          pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle,children: [
                            pw.Align(alignment: pw.Alignment.centerRight,child: pw.Padding(padding: pw.EdgeInsets.only(right: 10),child:  pw.Text(
                              commonCompanyYearSelectionProvider.CoSname == "UAE"?"Vat(AED) :":"Gst Tax :",
                              style: pw.TextStyle(fontSize: 18),
                            ))),
                            pw.Align(alignment: pw.Alignment.centerRight,
                                child: pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 20,vertical: 5),child:  pw.Text(
                                  double.parse(gstTax).toStringAsFixed(2) ?? "-:-",
                                  style: pw.TextStyle(fontSize: 18),
                                ),)
                            )

                          ]),


                          // pw.TableRow(
                          //     // crossAxisAlignment: pw.CrossAxisAlignment.end,
                          //     children: [
                          //   // pw.Text(
                          //   //   "Tag No :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   "Pcs :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //       // productDetail == null || productDetail["DESIGN_NO"] == ""
                          //       //     ?pw.SizedBox():
                          //       // pw.Column(
                          //       //   children: [
                          //       //     pw.Text(
                          //       //       "Design :",
                          //       //       style: pw.TextStyle(fontSize: 18),
                          //       //     ),
                          //       //     pw.SizedBox(height: 8),
                          //       //   ],
                          //       // ),
                          //   // pw.Text(
                          //   //   "Gr Wt :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   "Nt Wt :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //       // productDetail == null || productDetail["ITM_GHT_PRC"] == 0
                          //       //     ? pw.SizedBox():pw.Column(
                          //       //   children: [
                          //       //     pw.Text(
                          //       //       "Ghat % :",
                          //       //       style: pw.TextStyle(fontSize: 18),
                          //       //     ),
                          //       //     pw.SizedBox(height: 8),
                          //       //   ]
                          //       // ),
                          //
                          //
                          //       // productDetail == null || productDetail["ITM_GHAT"] == 0
                          //       //     ? pw.SizedBox():  pw.Column(
                          //       //       children: [
                          //       //         pw.Text(
                          //       //           "Ghat Weight :",
                          //       //           style: pw.TextStyle(fontSize: 18),
                          //       //         ),
                          //       //         pw.SizedBox(height: 8),
                          //       //       ],
                          //       //     ),
                          //       // productDetail == null || Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).amountType != "F"?pw.SizedBox():
                          //       // pw.Column(
                          //       //   children: [
                          //       //     pw.Text(
                          //       //       "Fine Weight :",
                          //       //       style: pw.TextStyle(fontSize: 18),
                          //       //     ),
                          //       //     pw.SizedBox(height: 8),
                          //       //   ],
                          //       // ),
                          //
                          //   //     pw.Text(
                          //   //   "Rate 1 Gm :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   "Item ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"AED":"Amt"} :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   "Lbr prc % :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   "Lbr Rate :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   "Lbr ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"AED":"Amt"} :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   "Oth ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"AED":"Amt"} :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   "Net ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"AED":"Amt"} :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   "Gst Tax :",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          // ]),
                          // pw.TableRow(
                          //     // crossAxisAlignment: pw.CrossAxisAlignment.start,
                          //     children: [
                          //   // pw.Text(
                          //   //   widget.tagNo.toString(),
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   productDetail["ITM_PCS"].toString(),
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //       pw.SizedBox(height: 8),
                          //       // productDetail == null || productDetail["DESIGN_NO"] == ""
                          //       //     ?pw.SizedBox():
                          //       // pw.Column(
                          //       //   children: [
                          //       //     pw.Text(
                          //       //       productDetail == null
                          //       //           ? "-:-"
                          //       //           : productDetail["DESIGN_NO"] == ""
                          //       //           ? "-"
                          //       //           : productDetail["DESIGN_NO"] ?? "-:-",
                          //       //       style: pw.TextStyle(fontSize: 18),
                          //       //     ),
                          //       //     pw.SizedBox(height: 8),
                          //       //   ],
                          //       // ),
                          //   // pw.Text(
                          //   //   double.parse(productDetail["ITM_GWT"].toString())
                          //   //       .toStringAsFixed(3),
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   double.parse(productDetail["TagNwt"].toString())
                          //   //       .toStringAsFixed(3),
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //       // productDetail == null || productDetail["ITM_GHT_PRC"] == 0
                          //       //     ? pw.SizedBox():pw.Column(
                          //       //       children: [
                          //       //         pw.Text(
                          //       //           productDetail["ITM_GHT_PRC"]
                          //       //               .toString(),
                          //       //           style: pw.TextStyle(fontSize: 18),
                          //       //         ),
                          //       //       ],
                          //       //     ),
                          //       // productDetail == null || productDetail["ITM_GHAT"] == 0
                          //       //     ? pw.SizedBox():  pw.Column(
                          //       //       children: [
                          //       //         pw.Text(
                          //       //           double.parse(productDetail["ITM_GHAT"]
                          //       //               .toString())
                          //       //               .toStringAsFixed(3) ,
                          //       //           style: pw.TextStyle(fontSize: 18),
                          //       //         ),
                          //       //       ],
                          //       //     ),
                          //
                          //
                          //       // productDetail == null || Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).amountType != "F"?pw.SizedBox():
                          //       // pw.Column(
                          //       //   children: [
                          //       //     pw.Text(
                          //       //       productDetail == null
                          //       //           ? "-:-"
                          //       //           : productDetail["ITM_FINE"] == ""
                          //       //           ? "-"
                          //       //           : double.parse(productDetail["ITM_FINE"]
                          //       //           .toString())
                          //       //           .toStringAsFixed(3) ??
                          //       //           "-:-",
                          //       //       style: pw.TextStyle(fontSize: 18),
                          //       //     ),
                          //       //   ],
                          //       // ),
                          //   // pw.Text(
                          //   //   double.parse(itemRate.toString())
                          //   //       .toStringAsFixed(2),
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   double.parse(itemAmount.toString())
                          //   //           .toStringAsFixed(2) ??
                          //   //       "-:-",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   double.parse(lbrPrc.toString())
                          //   //           .toStringAsFixed(2) ??
                          //   //       "-:-",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   double.parse(lbrRate.toString())
                          //   //           .toStringAsFixed(2) ??
                          //   //       "-:-",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   double.parse(lbrAmmount.toString())
                          //   //           .toStringAsFixed(2) ??
                          //   //       "-:-",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   double.parse(othAmmount.toString())
                          //   //           .toStringAsFixed(2) ??
                          //   //       "-:-",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   double.parse(netAmmount).toStringAsFixed(2) ??
                          //   //       "-:-",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          //   pw.SizedBox(height: 8),
                          //   // pw.Text(
                          //   //   double.parse(gstTax).toStringAsFixed(2) ?? "-:-",
                          //   //   style: pw.TextStyle(fontSize: 18),
                          //   // ),
                          // ]),
                        ]),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    "Total ${commonCompanyYearSelectionProvider.CoSname == "UAE"?"Value(AED)":"Amt"} : ${double.parse(totalAmount).toStringAsFixed(2) ?? "-:-"}",
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  // pw.SizedBox(height: 10),
                  // if (qrCodeImage != null)
                  //   pw.Image(pw.MemoryImage(qrCodeImage),
                  //       width: 100, height: 100),
                  // pw.SizedBox(height: 10),
                  // pw.Text(
                  //   "Scan for Tag No",
                  //   style: pw.TextStyle(fontSize: 18),
                  // ),
                  // pw.SizedBox(height: 8),
                  pw.Text(
                    "Thank you! Visit Again",
                    style: pw.TextStyle(fontSize: 18),
                  ),
                ])));

    // await Printing.layoutPdf(onLayout: (PdfPageFormat format ) => pdf.save());
    sharePDF(await pdf.save(), "tag_pdf");
  }

  Future<void> sharePDF(Uint8List pdfData, String fileName) async {
    try {
      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName.pdf';

      // Save the PDF file
      final file = File(filePath);
      await file.writeAsBytes(pdfData);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Here is the PDF file I generated!',
      );
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }

  Future<Uint8List?> generateQRCodeImage(String data) async {
    final qrValidation = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );

    if (qrValidation.status == QrValidationStatus.valid) {
      final qrCode = qrValidation.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        gapless: true,
      );

      final image = await painter.toImage(300); // Size of QR code
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }
    return null;
  }

  Future<void> _processAndShareImage(String url) async {
    final bytes;
    if (url.toLowerCase().contains("http")) {
      // Download the image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      // Load the image into memory
      bytes = response.bodyBytes;
    } else {
      bytes = File(url).readAsBytes();
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final ui.Image originalImage = frame.image;

    // Create a canvas to draw on
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Draw the original image
    final size =
        Size(originalImage.width.toDouble(), originalImage.height.toDouble());
    canvas.drawImageRect(
      originalImage,
      Rect.fromLTWH(0, 0, originalImage.width.toDouble(),
          originalImage.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Draw a white rectangle for the text background
    const double padding = 20;
    final textPainter = TextPainter(
      text: TextSpan(
        text: "Tag No : ${widget.tagNo}",
        style: const TextStyle(
            color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    final textWidth = textPainter.width + padding * 2;
    final textHeight = textPainter.height + padding * 2;
    final textOffset =
        Offset(size.width / 2 - textWidth / 2, size.height - textHeight - 30);

    canvas.drawRect(
      Rect.fromLTWH(textOffset.dx, textOffset.dy, textWidth, textHeight),
      Paint()..color = Colors.white,
    );

    // Draw the text
    textPainter.paint(
        canvas, Offset(textOffset.dx + padding, textOffset.dy + padding));

    // Finalize the image
    final picture = recorder.endRecording();
    final editedImage =
        await picture.toImage(originalImage.width, originalImage.height);
    final byteData =
        await editedImage.toByteData(format: ui.ImageByteFormat.png);

    // Save the image to a file
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/shared_image.png';
    final file = File(filePath);
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    // Share the image
    await Share.shareXFiles([XFile(filePath)], text: 'Check out this image!');
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.toUpperCase();
    return newValue.copyWith(text: newText, selection: newValue.selection);
  }
}
