import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/api_response_model.dart';
import '../services/api_services.dart';
import '../views/screens/splash/splash_screen.dart';
import 'Shared_Prefrences.dart';

class GlobalController extends GetxController {
  String feature1 = 'feature1',
      feature2 = 'feature2',
      feature3 = 'feature3',
      feature4 = 'feature4';

//var isShow =0.abs();
  @override
  void onInit() {
    // TODO: implement onInit
    //isShow++;
    super.onInit();
  }
}

class Glob {
  static Glob? _instance;

  factory Glob() => _instance ??= Glob._();

  //One instance, needs factory
  Glob._();

  static const BASE_URL =
      'https://eclaim2.slichealth.com/ords/ihmis_admin/hospital';

  String getBaseUrl() {
    return BASE_URL;
  }

  checkToken(BuildContext context) async {
    final ApiService authService = ApiService();
    APIResponse jsonResponse = await authService.checkToken();
    bool isValid = false;
    if (jsonResponse.message!.toLowerCase() == 'invalid token') {
      isValid = false;
    } else {
      isValid = true;
    }
    if (isValid == false) {
      sessionExpireDialog(context);
    }
  }
}

showLoaderDialog(BuildContext context, String message) {
  AlertDialog alert = AlertDialog(
    content: Row(
      children: [
        const CircularProgressIndicator(
          color: Colors.black,
        ),
        Expanded(child: Text(" $message...")),
      ],
    ),
  );
  showDialog(
    barrierDismissible: false,
    context: context,
    useRootNavigator: true,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

showErrorDialogCompleteAssessment(BuildContext context, APIResponse response) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error,
                        size: 60, color: Colors.red.withOpacity(0.6)),
                    const SizedBox(height: 10),
                    Text(response.message ?? "",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.red)),
                    SizedBox(height: 10),
                    Text(
                        'Questions: ${response.responses}/${response.total_questions}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            color: Colors.black)),
                    Text(
                        'Pictures: ${response.pictures}/${response.total_pictures}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            color: Colors.black)),
                    Text(
                        'Bed Capacity: ${response.given_bed}/${response.total_bed}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            color: Colors.black)),
                    Text(
                        'Staff: ${response.given_staff}/${response.total_staff}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            color: Colors.black)),
                    Text('Assessment Form: ${response.assessment_form}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            color: Colors.black)),
                    const SizedBox(height: 20),
                    buildDialogButton(
                        buttonText: 'Ok',
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
            ));
      });
}

sessionExpireDialog(BuildContext context) async {
  await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/expired.png',
                          height: 200, fit: BoxFit.contain),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Your Session has expired',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.black)),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Please login again to use our services.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                letterSpacing: 0.5,
                                color: Colors.black)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: buildDialogButton(
                              buttonText: 'Login',
                              textColor: Colors.black,
                              onPressed: () {
                                Navigator.pop(context);
                                logout(context);
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )),
        );
      });
}

Future<void> logout(BuildContext context) async {
  await SharedPreferencesHelper.saveName('');
  await SharedPreferencesHelper.saveUsername('');
  await SharedPreferencesHelper.saveZoneCode('');
  await SharedPreferencesHelper.saveToken('');
  await SharedPreferencesHelper.setIsLogin(false);
  Get.offAll(Splash());
}

Widget buildDialogButton(
    {required String buttonText,
    Color buttonColor = Colors.white,
    IconData? icon,
    Color textColor = const Color(0xFF999999),
    required VoidCallback onPressed}) {
  if (icon != null) {
    return ElevatedButton.icon(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(const EdgeInsets.all(15)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          )),
          elevation: MaterialStateProperty.all(3),
          backgroundColor: MaterialStateProperty.all(buttonColor),
          overlayColor: (buttonColor == Colors.white)
              ? MaterialStateProperty.all(Colors.black)
              : null,
        ),
        icon: Icon(icon, color: textColor),
        label: Text(buttonText,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: textColor)),
        onPressed: onPressed);
  } else {
    return ElevatedButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(const EdgeInsets.all(15)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          )),
          elevation: MaterialStateProperty.all(3),
          backgroundColor: MaterialStateProperty.all(buttonColor),
          overlayColor: (buttonColor == Colors.white)
              ? MaterialStateProperty.all(Colors.black)
              : null,
        ),
        child: Text(buttonText,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: textColor)),
        onPressed: onPressed);
  }
}
