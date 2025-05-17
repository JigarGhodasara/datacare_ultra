import 'dart:convert';
import 'dart:io';

import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/setting_screen.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:http/http.dart' as http;

import 'company_year_selection.dart';
import 'mySql_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isShow = false;
  final sqlConnection = SqlConnection.getInstance();
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Container(
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
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 30.0, horizontal: 24.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SettingScreen(
                                                isFromSplash: false,
                                              )));
                                },
                                child: Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 40,
                                ))),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 46.0,
                            fontWeight: FontWeight.w800,
                          ), // TextStyle
                        ), // Text
                        Text(
                          "To DataCare Ultra",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.w300,
                          ), // TextStyle
                        ), // Text
                      ]),
                )),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
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
                        TextField(
                          controller: userNameController,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ), // Outline InputBorder
                              filled: true,
                              fillColor: Color(0xFFe7edeb),
                              hintText: "Username",
                              hintStyle: TextStyle(fontSize: 20),
                              prefixIcon: Image.asset(AppImage.user,
                                  scale: 20,
                                  color: Colors.blue[800])), // InputDecoration
                        ),
                        SizedBox(
                          height: 20,
                        ), // TextField
                        TextField(
                          obscureText: isShow,
                          controller: passwordController,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ), // Outline InputBorder
                              filled: true,
                              fillColor: Color(0xFFe7edeb),
                              hintText: "Password",
                              hintStyle: TextStyle(fontSize: 20),
                              prefixIcon: Image.asset(
                                AppImage.padlock,
                                scale: 20,
                                color: Colors.blue[800],
                              ),
                              suffixIcon: isShow
                                  ? GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isShow = false;
                                        });
                                      },
                                      child: Image.asset(
                                        AppImage.hide,
                                        scale: 20,
                                      ))
                                  : GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isShow = true;
                                        });
                                      },
                                      child: Image.asset(
                                        AppImage.show,
                                        scale: 20,
                                      ))),
                          // InputDecoration
                        ),
                        SizedBox(
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
                            String? db =
                                await Preffrance().getString(Keys.DATABASE);
                            print("object");
                            if (userNameController.text != '') {
                              if (Platform.isAndroid) {
                                var connectionStatus =
                                    await sqlConnection.connect(
                                  ip: host!.contains(":") ? host.split(":")[0].toString():host,
                                  port: host.contains(":") ? host.split(":")[1].toString():"1433",
                                  databaseName: 'NextMain',
                                  username: userName!,
                                  password: password!,
                                );
                                print("aaa $connectionStatus");
                                if (connectionStatus) {
                                  dynamic result =
                                      await sqlConnection.queryDatabase(
                                          "SELECT LOGIN_NAME,LOGIN_PWD,LOGIN_CATG FROM LOGIN_MAST WHERE LOGIN_NAME = '" +
                                              userNameController.text +
                                              "'");
                                  print(result);
                                  if (result != null) {
                                    print(result.runtimeType);
                                    List data = jsonDecode(result);
                                    Provider.of<CommonCompanyYearSelectionProvider>(context,listen: false).changeUserType(data[0]['LOGIN_CATG']);

                                    if (data.isNotEmpty) {
                                      if (data[0]['LOGIN_PWD'] == null) {

                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    CompanyYearSelection()));
                                      } else {
                                        if (data[0]['LOGIN_PWD'] ==
                                            passwordController.text) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      CompanyYearSelection()));
                                        }else{
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                "Please verify your password"),
                                          ));
                                        }
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content:
                                            Text("Please verify your username"),
                                      ));
                                    }
                                  }
                                }

                                // var settings = new ConnectionSettings(
                                //     host: host!,
                                //     port: 1433,
                                //     user: userName,
                                //     password: password,
                                //     db: db);
                                // var conn = await MySqlConnection.connect(settings);
                                // var connectionStatus = await sqlConnection.connect(
                              } else {
                              dynamic isConnect =  MySQLService().connectToDatabase(dbName: "NextMain");
                              if(await  isConnect){
                                dynamic result = await MySQLService().Login(userNameController.text);
                                print("Login Data ${result}");
                                if (result != null) {
                                  // print(result.runtimeType);
                                  List data = result[0];
                                  Provider.of<CommonCompanyYearSelectionProvider>(context,listen: false).changeUserType(data[0]['LOGIN_CATG']);
                                  print("JigarData ${data}");
                                  if (data.isNotEmpty) {
                                    if (data[0]['LOGIN_PWD'] == null) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CompanyYearSelection()));
                                    } else {
                                      if (data[0]['LOGIN_PWD'] ==
                                          passwordController.text) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    CompanyYearSelection()));
                                      }else{
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              "Please verify your password"),
                                        ));
                                      }
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content:
                                      Text("Please verify your username"),
                                    ));
                                  }
                                }
                              }
                              }
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("Please Enter Atleast UserName"),
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
                                "Login",
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
      ), // Container,
    ));
  }
}
