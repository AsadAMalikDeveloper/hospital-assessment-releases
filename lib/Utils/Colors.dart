import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class color{
  static const Color blue = Color(0xff4e8de5);
  static const Color logoColor = Color(0xFF009FD0);
  static const Color bluePrimary = Color(0xFF108af9);
  static const Color lightGrey = Color(0xffe5e8ea);
  static const Color blueSecondary = Color(0xFF00569F);
  static const Color greyFontPrimary = Color(0xFF606060);
  static const Color greyFontSecondary= Color(0xFF727272);

}
returnColor(String card) {
  if(card.toString().toLowerCase()=="sapphire"){
    return Color(0xFF005a9c);//0xFF005a9c
  }else  if(card.toString().toLowerCase()=="deluxe"){
    return Color(0xFF8b0000);
  }else  if(card.toString().toLowerCase()=="gold"){
    return Color(0xFFc49102);//0xFFffa100
  }else  if(card.toString().toLowerCase()=="emerald"){
    return Color(0xFF237563);//0xFF1e6649
  }else{
    return Color(0xFF005a9c);//0xFF005a9c
  }
}
bool isUpdateRequired(String current, String min) {
  List<int> c = current.split('.').map(int.parse).toList();
  List<int> m = min.split('.').map(int.parse).toList();

  for (int i = 0; i < m.length; i++) {
    if (c[i] < m[i]) return true;
    if (c[i] > m[i]) return false;
  }
  return false;
}void showForceUpdateDialog(BuildContext context, String url) {
  print('objectURK ${url}');
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false, // 🔒 disable back
      child: AlertDialog(
        title: const Text("Update Required"),
        content: const Text(
          "A new version of the app is required. Please update to continue.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await downloadAndInstallApk(url);
            },
            child: const Text("Update"),
          )
        ],
      ),
    ),
  );
}
Future<void> downloadAndInstallApk(String url) async {
  final installStatus = await Permission.requestInstallPackages.status;
  if (!installStatus.isGranted) {
    final result = await Permission.requestInstallPackages.request();
    if (!result.isGranted) {
      await openAppSettings();
      return;
    }
  }

  // Use app's external files dir — no storage permission needed
  final dir = await getExternalStorageDirectory();
  final filePath = "${dir!.path}/update.apk";

  // Show progress if you want
  await Dio().download(
    url,
    filePath,
    onReceiveProgress: (received, total) {
      if (total != -1) {
        print('Download: ${(received / total * 100).toStringAsFixed(0)}%');
      }
    },
  );

  final result = await OpenFile.open(filePath);
  if (result.type != ResultType.done) {
    print('OpenFile error: ${result.message}');
  }
}
