import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/tagEstimate_screen.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class CategoryproductScreen extends StatefulWidget {
  String screenName;
  String prCode;
  String ItType;
  CategoryproductScreen(
      {Key? key,
      required this.screenName,
      required this.prCode,
      required this.ItType})
      : super(key: key);

  @override
  State<CategoryproductScreen> createState() => _CategoryproductScreenState();
}

class _CategoryproductScreenState extends State<CategoryproductScreen> {
  List<dynamic> categoryProductList = [];
  List<dynamic> searchCategoryProductList = [];
  final sqlConnection = SqlConnection.getInstance();
  List<dynamic> groupData = [
    {"GR_CODE": "", "GR_NAME": "Select Group"}
  ];
  String selectItem = "Select Item";
  dynamic selectedGroupCode = {"GR_CODE": "", "GR_NAME": "Select Group"};
  String co_code = "";
  String year = "";
  String lc_code = "";
  late LoadingProvider loadingProvider;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update your state here
      getProductList();
    });
    getFilterData();
  }

  void getProductList() async {
    loadingProvider.startLoading();
    setState(() {
    });
    String grpCode = "";
    if (selectedGroupCode["GR_NAME"] != "Select Group") {

      groupData.forEach((action) {
        if (action["GR_NAME"] == selectedGroupCode["GR_NAME"]) {
          grpCode = action["GR_CODE"];
        }
      });
      print("grpCode ${grpCode}");
    }

    print("prCode ${widget.prCode}");
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
      String query =
          "SELECT A.TAG_NO As TagNo,B.IT_NAME As ItmName,D.PR_CODE,C.ITM_SIZE As Size,C.ITM_PCS as Pcs,C.ITM_GWT As Grwt,C.ITM_NWT AS NetWt,C.LBR_PRC As LbrPrc,C.LBR_RATE As LRate,C.LBR_AMT LbrAmt,C.OTH_AMT OthAmt,C.ITM_MRP As Mrp,C.VCH_SRNO,C.LBR_TYPE AS LbrType,C.RATE_TYPE AS RateType,B.GR_CODE as GrCode, C.DESIGN_IMG_ID AS DesignImgId from ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE  And A.TAG_NO = C.TAG_NO And A.VCH_SRNO = C.VCH_SRNO And A.IT_CODE = C.IT_CODE) LEFT JOIN  ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE And A.IT_CODE = B.IT_CODE) LEFT JOIN PRODUCT_MAST AS D ON B.CO_CODE = D.CO_CODE And B.PR_CODE = D.PR_CODE WHERE A.CO_CODE = '$co_code' AND A.LC_CODE = '$lc_code' AND A.CO_YEAR = '$year' ";

      if (widget.ItType != '') {
        query += "AND B.IT_TYPE = '${widget.ItType}' ";
      }
      if (widget.prCode != "") {
        query += "AND D.PR_CODE = '${widget.prCode}' ";
      }
      // use for the filler
      if (grpCode != "") {
        query += "AND B.GR_CODE = '" + grpCode + "' ";
      }
      // if(selectItem != "Select Item"){
      //   query += "AND B.GR_CODE = '"+selectItem.splitMapJoin(" ")[1]+"'";
      // }
      // if !self.Sgroup.isEmpty {
      // query += "AND B.GR_CODE = '\(self.Sgroup)' "
      // }
      //

      // if !self.SItem.isEmpty {
      // query += "AND B.IT_CODE = '\(self.SItem)' "
      // }
      //weight Filter
//        if (Int(self.SWeightMin) != 0) {
//            query += "AND C.ITM_NWT >= '\(self.SWeightMin)'"
//        }
//
//        if (Int(SWeightMax) != 0) {
//            query += "AND C.ITM_NWT <= '\(self.SWeightMax)'"
//        }

      query +=
          "GROUP BY D.PR_CODE,A.TAG_NO,B.IT_NAME,B.IT_CODE,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.ITM_NWT,C.LBR_PRC,C.LBR_RATE,C.LBR_AMT,C.OTH_AMT,  C.ITM_MRP,C.VCH_SRNO,C.LBR_TYPE,C.RATE_TYPE, B.GR_CODE, C.DESIGN_IMG_ID HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0  ORDER BY A.TAG_NO DESC";
      log("query ${query}");
      dynamic result = await sqlConnection.queryDatabase(query);
      log("Resuult ${result}");
      categoryProductList = jsonDecode(result);
      searchCategoryProductList = jsonDecode(result);
    } else {
      dynamic result = await MySQLService()
          .getProducts(co_code,lc_code, year, widget.prCode, widget.ItType,grpCode);
      print("Reee $result");
      categoryProductList = result[0];

      if(selectItem != "Select Item"){
        // searchCategoryProductList.removeWhere((e)=> selectItem != e["ItmName"]);
        result[0].forEach((e){
          if(selectItem == e["ItemName"]){
            searchCategoryProductList.add(e);
          }
        });
      }else{
        searchCategoryProductList = result[0];
      }
    }


    loadingProvider.stopLoading();
    setState(() {});
    // log("Data $result");
  }

  fillterData({
   required String selectedItem,
    required dynamic selectGrp,
  }) {
    dynamic selectedGroupvalue = selectGrp;
    String item = selectedItem;
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
        builder: (context) => StatefulBuilder(builder: (context, setModalState) {


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
                        onTap: (){
                          selectItem = "Select Item";
                          selectedGroupCode = {"GR_CODE": "", "GR_NAME": "Select Group"};
                          getProductList();
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
                        onTap: (){
                          selectItem = item;
                          selectedGroupCode = selectedGroupvalue;
                          getProductList();
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
                                    items: groupData
                                        .map((dynamic items) {
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
                            height: 10,
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
                                    value: item,
                                    items: ["Select Item","${widget.screenName} 18K","${widget.screenName} 916"]
                                        .map((String items) {
                                      return DropdownMenuItem(
                                        value: items,
                                        child: Text(items),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      item = value!;
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

    }else{
      dynamic grpResult = await MySQLService().getStockFilterGrpData(co_code);
      print("grpResult $grpResult");
      groupData.addAll(grpResult[0]);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.screenName,
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
              fillterData(selectedItem: selectItem,selectGrp: selectedGroupCode);
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
          SizedBox(height: 15,),
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
                  hintText: "Search with tag no",
                  counterText: '',
                  contentPadding: EdgeInsets.only(left: 8, top: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        width: 2,
                        color: Color(0xFF006EB7)), //<-- SEE HERE
                  ),
                  prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 8,right: 8),
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
                        width: 2,
                        color: Color(0xFF006EB7)), //<-- SEE HERE
                  ),
                ),
                onChanged: (value) {
                  if (value != "") {
                    searchCategoryProductList = categoryProductList
                        .where((text) =>
                    text.containsKey("TagNo") &&
                        text["TagNo"].toString().toLowerCase().contains(
                            value.trim().toLowerCase()))
                        .toList();
                    setState(() {

                    });
                  }else{

                    searchCategoryProductList.clear();
                    searchCategoryProductList.addAll(categoryProductList);
                    setState(() {
                    });
                  }
                }),
          ),
         loadingProvider.isLoading ? SizedBox() :
          searchCategoryProductList.length == 0 ? Expanded(child: Center(child: Text(
            "No record found",
            style: GoogleFonts.nunito(
                color: Color(0xFF006EB7),
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),)) : Expanded(
              child: ListView.builder(
                  itemCount: searchCategoryProductList.length,
                  itemBuilder: (context, index) {
                    // if key_WEB_IMAGE == y
                    // then use path from key_WEB_PATH (tagUrl = "\(key_WEB_PATH)\(strTag)_\(strImageID).jpg")
                    String imagePath = "";
                    print(Provider.of<CommonCompanyYearSelectionProvider>(
                            context,
                            listen: false)
                        .webImage);
                    if (Provider.of<CommonCompanyYearSelectionProvider>(context,
                                listen: false)
                            .webImage
                            .toLowerCase() ==
                        "y") {

                      if(searchCategoryProductList[index]["DesignImgId"] != 'N'){
                        imagePath =
                        "${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).webPath}${searchCategoryProductList[index]["DesignImgId"]}.jpg";

                      }else{
                        imagePath =
                        "${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).webPath}${searchCategoryProductList[index]["TagNo"]}_${BigInt.from(searchCategoryProductList[index]["VCH_SRNO"])}.jpg";

                      }


                    }
                    print("Image $imagePath");
                    return GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> TagestimateScreen(productImage: imagePath,tagNo:searchCategoryProductList[index]["TagNo"].toString() ,VchSrNo:BigInt.from(searchCategoryProductList[index]["VCH_SRNO"]).toString() ,)));
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 15.0,
                            left: 15,
                            right: 15,
                            bottom:
                                searchCategoryProductList.length - 1 == index ? 15 : 0),
                        child: Container(
                          // padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 12,
                                    spreadRadius: -8,
                                    offset: Offset(2, 3))
                              ]),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: imagePath == ""
                                        ? Image(
                                            image:
                                                AssetImage(AppImage.placeHolder),
                                            height: 120,
                                            width: 120,
                                      fit: BoxFit.fitWidth,
                                          )
                                        : Image.network(imagePath,height: 120,width: 120,fit: BoxFit.fitWidth,errorBuilder: (context,_,t)=>Image(
                                      image:
                                      AssetImage(AppImage.placeHolder),
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.fitWidth,
                                    ) ,)),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10.0, right: 10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        searchCategoryProductList[index]['ItmName'],
                                        style: GoogleFonts.nunito(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF006EB7)),
                                      ),
                                      Text(
                                        searchCategoryProductList[index]['TagNo'],
                                        style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        double.parse(searchCategoryProductList[index]['Grwt']
                                            .toString()).toStringAsFixed(3),
                                        style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        double.parse(searchCategoryProductList[index]['NetWt']
                                            .toString()).toStringAsFixed(3),
                                        style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }))
        ],
      ),
    );
  }
}
