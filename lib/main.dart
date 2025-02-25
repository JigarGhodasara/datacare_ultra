import 'package:DataCareUltra/loading_widget.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers:  [
      ChangeNotifierProvider(create: (_) => CommonCompanyYearSelectionProvider()),
      ChangeNotifierProvider(create: (_) => LoadingProvider())
    ],child: MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          child: Loading(child:child!),
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        );
      },
      title: 'DataCareUltra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: const SplashScreen(),
    ),);
  }
}

