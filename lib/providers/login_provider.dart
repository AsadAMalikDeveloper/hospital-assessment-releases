import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../Utils/CheckInternetConnection.dart';
import '../Utils/Shared_Prefrences.dart';
import '../Utils/ToastMessages.dart';
import '../db_services/assessment_service.dart';
import '../db_services/db_helper.dart';
import '../models/api_response_model.dart';
import '../models/assessment_hospital_model.dart';
import '../models/login_model.dart';
import '../services/api_services.dart';
import '../views/screens/home/home_screen.dart';
import '../views/screens/hospitals/hospital_screens.dart';

class LoginProvider extends ChangeNotifier {
  Toast toast = Toast();
  final _service = ApiService();

  bool _isOffline = false;

  bool get isOffline => _isOffline;

  ///FOR NAVBAR//.
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  changeIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  changeIsOfflineStatus(bool isOffline) {
    _isOffline = isOffline;
    notifyListeners();
  }

  onItemTap(int index, BuildContext context) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();

      Navigator.pop(context);

      Future.microtask(() {
        switch (index) {
          case 0:
            Get.to(HomeScreen());
            break;
          case 1:
            Get.to(HospitalScreen());
            break;
          case 2:
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => CorporateHospitalsPage()),
            // );
            break;
          default:
            Get.to(HomeScreen());
        }
      });
    }
  }

  ///
  bool? _isLoading;

  bool? get isLoading => _isLoading;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CheckConnectivity _connectivityService = CheckConnectivity();

  setLoader(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  final AssessmentService _assessmentService = AssessmentService();
  Future<List<HospitalAssessmentModel>>? _assessmentsFuture;

  Future<List<HospitalAssessmentModel>>? get assessmentsFuture =>
      _assessmentsFuture;

  getUnSyncData() async {
    //await _assessmentService.syncSection(assessmentId, sectionId);

    _assessmentsFuture = _assessmentService.getAssessmentsWithSections();
  }

  Future<LoginModel?> login(
      BuildContext context, String email, String password) async {
    try {
      setLoader(true);
      var jsonResponse = await _service.login(email, password);
      String? status = jsonResponse.status;
      if (status == 'success') {
        await SharedPreferencesHelper.saveName(jsonResponse.name!);
        await SharedPreferencesHelper.saveUsername(jsonResponse.username!);
        await SharedPreferencesHelper.saveZoneCode(jsonResponse.zone_code!);
        await SharedPreferencesHelper.saveToken(jsonResponse.token!);
        await SharedPreferencesHelper.setIsLogin(true);
        setLoader(false);
        return jsonResponse;
      } else {
        setLoader(false);
        return jsonResponse;
      }
    } catch (e) {
      setLoader(false);
      return LoginModel(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> getChartData(BuildContext context) async {
    setLoader(true);
    final ApiService authService = ApiService();
    APIResponse jsonResponse = await authService.getChartData();

    if (jsonResponse.status!.toLowerCase() == 'success') {
      setLoader(false);
      return jsonResponse;
    } else {
      setLoader(false);
      return APIResponse(
          status: 'error',
          message: jsonResponse.message ?? "something went wrong");
    }
  }
}
