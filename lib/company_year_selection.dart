import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/dashboard_screen.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/tagEstimate_screen.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class CompanyYearSelection extends StatefulWidget {
  const CompanyYearSelection({Key? key}) : super(key: key);

  @override
  State<CompanyYearSelection> createState() => _CompanyYearSelectionState();
}

class _CompanyYearSelectionState extends State<CompanyYearSelection> {
  final sqlConnection = SqlConnection.getInstance();
  // late CommonCompanyYearSelectionProvider commonCompanyYearSelectionProvider;
  List<dynamic> companyName = [
    // {"CoCode": '', "NameT": '', "Show": "Select Company Name"}
  ];
  List<dynamic> location = [
    // {"LC_CODE": '', "LC_NAME": '', "Show": "Select Your Location"}
  ];
  List<dynamic> year = [
    // {"Year": "Select Your Year"}
  ];
  dynamic selectedCompany = "";
  dynamic sName = "";
  dynamic selectedLocation = "";
  dynamic selectedYear = "";
  dynamic data;
  dynamic locationData;
  dynamic yearData;
  late LoadingProvider loadingProvider;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // commonCompanyYearSelectionProvider =  ;
    loadingProvider =  Provider.of<LoadingProvider>(
        context,
        listen: false);
    // loadingProvider.startLoading();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update your state here
      getData();
    });

  }

  getData() async {
    loadingProvider.startLoading();
  if (Platform.isAndroid) {
      data = await sqlConnection.queryDatabase(
          "SELECT CO_CODE As CoCode,CO_NAME as NameT,CO_SNAME FROM CO_MAST ORDER BY CO_CODE");

      print("Year Data");
      print(data);
      // Provider.of<CommonCompanyYearSelectionProvider>(
      //     context,
      //     listen: false)
      //     .changeCO_year(selectedYear);
      companyName.addAll(jsonDecode(data).map((val) {
        print("aabbcc ${val['CO_SNAME']}");
        return {
          "CoCode": val['CoCode'].toString(),
          "NameT": val['NameT'],
          "Show": "${val['CoCode']}-${val['NameT']}",
          "sName": val['CO_SNAME'] ?? ''
        };
      }).toList());
      selectedCompany = companyName[0]['Show'];
      sName = companyName[0]['sName'];

      locationData = await sqlConnection.queryDatabase(
          "SELECT LC_CODE,LC_NAME FROM LOCT_MAST WHERE CO_CODE = '" +
              jsonDecode(data)[0]["CoCode"] +
              "'AND LC_CODE <> '' ORDER BY LC_CODE");
      location.addAll(jsonDecode(locationData).map((val) {
        return {
          "LC_CODE": val['LC_CODE'].toString(),
          "LC_NAME": val['LC_NAME'],
          "Show": "${val['LC_CODE']}-${val['LC_NAME']}"
        };
      }).toList());
      selectedLocation = location[0]['Show'];

      yearData = await sqlConnection.queryDatabase(
          "SELECT CO_YEAR As Year,OP_DATE,CL_DATE FROM YEAR_MAST WHERE CO_CODE = '" +
              jsonDecode(data)[0]["CoCode"] +
              "' ORDER BY CO_YEAR desc");
      year.addAll(jsonDecode(yearData));
      selectedYear = year[0]['Year'].toString();
    } else {
      dynamic companyData = await MySQLService().getCompanyData();
      data = companyData[0];
      print("data");
      print("$data");
      companyName.addAll(data.map((val) {
        return {
          "CoCode": val['CoCode'].toString(),
          "NameT": val['NameT'],
          "Show": "${val['CoCode']}-${val['NameT']}",
          "sName": val['CO_SNAME']
        };
      }).toList());
      print("${companyName}");
      selectedCompany = companyName[0]['Show'];
      sName = companyName[0]['sName'];

      print("com ${data[0]["CoCode"]}");

      dynamic locattionData =
          await MySQLService().getCompanyLocation(data[0]["CoCode"]);
      locationData = locattionData[0];
      location.addAll(locationData.map((val) {
        return {
          "LC_CODE": val['LC_CODE'].toString(),
          "LC_NAME": val['LC_NAME'],
          "Show": "${val['LC_CODE']}-${val['LC_NAME']}"
        };
      }).toList());
      selectedLocation = location[0]['Show'];

      dynamic yearsData = await MySQLService().getYears(data[0]["CoCode"]);
      yearData = yearsData[0];
      year.addAll(yearData);
      selectedYear = year[0]['Year'].toString();
    }
    setState(() {});
    loadingProvider.stopLoading();
    print("companyName ${selectedCompany}");
    print("companyName ${selectedLocation}");
    print("companyName ${selectedYear}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
          // maxWidth: MediaQuery.of(context).size.width,
        ), // BoxConstraints
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue[800]!,
              Colors.blue[600]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.centerRight,
          ), // LinearGradient
        ), // BoxDecoration
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                flex: 1,
                child: Row(
                  children: [
                    GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.keyboard_arrow_left_rounded,
                          color: Colors.white,
                          size: 50,
                        )),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "COMPANY & YEAR SELECTION",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                )),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        topLeft: Radius.circular(30))),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 45.0),
                          child: Image.asset(
                            AppImage.appLogo,
                            scale: 2,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: Color(0xFFe7edeb),
                              borderRadius: BorderRadius.circular(8.0)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8),
                            child: Row(
                              children: [
                                Image.asset(AppImage.businessAndTrade,
                                    scale: 20, color: Colors.blue[800]),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        canvasColor: Color(0xfff1f1f1),
                                      ),
                                      child: DropdownButton2(
                                          dropdownStyleData:
                                              DropdownStyleData(),
                                          isExpanded: true,
                                          value: selectedCompany,
                                          items:
                                              companyName.map((dynamic items) {
                                            return DropdownMenuItem(
                                              value: items['Show'],
                                              child: Text(items['Show']),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            selectedCompany = value;
                                            companyName.forEach((data){
                                              if(data['Show'] == value){
                                                sName = data['sName'];
                                              }
                                            });
                                            setState(() {});
                                          }),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),

                        Container(
                          decoration: BoxDecoration(
                              color: Color(0xFFe7edeb),
                              borderRadius: BorderRadius.circular(8.0)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8),
                            child: Row(
                              children: [
                                Image.asset(AppImage.branch,
                                    scale: 20, color: Colors.blue[800]),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton2(
                                        isExpanded: true,
                                        value: selectedLocation,
                                        items: location.map((dynamic items) {
                                          return DropdownMenuItem(
                                            value: items['Show'],
                                            child: Text(items['Show']),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          selectedLocation = value;
                                          setState(() {});
                                        }),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),

                        Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFFe7edeb),
                              borderRadius: BorderRadius.circular(8.0)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8),
                            child: Row(
                              children: [
                                Image.asset(AppImage.calendar,
                                    scale: 20, color: Colors.blue[800]),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton2(
                                        isExpanded: true,
                                        value: selectedYear,
                                        items: year.map((dynamic items) {
                                          return DropdownMenuItem(
                                            value: items['Year'],
                                            child: Text(items['Year']),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          selectedYear = value;
                                          setState(() {});
                                        }),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 40,
                        ), // TextField
                        GestureDetector(
                          onTap: () async {
                            String? host =
                                await Preffrance().getString(Keys.HOST);
                            String? userName =
                                await Preffrance().getString(Keys.USERNAME);
                            String? password =
                                await Preffrance().getString(Keys.PASSWORD);

                            print("Selected Year ${selectedYear}");
                            var newString;
                            if(selectedYear.toString().contains("-")){
                              String a = selectedYear.toString().split('-')[0];
                            newString = a.substring(a.length - 2);
                            }else {
                              newString = selectedYear.substring(selectedYear.length - 4);
                            }

                            print("newString");
                            print(newString);
                            String dataBaseName = "Next" + newString;
                            print("Database Name $dataBaseName");
                            Preffrance().setString(Keys.DATABASE, dataBaseName);
                            String? db =
                                await Preffrance().getString(Keys.DATABASE);
                            dynamic connectionStatus;
                            if (Platform.isAndroid) {
                              sqlConnection.disconnect();
                              connectionStatus = sqlConnection
                                  .connect(
                                      ip:host!.contains(":") ? host.split(":")[0].toString():host,
                                      port: host.contains(":") ? host.split(":")[1].toString():"1433",
                                      databaseName: db!,
                                      username: userName!,
                                      password: password!)
                                  .catchError((onError) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text(
                                      "Database can't find please select another year.."),
                                ));
                              });
                            } else {
                              connectionStatus =
                                  MySQLService().connectToDatabase();
                            }

                            // print("New connection ${await connectionStatus}");
                            if (await connectionStatus) {
                              Provider.of<CommonCompanyYearSelectionProvider>(
                                      context,
                                      listen: false)
                                  .changeCO_name(
                                      selectedCompany.toString().split('-')[1]);
                              Provider.of<CommonCompanyYearSelectionProvider>(
                                      context,
                                      listen: false)
                                  .changeCO_code(
                                      selectedCompany.toString().split('-')[0]);
                              Provider.of<CommonCompanyYearSelectionProvider>(
                                      context,
                                      listen: false)
                                  .changeLC_code(selectedLocation
                                      .toString()
                                      .split('-')[0]);
                              Provider.of<CommonCompanyYearSelectionProvider>(
                                      context,
                                      listen: false)
                                  .changeCO_year(selectedYear);
                              print("click submit $sName");

                              Provider.of<CommonCompanyYearSelectionProvider>(
                                  context,
                                  listen: false)
                                  .changeCoSName(sName == null ? "":sName );
                              dynamic SoftTypedata;
                              if (Platform.isAndroid) {
                                String softTypeQuery =
                                    "SELECT SUBSTRING(REF_NO,7,1) As SoftType,SUBSTRING(REF_NO,1,1) AS DemoType FROM HDD_MAST";
                                log(softTypeQuery);
                                dynamic result = await sqlConnection
                                    .queryDatabase(softTypeQuery);
                                SoftTypedata = jsonDecode(result);
                              } else {
                                dynamic sTypeData =
                                    await MySQLService().getSOftType();
                                SoftTypedata = sTypeData[0];
                              }
                              print("SoftType Data ${SoftTypedata}");

                              String sType = SoftTypedata[0]["SoftType"] ;
                              String dType = SoftTypedata[0]["DemoType"];
                              Provider.of<CommonCompanyYearSelectionProvider>(
                                  context,
                                  listen: false)
                                  .changesType(sType);
                              Provider.of<CommonCompanyYearSelectionProvider>(
                                  context,
                                  listen: false)
                                  .changedType(dType);
                              print("SSType ${sType}");
                              print("DDType ${dType}");

                              if (sType == "E" ||
                                  sType == "U" ||
                                  sType == "P" ||
                                  sType == "A" ||
                                  dType == "E" ||
                                  dType== "U" ||
                                  dType== "P" ||
                                  dType== "A"
                              ) {
                                print("Inside softType");


                                String userType =
                                    Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
                                        .userType;
                                print("UserType ${userType}");
                                if(userType == "A"){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => DashboardScreen()));
                                }else {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => TagestimateScreen()));
                                }

                              }
                              else if((sType == "B" || sType == "S" || dType == "B" || dType == "s") && Platform.isAndroid){
                                String userType =
                                    Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
                                        .userType;
                                print("UserType ${userType}");
                                if(userType == "A"){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => DashboardScreen()));
                                }else {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => TagestimateScreen()));
                                }
                              }
                              else{
                                // ScaffoldMessenger.of(context)
                                //     .showSnackBar(const SnackBar(
                                //   content: Text(
                                //       "Please upgrade your software version."),
                                // ));
                                showUpgradeRequiredDialog(context);
                              }

                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    "Database can't find please select another year.."),
                              ));
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: AppColor.PRIMARY_COLOR,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                            child: Center(
                                child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                "Submit",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 22),
                              ),
                            )),
                          ),
                        )
                      ],
                    )), // ,
              ),
            )
          ],
        ),
      ),
    );
  }
}
