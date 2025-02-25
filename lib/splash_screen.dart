import 'package:animate_do/animate_do.dart';
import 'package:DataCareUltra/setting_screen.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin{
  late AnimationController animation;
  late Animation<double> _fadeInFadeOut;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    animation = AnimationController(vsync: this, duration: const Duration(seconds: 4),);
    _fadeInFadeOut = Tween<double>(begin: 0.0, end: 1).animate(animation);

    // getData();
    animation.forward().whenComplete(()async{
      // print("object ${await Preffrance().getString(Keys.HOST)}");
      if(await Preffrance().getString(Keys.HOST) != null && await Preffrance().getString(Keys.USERNAME) != null && await Preffrance().getString(Keys.PASSWORD) != null && await Preffrance().getString(Keys.DATABASE) != null){
        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=> const LoginScreen()));
      }else{
        print("Dataaaa");
        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=> SettingScreen(isFromSplash: true,)));
      }


    });

  }
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: Color(0xffeeeeee),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        // decoration: BoxDecoration(
        //   image: DecorationImage(image: AssetImage(AppImage.splashBackGround),fit: BoxFit.fitWidth)
        // ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ZoomIn(duration:Duration(seconds: 5),child: Image.asset(AppImage.appLogo,),from: 0.7,),
            // AnimatedContainer(duration: Duration(seconds: 2),
            // height: _height,
            // width: _width,
            // child: Image.asset(AppImage.appLogo,)),
            // SizedBox(height: 15,),
            ZoomIn(
              duration:Duration(seconds: 5),
              child: FadeTransition(opacity: _fadeInFadeOut,child: RichText(
                text: TextSpan(
                  text: 'D',
                  style: GoogleFonts.poppins(color: Colors.red,fontSize: 35,fontWeight: FontWeight.w400),
                  // style: TextStyle(color: Colors.red,fontSize: 28,fontFamily: GoogleFonts.poppins),
                  children: <TextSpan>[
                    TextSpan(text: 'ata', style: TextStyle(color: Colors.black)),
                    TextSpan(text: 'C', style: TextStyle(color: Colors.red)),
                    TextSpan(text: 'are', style: TextStyle(color: Colors.black)),
                    TextSpan(text: ' U', style: TextStyle(color: Colors.red)),
                    TextSpan(text: 'ltra', style: TextStyle(color: Colors.black)),

                  ],
                ),
              ) ,),
            )

          ],
        ),
      )
    );
  }

  void getData() async{
    print("Inside the getData");
    Future.delayed(Duration(seconds: 3),()async{
      print("Inside the getData 12");
      final prefs= await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: null),
      );
      // SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String? value = await prefs.getString(Keys.HOST);
      print("Value ${value}");
    });

  }


}
