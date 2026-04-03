import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart';

import '../Utils/Shared_Prefrences.dart';
import '../Utils/globle_controller.dart';
import '../models/api_response_model.dart';
import '../models/assessment_hospital_model.dart';
import '../models/bed_capacity_model.dart';
import '../models/criteria_type_model.dart';
import '../models/districts_model.dart';
import '../models/hospital_model.dart';
import '../models/login_model.dart';
import '../models/picture_get_model.dart';
import '../models/section_model.dart';
import '../models/special_document_model.dart';
import '../models/staff_model.dart';
import '../models/state_model.dart';
class VersionModel {
  final String minVersion;
  final String latestVersion;
  final String apkUrl;
  final bool forceUpdate;

  VersionModel({
    required this.minVersion,
    required this.latestVersion,
    required this.apkUrl,
    required this.forceUpdate,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      minVersion: json['min_version'],
      latestVersion: json['latest_version'],
      apkUrl: json['apk_url'],
      forceUpdate: json['force_update'],
    );
  }
}
class ApiService {
  String API = Glob().getBaseUrl();
  Future<VersionModel?> checkAppVersion() async {
    try {
      Response response = await get(
        Uri.parse('$API/check_app_version'),
      ).timeout(const Duration(seconds: 10));
      print('objectCHECKVERSION ${response.body}');
      if (response.statusCode == 200) {
        return VersionModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("version error $e");
    }
    return null;
  }
  Future<LoginModel> login(String email, String password) async {
    try {
      Response response =
          await post(Uri.parse('$API/login'), headers: <String, String>{
        'user_id': email.toString(),
        'password': password.toString(),
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        var data = LoginModel.fromJson(res);
        return data;
      } else if (response.statusCode == 500) {
        return LoginModel(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return LoginModel(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return LoginModel(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> createAssessment(String spID, String cID) async {
    try {
      Response response = await post(Uri.parse('$API/create_assessment'),
          headers: <String, String>{
            'sp_id': spID,
            'criteria_id': cID,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        var data = APIResponse.fromMap(res);
        return data;
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> completeAssessment(String aID) async {
    try {
      Response response = await post(Uri.parse('$API/complete_assessment'),
          headers: <String, String>{
            'assessment_id': aID,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print('object $res');
        var data = APIResponse.fromMap(res);

        return data;
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }
// ── Add to your existing ApiService class ─────────────────────────────────
// Mirrors uploadImage() exactly — headers for params, raw binary body.
// Only difference: chunked write loop for upload progress tracking.

  Future<APIResponse> uploadVideo(
      String aid,
      String qid,
      String cSectionID,
      String fileName,
      Uint8List videoBytes, {
        Function(double progress)? onProgress,
      }) async {
    try {
      // ── Option A: Simple upload (no progress) ─────────────────────────
      // Identical to uploadImage — use this if you don't need progress bar.
      // Swap comment blocks with Option B below to enable progress.
      //
      // Response response = await post(
      //   Uri.parse('https://apps.slichealth.com/ords/ihmis_admin/assesment/video'),
      //   body: videoBytes,
      //   headers: <String, String>{
      //     'assessment_id': aid,
      //     'Content-Type': 'video/mp4',
      //     'qid': qid,
      //     'c_sec_id': cSectionID,
      //     'file_name': fileName,
      //     'token': await SharedPreferencesHelper.getToken(),
      //   },
      // ).timeout(const Duration(minutes: 5));

      // ── Option B: Chunked upload with live progress ───────────────────
      // Uses dart:io HttpClient directly (no extra packages).
      // Sends the same headers as uploadImage, just streams the body
      // in 64 KB chunks so we can report progress after each chunk.

      final token = await SharedPreferencesHelper.getToken();
      final uri = Uri.parse(
          '$API/insert_image');

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(minutes: 5);

      final request = await httpClient.openUrl('POST', uri);

      // ── Headers — exactly matching uploadImage pattern ─────────────────
      request.headers.set('assessment_id', aid);
      request.headers.set('Content-Type', 'video/mp4');
      request.headers.set('qid', qid);
      request.headers.set('c_sec_id', cSectionID);
      request.headers.set('file_name', fileName);
      request.headers.set('token', token);
      request.headers.set('Content-Length', videoBytes.length.toString());

      // ── Chunked body write with progress callback ──────────────────────
      const chunkSize = 65536; // 64 KB per chunk
      final total = videoBytes.length;

      for (int offset = 0; offset < total; offset += chunkSize) {
        final end =
        (offset + chunkSize < total) ? offset + chunkSize : total;
        request.add(videoBytes.sublist(offset, end));

        onProgress?.call(end / total); // 0.0 → 1.0

        // Yield to event loop — lets Flutter repaint the progress bar
        await Future.delayed(Duration.zero);
      }

      final httpResponse = await request.close();
      final responseBody =
      await httpResponse.transform(const Utf8Decoder()).join();

      httpClient.close();

      // ── Response handling — same as uploadImage ────────────────────────
      if (httpResponse.statusCode == 200) {
        final res = jsonDecode(responseBody);
        print('uploadVideo response: $res');
        return APIResponse.fromMap(res);
      } else if (httpResponse.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Server error, please try again');
      } else {
        return APIResponse(
            status: 'error',
            message: 'Request failed: ${httpResponse.reasonPhrase}');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }
  Future<APIResponse> uploadImage(
    String aid,
    String qid,
    String cSectionID,
    String fileName,
    Uint8List base64Image,
      String contentType
  ) async {
    print('object1 }');
    try {
      Response response = await post(
          //Uri.parse('https://apps.slichealth.com/ords/ihmis_admin/assesment/image'),
          Uri.parse('$API/insert_image'),
          body: base64Image,
          headers: <String, String>{
            'assessment_id': aid,
            'Content-Type': contentType,
            'qid': qid,
            'c_sec_id': cSectionID,
            'file_name': fileName,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));

      print('object1 ${response.body}');
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print('object ${res}');
        var data = APIResponse.fromMap(res);
        return data;
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> uploadPDF(
    String aid,
    String cSectionID,
    String fileName,
    Uint8List base64Image,
  ) async {
    print('hhh123 ${cSectionID} aa ${aid}');
    try {
      Response response = await post(
         // Uri.parse('https://apps.slichealth.com/ords/ihmis_admin/assesment/image'),
          Uri.parse('$API/insert_pdf'),
          body: base64Image,
          headers: <String, String>{
            'assessment_id': aid,
            'Content-Type': 'application/pdf',
            'qid': aid,
            'c_sec_id': cSectionID,
            'file_name': fileName,
            'type_id': "3",
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));

      print('object1234 ${response.body}');
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print('object4321 ${res}');
        var data = APIResponse.fromMap(res);
        return data;
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> submitSection(
      String cID, String aID, String sID, Map<String, dynamic> data1) async {
    try {
      String jsonData = json.encode(data1);

      var headers = {
        'criteria_id': cID,
        'section_id': sID,
        'assessment_id': aID,
        'token': await SharedPreferencesHelper.getToken(),
      };

      var request = MultipartRequest('POST', Uri.parse('$API/submit_section'));

      request.fields['json_data'] = jsonData;
      request.headers.addAll(headers);

      StreamedResponse response =
          await request.send().timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('object C=$cID S=$sID A=$aID $jsonData dd $responseBody');
        var res = jsonDecode(responseBody);
        var data = APIResponse.fromMap(res);
        return data;
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Server Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> submitSection1(
      String cID, String aID, String sID, Map<String, dynamic> data1) async {
    try {
      String jsonData = json.encode(data1);
      Response response = await post(Uri.parse('$API/submit_section'),
              headers: <String, String>{
                'criteria_id': cID,
                'section_id': sID,
                'assessment_id': aID,
                //'json_data': jsonData,
                'token': await SharedPreferencesHelper.getToken(),
              },
              body: jsonData)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        print(
            'object C=${cID.toString()} S=${sID} A=${aID} ${jsonData.toString()} dd ${response.body}');
        var res = jsonDecode(response.body);
        var data = APIResponse.fromMap(res);
        return data;
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> submitBedSection(String cID, String aID, String sID,
      String spID, Map<String, dynamic> data1) async {
    try {
      String jsonData = json.encode(data1);
      Response response = await post(Uri.parse('$API/submit_bed_section'),
          headers: <String, String>{
            'criteria_id': cID,
            'section_id': sID,
            'assessment_id': aID,
            'sp_id': spID,
            'json_data': jsonData,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        var data = APIResponse.fromMap(res);
        return data;
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> submitStaffSection(String cID, String aID, String sID,
      String spID, Map<String, dynamic> data1) async {
    try {
      String jsonData = json.encode(data1);
      Response response = await post(Uri.parse('$API/submit_staff_section'),
          headers: <String, String>{
            'criteria_id': cID,
            'section_id': sID,
            'assessment_id': aID,
            'sp_id': spID,
            'json_data': jsonData,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        var data = APIResponse.fromMap(res);
        return data;
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<List<StateModel>>> getStates() async {
    try {
      Response response =
          await get(Uri.parse('$API/stateList'), headers: <String, String>{
        'token': await SharedPreferencesHelper.getToken(),
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final itemCatModel1 = <StateModel>[];
        for (var item in jsonData['statesList']) {
          final itemCat = StateModel.fromJson(item);
          itemCatModel1.add(itemCat);
        }
        return APIResponse<List<StateModel>>(
            data: itemCatModel1,
            status: jsonData['status'],
            message: 'success');
      } else if (response.statusCode == 500) {
        return APIResponse<List<StateModel>>(
            data: [],
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<List<StateModel>>(
            data: [],
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<List<StateModel>>(
          data: [], status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<List<DistrictModel>>> getDistricts(
      String? stateID, String type) async {
    try {
      Response response =
          await get(Uri.parse('$API/districtList'), headers: <String, String>{
        'state_id': stateID!,
        'type': type,
        'token': await SharedPreferencesHelper.getToken(),
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final itemCatModel1 = <DistrictModel>[];
        for (var item in jsonData['districtList']) {
          final itemCat = DistrictModel.fromJson(item);
          itemCatModel1.add(itemCat);
        }
        return APIResponse<List<DistrictModel>>(
            data: itemCatModel1, status: jsonData['status']);
      } else if (response.statusCode == 500) {
        return APIResponse<List<DistrictModel>>(
            data: [],
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<List<DistrictModel>>(
            data: [],
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<List<DistrictModel>>(
          data: [], status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> checkToken() async {
    try {
      Response response = await get(Uri.parse('$API/check_token_validation'),
          headers: <String, String>{
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return APIResponse(
            status: jsonData['status'], message: jsonData['message']);
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> getChartData() async {
    try {
      Response response =
          await get(Uri.parse('$API/get_chart_data'), headers: <String, String>{
        'token': await SharedPreferencesHelper.getToken(),
      }).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        print('object1122 ${response.body}');
        final jsonData = json.decode(response.body);
        return APIResponse.fromMap(jsonData);
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> deletePicture(String aid, String qid) async {
    try {
      Response response = await delete(Uri.parse('$API/insert_image'),
          headers: <String, String>{
            'assessment_id': aid,
            'qid': qid,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return APIResponse(
            status: jsonData['status'], message: jsonData['message']);
      } else if (response.statusCode == 500) {
        return APIResponse(
            status: 'error', message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse(
            status: 'error', message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<List<HospitalModel>>> getHospitals(
      String? distID, String type) async {
    try {
      Response response =
          await get(Uri.parse('$API/hospitalList'), headers: <String, String>{
        'district_id': distID!,
        'type': type,
        'token': await SharedPreferencesHelper.getToken(),
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final itemCatModel1 = <HospitalModel>[];
        for (var item in jsonData['hospitalList']) {
          final itemCat = HospitalModel.fromJson(item);
          itemCatModel1.add(itemCat);
        }
        return APIResponse<List<HospitalModel>>(
            data: itemCatModel1, status: jsonData['status']);
      } else if (response.statusCode == 500) {
        return APIResponse<List<HospitalModel>>(
            data: [],
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<List<HospitalModel>>(
            data: [],
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<List<HospitalModel>>(
          data: [], status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<List<PicturesSectionModel>>> getPictures(
      String aid) async {
    try {
      Response response = await get(Uri.parse('$API/get_picture_section'),
          headers: <String, String>{
            'assessment_id': aid,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final itemCatModel1 = <PicturesSectionModel>[];
        for (var item in jsonData['pictureList']) {
          final itemCat = PicturesSectionModel.fromJson(item);
          itemCatModel1.add(itemCat);
        }
        return APIResponse<List<PicturesSectionModel>>(
            data: itemCatModel1, status: jsonData['status']);
      } else if (response.statusCode == 500) {
        return APIResponse<List<PicturesSectionModel>>(
            data: [],
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<List<PicturesSectionModel>>(
            data: [],
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<List<PicturesSectionModel>>(
          data: [], status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<PicturesSectionModel>> getPDF(String aid) async {
    try {
      Response response = await get(Uri.parse('$API/get_pdf_section'),
          headers: <String, String>{
            'assessment_id': aid,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final itemCat = PicturesSectionModel.fromJson(jsonData);
        return APIResponse<PicturesSectionModel>(
            data: itemCat,
            status: jsonData['status'],
            message: jsonData['message']);
      } else if (response.statusCode == 500) {
        return APIResponse<PicturesSectionModel>(
            data: PicturesSectionModel(),
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<PicturesSectionModel>(
            data: PicturesSectionModel(),
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<PicturesSectionModel>(
          data: PicturesSectionModel(), status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<List<HospitalAssessmentModel>>>
      getHospitalsAssessmentDetail(String spID) async {
    try {
      Response response = await get(Uri.parse('$API/hospital_assessments'),
          headers: <String, String>{
            'sp_id': spID,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final itemCatModel1 = <HospitalAssessmentModel>[];
        for (var item in jsonData['assessmentList']) {
          final itemCat = HospitalAssessmentModel.fromJson(item);
          itemCatModel1.add(itemCat);
        }
        return APIResponse<List<HospitalAssessmentModel>>(
            data: itemCatModel1, status: jsonData['status']);
      } else if (response.statusCode == 500) {
        return APIResponse<List<HospitalAssessmentModel>>(
            data: [],
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<List<HospitalAssessmentModel>>(
            data: [],
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<List<HospitalAssessmentModel>>(
          data: [], status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<List<SectionModel>>> getSectionList(
      String cID, String aID) async {
    try {
      Response response = await get(Uri.parse('$API/section_title_list'),
          headers: <String, String>{
            'criteria_id': cID,
            'assessment_id': aID,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final itemCatModel1 = <SectionModel>[];
        for (var item in jsonData['sectionList']) {
          final itemCat = SectionModel.fromJson(item);
          itemCatModel1.add(itemCat);
        }
        return APIResponse<List<SectionModel>>(
            data: itemCatModel1, status: jsonData['status']);
      } else if (response.statusCode == 500) {
        return APIResponse<List<SectionModel>>(
            data: [],
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<List<SectionModel>>(
            data: [],
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<List<SectionModel>>(
          data: [], status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<List<CriteriaTypeModel>>> getCriteriaTypeList() async {
    try {
      Response response = await get(Uri.parse('$API/criteria_type_list'),
          headers: <String, String>{
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final itemCatModel1 = <CriteriaTypeModel>[];
        for (var item in jsonData['criteriaList']) {
          final itemCat = CriteriaTypeModel.fromJson(item);
          itemCatModel1.add(itemCat);
        }
        return APIResponse<List<CriteriaTypeModel>>(
            data: itemCatModel1, status: jsonData['status']);
      } else if (response.statusCode == 500) {
        return APIResponse<List<CriteriaTypeModel>>(
            data: [],
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<List<CriteriaTypeModel>>(
            data: [],
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<List<CriteriaTypeModel>>(
          data: [], status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<List<StaffModel>>> getStaffList(
      String aID, String cID, String spID, String sID) async {
    try {
      Response response = await get(Uri.parse('$API/get_staff_bed_text'),
          headers: <String, String>{
            'assessment_id': aID,
            'criteria_id': cID,
            'section_id': sID,
            'sp_id': spID,
            'get_type': 'staff',
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('object $jsonData');
        final itemCatModel1 = <StaffModel>[];
        for (var item in jsonData['staffingList']) {
          final itemCat = StaffModel.fromJson(item);
          itemCatModel1.add(itemCat);
        }
        return APIResponse<List<StaffModel>>(
            data: itemCatModel1, status: jsonData['status']);
      } else if (response.statusCode == 500) {
        return APIResponse<List<StaffModel>>(
            data: [],
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<List<StaffModel>>(
            data: [],
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<List<StaffModel>>(
          data: [], status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<SpecialDocumentModel>> getSpecialDocument(
    String aID,
    String c_type_ID,
    String spID,
  ) async {
    try {
      Response response = await get(Uri.parse('$API/get_special_document'),
          headers: <String, String>{
            'assessment_id': aID,
            'criteria_type_id': c_type_ID,
            'sp_id': spID,
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('object123 ${jsonData}');

        final itemCat = SpecialDocumentModel.fromJson(jsonData);

        return APIResponse<SpecialDocumentModel>(
            data: itemCat, status: 'success');
      } else if (response.statusCode == 500) {
        return APIResponse<SpecialDocumentModel>(
            data: SpecialDocumentModel(),
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<SpecialDocumentModel>(
            data: SpecialDocumentModel(),
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      print('object321 ${e.toString()}');
      return APIResponse<SpecialDocumentModel>(
          data: SpecialDocumentModel(), status: 'error', message: e.toString());
    }
  }

  Future<APIResponse<List<BedCapacityModel>>> getBedCapacityList(
      String aID, String cID, String spID, String sID) async {
    try {
      Response response = await get(Uri.parse('$API/get_staff_bed_text'),
          headers: <String, String>{
            'assessment_id': aID,
            'criteria_id': cID,
            'section_id': sID,
            'sp_id': spID,
            'get_type': 'bed',
            'token': await SharedPreferencesHelper.getToken(),
          }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        final itemCatModel1 = <BedCapacityModel>[];
        for (var item in jsonData['bedList']) {
          print('object ${item}');
          final itemCat = BedCapacityModel.fromJson(item);
          itemCatModel1.add(itemCat);
        }
        return APIResponse<List<BedCapacityModel>>(
            data: itemCatModel1, status: jsonData['status']);
      } else if (response.statusCode == 500) {
        return APIResponse<List<BedCapacityModel>>(
            data: [],
            status: 'error',
            message: 'Sever Error, please try again');
      } else if (response.statusCode != 200 && response.statusCode != 500) {
        throw Exception(response.reasonPhrase);
      } else {
        return APIResponse<List<BedCapacityModel>>(
            data: [],
            status: 'error',
            message: 'Request failed, please try again!');
      }
    } on TimeoutException catch (_) {
      throw 'Looks like your internet is unstable, please try again.';
    } catch (e) {
      return APIResponse<List<BedCapacityModel>>(
          data: [], status: 'error', message: e.toString());
    }
  }
}
