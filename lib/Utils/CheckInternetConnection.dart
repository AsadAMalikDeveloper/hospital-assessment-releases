import 'package:connectivity_plus/connectivity_plus.dart';

class CheckConnectivity {
  late List<ConnectivityResult> _connectivityResult;
  late Connectivity _connectivity;

  Future<bool?> checkConnection() async {
    _connectivity = Connectivity();
    final List<ConnectivityResult> result =
        await _connectivity.checkConnectivity();
    _connectivityResult = result;
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _connectivityResult = result;
    });
    for (int i = 0; i < _connectivityResult.length; i++) {
      //print("dsds ${_connectivityResult[i]}");
    }
    if (_connectivityResult[0] == ConnectivityResult.none) {
      return false;
    } else {
      return true;
    }
  }
}
