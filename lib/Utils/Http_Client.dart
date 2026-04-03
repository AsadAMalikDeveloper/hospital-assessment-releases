import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    }

    return super.createHttpClient(context)
      ..findProxy = (uri) {
        return "PROXY localhost:8080";
      }
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}