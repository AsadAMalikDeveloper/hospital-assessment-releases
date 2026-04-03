import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../Utils/CheckInternetConnection.dart';
import '../Utils/ToastMessages.dart';
import '../db_services/db_helper.dart';
import '../models/api_response_model.dart';
import '../models/bed_capacity_model.dart';
import '../models/picture_get_model.dart';
import '../models/section_model.dart';
import '../models/special_document_model.dart';
import '../models/staff_model.dart';
import '../models/video_section_model.dart';
import '../services/api_services.dart';

class AssessmentProvider extends ChangeNotifier {
  final CheckConnectivity _connectivityService = CheckConnectivity();
  final _service = ApiService();

  // ── Existing loaders ───────────────────────────────────────────────────────

  bool? _isLoading;

  bool? get isLoading => _isLoading;

  bool? _isLoadingOfflineDownload;

  bool? get isLoadingOfflineDownload => _isLoadingOfflineDownload;

  bool? _isLoadingDelete;

  bool? get isLoadingDelete => _isLoadingDelete;

  bool? _isLoadingSubmitSection;

  bool? get isLoadingSubmitSection => _isLoadingSubmitSection;

  bool? _isLoadingStaff;

  bool? get isLoadingStaff => _isLoadingStaff;

  bool? _isLoadingSpecialDocument;

  bool? get isLoadingSpecialDocument => _isLoadingSpecialDocument;

  bool? _isLoadingPdfUploading;

  bool? get isLoadingPdfUploading => _isLoadingPdfUploading;

  bool? _isLoadingCompleteAssessment;

  bool? get isLoadingCompleteAssessment => _isLoadingCompleteAssessment;

  bool? _isLoadingPictureSection;

  bool? get isLoadingPictureSection => _isLoadingPictureSection;

  // ── NEW: Video loaders ─────────────────────────────────────────────────────

  bool? _isLoadingVideoSection;

  bool? get isLoadingVideoSection => _isLoadingVideoSection;

  bool? _isLoadingVideoUploading;

  bool? get isLoadingVideoUploading => _isLoadingVideoUploading;

  bool? _isLoadingVideoDelete;

  bool? get isLoadingVideoDelete => _isLoadingVideoDelete;

  // ── Existing data ──────────────────────────────────────────────────────────

  List<PicturesSectionModel>? _picsList = [];

  List<PicturesSectionModel>? get picsList => _picsList;

  List<PicturesSectionModel>? _pdfOffline = [];

  List<PicturesSectionModel>? get pdfOffline => _pdfOffline;

  PicturesSectionModel? _pdfData = PicturesSectionModel();

  PicturesSectionModel? get pdfData => _pdfData;

  List<StaffModel>? _staffList = [];

  List<StaffModel>? get staffList => _staffList;

  SpecialDocumentModel? _specialDocumentModel = SpecialDocumentModel();

  SpecialDocumentModel? get specialDocumentModel => _specialDocumentModel;

  List<BedCapacityModel>? _bedList = [];

  List<BedCapacityModel>? get bedList => _bedList;

  bool? _hasChild;

  bool? get hasChild => _hasChild;

  bool? _hasSubChild;

  bool? get hasSubChild => _hasSubChild;

  List<SectionModel>? _sectionList = [];

  List<SectionModel>? get sectionList => _sectionList;

  int _selectedIndex = -1;

  int get selectedIndex => _selectedIndex;

  int _selectedIndexChild = -1;

  int get selectedIndexChild => _selectedIndexChild;

  int _selectedIndexSubChild = -1;

  int get selectedIndexSubChild => _selectedIndexSubChild;

  // ── NEW: Video data ────────────────────────────────────────────────────────

  // Mirrors _picsList pattern exactly
  List<VideoSectionModel>? _videoList = [];

  List<VideoSectionModel>? get videoList => _videoList;

  // ── Existing setters ───────────────────────────────────────────────────────

  setHasChild(bool loading, int index) {
    _hasChild = loading;
    _hasSubChild = false;
    _selectedIndex = index;
    _selectedIndexChild = -1;
    notifyListeners();
  }

  setHasSubChild(bool loading, int index) {
    _hasSubChild = loading;
    _selectedIndexChild = index;
    _selectedIndexSubChild = -1;
    notifyListeners();
  }

