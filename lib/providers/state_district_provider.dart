import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Utils/CheckInternetConnection.dart';
import '../Utils/ToastMessages.dart';
import '../db_services/db_helper.dart';
import '../models/districts_model.dart';
import '../models/hospital_model.dart';
import '../models/state_model.dart';
import '../services/api_services.dart';

class StateDistrictProvider extends ChangeNotifier {
  // CheckConnectivity checkConnectivity = CheckConnectivity();
  final CheckConnectivity _connectivityService = CheckConnectivity();
  Toast toast = Toast();
  final _service = ApiService();

  bool? _isLoading;

  bool? get isLoading => _isLoading;

  bool? _isLoadingDistricts;

  bool? get isLoadingDistricts => _isLoadingDistricts;

  List<StateModel>? _stateList=[];

  List<StateModel>? get stateList => _stateList;
  List<DistrictModel>? _districtsList=[];

  List<DistrictModel>? get districtsList => _districtsList;

  bool? _isLoadingHospitals;

  bool? get isLoadingHospitals => _isLoadingHospitals;
  List<HospitalModel>? _hospitalList=[];

  List<HospitalModel>? get hospitalList => _hospitalList;

  void disposeValues() {
    _stateList = [];
    _districtsList = [];
    _hospitalList = [];
  }

  setLoader(bool loading) {
    _isLoading = loading;
  }

  setLoaderDistricts(bool loading) {
    _isLoadingDistricts = loading;
    notifyListeners();
  }

  setLoaderHospitals(bool loading) {
    _isLoadingHospitals = loading;
    notifyListeners();
  }

  DatabaseHelper _databaseHelper = DatabaseHelper();

  getStateList(BuildContext context, bool isOffline) async {
    try {
      if (isOffline) {
        disposeValues();
        setLoader(true);
        var jsonResponse = await _databaseHelper.getAllStates();

        _stateList = jsonResponse;
        setLoader(false);
        notifyListeners();
      } else {
        disposeValues();
        setLoader(true);
        var jsonResponse = await _service.getStates();
        String? status = jsonResponse.status;
        if (status!.toLowerCase() == 'success') {
          _stateList = jsonResponse.data;
          setLoader(false);
          notifyListeners();
        } else {
          _stateList = [];
          setLoader(false);
          notifyListeners();
        }
      }
    } catch (e) {
      setLoader(false);
      _stateList = [];
      notifyListeners();
    }
  }

  getDistrictsList(BuildContext context, String? stateID, String type,
      bool isOffline) async {
    try {
      if (isOffline) {
        _districtsList = [];
        setLoaderDistricts(true);
        var jsonResponse = await _databaseHelper.getAllDistricts(stateID!);
        _districtsList = jsonResponse;
        setLoaderDistricts(false);
      } else {
        _districtsList = [];
        setLoaderDistricts(true);
        var jsonResponse = await _service.getDistricts(stateID!, type);
        String? status = jsonResponse.status;
        if (status!.toLowerCase() == 'success') {
          _districtsList = jsonResponse.data;
          setLoaderDistricts(false);
        } else {
          _districtsList = [];
          setLoaderDistricts(false);
        }
      }
    } catch (e) {
      _districtsList = [];
      setLoaderDistricts(false);
    }
  }

  getHospitalList(BuildContext context, String distID,String type, bool isOffline) async {
    try {
      if (isOffline) {
        _hospitalList = [];
        setLoaderHospitals(true);
        var jsonResponse =
            await _databaseHelper.getAllHospital(int.parse(distID));
        _hospitalList = jsonResponse;
        setLoaderHospitals(false);
      } else {
        _hospitalList = [];
        setLoaderHospitals(true);
        var jsonResponse = await _service.getHospitals(distID, type);
        String? status = jsonResponse.status;
        if (status!.toLowerCase() == 'success') {
          _hospitalList = jsonResponse.data;
          setLoaderHospitals(false);
        } else {
          _hospitalList = [];
          setLoaderHospitals(false);
        }
      }
    } catch (e) {
      _hospitalList = [];
      setLoaderHospitals(false);
    }
  }
}
