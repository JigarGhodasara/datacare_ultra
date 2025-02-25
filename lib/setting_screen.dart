import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class SettingScreen extends StatefulWidget {
  bool isFromSplash;
   SettingScreen({Key? key,required this.isFromSplash}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  TextEditingController ipController = TextEditingController();
  TextEditingController userNameController = TextEditingController(text: 'sa');
  TextEditingController passwordController = TextEditingController(text: 'datacare@123');
  TextEditingController databaseController = TextEditingController(text: 'NextMain');
  bool isShow = true;
  final _formKey = GlobalKey<FormState>();
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDataFromStorage();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body:  Container(
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
                widget.isFromSplash? SizedBox(): GestureDetector(onTap: ()=> Navigator.pop(context),child: Icon(Icons.keyboard_arrow_left_rounded,color: Colors.white,size: 50,)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("IP ADDRESS SETTING",style: TextStyle(fontSize: 20,color: Colors.white,fontWeight: FontWeight.w600),)
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
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        topLeft: Radius.circular(30))),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SingleChildScrollView(
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
                          TextFormField(
                            controller: ipController,
                            style: TextStyle(fontSize: 20),
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ), // Outline InputBorder
                                filled: true,
                                fillColor: Color(0xFFe7edeb),
                                hintText: "IP Address",
                                hintStyle: TextStyle(fontSize: 20),
                                prefixIcon: Image.asset(AppImage.ipaddress,
                                    scale: 20,
                                    color: Colors.blue[800])), // InputDecoration
                            validator: (value){
                              if(value == ''){
                                return 'Please enter UserName';
                              }
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            style: TextStyle(fontSize: 20),
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
                         validator: (value){
                              if(value == ''){
                                return 'Please enter UserName';
                              }
                         },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            style: TextStyle(fontSize: 20),
                            controller: passwordController,
                            obscureText: isShow,
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
                                suffixIcon: !isShow
                                    ? GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isShow = !isShow;
                                      });
                                    },
                                    child: Image.asset(
                                      AppImage.hide,
                                      scale: 20,
                                    ))
                                    : GestureDetector(
                                    onTap: () {
                                      print(isShow);
                                      setState(() {
                                        isShow = !isShow;
                                      });
                                    },
                                    child: Image.asset(
                                      AppImage.show,
                                      scale: 20,
                                    ))),
                            validator: (value){
                              if(value != ""){
                                return 'Please enter password';
                              }
                            },
                            // InputDecoration
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            style: TextStyle(fontSize: 20),
                            controller: databaseController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ), // Outline InputBorder
                                filled: true,
                                fillColor: Color(0xFFe7edeb),
                                hintText: "Database",
                                hintStyle: TextStyle(fontSize: 20),
                                prefixIcon: Image.asset(AppImage.database,
                                    scale: 20,
                                    color: Colors.blue[800]),
                      
                            ),
                            validator: (value){
                              if(value != ''){
                                return 'Please enter Database Name';
                              }
                            },// InputDecoration
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            height: 40,
                          ), // TextField
                          GestureDetector(
                            onTap: ()async{
                      
                              if(ipController.text != '' && userNameController.text != '' && passwordController.text != '' && databaseController.text != ''){
                                Preffrance().setString(Keys.HOST, ipController.text);
                                Preffrance().setString(Keys.USERNAME, userNameController.text);
                                Preffrance().setString(Keys.PASSWORD, passwordController.text);
                                Preffrance().setString(Keys.DATABASE, databaseController.text);
                                Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=> const LoginScreen()));


                                print("${await Preffrance().getString(Keys.HOST)}");
                                print("${await Preffrance().getString(Keys.USERNAME)}");
                                print("${await Preffrance().getString(Keys.PASSWORD) }");
                                print("${await Preffrance().getString(Keys.DATABASE)}");
                              }else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text("Please enter all details."),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                      ),
                    )), // ,
              ),
            )
          ],
        ),
      ),
    );
  }

  void getDataFromStorage() async{
  String? host = await Preffrance().getString(Keys.HOST);
  String? username = await Preffrance().getString(Keys.USERNAME);
  String? dbPass = await Preffrance().getString(Keys.PASSWORD);
  String? dbName = await Preffrance().getString(Keys.DATABASE);
  if(host != '' || host != null){
    ipController.text = host!;

  }
  if(username != "" || username != null){
  userNameController.text = username ?? "";
  }
  if(dbPass != "" || dbPass != null){
    passwordController.text = dbPass ?? "";
  }
  if(dbName != "" || dbName != null){
  databaseController.text = dbName ?? "";
  }
  setState(() {
  });
  }
}
