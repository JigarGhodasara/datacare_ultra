import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class PhonebookScreen extends StatefulWidget {
  const PhonebookScreen({Key? key}) : super(key: key);

  @override
  State<PhonebookScreen> createState() => _PhonebookScreenState();
}

class _PhonebookScreenState extends State<PhonebookScreen> {
  final sqlConnection = SqlConnection.getInstance();
  List<dynamic> phoneBook = [];
  List<dynamic> searchPhoneBook = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPhoneBookData();
  }

  void getPhoneBookData() async {
    String co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    String year =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_year;

    if (Platform.isAndroid) {
      String RsQry =
          "SELECT AC_CODE,AC_NAME,AC_CITY,AC_MOBILE,AC_AREA,AC_EMAIL,AC_ADD1,AC_ADD2,AC_ADD3 FROM AC_MAST WHERE CO_CODE = '" +
              co_code +
              "' AND AC_GR IN ('00','01','04','05','10','15','20') AND AC_MOBILE IS NOT NULL AND AC_MOBILE != '' ORDER BY AC_NAME";
      dynamic result = await sqlConnection.queryDatabase(RsQry);
      log("PhoneBook data $result");
      phoneBook = jsonDecode(result);
      searchPhoneBook = jsonDecode(result);
      // stockReport = jsonDecode(result);
    } else {
      dynamic result = await MySQLService().getPhoneBookData(co_code);
      log("PhoneBook data $result");
      phoneBook = result[0];
      searchPhoneBook = result[0];
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Phone Book",
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
                  hintText: "Search with account name",
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
                    searchPhoneBook = phoneBook
                        .where((text) =>
                    text.containsKey("AC_NAME") &&
                        text["AC_NAME"].toString().toLowerCase().contains(
                            value.trim().toLowerCase()))
                        .toList();
                    setState(() {

                    });
                  }else{

                    searchPhoneBook.clear();
                    searchPhoneBook.addAll(phoneBook);
                    setState(() {
                    });
                  }
                }),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: searchPhoneBook.length,
                  itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                            top: 15.0,
                            left: 15,
                            right: 15,
                            bottom: index == searchPhoneBook.length - 1 ? 15 : 0),
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
                                searchPhoneBook[index]["AC_NAME"],
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
                                        "Address",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Adress 2",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Adress 3",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Area",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "City",
                                        style: GoogleFonts.nunito(
                                            color: Color(0xFF006EB7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        "Email",
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
                                        searchPhoneBook[index]["AC_MOBILE"],
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchPhoneBook[index]["AC_ADD1"],
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchPhoneBook[index]["AC_ADD2"],
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchPhoneBook[index]["AC_ADD3"],
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchPhoneBook[index]["AC_AREA"],
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchPhoneBook[index]["AC_CITY"],
                                        style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 3.5,
                                      ),
                                      Text(
                                        searchPhoneBook[index]["AC_EMAIL"],
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
                                              '+91${searchPhoneBook[index]["AC_MOBILE"]}',
                                          text: "Hello");
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
                                          "tel://+91${searchPhoneBook[index]["AC_MOBILE"]}");
                                    },
                                    child: Image.asset(
                                      AppImage.telephone,
                                      scale: 18,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      launchUrlString(
                                          'sms:+91${searchPhoneBook[index]["AC_MOBILE"]}?body=Hello');
                                    },
                                    child: Image.asset(
                                      AppImage.chat,
                                      scale: 18,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Share.share('Hello');
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
