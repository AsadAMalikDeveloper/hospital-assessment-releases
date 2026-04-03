import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Colors.dart';
class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    _connectivity.onConnectivityChanged.listen(_updateConnectionState);
  }

  void _updateConnectionState(List<ConnectivityResult> connectivityResult) {
    if (connectivityResult[0] == ConnectivityResult.none) {
      Get.dialog( WillPopScope(
        onWillPop: () {
          return Future<bool>.value(false);
        },
        child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi, size: 60, color: Colors.red.withOpacity(0.6)),
                    const SizedBox(height: 10),
                    const Text('No Internet Connection',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: Colors.red)),
                    const SizedBox(height: 10),
                    Text('PLEASE CONNECT TO INTERNET',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: color.blue)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )),
      ),barrierDismissible: false);
      // Get.rawSnackbar(
      //     messageText: Text(
      //       'PLEASE CONNECT TO INTERNET',
      //       style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
      //     ),
      //     isDismissible: false,
      //     duration: Duration(days: 1),
      //     backgroundColor: Colors.red[400]!,
      //     icon: Icon(
      //       Icons.wifi,
      //       color: Colors.white,
      //       size: 35,
      //     ),
      //     margin: EdgeInsets.zero,
      //     snackStyle: SnackStyle.GROUNDED);
    } else {
     if(Get.isDialogOpen??false){
       Navigator.pop(Get.overlayContext!, true);
       Get.rawSnackbar(
           messageText: Text(
             'INTERNET RESTORED',
             style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
           ),
           isDismissible: false,
           duration: Duration(seconds: 2),
           backgroundColor: Colors.green[400]!,
           icon: Icon(
             Icons.wifi,
             color: Colors.white,
             size: 35,
           ),
           margin: EdgeInsets.zero,
           snackStyle: SnackStyle.GROUNDED);
     }
    }
  }
}
