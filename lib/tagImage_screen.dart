import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/categoryProduct_screen.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class TagimageScreen extends StatefulWidget {
  const TagimageScreen({Key? key}) : super(key: key);

  @override
  State<TagimageScreen> createState() => _TagimageScreenState();
}

class _TagimageScreenState extends State<TagimageScreen> {
  final sqlConnection = SqlConnection.getInstance();
  int selectedOption = 2;
  String ItType = 'G';
  List<dynamic> category = [];
  List<dynamic> searchCategory = [];
  late LoadingProvider loadingProvider;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update your state here
      getProductCategory();
    });
  }

  void getProductCategory() async {
    loadingProvider.startLoading();
    setState(() {

    });
    String co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;

    // print("SELECT B.PR_CODE,C.PR_NAME FROM (MAIN_STOCK AS A INNER JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE) "
    //     + "INNER JOIN PRODUCT_MAST AS C ON B.CO_CODE = C.CO_CODE AND B.PR_CODE = C.PR_CODE WHERE A.CO_CODE = '" + co_code + "' AND B.IT_TYPE IN ('" + ItType + "') AND A.TAG_NO <> 'N' GROUP BY B.PR_CODE,C.PR_NAME ORDER BY PR_NAME");
    if (Platform.isAndroid) {
      String qery =
          "SELECT B.PR_CODE,C.PR_NAME FROM (MAIN_STOCK AS A INNER JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE) " +
              "INNER JOIN PRODUCT_MAST AS C ON B.CO_CODE = C.CO_CODE AND B.PR_CODE = C.PR_CODE WHERE A.CO_CODE = '" +
              co_code +
              "' AND A.TAG_NO <> 'N' ";
      if (ItType != '') {
        qery += " AND B.IT_TYPE = '" + ItType + "'";
      }
      qery += " GROUP BY B.PR_CODE,C.PR_NAME ORDER BY PR_NAME";
      dynamic result = await sqlConnection.queryDatabase(qery);

      category = jsonDecode(result);
      searchCategory = jsonDecode(result);
      print(category);
    } else {
      dynamic result = await MySQLService().getProductCategory(co_code, ItType);
      category = result[0];
      searchCategory = result[0];
    }

    loadingProvider.stopLoading();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tag Image",
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
                  hintText: "Search with product name",
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
                    searchCategory = category
                        .where((text) =>
                    text.containsKey("PR_NAME") &&
                        text["PR_NAME"].toString().toLowerCase().contains(
                            value.trim().toLowerCase()))
                        .toList();
                    setState(() {

                    });
                  }else{

                    searchCategory.clear();
                    searchCategory.addAll(category);
                    setState(() {
                    });
                  }
                }),
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
                      setState(() {
                        selectedOption = value!;
                        ItType = '';
                        getProductCategory();
                        print("Button value: $value");
                      });
                    },
                  ),
                  Text("All"),
                ],
              ),
              Row(
                children: [
                  Radio<int>(
                    value: 2,
                    activeColor: Color(0xFF006EB7),
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value!;
                        ItType = 'G';
                        getProductCategory();
                        print("Button value: $value");
                      });
                    },
                  ),
                  Text("Gold"),
                ],
              ),
              Row(
                children: [
                  Radio<int>(
                    value: 3,
                    activeColor: Color(0xFF006EB7),
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value!;
                        ItType = 'S';
                        getProductCategory();
                        print("Button value: $value");
                      });
                    },
                  ),
                  Text("Silver"),
                ],
              )
            ],
          ),
          Expanded(
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: GridView.builder(
                  // physics: NeverScrollableScrollPhysics(),
                  // shrinkWrap: true,
                  itemCount: searchCategory.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 10.0,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CategoryproductScreen(
                                      screenName: searchCategory[index]['PR_NAME'],
                                      prCode: searchCategory[index]['PR_CODE'],
                                      ItType: ItType,
                                    )));
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.blue[400]!,
                                  blurRadius: 8,
                                  spreadRadius: -5,
                                  offset: Offset(0, 2))
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              AppImage.ring,
                              scale: 15,
                            ),
                            Text(
                              searchCategory[index]['PR_NAME'],
                              style: GoogleFonts.nunito(
                                  color: Color(0xFF006EB7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }
}
