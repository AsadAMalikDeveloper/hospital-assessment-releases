import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hospital_assessment_slic/providers/assessment_provider.dart';
import 'package:hospital_assessment_slic/providers/hospital_assessment_detail_provider.dart';
import 'package:hospital_assessment_slic/providers/login_provider.dart';
import 'package:hospital_assessment_slic/providers/state_district_provider.dart';
import 'package:hospital_assessment_slic/views/screens/splash/splash_screen.dart';

import 'package:provider/provider.dart';

import 'Utils/Http_Client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ⭐ REQUIRED
  await ScreenUtil.ensureScreenSize();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.blue,
    statusBarIconBrightness: Brightness.light,
  ));
  HttpOverrides.global = new MyHttpOverrides();
  runApp(const MyApp());
  //DependencyInjection.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        useInheritedMediaQuery: true,
        designSize: const Size(428, 926),
        builder: (BuildContext context, child) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => LoginProvider()),
              ChangeNotifierProvider(create: (context) => StateDistrictProvider()),
              ChangeNotifierProvider(create: (context) => HospitalAssessmentDetailProvider()),
              ChangeNotifierProvider(create: (context) => AssessmentProvider()),
            ],
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
                useMaterial3: true,
              ),
              home: Splash(),
            ),
          );
        });
  }
}
