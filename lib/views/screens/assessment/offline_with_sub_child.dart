// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hospital_assessment/Utils/CheckInternetConnection.dart';
// import 'package:hospital_assessment/Utils/Colors.dart';
// import 'package:hospital_assessment/Utils/ToastMessages.dart';
// import 'package:hospital_assessment/Utils/globle_controller.dart';
// import 'package:hospital_assessment/db_services/db_helper.dart';
// import 'package:hospital_assessment/models/api_response_model.dart';
// import 'package:hospital_assessment/models/assessment_hospital_model.dart';
// import 'package:hospital_assessment/models/picture_get_model.dart';
// import 'package:hospital_assessment/models/section_model.dart';
// import 'package:hospital_assessment/models/video_section_model.dart';
// import 'package:hospital_assessment/providers/assessment_provider.dart';
// import 'package:hospital_assessment/widgets/video_question_widget.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class AssessmentScreenOfflineWCOLD extends StatefulWidget {
//   final HospitalAssessmentModel hospitalAssessmentModel;
//
//   AssessmentScreenOfflineWCOLD({super.key, required this.hospitalAssessmentModel});
//
//   @override
//   State<AssessmentScreenOfflineWCOLD> createState() =>
//       _AssessmentScreenOfflineWCOLDState();
// }
//
// class _AssessmentScreenOfflineWCOLDState extends State<AssessmentScreenOfflineWCOLD> {
//   List<TextEditingController> _fullTimeControllers = [];
//   List<TextEditingController> _partTimeControllers = [];
//   List<TextEditingController> _maleControllers = [];
//   List<TextEditingController> _femaleControllers = [];
//   List<TextEditingController> _responseTextControllers = [];
//
//   @override
//   void initState() {
//     super.initState();
//     getData();
//   }
//
//   Future<void> getData() async {
//     _fullTimeControllers = [];
//     _partTimeControllers = [];
//     _maleControllers = [];
//     _femaleControllers = [];
//     _responseTextControllers = [];
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
//       final provider = Provider.of<AssessmentProvider>(context, listen: false);
//       await provider.getSectionListOffline(
//           context,
//           widget.hospitalAssessmentModel.criteria_type_id ?? "",
//           widget.hospitalAssessmentModel.assessment_id ?? "");
//       await provider.getVideosListOffline(
//           context, widget.hospitalAssessmentModel.assessment_id ?? "");
//
//       //await Glob().checkToken(context);
//     });
//   }
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//     for (var controller in _fullTimeControllers) {
//       controller.dispose();
//     }
//     for (var controller in _partTimeControllers) {
//       controller.dispose();
//     }
//     for (var controller in _maleControllers) {
//       controller.dispose();
//     }
//     for (var controller in _femaleControllers) {
//       controller.dispose();
//     }
//     for (var controller in _responseTextControllers) {
//       controller.dispose();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<AssessmentProvider>(context);
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             '${widget.hospitalAssessmentModel.hospital} (${widget.hospitalAssessmentModel.criteria})',
//             style: GoogleFonts.poppins(fontSize: 12),
//           ),
//         ),
//         body: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Flexible(
//                     child: Material(
//                       elevation: 8,
//                       child: Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.blue),
//                             color: Colors.blue),
//                         child: Padding(
//                           padding: const EdgeInsets.all(5.0),
//                           child: Text(
//                             "Selected",
//                             style: TextStyle(
//                                 fontFamily: 'HEL',
//                                 color: Colors.white,
//                                 fontSize: 10),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Flexible(
//                     child: Material(
//                       elevation: 8,
//                       child: Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.red),
//                             color: Colors.red),
//                         child: Padding(
//                           padding: const EdgeInsets.all(5.0),
//                           child: Text(
//                             "Partial Completed",
//                             style: TextStyle(
//                                 fontFamily: 'HEL',
//                                 color: Colors.white,
//                                 fontSize: 10),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Flexible(
//                     child: Material(
//                       elevation: 8,
//                       child: Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.green),
//                             color: Colors.green),
//                         child: Padding(
//                           padding: const EdgeInsets.all(5.0),
//                           child: Text(
//                             "Completed",
//                             style: TextStyle(
//                                 fontFamily: 'HEL',
//                                 color: Colors.white,
//                                 fontSize: 10),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Flexible(
//                     child: Material(
//                       elevation: 8,
//                       child: Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey),
//                             color: Colors.grey),
//                         child: Padding(
//                           padding: const EdgeInsets.all(5.0),
//                           child: Text(
//                             "Pending",
//                             style: TextStyle(
//                                 fontFamily: 'HEL',
//                                 color: Colors.white,
//                                 fontSize: 10),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             provider.sectionList == null || provider.sectionList!.isEmpty
//                 ? const Center(child: CircularProgressIndicator())
//                 : header(provider),
//             provider.hasChild == true ? child(provider) : const SizedBox(),
//             provider.hasSubChild == true ? subChild(provider) : const SizedBox(),
//             provider.selectedIndex == -1
//                 ? const SizedBox()
//                 : (provider.isLoadingStaff == true ||
//                 provider.isLoadingPictureSection == true)
//                 ? const Center(
//               child: CircularProgressIndicator(),
//             )
//                 : (provider.sectionList![provider.selectedIndex].type_id ==
//                 "3")
//                 ? //Assessment Form
//             Expanded(
//               child: SingleChildScrollView(
//                 child: SizedBox(
//                   // height: 0.45.sh,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 15, vertical: 15),
//                     child: Container(
//                       decoration: const BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [color.blue, color.bluePrimary],
//                             // Gradient colors
//                             begin: Alignment.centerLeft,
//                             // Gradient start position
//                             end: Alignment.center,
//                             // Gradient end position
//                             stops: [0.0, 1.0], // Gradient stops
//                           ),
//                           borderRadius:
//                           BorderRadius.all(Radius.circular(20)),
//                           color: color.bluePrimary),
//                       child: Padding(
//                         padding: const EdgeInsets.all(10.0),
//                         child: Column(
//                           mainAxisAlignment:
//                           MainAxisAlignment.center,
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Container(
//                                       decoration: decoration1,
//                                       child: provider
//                                           .isLoadingPictureSection ==
//                                           true
//                                           ? Center(
//                                         child:
//                                         CircularProgressIndicator(),
//                                       )
//                                           : provider.pdfOffline!
//                                           .isEmpty
//                                           ? boxContent(
//                                           context,
//                                           "Select PDF File",
//                                           "1",
//                                           "assets/images/cnic_icon.png",
//                                           provider,
//                                           widget
//                                               .hospitalAssessmentModel
//                                               .assessment_id!)
//                                           : Padding(
//                                         padding:
//                                         const EdgeInsets
//                                             .all(
//                                             10.0),
//                                         child: Column(
//                                           children: [
//                                             Row(
//                                               mainAxisAlignment:
//                                               MainAxisAlignment
//                                                   .spaceBetween,
//                                               children: [
//                                                 Text(
//                                                   "Preview",
//                                                   style: GoogleFonts.poppins(
//                                                       color:
//                                                       Colors.black,
//                                                       fontSize: 15),
//                                                 ),
//                                                 GestureDetector(
//                                                   onTap:
//                                                       () {
//                                                     deletePdfOffline(
//                                                         context,
//                                                         provider,
//                                                         widget.hospitalAssessmentModel.assessment_id!);
//                                                   },
//                                                   child:
//                                                   Container(
//                                                     padding: const EdgeInsets
//                                                         .all(
//                                                         4.0),
//                                                     decoration:
//                                                     const BoxDecoration(
//                                                       shape:
//                                                       BoxShape.circle,
//                                                       color:
//                                                       Colors.red,
//                                                     ),
//                                                     child:
//                                                     const Icon(
//                                                       Icons.delete,
//                                                       color:
//                                                       Colors.white,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             SizedBox(
//                                               height: 150,
//                                               child:
//                                               Padding(
//                                                 padding: const EdgeInsets
//                                                     .all(
//                                                     8.0),
//                                                 child:
//                                                 PDFView(
//                                                   filePath: provider
//                                                       .pdfOffline![0]
//                                                       .doc_id!,
//                                                   onPageChanged: (int?
//                                                   page,
//                                                       int?
//                                                       total) {
//                                                     setState(
//                                                             () {
//                                                           _pages =
//                                                           total!;
//                                                           _isPDFReadable =
//                                                           true;
//                                                         });
//                                                   },
//                                                   onError:
//                                                       (error) {
//                                                     setState(
//                                                             () {
//                                                           _isPDFReadable =
//                                                           false;
//                                                         });
//                                                   },
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       )),
//                                 ),
//                                 SizedBox(
//                                   width: 10,
//                                 ),
//                               ],
//                             ),
//                             SizedBox(
//                               height: 5,
//                             ),
//                             (provider.pdfData!.doc_id ?? "") != ''
//                                 ? Column(
//                               children: [
//                                 Row(
//                                   mainAxisAlignment:
//                                   MainAxisAlignment.start,
//                                   children: [
//                                     Flexible(
//                                       child: Text(
//                                         '1 Document is already uploaded',
//                                         style: TextStyle(
//                                             fontSize: 18,
//                                             color:
//                                             Colors.white),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 Row(
//                                   mainAxisAlignment:
//                                   MainAxisAlignment.start,
//                                   children: [
//                                     Flexible(
//                                       child: Text(
//                                         'Uploading the new document will replace the previous one',
//                                         style: TextStyle(
//                                             fontSize: 14,
//                                             color:
//                                             Colors.white),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//
//                               ],
//                             )
//                                 : SizedBox()
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             )
//                 : Flexible(
//               child: ListView.builder(
//                 itemCount: (provider.hasChild == true &&
//                     provider.selectedIndexChild != -1)
//                     ? provider
//                     .sectionList![provider.selectedIndex]
//                     .child![provider.selectedIndexChild]
//                     .questions!
//                     .isEmpty
//                     ? (provider.hasSubChild == true &&
//                     provider.selectedIndexSubChild !=
//                         -1)
//                     ? provider
//                     .sectionList![
//                 provider.selectedIndex]
//                     .child![provider.selectedIndexChild]
//                     .child![
//                 provider.selectedIndexSubChild]
//                     .questions!
//                     .length
//                     : provider
//                     .sectionList![
//                 provider.selectedIndex]
//                     .child![provider.selectedIndexChild]
//                     .questions!
//                     .length
//                     : provider
//                     .sectionList![provider.selectedIndex]
//                     .child![provider.selectedIndexChild]
//                     .questions!
//                     .length
//                     : provider.sectionList![provider.selectedIndex]
//                     .questions!.length,
//                 itemBuilder: (context, index) {
//                   return (provider.hasChild == true &&
//                       provider.selectedIndexChild != -1)
//                       ? provider
//                       .sectionList![provider.selectedIndex]
//                       .child![provider.selectedIndexChild]
//                       .questions!
//                       .isEmpty
//                       ? QuestionWidget(
//                     key: Key(provider
//                         .sectionList![
//                     provider.selectedIndex]
//                         .child![
//                     provider.selectedIndexChild]
//                         .child![provider
//                         .selectedIndexSubChild]
//                         .questions![index]
//                         .q_id!),
//                     question: provider
//                         .sectionList![
//                     provider.selectedIndex]
//                         .child![
//                     provider.selectedIndexChild]
//                         .child![provider
//                         .selectedIndexSubChild]
//                         .questions![index],
//                     type: provider
//                         .sectionList![
//                     provider.selectedIndex]
//                         .type_id ??
//                         '',
//                     aid: widget.hospitalAssessmentModel!
//                         .assessment_id!,
//                     provider: provider,
//                     fullTimeController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "1" &&
//                         _fullTimeControllers
//                             .isNotEmpty)
//                         ? _fullTimeControllers[index]
//                         : TextEditingController(),
//                     partTimeController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "1" &&
//                         _partTimeControllers
//                             .isNotEmpty)
//                         ? _partTimeControllers[index]
//                         : TextEditingController(),
//                     maleController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "2" &&
//                         _maleControllers.isNotEmpty)
//                         ? _maleControllers[index]
//                         : TextEditingController(),
//                     femaleController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "2" &&
//                         _femaleControllers.isNotEmpty)
//                         ? _femaleControllers[index]
//                         : TextEditingController(),
//                     responseTextController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         " " &&
//                         _responseTextControllers
//                             .isNotEmpty)
//                         ? _responseTextControllers[index]
//                         : TextEditingController(),
//                   )
//                       : (provider.hasSubChild == true &&
//                       provider.selectedIndexSubChild !=
//                           -1)
//                       ? QuestionWidget(
//                     key: Key(provider
//                         .sectionList![
//                     provider.selectedIndex]
//                         .child![provider
//                         .selectedIndexChild]
//                         .questions![index]
//                         .q_id!),
//                     question: provider
//                         .sectionList![
//                     provider.selectedIndex]
//                         .child![provider
//                         .selectedIndexChild]
//                         .questions![index],
//                     type: provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ??
//                         '',
//                     aid: widget
//                         .hospitalAssessmentModel!
//                         .assessment_id!,
//                     provider: provider,
//                     fullTimeController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "1" &&
//                         _fullTimeControllers
//                             .isNotEmpty)
//                         ? _fullTimeControllers[index]
//                         : TextEditingController(),
//                     partTimeController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "1" &&
//                         _partTimeControllers
//                             .isNotEmpty)
//                         ? _partTimeControllers[index]
//                         : TextEditingController(),
//                     maleController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "2" &&
//                         _maleControllers
//                             .isNotEmpty)
//                         ? _maleControllers[index]
//                         : TextEditingController(),
//                     femaleController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "2" &&
//                         _femaleControllers
//                             .isNotEmpty)
//                         ? _femaleControllers[index]
//                         : TextEditingController(),
//                     responseTextController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         " " &&
//                         _responseTextControllers
//                             .isNotEmpty)
//                         ? _responseTextControllers[
//                     index]
//                         : TextEditingController(),
//                   )
//                       : QuestionWidget(
//                     key: Key(provider
//                         .sectionList![
//                     provider.selectedIndex]
//                         .child![provider
//                         .selectedIndexChild]
//                         .questions![index]
//                         .q_id!),
//                     question: provider
//                         .sectionList![
//                     provider.selectedIndex]
//                         .child![provider
//                         .selectedIndexChild]
//                         .questions![index],
//                     type: provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ??
//                         '',
//                     aid: widget
//                         .hospitalAssessmentModel!
//                         .assessment_id!,
//                     provider: provider,
//                     fullTimeController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "1" &&
//                         _fullTimeControllers
//                             .isNotEmpty)
//                         ? _fullTimeControllers[index]
//                         : TextEditingController(),
//                     partTimeController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "1" &&
//                         _partTimeControllers
//                             .isNotEmpty)
//                         ? _partTimeControllers[index]
//                         : TextEditingController(),
//                     maleController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "2" &&
//                         _maleControllers
//                             .isNotEmpty)
//                         ? _maleControllers[index]
//                         : TextEditingController(),
//                     femaleController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "2" &&
//                         _femaleControllers
//                             .isNotEmpty)
//                         ? _femaleControllers[index]
//                         : TextEditingController(),
//                     responseTextController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         " " &&
//                         _responseTextControllers
//                             .isNotEmpty)
//                         ? _responseTextControllers[
//                     index]
//                         : TextEditingController(),
//                   )
//                       : QuestionWidget(
//                     key: Key(provider
//                         .sectionList![provider.selectedIndex]
//                         .questions![index]
//                         .q_id!),
//                     question: provider
//                         .sectionList![provider.selectedIndex]
//                         .questions![index],
//                     type: provider
//                         .sectionList![
//                     provider.selectedIndex]
//                         .type_id ??
//                         '',
//                     aid: widget.hospitalAssessmentModel!
//                         .assessment_id!,
//                     provider: provider,
//                     fullTimeController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "1" &&
//                         _fullTimeControllers.isNotEmpty)
//                         ? _fullTimeControllers[index]
//                         : TextEditingController(),
//                     partTimeController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "1" &&
//                         _partTimeControllers.isNotEmpty)
//                         ? _partTimeControllers[index]
//                         : TextEditingController(),
//                     maleController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "2" &&
//                         _maleControllers.isNotEmpty)
//                         ? _maleControllers[index]
//                         : TextEditingController(),
//                     femaleController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         "2" &&
//                         _femaleControllers.isNotEmpty)
//                         ? _femaleControllers[index]
//                         : TextEditingController(),
//                     responseTextController: (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .questions !=
//                         [] &&
//                         provider
//                             .sectionList![
//                         provider.selectedIndex]
//                             .questions!
//                             .isNotEmpty)
//                         ? (provider
//                         .sectionList![provider
//                         .selectedIndex]
//                         .type_id ==
//                         " " &&
//                         provider
//                             .sectionList![provider
//                             .selectedIndex]
//                             .questions![0]
//                             .question_type ==
//                             'text')
//                         ? _responseTextControllers[index]
//                         : TextEditingController()
//                         : TextEditingController(),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(
//               height: 8,
//             ),
//             provider.selectedIndex == -1
//                 ? const SizedBox()
//                 : Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 provider.isLoadingSubmitSection == true
//                     ? const Center(
//                   child: CircularProgressIndicator(),
//                 )
//                     : provider.sectionList![provider.selectedIndex]
//                     .type_id ==
//                     "3"
//                     ? SizedBox()
//                     : SizedBox(
//                   width: MediaQuery.of(context).size.width / 2,
//                   child: MaterialButton(
//                     onPressed: () {
//                       submitSectionOffline(
//                         provider,
//                         context,
//                       );
//                     },
//                     color: Colors.blue,
//                     elevation: 8,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(13),
//                     ),
//                     child: const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 14),
//                       child: Text(
//                         'Submit Section',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 15,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 10,
//                 ),
//                 provider.isLoadingCompleteAssessment == true
//                     ? Center(
//                   child: CircularProgressIndicator(),
//                 )
//                     : SizedBox(
//                   width: MediaQuery.of(context).size.width / 1.8,
//                   child: MaterialButton(
//                     onPressed: () {
//                       completeAssessment(
//                           context,
//                           provider,
//                           widget.hospitalAssessmentModel
//                               .assessment_id!);
//                     },
//                     color: Colors.blue,
//                     elevation: 8,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(13),
//                     ),
//                     child: const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 14),
//                       child: Text(
//                         'Complete Assessment',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 15,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Decoration decoration1 = const BoxDecoration(
//       borderRadius: BorderRadius.all(Radius.circular(20)), color: Colors.white);
//
//   List<Map<String, String>> gatherResponses(AssessmentProvider provider) {
//     List<Map<String, String>> responses = [];
//
//     for (var question in provider.selectedIndexChild == -1
//         ? provider.sectionList![provider.selectedIndex].questions!
//         : provider.sectionList![provider.selectedIndex]
//         .child![provider.selectedIndexChild].questions!) {
//       if (question.response_ids != null) {
//         final optionDescription = question.options!
//             .firstWhere((option) => option.id == question.response_ids,
//             orElse: () => Option(id: "", description: ""))
//             .description;
//         responses.add({
//           'qid': question.q_id!,
//           'response': optionDescription,
//           'response_ids': question.response_ids!.trim(),
//         });
//       }
//     }
//
//     return responses;
//   }
//
//   List<Map<String, String>> gatherResponsesOnline(List<Question> questions) {
//     List<Map<String, String>> responses = [];
//     print('12121212 ${questions.length}');
//     for (var question in questions) {
//       if (question.response_ids != null) {
//         final optionDescription = question.options!
//             .firstWhere((option) => option.id == question.response_ids,
//             orElse: () => Option(id: "", description: ""))
//             .description;
//         responses.add({
//           'qid': question.q_id!,
//           'response': optionDescription,
//           'response_ids': question.response_ids!.trim(),
//         });
//       }
//     }
//
//     return responses;
//   }
//
//   List<Map<String, String>> gatherTextResponses(AssessmentProvider provider) {
//     List<Map<String, String>> responses = [];
//
//     for (var question in provider.selectedIndexChild == -1
//         ? provider.sectionList![provider.selectedIndex].questions!
//         : provider.sectionList![provider.selectedIndex]
//         .child![provider.selectedIndexChild].questions!) {
//       responses.add({
//         'qid': question.q_id!,
//         'response': question.response!,
//         'response_ids': question.response_ids!.trim() ?? "",
//       });
//     }
//
//     return responses;
//   }
//
//   List<Map<String, String>> gatherTextResponsesOnline(
//       List<Question> questions) {
//     List<Map<String, String>> responses = [];
//
//     for (Question question in questions) {
//       responses.add({
//         'qid': question.q_id!,
//         'response': question.response!,
//         'response_ids': question.response_ids!.trim() ?? "",
//       });
//     }
//
//     return responses;
//   }
//
//   List<Map<String, String>> gatherBedResponses(AssessmentProvider provider) {
//     List<Map<String, String>> responses = [];
//
//     for (var question in provider.bedList!) {
//       responses.add({
//         'male': question.male == 0 ? '' : question.male!.toString(),
//         'female': question.female == 0 ? '' : question.female!.toString(),
//         'qid': question.q_id!,
//       });
//     }
//
//     return responses;
//   }
//
//   List<Map<String, String>> gatherStaffResponses(AssessmentProvider provider) {
//     List<Map<String, String>> responses = [];
//
//     for (var question in provider.staffList!) {
//       responses.add({
//         'full_time':
//         question.full_time == 0 ? '' : question.full_time!.toString(),
//         'part_time':
//         question.part_time == 0 ? '' : question.part_time!.toString(),
//         'qid': question.q_id!,
//       });
//     }
//
//     return responses;
//   }
//
//   Map<String, dynamic> generateJson(
//       List<Map<String, String>> responses, AssessmentProvider provider) {
//     return {
//       'responses': responses,
//     };
//   }
//
//   void resetResponses(AssessmentProvider provider) {
//     for (var section in provider.sectionList!) {
//       for (var question in section.questions!) {
//         question.response_ids = null;
//       }
//       for (var child in section.child ?? []) {
//         for (var question in child.questions ?? []) {
//           question.response_ids = null;
//         }
//       }
//     }
//   }
//
//   void resetBedResponses(AssessmentProvider provider) {}
//
//   void moveToNextSection(AssessmentProvider provider) {
//     // Implement the logic to move to the next section
//     if (provider.selectedIndex < provider.sectionList!.length - 1) {
//       provider.setChildRemovedOnBack();
//       provider.setSelectedIndex(provider.selectedIndex + 1);
//     } else {
//       // Handle completion of all sections
//     }
//   }
//
//   Widget child(AssessmentProvider provider) {
//     return SizedBox(
//       height: 120, // Adjust the height as needed
//       child: provider.isLoading == true
//           ? const Center(
//         child: CircularProgressIndicator(),
//       )
//           : ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount:
//         provider.sectionList![provider.selectedIndex].child!.length,
//         itemBuilder: (context, index) {
//           var items =
//           provider.sectionList![provider.selectedIndex].child![index];
//           return InkWell(
//             onTap: () {
//               //provider.setChildIndex(index);
//               if (items.child!.isNotEmpty) {
//                 provider.setHasSubChild(true, index);
//               } else {
//                 provider.setHasSubChild(false, index);
//               }
//             },
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 70, // Width of the circular background
//                     height: 70, // Height of the circular background
//                     decoration: BoxDecoration(
//                       color: provider.selectedIndexChild == index
//                           ? Colors.blue
//                           : getCheckChild(provider, index) == 1
//                           ? Colors.green
//                           : getCheckChild(provider, index) == 2
//                           ? Colors.redAccent
//                           : Colors.grey, // Background color
//                       shape: BoxShape.circle, // Circular shape
//                     ),
//                     child: Center(
//                       child: Padding(
//                         padding: const EdgeInsets.all(5.0),
//                         child: Text(
//                           "${items.list_title}",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 8.0, // Font size
//                             fontWeight: FontWeight.bold, // Font weight
//                             color: provider.selectedIndexChild == index
//                                 ? Colors.white
//                                 : Colors.black, // Text color
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget subChild(AssessmentProvider provider) {
//     return SizedBox(
//       height: 120, // Adjust the height as needed
//       child: provider.isLoading == true
//           ? const Center(
//         child: CircularProgressIndicator(),
//       )
//           : ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: provider.sectionList![provider.selectedIndex]
//             .child![provider.selectedIndexChild].child!.length,
//         itemBuilder: (context, index) {
//           var items = provider.sectionList![provider.selectedIndex]
//               .child![provider.selectedIndexChild].child![index];
//           return InkWell(
//             onTap: () {
//               provider.setSubChildIndex(index);
//             },
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 70, // Width of the circular background
//                     height: 70, // Height of the circular background
//                     decoration: BoxDecoration(
//                       color: provider.selectedIndexSubChild == index
//                           ? Colors.blue
//                           : getCheckSubChild(provider, index) == 1
//                           ? Colors.green
//                           : getCheckSubChild(provider, index) == 2
//                           ? Colors.redAccent
//                           : Colors.grey, // Background color
//                       shape: BoxShape.circle, // Circular shape
//                     ),
//                     child: Center(
//                       child: Padding(
//                         padding: const EdgeInsets.all(5.0),
//                         child: Text(
//                           "${items.list_title}",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 8.0, // Font size
//                             fontWeight: FontWeight.bold, // Font weight
//                             color: provider.selectedIndexChild == index
//                                 ? Colors.white
//                                 : Colors.black, // Text color
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget header(AssessmentProvider provider) {
//     return Column(
//       children: [
//         SizedBox(
//           height: 120, // Adjust the height as needed
//           child: provider.isLoading == true
//               ? const Center(
//             child: CircularProgressIndicator(),
//           )
//               : ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: provider.sectionList!.length,
//             itemBuilder: (context, index) {
//               var items = provider.sectionList![index];
//               return InkWell(
//                 onTap: () {
//                   provider.setChildRemovedOnBack();
//                   if (provider.sectionList![index].type_id == "1") {
//                     clearTextFields();
//                     getStaffData(provider, index);
//                   }
//                   if (provider.sectionList![index].type_id == "2") {
//                     clearTextFields();
//                     getBedData(provider, index);
//                   }
//                   if (provider.sectionList![index].type_id == "3") {
//                     clearTextFields();
//                     getPDFData(provider);
//                   }
//                   if (provider.sectionList![index].questions != [] &&
//                       provider
//                           .sectionList![index].questions!.isNotEmpty) {
//                     if (provider.sectionList![index].type_id == " " &&
//                         provider.sectionList![index].questions![0]
//                             .question_type ==
//                             'text') {
//                       clearTextFields();
//                       getTextData(provider, index);
//                     }
//                   }
//                   if (provider.sectionList![index].questions != [] &&
//                       provider
//                           .sectionList![index].questions!.isNotEmpty) {
//                     if (provider.sectionList![index].type_id == " " &&
//                         provider.sectionList![index].questions![0]
//                             .question_type ==
//                             'files') {
//                       clearTextFields();
//                       getPictureData(provider, index);
//                     }
//                   }
//                   if (items.child!.isNotEmpty) {
//                     provider.setHasChild(true, index);
//                   } else {
//                     provider.setHasChild(false, index);
//                   }
//                 },
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 70, // Width of the circular background
//                         height: 70, // Height of the circular background
//                         decoration: BoxDecoration(
//                           color: provider.selectedIndex == index
//                               ? Colors.blue
//                               : getCheck(provider, index) == 1
//                               ? Colors.green
//                               : getCheck(provider, index) == 2
//                               ? Colors.redAccent
//                               : Colors.grey, // Background color
//                           shape: BoxShape.circle, // Circular shape
//                         ),
//                         child: Center(
//                           child: Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: Text(
//                               "${items.list_title}",
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 8.0, // Font size
//                                 fontWeight:
//                                 FontWeight.bold, // Font weight
//                                 color: provider.selectedIndex == index
//                                     ? Colors.white
//                                     : Colors.black, // Text color
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Toast toast = Toast();
//
//   final DatabaseHelper _dbHelper = DatabaseHelper();
//   final CheckConnectivity _connectivityService = CheckConnectivity();
//
//   submitSectionOffline(
//       AssessmentProvider provider, BuildContext context) async {
//     if (provider.sectionList![provider.selectedIndex].type_id == "1") {
//       final responses = gatherStaffResponses(provider);
//       final json = generateJson(responses, provider);
//       print("STAFFJSON ${jsonEncode(json)}");
//       for (var data in json['responses']) {
//         await DatabaseHelper().updateStaffing(
//             data['qid']!,
//             int.parse(data['full_time'] == "" ? "0" : data['full_time']!),
//             int.parse(data['part_time'] == "" ? "0" : data['part_time']!));
//       }
//       clearTextFields();
//       provider.disposeValues();
//       getData();
//
//     } else if (provider.sectionList![provider.selectedIndex].type_id == "2") {
//       //bed capacity
//       final responses = gatherBedResponses(provider);
//       final json = generateJson(responses, provider);
//       print("BEDJSON ${jsonEncode(json)}");
//       for (var data in json['responses']) {
//         await DatabaseHelper().updateBedCapacity(
//             data['qid']!,
//             int.parse(data['male'] == "" ? "0" : data['male']!),
//             int.parse(data['female'] == "" ? "0" : data['female']!));
//       }
//       clearTextFields();
//       provider.disposeValues();
//       getData();
//     } else if (provider.sectionList![provider.selectedIndex].questions != [] &&
//         provider.sectionList![provider.selectedIndex].questions!.isNotEmpty) {
//       if (provider.sectionList![provider.selectedIndex].type_id == " " &&
//           provider.sectionList![provider.selectedIndex].questions![0]
//               .question_type ==
//               'text') {
//         final responses = gatherTextResponses(provider);
//         final json = generateJson(responses, provider);
//         print(jsonEncode(json)); // You can handle the JSON as needed
//         for (var data in json['responses']) {
//           await DatabaseHelper().updateQuestionInSectionData(
//               provider.selectedIndexChild == -1
//                   ? provider.sectionList![provider.selectedIndex].id!
//                   : provider.sectionList![provider.selectedIndex]
//                   .child![provider.selectedIndexChild].id!,
//               data['qid']!,
//               data['response']!,
//               data['response_ids']!);
//         }
//         resetResponses(provider); // Reset responses after gathering
//         clearTextFields();
//         provider.disposeValues();
//         getData();
//
//       } else {
//         print(
//             'ssa12 ${provider.sectionList![provider.selectedIndex].questions![0].question_type}');
//         final responses = gatherResponses(provider);
//         final json = generateJson(responses, provider);
//         print(jsonEncode(json)); // You can handle the JSON as needed
//         for (var data in json['responses']) {
//           await DatabaseHelper().updateQuestionInSectionData(
//               provider.selectedIndexChild == -1
//                   ? provider.sectionList![provider.selectedIndex].id!
//                   : provider.sectionList![provider.selectedIndex]
//                   .child![provider.selectedIndexChild].id!,
//               data['qid']!,
//               data['response']!,
//               data['response_ids']!);
//         }
//         resetResponses(provider); // Reset responses after gathering
//         clearTextFields();
//         provider.disposeValues();
//         getData();
//       }
//     }
//   }
//
//   getStaffData(AssessmentProvider provider, int index) async {
//     print('object');
//     await provider.getStaffListOffline(
//         context,
//         widget.hospitalAssessmentModel.assessment_id!,
//         widget.hospitalAssessmentModel.criteria_type_id!,
//         widget.hospitalAssessmentModel.sp_id!,
//         provider.sectionList![index].id!);
//     print('Staff list order:');
//     for (int i = 0; i < provider.staffList!.length; i++) {
//       print('  $i: ${provider.staffList![i].question} (q_id: ${provider.staffList![i].q_id})');
//     }
//     if (provider.staffList!.isNotEmpty) {
//       _fullTimeControllers = [];
//       _partTimeControllers = [];
//       _fullTimeControllers = provider.staffList!.map((staff) {
//         final controller = TextEditingController(
//             text: staff.full_time == 0 ? '' : staff.full_time.toString());
//         controller.addListener(() {
//           if (controller.text.isNotEmpty) {
//             setState(() {
//               staff.full_time = int.parse(controller.text);
//             });
//           }
//         });
//         return controller;
//       }).toList();
//       _partTimeControllers = provider.staffList!.map((staff) {
//         final controller = TextEditingController(
//             text: staff.part_time == 0 ? '' : staff.part_time.toString());
//         controller.addListener(() {
//           if (controller.text.isNotEmpty) {
//             setState(() {
//               staff.part_time = int.parse(controller.text);
//             });
//           }
//         });
//         return controller;
//       }).toList();
//     }
//   }
//
//   getBedData(AssessmentProvider provider, int index) async {
//     print('1212122');
//     await provider.getBedCapacityListOffline(
//         context,
//         widget.hospitalAssessmentModel.assessment_id!,
//         widget.hospitalAssessmentModel.criteria_type_id!,
//         widget.hospitalAssessmentModel.sp_id!,
//         provider.sectionList![index].id!);
//
//     if (provider.bedList != []) {
//       _maleControllers = [];
//       _femaleControllers = [];
//       _maleControllers = provider.bedList!.map((staff) {
//         final controller = TextEditingController(
//             text: staff.male == 0 ? '' : staff.male.toString());
//         controller.addListener(() {
//           if (controller.text.isNotEmpty) {
//             setState(() {
//               staff.male = int.parse(controller.text);
//             });
//           }
//         });
//         return controller;
//       }).toList();
//       _femaleControllers = provider.bedList!.map((staff) {
//         final controller = TextEditingController(
//             text: staff.female == 0 ? '' : staff.female.toString());
//         controller.addListener(() {
//           if (controller.text.isNotEmpty) {
//             setState(() {
//               staff.female = int.parse(controller.text);
//             });
//           }
//         });
//         return controller;
//       }).toList();
//     }
//   }
//
//   getTextData(AssessmentProvider provider, int index) {
//     if (provider.sectionList != []) {
//       _responseTextControllers = [];
//       _responseTextControllers =
//           provider.sectionList![index].questions!.map((staff) {
//             final controller =
//             TextEditingController(text: staff.response.toString());
//             controller.addListener(() {
//               if (controller.text.isNotEmpty) {
//                 setState(() {
//                   staff.response = controller.text;
//                 });
//               }
//             });
//             return controller;
//           }).toList();
//     }
//   }
//
//   getPictureData(AssessmentProvider provider, int index) async {
//     await provider.getPicturesListOffline(
//       context,
//       widget.hospitalAssessmentModel.assessment_id!,
//     );
//   }
//
//   getPDFData(AssessmentProvider provider) async {
//     await provider.getPdfOffline(
//       context,
//       widget.hospitalAssessmentModel.assessment_id!,
//     );
//   }
//
//   void showLoaderDialog(BuildContext context, String message) {
//     showDialog(
//       barrierDismissible: false,
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           content: Row(
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(width: 10),
//               Flexible(child: Text(message)),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   void updateLoaderMessage(BuildContext context, String message) {
//     Navigator.of(context).pop();
//     showLoaderDialog(context, message);
//   }
//   Future<void> completeAssessment(
//       BuildContext context,
//       AssessmentProvider provider,
//       String assessment_id,
//       ) async {
//     // ── 1. Connectivity ───────────────────────────────────────────────────────
//     if (await _connectivityService.checkConnection()==false) {
//       toast.showErrorToast(
//           'No internet connection. Please connect and try again.');
//       return;
//     }
//
//     // ── 2. Load all offline data ──────────────────────────────────────────────
//     final APIResponse jsonResponse = await DatabaseHelper().getALLItemList();
//     if (jsonResponse.data == null || jsonResponse.data!.isEmpty) {
//       toast.showErrorToast('No assessment data found to upload.');
//       return;
//     }
//     final sections = jsonResponse.data! as List<SectionModel>;
//
//     // ── 3. Pre-build item list ────────────────────────────────────────────────
//     //    Every item registered upfront → user sees full list greyed out
//     //    before upload starts, then items light up one by one.
//     final items = <_UploadItem>[];
//     int _idSeq = 0;
//     String _nextId() => '${_idSeq++}';
//
//     for (final s in sections) {
//       final sl = s.list_title ?? s.id ?? 'Section';
//       final typeLabel = _sectionTypeLabel(s);
//       items.add(_UploadItem(
//           id: _nextId(), label: '$typeLabel — $sl', indent: ''));
//
//       for (final c in s.child ?? []) {
//         items.add(_UploadItem(
//             id: _nextId(),
//             label: c.list_title ?? c.id ?? 'Sub-section',
//             indent: '  └ '));
//         for (final sub in c.child ?? []) {
//           items.add(_UploadItem(
//               id: _nextId(),
//               label: sub.list_title ?? sub.id ?? 'Item',
//               indent: '    └ '));
//         }
//       }
//     }
//
//     // ── 4. Show dialog ────────────────────────────────────────────────────────
//     final ctrl = _ProgressController(context);
//     ctrl.register(items);
//     ctrl.show();
//
//     // Cursor walks items in the exact same order as the loop below
//     int cursor = 0;
//
//     // ── Inner helpers (defined here to close over ctrl/provider/widget) ───────
//
//     Future<void> submitQuestions(
//         String itemId,
//         String sectionId,
//         List<Question> questions,
//         String qType,
//         ) async {
//       if (questions.isEmpty) {
//         ctrl.finish(itemId, success: true);
//         return;
//       }
//       final responses = qType == 'text'
//           ? gatherTextResponsesOnline(questions)
//           : gatherResponsesOnline(questions);
//       final json = generateJson(responses, provider);
//       final res = await provider.submitSection(
//         widget.hospitalAssessmentModel.criteria_type_id!,
//         widget.hospitalAssessmentModel.assessment_id!,
//         sectionId,
//         json,
//       );
//       final ok = res.status!.toLowerCase() == 'success';
//       ctrl.finish(itemId, success: ok, error: ok ? null : res.message);
//     }
//
//     Future<void> submitStaff(String itemId, String sectionId) async {
//       await provider.getStaffListOffline(
//         context,
//         widget.hospitalAssessmentModel.assessment_id!,
//         widget.hospitalAssessmentModel.criteria_type_id!,
//         widget.hospitalAssessmentModel.sp_id!,
//         sectionId,
//       );
//       final res = await provider.submitStaffSection(
//         widget.hospitalAssessmentModel.criteria_type_id!,
//         widget.hospitalAssessmentModel.assessment_id!,
//         sectionId,
//         widget.hospitalAssessmentModel.sp_id!,
//         generateJson(gatherStaffResponses(provider), provider),
//       );
//       final ok = res.status!.toLowerCase() == 'success';
//       ctrl.finish(itemId, success: ok, error: ok ? null : res.message);
//     }
//
//     Future<void> submitBed(String itemId, String sectionId) async {
//       await provider.getBedCapacityListOffline(
//         context,
//         widget.hospitalAssessmentModel.assessment_id!,
//         widget.hospitalAssessmentModel.criteria_type_id!,
//         widget.hospitalAssessmentModel.sp_id!,
//         sectionId,
//       );
//       final res = await provider.submitBedSection(
//         widget.hospitalAssessmentModel.criteria_type_id!,
//         widget.hospitalAssessmentModel.assessment_id!,
//         sectionId,
//         widget.hospitalAssessmentModel.sp_id!,
//         generateJson(gatherBedResponses(provider), provider),
//       );
//       final ok = res.status!.toLowerCase() == 'success';
//       ctrl.finish(itemId, success: ok, error: ok ? null : res.message);
//     }
//
//     // ── 5. Upload loop ────────────────────────────────────────────────────────
//     try {
//       for (final section in sections) {
//         final rootId = items[cursor].id;
//         cursor++;
//
//         // ════════════════════════════════════════════════════════════════════
//         // STAFF
//         // ════════════════════════════════════════════════════════════════════
//         if (section.type_id == "1") {
//           ctrl.begin(rootId,
//               stage: 'Uploading staff',
//               detail: section.list_title ?? '');
//           await submitStaff(rootId, section.id!);
//
//           for (final child in section.child ?? []) {
//             final cId = items[cursor].id; cursor++;
//             ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
//             await submitStaff(cId, child.id!);
//
//             for (final sub in child.child ?? []) {
//               final sId = items[cursor].id; cursor++;
//               ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
//               await submitStaff(sId, sub.id!);
//               await Future.delayed(const Duration(milliseconds: 300));
//             }
//             await Future.delayed(const Duration(milliseconds: 300));
//           }
//
//           // ════════════════════════════════════════════════════════════════════
//           // BED CAPACITY
//           // ════════════════════════════════════════════════════════════════════
//         } else if (section.type_id == "2") {
//           ctrl.begin(rootId,
//               stage: 'Uploading bed capacity',
//               detail: section.list_title ?? '');
//           await submitBed(rootId, section.id!);
//
//           for (final child in section.child ?? []) {
//             final cId = items[cursor].id; cursor++;
//             ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
//             await submitBed(cId, child.id!);
//
//             for (final sub in child.child ?? []) {
//               final sId = items[cursor].id; cursor++;
//               ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
//               await submitBed(sId, sub.id!);
//               await Future.delayed(const Duration(milliseconds: 300));
//             }
//             await Future.delayed(const Duration(milliseconds: 300));
//           }
//
//           // ════════════════════════════════════════════════════════════════════
//           // PDF
//           // ════════════════════════════════════════════════════════════════════
//         } else if (section.type_id == "3") {
//           ctrl.begin(rootId,
//               stage: 'Uploading PDF', detail: '');
//           // Reload — disposeValues() clears pdfOffline between sections
//           await provider.getPdfOffline(
//               context, widget.hospitalAssessmentModel.assessment_id!);
//           if (provider.pdfOffline != null &&
//               provider.pdfOffline!.isNotEmpty) {
//             await uploadPDF(context,
//                 widget.hospitalAssessmentModel.assessment_id!, provider);
//           }
//           ctrl.finish(rootId, success: true);
//
//           // ════════════════════════════════════════════════════════════════════
//           // QUESTION SECTIONS
//           // ════════════════════════════════════════════════════════════════════
//         } else if (section.questions != null &&
//             section.questions!.isNotEmpty) {
//
//           final qType = section.questions![0].question_type ?? '';
//           final fileType = section.questions![0].file_type ?? '';
//
//           // ── VIDEO ────────────────────────────────────────────────────────
//           if (qType == 'files' && fileType == 'video') {
//             ctrl.begin(rootId,
//                 stage: 'Uploading videos',
//                 detail: section.list_title ?? '');
//             // Reload offline videos so we have the latest file paths
//             await provider.getVideosListOffline(
//                 context, widget.hospitalAssessmentModel.assessment_id!);
//             await uploadVideosOnline(context, provider, section);
//             ctrl.finish(rootId, success: true);
//
//             for (final child in section.child ?? []) {
//               final cId = items[cursor].id; cursor++;
//               ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
//               if (child.questions != null && child.questions!.isNotEmpty) {
//                 await submitQuestions(cId, child.id!, child.questions!,
//                     child.questions![0].question_type ?? '');
//               } else {
//                 ctrl.finish(cId, success: true);
//               }
//               for (final sub in child.child ?? []) {
//                 final sId = items[cursor].id; cursor++;
//                 ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
//                 if (sub.questions != null && sub.questions!.isNotEmpty) {
//                   await submitQuestions(sId, sub.id!, sub.questions!,
//                       sub.questions![0].question_type ?? '');
//                 } else {
//                   ctrl.finish(sId, success: true);
//                 }
//                 await Future.delayed(const Duration(milliseconds: 300));
//               }
//               await Future.delayed(const Duration(milliseconds: 300));
//             }
//
//             // ── IMAGES ───────────────────────────────────────────────────────
//           } else if (qType == 'files') {
//             ctrl.begin(rootId,
//                 stage: 'Uploading images',
//                 detail: section.list_title ?? '');
//             await getPictureData(provider, 0);
//             await uploadPicturesOnline(context, provider, section);
//             ctrl.finish(rootId, success: true);
//
//             for (final child in section.child ?? []) {
//               final cId = items[cursor].id; cursor++;
//               ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
//               if (child.questions != null && child.questions!.isNotEmpty) {
//                 await submitQuestions(cId, child.id!, child.questions!,
//                     child.questions![0].question_type ?? '');
//               } else {
//                 ctrl.finish(cId, success: true);
//               }
//               for (final sub in child.child ?? []) {
//                 final sId = items[cursor].id; cursor++;
//                 ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
//                 if (sub.questions != null && sub.questions!.isNotEmpty) {
//                   await submitQuestions(sId, sub.id!, sub.questions!,
//                       sub.questions![0].question_type ?? '');
//                 } else {
//                   ctrl.finish(sId, success: true);
//                 }
//                 await Future.delayed(const Duration(milliseconds: 300));
//               }
//               await Future.delayed(const Duration(milliseconds: 300));
//             }
//
//             // ── TEXT ─────────────────────────────────────────────────────────
//           } else if (qType == 'text') {
//             ctrl.begin(rootId,
//                 stage: 'Uploading text responses',
//                 detail: section.list_title ?? '');
//             await submitQuestions(
//                 rootId, section.id!, section.questions!, 'text');
//
//             for (final child in section.child ?? []) {
//               final cId = items[cursor].id; cursor++;
//               ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
//               if (child.questions != null && child.questions!.isNotEmpty) {
//                 await submitQuestions(
//                     cId, child.id!, child.questions!, 'text');
//               } else {
//                 ctrl.finish(cId, success: true);
//               }
//               for (final sub in child.child ?? []) {
//                 final sId = items[cursor].id; cursor++;
//                 ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
//                 if (sub.questions != null && sub.questions!.isNotEmpty) {
//                   await submitQuestions(
//                       sId, sub.id!, sub.questions!, 'text');
//                 } else {
//                   ctrl.finish(sId, success: true);
//                 }
//                 await Future.delayed(const Duration(milliseconds: 300));
//               }
//               await Future.delayed(const Duration(milliseconds: 300));
//             }
//
//             // ── RADIO / OTHER ─────────────────────────────────────────────────
//           } else {
//             ctrl.begin(rootId,
//                 stage: 'Uploading responses',
//                 detail: section.list_title ?? '');
//             await submitQuestions(
//                 rootId, section.id!, section.questions!, qType);
//
//             for (final child in section.child ?? []) {
//               final cId = items[cursor].id; cursor++;
//               ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
//               if (child.questions != null && child.questions!.isNotEmpty) {
//                 await submitQuestions(cId, child.id!, child.questions!,
//                     child.questions![0].question_type ?? '');
//               } else {
//                 ctrl.finish(cId, success: true);
//               }
//               for (final sub in child.child ?? []) {
//                 final sId = items[cursor].id; cursor++;
//                 ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
//                 if (sub.questions != null && sub.questions!.isNotEmpty) {
//                   await submitQuestions(sId, sub.id!, sub.questions!,
//                       sub.questions![0].question_type ?? '');
//                 } else {
//                   ctrl.finish(sId, success: true);
//                 }
//                 await Future.delayed(const Duration(milliseconds: 300));
//               }
//               await Future.delayed(const Duration(milliseconds: 300));
//             }
//             await Future.delayed(const Duration(milliseconds: 300));
//           }
//
//           // ════════════════════════════════════════════════════════════════════
//           // NO-QUESTION SECTIONS  (children only)
//           // ════════════════════════════════════════════════════════════════════
//         } else if (section.child != null && section.child!.isNotEmpty) {
//           ctrl.begin(rootId,
//               stage: 'Uploading section',
//               detail: section.list_title ?? '');
//           ctrl.finish(rootId, success: true);
//
//           for (final child in section.child ?? []) {
//             final cId = items[cursor].id; cursor++;
//             ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
//             if (child.questions != null && child.questions!.isNotEmpty) {
//               await submitQuestions(cId, child.id!, child.questions!,
//                   child.questions![0].question_type ?? '');
//             } else {
//               ctrl.finish(cId, success: true);
//             }
//             for (final sub in child.child ?? []) {
//               final sId = items[cursor].id; cursor++;
//               ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
//               if (sub.questions != null && sub.questions!.isNotEmpty) {
//                 await submitQuestions(sId, sub.id!, sub.questions!,
//                     sub.questions![0].question_type ?? '');
//               } else {
//                 ctrl.finish(sId, success: true);
//               }
//               await Future.delayed(const Duration(milliseconds: 300));
//             }
//             await Future.delayed(const Duration(milliseconds: 300));
//           }
//
//         } else {
//           // Completely unhandled — skip silently
//           if (cursor > 0) ctrl.finish(items[cursor - 1].id, success: true);
//         }
//       }
//
//       // ── 6. Complete assessment on server ──────────────────────────────────
//       ctrl.setStage('Completing assessment...', 'Sending final request');
//
//       final APIResponse response =
//       await provider.completeAssessment(assessment_id);
//
//       ctrl.dismiss();
//
//       if (response.status!.toLowerCase() == 'success') {
//         toast.showSuccessToast(response.message ?? 'Assessment completed');
//         Get.back(result: [
//           {'backValue': 'completed'}
//         ]);
//       } else {
//         showErrorDialogCompleteAssessment(context, response);
//       }
//     } catch (e, stack) {
//       ctrl.dismiss();
//       debugPrint('completeAssessment ERROR: $e\n$stack');
//       toast.showErrorToast('Unexpected error: ${e.toString()}');
//     }
//   }
//
// // ── Section type label (used to build the pre-rendered list) ──────────────
//   String _sectionTypeLabel(SectionModel s) {
//     if (s.type_id == "1") return 'Staff';
//     if (s.type_id == "2") return 'Bed capacity';
//     if (s.type_id == "3") return 'PDF';
//     if (s.questions == null || s.questions!.isEmpty) return 'Responses';
//     final qt = s.questions![0].question_type ?? '';
//     final ft = s.questions![0].file_type ?? '';
//     if (qt == 'files' && ft == 'video') return '🎥 Video';
//     if (qt == 'files') return '🖼 Images';
//     if (qt == 'text') return 'Text';
//     return 'Responses';
//   }
//
//   Future<void> completeAssessmentWorking(BuildContext context,
//       AssessmentProvider provider, String assessment_id) async {
//     if (await _connectivityService.checkConnection() == true) {
//       showLoaderDialog(context, 'Starting upload...');
//       final APIResponse jsonResponse = await DatabaseHelper().getALLItemList();
//       if (jsonResponse.data != []) {
//         bool allSectionsSuccess = true;
//         for (SectionModel sectionModel in jsonResponse.data!) {
//           if (sectionModel.type_id == "1") {
//             updateLoaderMessage(context, 'Uploading staff section...');
//             await provider.getStaffListOffline(
//                 context,
//                 widget.hospitalAssessmentModel.assessment_id!,
//                 widget.hospitalAssessmentModel.criteria_type_id!,
//                 widget.hospitalAssessmentModel.sp_id!,
//                 sectionModel.id!);
//             final responses = gatherStaffResponses(provider);
//             final json = generateJson(responses, provider);
//             print(jsonEncode(json));
//             APIResponse res = await provider.submitStaffSection(
//                 widget.hospitalAssessmentModel.criteria_type_id!,
//                 widget.hospitalAssessmentModel.assessment_id!,
//                 sectionModel.id!,
//                 widget.hospitalAssessmentModel.sp_id!,
//                 json);
//             if (res.status!.toLowerCase() != 'success') {
//               toast.showErrorToast('STAFF ${res.message}' ?? '');
//               allSectionsSuccess = false;
//               break;
//             }
//           } else if (sectionModel.type_id == "2") {
//             updateLoaderMessage(context, 'Uploading bed capacity...');
//             await provider.getBedCapacityListOffline(
//                 context,
//                 widget.hospitalAssessmentModel.assessment_id!,
//                 widget.hospitalAssessmentModel.criteria_type_id!,
//                 widget.hospitalAssessmentModel.sp_id!,
//                 sectionModel.id!);
//             final responses = gatherBedResponses(provider);
//             final json = generateJson(responses, provider);
//             print(jsonEncode(json));
//             APIResponse res = await provider.submitBedSection(
//                 widget.hospitalAssessmentModel.criteria_type_id!,
//                 widget.hospitalAssessmentModel.assessment_id!,
//                 sectionModel.id!,
//                 widget.hospitalAssessmentModel.sp_id!,
//                 json);
//             if (res.status!.toLowerCase() != 'success') {
//               toast.showErrorToast('BED ${res.message}' ?? '');
//               allSectionsSuccess = false;
//               break;
//             }
//           } else if (sectionModel.type_id == "3") {
//             updateLoaderMessage(context, 'Uploading PDF...');
//             uploadPDF(context, widget.hospitalAssessmentModel.assessment_id!,
//                 provider);
//           } else if (sectionModel.type_id == " " &&
//               sectionModel.questions![0].question_type == 'files') {
//             updateLoaderMessage(context, 'Uploading pictures...');
//             await getPictureData(provider, 0);
//             await uploadPicturesOnline(context, provider, sectionModel);
//           } else if (sectionModel.type_id == " " &&
//               sectionModel.questions![0].question_type == 'text') {
//             updateLoaderMessage(context, 'Uploading text responses...');
//             final responses =
//             gatherTextResponsesOnline(sectionModel.questions!);
//             final json = generateJson(responses, provider);
//             print(jsonEncode(json));
//             APIResponse res = await provider.submitSection(
//                 widget.hospitalAssessmentModel.criteria_type_id!,
//                 widget.hospitalAssessmentModel.assessment_id!,
//                 sectionModel.id!,
//                 json);
//             if (res.status!.toLowerCase() != 'success') {
//               toast.showErrorToast('TEXT ${res.message}' ?? '');
//               allSectionsSuccess = false;
//               break;
//             }
//           } else {
//             updateLoaderMessage(context, 'Uploading responses...');
//             final responses = gatherResponsesOnline(sectionModel.questions!);
//             final json = generateJson(responses, provider);
//             print('ResponseJSON ${jsonEncode(json)}');
//             APIResponse res = await provider.submitSection(
//                 widget.hospitalAssessmentModel.criteria_type_id!,
//                 widget.hospitalAssessmentModel.assessment_id!,
//                 sectionModel.id!,
//                 json);
//             if (res.status!.toLowerCase() != 'success') {
//               toast.showErrorToast('RESPONSE ${res.message}' ?? '');
//               allSectionsSuccess = false;
//               break;
//             }
//           }
//           // Process child sections
//           if (sectionModel.child != []) {
//             for (SectionChildModel childModel in sectionModel.child!) {
//               updateLoaderMessage(context, 'Uploading child section...');
//               final responses = gatherResponsesOnline(childModel.questions!);
//               final json = generateJson(responses, provider);
//               print(jsonEncode(json));
//               APIResponse res = await provider.submitSection(
//                   widget.hospitalAssessmentModel.criteria_type_id!,
//                   widget.hospitalAssessmentModel.assessment_id!,
//                   childModel.id!,
//                   json);
//               if (res.status!.toLowerCase() != 'success') {
//                 toast.showErrorToast('RESPONSE ${res.message}' ?? '');
//                 allSectionsSuccess = false;
//                 break;
//               }
//             }
//           }
//
//           // If any section failed, break out of the main loop
//           if (!allSectionsSuccess) break;
//         }
//
//         // After all sections are processed, complete the assessment if all sections were successful
//         if (allSectionsSuccess) {
//           updateLoaderMessage(context, 'Completing assessment...');
//           APIResponse response =
//           await provider.completeAssessment(assessment_id);
//           Navigator.of(context, rootNavigator: true)
//               .pop(); // Dismiss the dialog
//           if (response.status!.toLowerCase() == 'success') {
//             toast.showSuccessToast('${response.message}');
//             Get.back(result: [
//               {"backValue": "done"}
//             ]);
//           } else {
//             showErrorDialogCompleteAssessment(context, response);
//           }
//         } else {
//           Navigator.of(context, rootNavigator: true)
//               .pop(); // Dismiss the dialog if any section failed
//         }
//       } else {
//         Navigator.of(context, rootNavigator: true)
//             .pop(); // Dismiss the dialog if no data to process
//       }
//     } else {
//       toast.showErrorToast(
//           'You need internet connection to upload this assessment');
//     }
//   }
//   Future<void> uploadVideosOnline(BuildContext context,
//       AssessmentProvider provider, SectionModel sectionModel) async {
//     final videoList = provider.videoList;
//     if (videoList == null || videoList.isEmpty) {
//       print('uploadVideosOnline: no videos found for this section');
//       return;
//     }
//
//     for (VideoSectionModel videoModel in videoList) {
//       // Find the matching question in this section
//       Question? matchingQuestion = sectionModel.questions!.firstWhere(
//             (q) => q.q_id == videoModel.qid,
//         orElse: () => Question(q_id: ''),
//       );
//
//       if (matchingQuestion.q_id == null || matchingQuestion.q_id!.isEmpty) {
//         print(
//             'uploadVideosOnline: no matching question for qid=${videoModel.qid}');
//         continue;
//       }
//
//       // doc_id holds the local file path (set in insertVideo)
//       final filePath = videoModel.doc_id;
//       if (filePath == null || filePath.isEmpty) {
//         print('uploadVideosOnline: empty file path for qid=${videoModel.qid}');
//         continue;
//       }
//
//       final file = File(filePath);
//       if (!file.existsSync()) {
//         toast.showErrorToast(
//             'Video file missing for: ${matchingQuestion.description ?? matchingQuestion.q_id}');
//         print('uploadVideosOnline: file not found at $filePath');
//         continue; // skip missing file, don't block other uploads
//       }
//
//       final filename =
//           'video_${matchingQuestion.q_id}_${DateTime.now().millisecondsSinceEpoch}.mp4';
//
//       updateLoaderMessage(
//         context,
//         'Uploading video:\n${matchingQuestion.description ?? matchingQuestion.q_id}',
//       );
//
//       print(
//           'uploadVideosOnline: uploading ${file.path} (${(file.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)');
//
//       final APIResponse? res = await provider.uploadVideo(
//         context,
//         widget.hospitalAssessmentModel.assessment_id!,
//         matchingQuestion.q_id!,
//         sectionModel.id!, // csid
//         filename,
//         file,
//       );
//
//       if (res?.status?.toLowerCase() == 'success') {
//         print('uploadVideosOnline: success for qid=${matchingQuestion.q_id}');
//       } else {
//         toast.showErrorToast(
//             'VIDEO UPLOAD FAILED: ${res?.message ?? 'Unknown error'}');
//         print(
//             'uploadVideosOnline: failed for qid=${matchingQuestion.q_id} — ${res?.message}');
//         // continue to next video — same behaviour as uploadPicturesOnline
//       }
//
//       // Small delay between uploads to avoid server overload
//       await Future.delayed(const Duration(milliseconds: 500));
//     }
//   }
//   Future<void> uploadPicturesOnline(BuildContext context,
//       AssessmentProvider provider, SectionModel sectionModel) async {
//     for (PicturesSectionModel picturesSectionModel in provider.picsList!) {
//       // Find the corresponding question for the picture
//       Question? matchingQuestion = sectionModel.questions!.firstWhere(
//               (question) => question.q_id == picturesSectionModel.qid,
//           orElse: () => Question(q_id: ''));
//
//       if (matchingQuestion.q_id != '') {
//         print('Uploading picture for question ${matchingQuestion.q_id}');
//         XFile imageFile = XFile(picturesSectionModel.doc_id!);
//         APIResponse? res = await provider.pickImage(
//             context,
//             widget.hospitalAssessmentModel.assessment_id!,
//             matchingQuestion.q_id!,
//             sectionModel.id!,
//             imageFile.name,
//             imageFile);
//         if (res!.status!.toLowerCase() != 'success') {
//           toast.showErrorToast('TEXT ${res.message}' ?? '');
//           break;
//         }
//       } else {
//         print(
//             'No matching question found for picture with doc_id ${picturesSectionModel.doc_id}');
//       }
//     }
//   }
//
//   Widget boxContent(BuildContext context, String name, String no, String image,
//       AssessmentProvider provider, String aid) {
//     return GestureDetector(
//       onTap: () {
//         _pickPDFFile(provider, aid);
//       },
//       child: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(10.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2), // Shadow color
//                         spreadRadius: 2, // Spread radius
//                         blurRadius: 5, // Blur radius
//                         offset:
//                         const Offset(2, 4), // Offset (vertical, horizontal)
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Image.asset(
//                       image,
//                       height: 0.04.sh,
//                       width: 0.04.sh,
//                     ),
//                   )),
//               SizedBox(height: 15.h),
//               Text(
//                 name,
//                 style: GoogleFonts.poppins(fontSize: 12.sp),
//               ),
//               SizedBox(height: 2.0.h),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                         child: Container(
//                           decoration: const BoxDecoration(
//                               borderRadius: BorderRadius.all(Radius.circular(10)),
//                               color: Colors.white),
//                           child: Padding(
//                             padding: const EdgeInsets.all(2.0),
//                             child: Text(
//                               "UPLOAD",
//                               style: GoogleFonts.poppins(
//                                   color: color.bluePrimary,
//                                   fontSize: 12.sp,
//                                   fontWeight: FontWeight.w600),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         )),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   List<int>? pdfBytes;
//   FilePickerResult _pdfFileResult = const FilePickerResult([]);
//   TextEditingController amountController = TextEditingController();
//
//   Future<void> _pickPDFFile(AssessmentProvider provider, String aid) async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//         allowCompression: true,
//         compressionQuality: 50,
//         allowMultiple: false,
//       );
//
//       if (result != null) {
//         // setState(() {
//         //   _pdfFileResult = result;
//         // });
//
//         XFile pdfFile = XFile(result.files.single.path!);
//         print('sdsadasd ${pdfFile.path}');
//         APIResponse? res = await provider.pickPdfOffline(context, aid, pdfFile);
//         if (res!.status!.toLowerCase() == 'success') {
//           toast.showSuccessToast(res.message ?? "");
//           getPDFData(provider);
//         } else {
//           toast.showErrorToast('ERROR: ${res.message}');
//         }
//       }
//     } catch (e) {
//       toast.showErrorToast("Error picking PDF file: $e");
//     }
//   }
//
//   late int _pages;
//   bool _isPDFReadable = true;
//
//   uploadPDF(
//       BuildContext context, String aid, AssessmentProvider provider) async {
//     File file = File(provider.pdfOffline![0].doc_id!);
//     if (file.existsSync()) {
//       Uint8List image = await file.readAsBytes();
//       APIResponse? res = await provider.pickPDF(
//           context,
//           aid,
//           provider.sectionList!
//               .firstWhere((o) => o.type_id == "3",
//               orElse: () => SectionModel(id: aid))
//               .id!,
//           'Special Document.pdf',
//           image);
//       if (res!.status!.toLowerCase() != 'success') {
//         toast.showErrorToast('TEXT ${res.message}' ?? '');
//       } else {
//         toast.showErrorToast(res.message ?? '');
//       }
//     }
//   }
//
//   Future<void> openURL(BuildContext context, String docID) async {
//     String url =
//         "https://apps.slichealth.com/ords/ihmis_admin/assesment/pdf?doc_id=$docID";
//     try {
//       if (await canLaunchUrl(Uri.parse(url))) {
//         await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//       } else {
//         toast.showErrorToast("Failed: Could not launch $url");
//       }
//     } catch (e) {
//       toast.showErrorToast("Catch: Could not launch ${e.toString()}");
//     }
//   }
//
//   void clearTextFields() {
//     _fullTimeControllers.clear();
//     _partTimeControllers.clear();
//     _maleControllers.clear();
//     _femaleControllers.clear();
//     _responseTextControllers.clear();
//   }
//
//   getCheck(AssessmentProvider provider, int index) {
//     if (provider.sectionList![index].type_id == "3") {
//       if (provider.pdfOffline!.isEmpty) {
//         return 0;
//       } else {
//         return 1;
//       }
//     }
//     // else if () {}
//     // else if () {}
//     // else if () {}
//     else {
//       if ((provider.sectionList![index].questions!.length) ==
//           (provider.sectionList![index].questions!
//               .where((element) => element.response!.trim() != "")
//               .length)) {
//         return 1;
//       }
//       if (provider.sectionList![index].questions!
//           .where((element) => element.response!.trim() != "")
//           .isNotEmpty) {
//         return 2;
//       }
//       if (provider.sectionList![index].questions!
//           .where((element) => element.response!.trim() != "")
//           .isEmpty) {
//         return 0;
//       }
//     }
//   }
//
//   getCheckChild(AssessmentProvider provider, int index) {
//     if ((provider.sectionList![provider.selectedIndex].child![index].questions!
//         .length) ==
//         provider.sectionList![provider.selectedIndex].child![index].questions!
//             .where((element) => element.response!.trim() != "")
//             .length) {
//       return 1;
//     }
//     if (provider.sectionList![provider.selectedIndex].child![index].questions!
//         .isNotEmpty) {
//       return 2;
//     }
//     if (provider.sectionList![provider.selectedIndex].child![index].questions!
//         .isEmpty) {
//       return 0;
//     }
//   }
//
//   getCheckSubChild(AssessmentProvider provider, int index) {
//     if ((provider
//         .sectionList![provider.selectedIndex]
//         .child![provider.selectedIndexChild]
//         .child![index]
//         .questions!
//         .length) ==
//         provider.sectionList![provider.selectedIndex]
//             .child![provider.selectedIndexChild].child![index].questions!
//             .where((element) => element.response!.trim() != "")
//             .length) {
//       return 1;
//     }
//     if (provider
//         .sectionList![provider.selectedIndex]
//         .child![provider.selectedIndexChild]
//         .child![index]
//         .questions!
//         .isNotEmpty) {
//       return 2;
//     }
//     if (provider.sectionList![provider.selectedIndex]
//         .child![provider.selectedIndexChild].child![index].questions!.isEmpty) {
//       return 0;
//     }
//   }
//
//   Future<void> deletePdfOffline(
//       BuildContext context, AssessmentProvider provider, String aid) async {
//     APIResponse res = await DatabaseHelper().deletePdf(aid);
//
//     if (res.status!.toLowerCase() == 'success') {
//       getPDFData(provider);
//     }
//   }
// }
//
// class QuestionWidget extends StatefulWidget {
//   final Question question;
//   final String type;
//   String? aid;
//   final AssessmentProvider provider;
//   TextEditingController? fullTimeController;
//   TextEditingController? partTimeController;
//   TextEditingController? maleController;
//   TextEditingController? femaleController;
//   TextEditingController? responseTextController;
//
//   QuestionWidget(
//       {required Key key,
//         required this.question,
//         required this.type,
//         this.aid,
//         required this.provider,
//         this.fullTimeController,
//         this.partTimeController,
//         this.maleController,
//         this.femaleController,
//         this.responseTextController})
//       : super(key: key);
//
//   @override
//   _QuestionWidgetState createState() => _QuestionWidgetState();
// }
//
// class _QuestionWidgetState extends State<QuestionWidget> {
//   String? selectedOption;
//
//   getPictureData(BuildContext context, AssessmentProvider provider) async {
//     await provider.getPicturesListOffline(
//       context,
//       widget.aid!,
//     );
//   }
//
//   getPDFData(BuildContext context, AssessmentProvider provider) async {
//     await provider.getPdfOffline(
//       context,
//       widget.aid!,
//     );
//   }
//
//   Toast toast = Toast();
//
//   showBottomSheetNew(BuildContext context, String aid, String qid,
//       AssessmentProvider provider) async {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return SafeArea(
//           child: Wrap(
//             children: <Widget>[
//               ListTile(
//                 leading: const Icon(Icons.camera),
//                 title: const Text('Camera'),
//                 onTap: () async {
//                   Navigator.pop(context);
//                   final pickedFile =
//                   await ImagePicker().pickImage(source: ImageSource.camera);
//                   if (pickedFile != null) {
//                     // Do something with the picked image
//                     XFile imageFile = XFile(pickedFile.path);
//                     APIResponse? res = await provider.pickImageOffline(
//                         context, aid, qid, imageFile);
//                     if (res!.status!.toLowerCase() == 'success') {
//                       toast.showSuccessToast(res.message ?? "");
//                       getPictureData(context, provider);
//                     } else {
//                       toast.showErrorToast(res.message ?? '');
//                     }
//                   }
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Gallery'),
//                 onTap: () async {
//                   Navigator.pop(context);
//                   final pickedFile =
//                   await ImagePicker().pickImage(source: ImageSource.gallery);
//                   if (pickedFile != null) {
//                     XFile imageFile = XFile(pickedFile.path);
//                     APIResponse? res = await provider.pickImageOffline(
//                         context, aid, qid, imageFile);
//                     if (res!.status!.toLowerCase() == 'success') {
//                       toast.showSuccessToast(res.message ?? "");
//                       getPictureData(context, provider);
//                     } else {
//                       toast.showErrorToast(res.message ?? '');
//                     }
//                   }
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     print('object12131 ${widget.type}');
//     selectedOption = widget.question.response_ids;
//   }
//
//   bool allQuestionsAnswered(Question question) {
//     return question.response!.trim() != "";
//   }
//
//   getCheck(AssessmentProvider provider, int index) {
//     if ((provider.sectionList![index].questions!.length) ==
//         (provider.sectionList![index].questions!
//             .where((element) => element.response != " ")
//             .length)) {
//       return 1;
//     }
//     if (provider.sectionList![index].questions!
//         .where((element) => element.response != " ")
//         .isNotEmpty) {
//       return 2;
//     }
//     if (provider.sectionList![index].questions!
//         .where((element) => element.response != " ")
//         .isEmpty) {
//       return 0;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.all(8.0),
//       color: allQuestionsAnswered(widget.question)
//           ? Colors.greenAccent
//           : Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               widget.question.description ?? "",
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(),
//             if (widget.type == "1") //Staffing
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Flexible(
//                     child: Padding(
//                       padding: const EdgeInsets.all(2.0),
//                       child: TextField(
//                         textAlign: TextAlign.center,
//                         controller: widget.fullTimeController,
//                         keyboardType: TextInputType.number,
//                         decoration: InputDecoration(
//                           labelText: 'Full Time',
//                           hintText: 'No.',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           filled: true,
//                           contentPadding: const EdgeInsets.all(10),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Flexible(
//                     child: Padding(
//                       padding: const EdgeInsets.all(2.0),
//                       child: TextField(
//                         textAlign: TextAlign.center,
//                         controller: widget.partTimeController,
//                         keyboardType: TextInputType.number,
//                         decoration: InputDecoration(
//                           labelText: 'Part Time',
//                           hintText: 'No.',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           filled: true,
//                           contentPadding: const EdgeInsets.all(10),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             if (widget.type == "2") //Bed
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Flexible(
//                     child: Padding(
//                       padding: const EdgeInsets.all(2.0),
//                       child: TextField(
//                         textAlign: TextAlign.center,
//                         controller: widget.maleController,
//                         keyboardType: TextInputType.number,
//                         onChanged: (val) {
//                           print('object ${val}');
//                           if (val.isNotEmpty) {
//                             widget.maleController!.text = val;
//                           }
//                         },
//                         decoration: InputDecoration(
//                           labelText: 'Male',
//                           hintText: 'No.',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           filled: true,
//                           contentPadding: const EdgeInsets.all(10),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Flexible(
//                     child: Padding(
//                       padding: const EdgeInsets.all(2.0),
//                       child: TextField(
//                         textAlign: TextAlign.center,
//                         controller: widget.femaleController,
//                         keyboardType: TextInputType.number,
//                         onChanged: (val) {
//                           if (val.isNotEmpty) {
//                             widget.femaleController!.text = val;
//                           }
//                         },
//                         decoration: InputDecoration(
//                           labelText: 'Female',
//                           hintText: 'No.',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           filled: true,
//                           contentPadding: const EdgeInsets.all(10),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             widget.question.question_type == 'radio'
//                 ? ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: widget.question.options!.length,
//               itemBuilder: (context, index) {
//                 final option = widget.question.options![index];
//
//                 return RadioListTile<String>(
//                   title: Text(option.description),
//                   value: option.id,
//                   groupValue: selectedOption,
//                   onChanged: (value) {
//                     setData(value, option, widget.question);
//                   },
//                 );
//               },
//             )
//                 : widget.question.question_type == 'files'
//             // ── files branch: split on file_type ─────────────────────────
//                 ? (widget.question.file_type == 'video')
//             // ── VIDEO ────────────────────────────────────────────────
//                 ? VideoQuestionWidget(
//               key: ValueKey('video_${widget.question.q_id}'),
//               isOffline: true,
//               qid: widget.question.q_id!,
//               aid: widget.aid ?? '',
//               sid: (widget.provider.selectedIndexSubChild != -1
//                   ? widget
//                   .provider
//                   .sectionList![widget.provider.selectedIndex]
//                   .child![widget.provider.selectedIndexChild]
//                   .child![
//               widget.provider.selectedIndexSubChild]
//                   .id!
//                   : widget.provider.selectedIndexChild != -1
//                   ? widget
//                   .provider
//                   .sectionList![
//               widget.provider.selectedIndex]
//                   .child![
//               widget.provider.selectedIndexChild]
//                   .id!
//                   : widget
//                   .provider
//                   .sectionList![
//               widget.provider.selectedIndex]
//                   .id!),
//               questionDescription:
//               widget.question.description ?? '',
//               provider: widget.provider,
//             )
//                 : Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 widget.provider.picsList != []
//                     ? widget.provider.picsList!
//                     .where((e) =>
//                 e.qid == widget.question!.q_id)
//                     .isNotEmpty
//                     ? GestureDetector(
//                   onTap: () {
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return Dialog(
//                           child: Container(
//                             width: double.infinity,
//                             height: double.infinity,
//                             color: Colors.black,
//                             child: GestureDetector(
//                               onTap: () {
//                                 Navigator.of(context)
//                                     .pop();
//                               },
//                               child: Image.file(
//                                 File(
//                                     '${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}'),
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                   child: SizedBox(
//                     height: 150,
//                     width: 150,
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         const CircularProgressIndicator(),
//                         Image.file(
//                           File(
//                               '${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}'),
//                           key: ValueKey(
//                             '${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}',
//                           ),
//                           fit: BoxFit.cover,
//                           errorBuilder: (BuildContext
//                           context,
//                               Object error,
//                               StackTrace? stackTrace) {
//                             return const Icon(
//                                 Icons.error);
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//                     : const SizedBox()
//                     : const SizedBox(),
//                 Column(
//                   children: [
//                     widget.provider.picsList != []
//                         ? widget.provider.picsList!
//                         .where((e) =>
//                     e.qid ==
//                         widget.question!.q_id)
//                         .isEmpty
//                         ? SizedBox(
//                       child: MaterialButton(
//                         onPressed: () {
//                           showBottomSheetNew(
//                               context,
//                               widget.aid!,
//                               widget.question.q_id!,
//                               widget.provider);
//                         },
//                         color: Colors.grey,
//                         elevation: 8,
//                         shape: RoundedRectangleBorder(
//                           borderRadius:
//                           BorderRadius.circular(13),
//                         ),
//                         child: const Padding(
//                           padding: EdgeInsets.symmetric(
//                               vertical: 14),
//                           child: Text(
//                             'Upload Picture',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight:
//                               FontWeight.bold,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ),
//                       ),
//                     )
//                         : const SizedBox()
//                         : const SizedBox(),
//                     widget.provider.picsList != []
//                         ? widget.provider.picsList!
//                         .where((e) =>
//                     e.qid ==
//                         widget.question!.q_id)
//                         .isNotEmpty
//                         ? (widget.provider.isLoadingDelete ==
//                         true)
//                         ? const Center(
//                       child:
//                       CircularProgressIndicator(),
//                     )
//                         : SizedBox(
//                       child: MaterialButton(
//                         onPressed: () {
//                           deletePicture(
//                               context,
//                               widget.aid!,
//                               widget.question.q_id!,
//                               widget.provider);
//                         },
//                         color: Colors.red,
//                         elevation: 8,
//                         shape:
//                         RoundedRectangleBorder(
//                           borderRadius:
//                           BorderRadius.circular(
//                               13),
//                         ),
//                         child: const Padding(
//                           padding:
//                           EdgeInsets.symmetric(
//                               vertical: 14),
//                           child: Text(
//                             'Delete Picture',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight:
//                               FontWeight.bold,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ),
//                       ),
//                     )
//                         : const SizedBox()
//                         : const SizedBox(),
//                   ],
//                 ),
//               ],
//             )
//                 : (widget.question.question_type == "text" &&
//                 widget.type == " ")
//                 ? Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Flexible(
//                   child: Padding(
//                     padding: const EdgeInsets.all(2.0),
//                     child: TextField(
//                       textAlign: TextAlign.center,
//                       controller: widget.responseTextController,
//                       keyboardType: TextInputType.text,
//                       decoration: InputDecoration(
//                         hintText: '',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         filled: true,
//                         contentPadding: const EdgeInsets.all(10),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             )
//                 : const SizedBox(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   deletePicture(BuildContext context, String aid, String qid,
//       AssessmentProvider provider) async {
//     //APIResponse res = await provider.deletePicture(context, aid, qid);
//     APIResponse res = await DatabaseHelper().deleteImage(qid);
//
//     if (res.status!.toLowerCase() == 'success') {
//       getPictureData(context, provider);
//     }
//   }
//
//   void setData(String? value, Option option, Question question) async {
//     //print('qqwq ${question.options!.firstWhere((option1) => option1.id == option.id, orElse: () => Option(id: "", description: "")).description}');
//     await DatabaseHelper().updateQuestionInSectionData(
//         widget.provider.selectedIndexSubChild != -1
//             ? widget
//             .provider
//             .sectionList![widget.provider.selectedIndex]
//             .child![widget.provider.selectedIndexChild]
//             .child![widget.provider.selectedIndexSubChild]
//             .id!
//             : widget.provider.selectedIndexChild != -1
//             ? widget.provider.sectionList![widget.provider.selectedIndex]
//             .child![widget.provider.selectedIndexChild].id!
//             : widget
//             .provider.sectionList![widget.provider.selectedIndex].id!,
//         question.q_id!,
//         question.options!
//             .firstWhere((option1) => option1.id == option.id,
//             orElse: () => Option(id: "", description: ""))
//             .description,
//         option.id);
//     setState(() {
//       selectedOption = value;
//       widget.question.response_ids = value;
//     });
//   }
// }
//
// enum _UploadStatus { pending, running, done, failed }
//
// class _UploadItem {
//   final String id;
//   final String label;
//   final String indent;
//   _UploadStatus status;
//   String? errorMsg;
//
//   _UploadItem({
//     required this.id,
//     required this.label,
//     required this.indent,
//     this.status = _UploadStatus.pending,
//     this.errorMsg,
//   });
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // CONTROLLER
// // ─────────────────────────────────────────────────────────────────────────────
//
// class _ProgressController {
//   final BuildContext rootContext;
//   final _notifier = ValueNotifier<int>(0);
//
//   String _stage = 'Preparing...';
//   String _detail = '';
//   int _done = 0;
//   int _total = 0;
//   final List<_UploadItem> _items = [];
//   bool _isShowing = false;
//
//   _ProgressController(this.rootContext);
//
//   void register(List<_UploadItem> items) {
//     _items.addAll(items);
//     _total = items.length;
//     _notify();
//   }
//
//   void begin(String itemId, {String? stage, String? detail}) {
//     if (stage != null) _stage = stage;
//     _detail = detail ?? '';
//     final item = _find(itemId);
//     if (item != null) item.status = _UploadStatus.running;
//     _notify();
//   }
//
//   void finish(String itemId, {required bool success, String? error}) {
//     final item = _find(itemId);
//     if (item != null) {
//       item.status = success ? _UploadStatus.done : _UploadStatus.failed;
//       item.errorMsg = error;
//     }
//     _done++;
//     _notify();
//   }
//
//   void setStage(String stage, [String detail = '']) {
//     _stage = stage;
//     _detail = detail;
//     _notify();
//   }
//
//   _UploadItem? _find(String id) {
//     try {
//       return _items.firstWhere((i) => i.id == id);
//     } catch (_) {
//       return null;
//     }
//   }
//
//   void show() {
//     _isShowing = true;
//     showDialog(
//       context: rootContext,
//       barrierDismissible: false,
//       builder: (_) => _ProgressDialog(ctrl: this),
//     );
//   }
//
//   void dismiss() {
//     if (_isShowing) {
//       _isShowing = false;
//       Navigator.of(rootContext, rootNavigator: true).pop();
//     }
//   }
//
//   void _notify() => _notifier.value++;
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // PROGRESS DIALOG
// // ─────────────────────────────────────────────────────────────────────────────
//
// class _ProgressDialog extends StatelessWidget {
//   final _ProgressController ctrl;
//   const _ProgressDialog({required this.ctrl});
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async => false,
//       child: Dialog(
//         shape:
//         RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         insetPadding:
//         const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
//         clipBehavior: Clip.antiAlias,
//         child: ValueListenableBuilder<int>(
//           valueListenable: ctrl._notifier,
//           builder: (_, __, ___) {
//             final total = ctrl._total;
//             final done = ctrl._done;
//             final progress = total > 0 ? done / total : null;
//             final failed = ctrl._items
//                 .where((i) => i.status == _UploadStatus.failed)
//                 .length;
//             final pct = progress != null
//                 ? '${(progress * 100).round()}%'
//                 : '';
//             final headerColor =
//             failed > 0 ? Colors.orange.shade600 : Colors.blue.shade600;
//
//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // ── Colour header band ─────────────────────────────────
//                 Container(
//                   width: double.infinity,
//                   color: headerColor,
//                   padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(children: [
//                         done < total || total == 0
//                             ? const SizedBox(
//                           width: 16,
//                           height: 16,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                             : const Icon(Icons.check_circle,
//                             color: Colors.white, size: 16),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             ctrl._stage,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w700,
//                               letterSpacing: 0.1,
//                             ),
//                           ),
//                         ),
//                         if (pct.isNotEmpty)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Text(pct,
//                                 style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600)),
//                           ),
//                       ]),
//                       if (ctrl._detail.isNotEmpty) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           ctrl._detail,
//                           style: TextStyle(
//                               color: Colors.white.withOpacity(0.82),
//                               fontSize: 11),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                       const SizedBox(height: 12),
//                       // Progress bar
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(4),
//                         child: LinearProgressIndicator(
//                           value: progress,
//                           minHeight: 5,
//                           backgroundColor:
//                           Colors.white.withOpacity(0.25),
//                           valueColor: const AlwaysStoppedAnimation(
//                               Colors.white),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         mainAxisAlignment:
//                         MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             '$done / $total sections',
//                             style: TextStyle(
//                                 color: Colors.white.withOpacity(0.8),
//                                 fontSize: 10),
//                           ),
//                           if (failed > 0)
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 6, vertical: 1),
//                               decoration: BoxDecoration(
//                                 color: Colors.red.shade400,
//                                 borderRadius:
//                                 BorderRadius.circular(8),
//                               ),
//                               child: Text(
//                                 '$failed failed',
//                                 style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 10),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // ── Section list ───────────────────────────────────────
//                 ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxHeight:
//                     MediaQuery.of(context).size.height * 0.36,
//                     minHeight: 60,
//                   ),
//                   child: ListView.builder(
//                     shrinkWrap: true,
//                     padding: const EdgeInsets.symmetric(vertical: 6),
//                     itemCount: ctrl._items.length,
//                     itemBuilder: (_, i) =>
//                         _ItemRow(item: ctrl._items[i]),
//                   ),
//                 ),
//
//                 // ── Bottom warning / spacer ────────────────────────────
//                 if (failed > 0)
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 10),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.shade50,
//                       border: Border(
//                           top: BorderSide(
//                               color: Colors.orange.shade200,
//                               width: 0.8)),
//                     ),
//                     child: Row(children: [
//                       Icon(Icons.warning_amber_rounded,
//                           size: 14,
//                           color: Colors.orange.shade700),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           '$failed section(s) had errors — '
//                               'assessment will still be submitted.',
//                           style: TextStyle(
//                               fontSize: 11,
//                               color: Colors.orange.shade800),
//                         ),
//                       ),
//                     ]),
//                   )
//                 else
//                   const SizedBox(height: 6),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // ITEM ROW
// // ─────────────────────────────────────────────────────────────────────────────
//
// class _ItemRow extends StatelessWidget {
//   final _UploadItem item;
//   const _ItemRow({required this.item});
//
//   @override
//   Widget build(BuildContext context) {
//     final isPending = item.status == _UploadStatus.pending;
//     final isRunning = item.status == _UploadStatus.running;
//     final isDone = item.status == _UploadStatus.done;
//     final isFailed = item.status == _UploadStatus.failed;
//
//     Widget leading;
//     if (isRunning) {
//       leading = SizedBox(
//         width: 13,
//         height: 13,
//         child: CircularProgressIndicator(
//             strokeWidth: 1.8,
//             color: Colors.blue.shade500),
//       );
//     } else if (isDone) {
//       leading = Icon(Icons.check_circle_rounded,
//           size: 13, color: Colors.green.shade500);
//     } else if (isFailed) {
//       leading =
//           Icon(Icons.cancel_rounded, size: 13, color: Colors.red.shade400);
//     } else {
//       leading = Icon(Icons.radio_button_unchecked,
//           size: 13, color: Colors.grey.shade300);
//     }
//
//     final leftPad = item.indent.isEmpty
//         ? 16.0
//         : item.indent.length > 3
//         ? 36.0
//         : 26.0;
//
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       color: isRunning
//           ? Colors.blue.shade50.withOpacity(0.5)
//           : Colors.transparent,
//       padding: EdgeInsets.fromLTRB(leftPad, 4, 16, 4),
//       child: Row(children: [
//         leading,
//         const SizedBox(width: 8),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 item.label,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight:
//                   isRunning ? FontWeight.w600 : FontWeight.w400,
//                   color: isPending
//                       ? Colors.grey.shade50 ?? Colors.grey.shade400
//                       : isRunning
//                       ? Colors.blue.shade700
//                       : isFailed
//                       ? Colors.red.shade600
//                       : Colors.grey.shade700,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               if (isFailed && item.errorMsg != null)
//                 Text(
//                   item.errorMsg!,
//                   style: TextStyle(
//                       fontSize: 10, color: Colors.red.shade400),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//             ],
//           ),
//         ),
//       ]),
//     );
//   }
// }