  setOfflineDownloadLoader(bool isLoading) {
    _isLoadingOfflineDownload = isLoading;
    notifyListeners();
  }

  setChildIndex(int index) {
    _selectedIndexChild = index;
    notifyListeners();
  }

  setSubChildIndex(int index) {
    _selectedIndexSubChild = index;
    notifyListeners();
  }

  setLoaderPictureSection(bool loader) {
    _isLoadingPictureSection = loader;
    notifyListeners();
  }

  setLoaderPDFUploading(bool loader) {
    _isLoadingPdfUploading = loader;
    notifyListeners();
  }

  setLoaderSubmitSection(bool loader) {
    _isLoadingSubmitSection = loader;
    notifyListeners();
  }

  setLoaderCompleteAssessment(bool loader) {
    _isLoadingCompleteAssessment = loader;
    notifyListeners();
  }

  setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  setSpecialDocumentLoader(bool loader) {
    _isLoadingSpecialDocument = loader;
    notifyListeners();
  }

  setChildRemovedOnBack() {
    _hasChild = false;
    _selectedIndexChild = -1;
    _selectedIndex = -1;
    notifyListeners();
  }

  setLoader(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  setLoaderDelete(bool loading) {
    _isLoadingDelete = loading;
    notifyListeners();
  }

  setLoaderStaff(bool loading) {
    _isLoadingStaff = loading;
    notifyListeners();
  }

  // ── NEW: Video loader setters ──────────────────────────────────────────────

  setLoaderVideoSection(bool loader) {
    _isLoadingVideoSection = loader;
    notifyListeners();
  }

  setLoaderVideoUploading(bool loader) {
    _isLoadingVideoUploading = loader;
    notifyListeners();
  }

  setLoaderVideoDelete(bool loader) {
    _isLoadingVideoDelete = loader;
    notifyListeners();
  }

  // ── disposeValues — extended to include video ──────────────────────────────

  disposeValues() {
    _selectedIndex = -1;
    _selectedIndexChild = -1;
    _selectedIndexSubChild = -1;
    _hasChild = false;
    _hasSubChild = false;
    _sectionList = [];
    _bedList = [];
    _picsList = [];
    _pdfData = PicturesSectionModel();
    // ← DO NOT clear _videoList here
    // Videos are loaded once per assessment and should persist
    // across section navigation. They get cleared in getData() refresh.
    notifyListeners();
  }

  // ── Existing methods (unchanged) ───────────────────────────────────────────
// ── Replace the uploadVideo method in AssessmentProvider ──────────────────
// Mirrors pickImage() exactly: reads File → Uint8List → passes to service.
// Extra: exposes uploadProgress notifier for the UI progress bar.

// Add this field at the top of AssessmentProvider alongside other fields:
//
//   double _uploadVideoProgress = 0;
//   double get uploadVideoProgress => _uploadVideoProgress;
//
//   void _setUploadVideoProgress(double p) {
//     _uploadVideoProgress = p;
//     notifyListeners();
//   }

  Future<APIResponse?> uploadVideo(
    BuildContext context,
    String aid,
    String qid,
    String sid, // = csid (criteria section id)
    String fileName,
    File videoFile,
  ) async {
    setLoaderVideoUploading(true);
    _setUploadVideoProgress(0); // reset progress

    try {
      // Read compressed file to bytes — same pattern as pickImage()
      final Uint8List videoBytes = await videoFile.readAsBytes();

      final APIResponse res = await _service.uploadVideo(
        aid,
        qid,
        sid,
        fileName,
        videoBytes,
        onProgress: (p) {
          // p is 0.0 → 1.0
          _setUploadVideoProgress(p);
        },
      );

      if (res.status!.toLowerCase() == 'success') {
        setLoaderVideoUploading(false);
        _setUploadVideoProgress(1.0); // ensure full on success
        return APIResponse(status: 'success', message: res.message);
      } else {
        setLoaderVideoUploading(false);
        _setUploadVideoProgress(0);
        return APIResponse(status: 'error', message: res.message);
      }
    } catch (e) {
      setLoaderVideoUploading(false);
      _setUploadVideoProgress(0);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

// ── Add these to AssessmentProvider fields + setters ──────────────────────

  double _uploadVideoProgress = 0;

  double get uploadVideoProgress => _uploadVideoProgress;

  void _setUploadVideoProgress(double p) {
    _uploadVideoProgress = p;
    notifyListeners();
  }

  getSectionList(BuildContext context, String cID, String aID) async {
    try {
      disposeValues();
      _sectionList = [];
      _hasChild = false;
      print('object ${aID}');
      setLoader(true);
      var jsonResponse = await _service.getSectionList(cID, aID);
      String? status = jsonResponse.status;
      print('object ${jsonResponse.message}');
      if (status!.toLowerCase() == 'success') {
        _sectionList = jsonResponse.data;
        setLoader(false);
      } else {
        _sectionList = [];
        setLoader(false);
      }
    } catch (e) {
      _sectionList = [];
      setLoader(false);
    }
  }

  getSectionListOffline(BuildContext context, String cID, String aID) async {
    try {
      disposeValues();
      _sectionList = [];
      _videoList = [];
      _hasChild = false;
      print('object ${aID}');
      setLoader(true);
      final APIResponse jsonResponse = await DatabaseHelper().getALLItemList();
      if (jsonResponse.data != null) {
        print('offline ${aID}');
        _sectionList = jsonResponse.data;
        setLoader(false);
      } else {
        _sectionList = [];
        setLoader(false);
      }
    } catch (e) {
      _sectionList = [];
      setLoader(false);
    }
  }

  getStaffList(BuildContext context, String aID, String cID, String spID,
      String sID) async {
    try {
      _staffList = [];
      setLoaderStaff(true);
      var jsonResponse = await _service.getStaffList(aID, cID, spID, sID);
      String? status = jsonResponse.status;
      if (status!.toLowerCase() == 'success') {
        _staffList = jsonResponse.data;
        setLoaderStaff(false);
      } else {
        _staffList = [];
        setLoaderStaff(false);
      }
    } catch (e) {
      _staffList = [];
      setLoaderStaff(false);
    }
  }

  getStaffListOffline(BuildContext context, String aID, String cID, String spID,
      String sID) async {
    try {
      print('staff123 }');
      _staffList = [];
      setLoaderStaff(true);
      var jsonResponse = await DatabaseHelper().getStaffingList();
      if (jsonResponse.data != []) {
        _staffList = jsonResponse.data;
        setLoaderStaff(false);
      } else {
        _staffList = [];
        setLoaderStaff(false);
      }
    } catch (e) {
      _staffList = [];
      setLoaderStaff(false);
    }
  }

  getBedCapacityList(BuildContext context, String aID, String cID, String spID,
      String sID) async {
    try {
      _bedList = [];
      setLoaderStaff(true);
      var jsonResponse = await _service.getBedCapacityList(aID, cID, spID, sID);
      String? status = jsonResponse.status;
      if (status!.toLowerCase() == 'success') {
        _bedList = jsonResponse.data;
        setLoaderStaff(false);
      } else {
        _bedList = [];
        setLoaderStaff(false);
      }
    } catch (e) {
      _bedList = [];
      setLoaderStaff(false);
    }
  }

  getBedCapacityListOffline(BuildContext context, String aID, String cID,
      String spID, String sID) async {
    try {
      _bedList = [];
      setLoaderStaff(true);
      print('object2121 ');
      var jsonResponse = await DatabaseHelper().getBedCapacity();
      print('object2121 ${jsonResponse.data}');
      if (jsonResponse.data != null) {
        _bedList = jsonResponse.data;
        setLoaderStaff(false);
      } else {
        _bedList = [];
        setLoaderStaff(false);
      }
    } catch (e) {
      _bedList = [];
      setLoaderStaff(false);
    }
  }

// ── Add to AssessmentProvider ──────────────────────────────────────────────

// Offline: save compressed video to SQLite
// Mirrors pickImageOffline() exactly
  Future<APIResponse?> pickVideoOffline(
    BuildContext context,
    String aid,
    String qid,
    String filePath,
  ) async {
    setLoaderVideoUploading(true);
    try {
      final jsonResponse =
          await DatabaseHelper().insertVideo(aid, qid, filePath);
      if (jsonResponse.status!.toLowerCase() == 'success') {
        setLoaderVideoUploading(false);
        return APIResponse(status: 'success', message: jsonResponse.message);
      } else {
        setLoaderVideoUploading(false);
        return APIResponse(status: 'error', message: jsonResponse.message);
      }
    } catch (e) {
      setLoaderVideoUploading(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

// Offline: load videos from SQLite
// Mirrors getPicturesListOffline() exactly
  getVideosListOffline(BuildContext context, String aID) async {
    try {
      _videoList = [];
      _videoList!.clear();
      setLoaderVideoSection(true);
      final jsonResponse = await DatabaseHelper().getVideos(aID);
      if (jsonResponse.data != null) {
        _videoList = jsonResponse.data;
        setLoaderVideoSection(false);
      } else {
        _videoList = [];
        setLoaderVideoSection(false);
      }
    } catch (e) {
      _videoList = [];
      setLoaderVideoSection(false);
    }
  }

// Offline: delete video from SQLite
// Mirrors deletePictureOffline() exactly
  Future<APIResponse> deleteVideoOffline(
      BuildContext context, String aid, String qid) async {
    try {
      setLoaderVideoDelete(true);
      final jsonResponse = await DatabaseHelper().deleteVideo(qid);
      setLoaderVideoDelete(false);
      return jsonResponse;
    } catch (e) {
      setLoaderVideoDelete(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> deletePicture(
      BuildContext context, String aid, String qid) async {
    try {
      setLoaderDelete(true);
      var jsonResponse = await _service.deletePicture(aid, qid);
      setLoaderDelete(false);
      return jsonResponse;
    } catch (e) {
      setLoaderDelete(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> deletePictureOffline(
      BuildContext context, String aid, String qid) async {
    try {
      setLoaderDelete(true);
      var jsonResponse = await _service.deletePicture(aid, qid);
      setLoaderDelete(false);
      return jsonResponse;
    } catch (e) {
      setLoaderDelete(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  getPicturesList(BuildContext context, String aID) async {
    try {
      _picsList = [];
      _picsList!.clear();
      setLoaderPictureSection(true);
      var jsonResponse = await _service.getPictures(aID);
      String? status = jsonResponse.status;
      if (status!.toLowerCase() == 'success') {
        _picsList = jsonResponse.data;
        setLoaderPictureSection(false);
      } else {
        _picsList = [];
        setLoaderPictureSection(false);
      }
    } catch (e) {
      _picsList = [];
      setLoaderPictureSection(false);
    }
  }

  getPicturesListOffline(BuildContext context, String aID) async {
    try {
      _picsList = [];
      _picsList!.clear();
      setLoaderPictureSection(true);
      var jsonResponse = await DatabaseHelper().getImages();
      if (jsonResponse.data != []) {
        _picsList = jsonResponse.data;
        setLoaderPictureSection(false);
      } else {
        _picsList = [];
        setLoaderPictureSection(false);
      }
    } catch (e) {
      _picsList = [];
      setLoaderPictureSection(false);
    }
  }

  getPdfOffline(BuildContext context, String aID) async {
    try {
      _pdfOffline = [];
      _pdfOffline!.clear();
      setLoaderPictureSection(true);
      var jsonResponse = await DatabaseHelper().getPDF();
      print('object31 ${jsonResponse.data}');
      if (jsonResponse.data != []) {
        _pdfOffline = jsonResponse.data;
        setLoaderPictureSection(false);
      } else {
        _pdfOffline = [];
        setLoaderPictureSection(false);
      }
    } catch (e) {
      _pdfOffline = [];
      setLoaderPictureSection(false);
    }
  }

  getPDF(BuildContext context, String aID) async {
    try {
      _pdfData = PicturesSectionModel(doc_id: '');
      setLoaderStaff(true);
      var jsonResponse = await _service.getPDF(aID);
      String? status = jsonResponse.status;
      if (status!.toLowerCase() == 'success') {
        _pdfData = jsonResponse.data;
        setLoaderStaff(false);
      } else {
        _pdfData = PicturesSectionModel();
        setLoaderStaff(false);
      }
    } catch (e) {
      _pdfData = PicturesSectionModel();
      setLoaderStaff(false);
    }
  }

  Future<APIResponse> submitSection(
      String cID, String aID, String sID, Map<String, dynamic> data1) async {
    try {
      print('object C=${cID.toString()} S=${sID} A=${aID} ${data1.toString()}');
      setLoaderSubmitSection(true);
      var jsonResponse = await _service.submitSection(cID, aID, sID, data1);
      setLoaderSubmitSection(false);
      return jsonResponse;
    } catch (e) {
      setLoaderSubmitSection(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> completeAssessment(String aID) async {
    try {
      setLoaderCompleteAssessment(true);
      var jsonResponse = await _service.completeAssessment(aID);
      setLoaderCompleteAssessment(false);
      return jsonResponse;
    } catch (e) {
      setLoaderCompleteAssessment(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> submitBedSection(String cID, String aID, String sID,
      String spID, Map<String, dynamic> data1) async {
    try {
      setLoaderSubmitSection(true);
      var jsonResponse =
          await _service.submitBedSection(cID, aID, sID, spID, data1);
      setLoaderSubmitSection(false);
      return jsonResponse;
    } catch (e) {
      setLoaderSubmitSection(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse> submitStaffSection(String cID, String aID, String sID,
      String spID, Map<String, dynamic> data1) async {
    try {
      setLoaderSubmitSection(true);
      var jsonResponse =
          await _service.submitStaffSection(cID, aID, sID, spID, data1);
      setLoaderSubmitSection(false);
      return jsonResponse;
    } catch (e) {
      setLoaderSubmitSection(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Toast toast = Toast();

  _compressImage(var _image) async {
    try {
      var imageBytes = await _image!.readAsBytes();
      final compressedImageBytes = await FlutterImageCompress.compressWithList(
        imageBytes!,
        quality: 100,
        minHeight: 300,
        minWidth: 350,
      );
      return compressedImageBytes;
    } catch (e) {
      toast.showErrorToast(e.toString());
    }
  }

  _compressImageToFile(XFile image) async {
    try {
      var imageBytes = await image.readAsBytes();
      final compressedImageBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: 100,
        minHeight: 300,
        minWidth: 350,
      );
      return compressedImageBytes;
    } catch (e) {
      toast.showErrorToast(e.toString());
    }
  }

  Uint8List changeImageExtension(Uint8List imageBytes, String newExtension) {
    String imageDataWithNewExtension =
        String.fromCharCodes(imageBytes).replaceFirstMapped(
      RegExp(r'\.(\w+)$'),
      (match) => ".$newExtension",
    );
    return Uint8List.fromList(imageDataWithNewExtension.codeUnits);
  }

  XFile changeImageExtensionToFIle(Uint8List imageBytes, String newExtension) {
    String imageDataWithNewExtension =
        String.fromCharCodes(imageBytes).replaceFirstMapped(
      RegExp(r'\.(\w+)$'),
      (match) => ".$newExtension",
    );
    return XFile.fromData(
        Uint8List.fromList(imageDataWithNewExtension.codeUnits));
  }

  Future<APIResponse?> pickImage(
      BuildContext context,
      String aid,
      String qid,
      String cSectionID,
      String fileName,
      XFile image,
      String contentType,
      bool isPdf) async {
    setLoaderSubmitSection(true);
    try {
      Uint8List fileBytes;

      if (isPdf) {
        // ✅ PDFs: no compression
        fileBytes = await XFile(image.path).readAsBytes();
      } else {
        // ✅ Images: compress & change extension
        final Uint8List imageBytes = await _compressImage(image);
        fileBytes = changeImageExtension(imageBytes, 'jpeg'); // keep jpeg
      }
      // Uint8List imageBytes = await _compressImage(image);
      // final Uint8List modifiedImageBytes =
      // changeImageExtension(imageBytes, 'jpeg');
      var jsonResponse = await _service.uploadImage(
          aid, qid, cSectionID, fileName, fileBytes, contentType);
      if (jsonResponse.status!.toLowerCase() == 'success') {
        setLoaderSubmitSection(false);
        return APIResponse(status: 'success', message: jsonResponse.message);
      } else {
        setLoaderSubmitSection(false);
        return APIResponse(status: 'error', message: jsonResponse.message);
      }
    } catch (e) {
      setLoaderSubmitSection(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<String> convertXFileToBase64(XFile imageFile) async {
    Uint8List fileBytes = await imageFile.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<APIResponse?> pickPdfOffline(
      BuildContext context, String aid, XFile? pdf) async {
    setLoaderSubmitSection(true);
    try {
      Uint8List fileBytes = await pdf!.readAsBytes();
      String base64String = base64Encode(fileBytes);
      var jsonResponse =
          await DatabaseHelper().insertPDF(aid, pdf.path, base64String);
      if (jsonResponse.status!.toLowerCase() == 'success') {
        setLoaderSubmitSection(false);
        return APIResponse(status: 'success', message: jsonResponse.message);
      } else {
        setLoaderSubmitSection(false);
        return APIResponse(status: 'error', message: jsonResponse.message);
      }
    } catch (e) {
      setLoaderSubmitSection(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse?> pickImageOffline(
      BuildContext context, String aid, String qid, XFile image) async {
    setLoaderSubmitSection(true);
    try {
      final bool isPdf = image.path.toLowerCase().endsWith('.pdf');

      Uint8List fileBytes;

      if (isPdf) {
        // ✅ no compression for pdf
        fileBytes = await image.readAsBytes();
      } else {
        // ✅ compress only images
        fileBytes = await _compressImageToFile(image);
      }

      final XFile modifiedFile =
          changeImageExtensionToFIle(fileBytes, isPdf ? 'pdf' : 'jpeg');

      // String base64String = await convertXFileToBase64(modifiedFile);
      // Uint8List imageBytes = await _compressImageToFile(image);
      // final XFile modifiedImage =
      // changeImageExtensionToFIle(imageBytes, 'jpeg');
      String base64String = await convertXFileToBase64(modifiedFile);
      var jsonResponse = await DatabaseHelper()
          .insertImage(aid, qid, image!.path, base64String);
      if (jsonResponse.status!.toLowerCase() == 'success') {
        setLoaderSubmitSection(false);
        return APIResponse(status: 'success', message: jsonResponse.message);
      } else {
        setLoaderSubmitSection(false);
        return APIResponse(status: 'error', message: jsonResponse.message);
      }
    } catch (e) {
      setLoaderSubmitSection(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  Future<APIResponse?> pickPDF(BuildContext context, String aid,
      String cSectionID, String fileName, Uint8List base64Image) async {
    setLoaderPDFUploading(true);
    try {
      var jsonResponse =
          await _service.uploadPDF(aid, cSectionID, fileName, base64Image);
      if (jsonResponse.status!.toLowerCase() == 'success') {
        setLoaderPDFUploading(false);
        return APIResponse(status: 'success', message: jsonResponse.message);
      } else {
        setLoaderPDFUploading(false);
        return APIResponse(status: 'error', message: jsonResponse.message);
      }
    } catch (e) {
      setLoaderPDFUploading(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }

  getSpecialDocument(
      BuildContext context, String c_type_ID, String aID, String spID) async {
    try {
      _specialDocumentModel = SpecialDocumentModel();
      setSpecialDocumentLoader(true);
      var jsonResponse =
          await _service.getSpecialDocument(aID, c_type_ID, spID);
      String? status = jsonResponse.status;
      if (status!.toLowerCase() == 'success') {
        _specialDocumentModel = jsonResponse.data;
        setSpecialDocumentLoader(false);
      } else {
        _specialDocumentModel = SpecialDocumentModel();
        setSpecialDocumentLoader(false);
      }
    } catch (e) {
      _specialDocumentModel = SpecialDocumentModel();
      setSpecialDocumentLoader(false);
    }
  }

  // ── NEW: Video methods — mirrors getPicturesList / pickImage / deletePicture ─

  /// Fetch all videos for this assessment — mirrors getPicturesList
  getVideosList(BuildContext context, String aID) async {
    try {
      _videoList = [];
      _videoList!.clear();
      setLoaderVideoSection(true);
      // var jsonResponse = await _service.getVideos(aID);
      // String? status = jsonResponse.status;
      // if (status!.toLowerCase() == 'success') {
      //   _videoList = jsonResponse.data;
      //   setLoaderVideoSection(false);
      // } else {
      //   _videoList = [];
      //   setLoaderVideoSection(false);
      // }
    } catch (e) {
      _videoList = [];
      setLoaderVideoSection(false);
    }
  }

  /// Delete a video by doc_id — mirrors deletePicture
  Future<APIResponse> deleteVideo(
      BuildContext context, String aid, String qid) async {
    try {
      // setLoaderVideoDelete(true);
      // var jsonResponse = await _service.deleteVideo(aid, qid);
      // setLoaderVideoDelete(false);
      // return jsonResponse;
      return APIResponse(status: 'error', message: ' e.toString()');
    } catch (e) {
      setLoaderVideoDelete(false);
      return APIResponse(status: 'error', message: e.toString());
    }
  }
}
