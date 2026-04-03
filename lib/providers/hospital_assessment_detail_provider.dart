import 'package:flutter/material.dart';

import '../Utils/CheckInternetConnection.dart';
import '../Utils/ToastMessages.dart';
import '../models/api_response_model.dart';
import '../models/assessment_hospital_model.dart';
import '../models/criteria_type_model.dart';
import '../services/api_services.dart';

class HospitalAssessmentDetailProvider extends ChangeNotifier {
  final CheckConnectivity _connectivityService = CheckConnectivity();
  Toast toast = Toast();
  final _service = ApiService();

  bool? _isLoading;

  bool? get isLoading => _isLoading;

  bool? _isLoadingCriteria;

  bool? get isLoadingCriteria => _isLoadingCriteria;

  bool? _isLoadingCreateAssessment;

  bool? get isLoadingCreateAssessment => _isLoadingCreateAssessment;

  List<HospitalAssessmentModel>? _hospitalAssessmentDetailList = [];

  List<HospitalAssessmentModel>? get hospitalAssessmentDetailList =>
      _hospitalAssessmentDetailList;

  List<CriteriaTypeModel>? _criteriaTypeList = [];

  List<CriteriaTypeModel>? get criteriaTypeList => _criteriaTypeList;

  setLoader(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  setLoaderCriteria(bool loading) {
    _isLoadingCriteria = loading;
    notifyListeners();
  }

  setLoaderCreateAssessment(bool loading) {
    _isLoadingCreateAssessment = loading;
    notifyListeners();
  }

  getHospitalAssessmentDetail(BuildContext context, String spID) async {
    try {
      _hospitalAssessmentDetailList = [];
      setLoader(true);
      var jsonResponse = await _service.getHospitalsAssessmentDetail(spID);
      String? status = jsonResponse.status;
      if (status!.toLowerCase() == 'success') {
        _hospitalAssessmentDetailList = jsonResponse.data;
        setLoader(false);
      } else {
        _hospitalAssessmentDetailList = [];
        setLoader(false);
      }
    } catch (e) {
      _hospitalAssessmentDetailList = [];
      setLoader(false);
    }
  }

  getCriteriaType(BuildContext context) async {
    try {
      _criteriaTypeList = [];
      setLoaderCriteria(true);
      var jsonResponse = await _service.getCriteriaTypeList();
      String? status = jsonResponse.status;
      if (status!.toLowerCase() == 'success') {
        _criteriaTypeList = jsonResponse.data;
        setLoaderCriteria(false);
      } else {
        _criteriaTypeList = [];
        setLoaderCriteria(false);
      }
    } catch (e) {
      _criteriaTypeList = [];
      setLoaderCriteria(false);
    }
  }

  Future<APIResponse> createAssessment(
      BuildContext context, String spID, String cID) async {
    try {
      setLoaderCreateAssessment(true);
      var jsonResponse = await _service.createAssessment(spID, cID);
      setLoaderCreateAssessment(false);
      return jsonResponse;
    } catch (e) {
      setLoaderCreateAssessment(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }
}
