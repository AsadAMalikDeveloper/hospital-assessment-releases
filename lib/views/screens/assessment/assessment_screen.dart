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
// import 'package:hospital_assessment/providers/assessment_provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class AssessmentScreen extends StatefulWidget {
//   final HospitalAssessmentModel hospitalAssessmentModel;
//
//   AssessmentScreen({super.key, required this.hospitalAssessmentModel});
//
//   @override
//   State<AssessmentScreen> createState() => _AssessmentScreenState();
// }
//
// class _AssessmentScreenState extends State<AssessmentScreen> {
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
//       await provider.getSectionList(
//           context,
//           widget.hospitalAssessmentModel.criteria_type_id ?? "",
//           widget.hospitalAssessmentModel.assessment_id ?? "");
//       await provider.getPDF(
//           context, widget.hospitalAssessmentModel.assessment_id ?? "");
//
//       await Glob().checkToken(context);
//     });
//   }
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//     _fullTimeControllers.forEach((controller) => controller.dispose());
//     _partTimeControllers.forEach((controller) => controller.dispose());
//     _maleControllers.forEach((controller) => controller.dispose());
//     _femaleControllers.forEach((controller) => controller.dispose());
//     _responseTextControllers.forEach((controller) => controller.dispose());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<AssessmentProvider>(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           '${widget.hospitalAssessmentModel.hospital} (${widget.hospitalAssessmentModel.criteria})',
//           style: GoogleFonts.poppins(fontSize: 12),
//         ),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Flexible(
//                   child: Material(
//                     elevation: 8,
//                     child: Container(
//                       decoration: BoxDecoration(
//                           border: Border.all(color: Colors.blue),
//                           color: Colors.blue),
//                       child: Padding(
//                         padding: const EdgeInsets.all(5.0),
//                         child: Text(
//                           "Selected",
//                           style: TextStyle(
//                               fontFamily: 'HEL',
//                               color: Colors.white,
//                               fontSize: 10),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Flexible(
//                   child: Material(
//                     elevation: 8,
//                     child: Container(
//                       decoration: BoxDecoration(
//                           border: Border.all(color: Colors.red),
//                           color: Colors.red),
//                       child: Padding(
//                         padding: const EdgeInsets.all(5.0),
//                         child: Text(
//                           "Partial Completed",
//                           style: TextStyle(
//                               fontFamily: 'HEL',
//                               color: Colors.white,
//                               fontSize: 10),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Flexible(
//                   child: Material(
//                     elevation: 8,
//                     child: Container(
//                       decoration: BoxDecoration(
//                           border: Border.all(color: Colors.green),
//                           color: Colors.green),
//                       child: Padding(
//                         padding: const EdgeInsets.all(5.0),
//                         child: Text(
//                           "Completed",
//                           style: TextStyle(
//                               fontFamily: 'HEL',
//                               color: Colors.white,
//                               fontSize: 10),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Flexible(
//                   child: Material(
//                     elevation: 8,
//                     child: Container(
//                       decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           color: Colors.grey),
//                       child: Padding(
//                         padding: const EdgeInsets.all(5.0),
//                         child: Text(
//                           "Unselected",
//                           style: TextStyle(
//                               fontFamily: 'HEL',
//                               color: Colors.white,
//                               fontSize: 10),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           provider.sectionList == null || provider.sectionList!.isEmpty
//               ? const Center(child: CircularProgressIndicator())
//               : header(provider),
//           provider.hasChild == true ? child(provider) : const SizedBox(),
//           if (provider.selectedIndex != -1)
//             provider.selectedIndex == -1
//                 ? const SizedBox()
//                 : (provider.isLoadingStaff == true ||
//                         provider.isLoadingPictureSection == true)
//                     ? const Center(
//                         child: CircularProgressIndicator(),
//                       )
//                     : (provider.sectionList![provider.selectedIndex].type_id ==
//                             "3")
//                         ? //Assessment Form
//
//                         Expanded(
//                             child: SingleChildScrollView(
//                               child: SizedBox(
//                                 // height: 0.45.sh,
//                                 child: Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 15, vertical: 15),
//                                   child: Container(
//                                     decoration: const BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             color.blue,
//                                             color.bluePrimary
//                                           ],
//                                           // Gradient colors
//                                           begin: Alignment.centerLeft,
//                                           // Gradient start position
//                                           end: Alignment.center,
//                                           // Gradient end position
//                                           stops: [0.0, 1.0], // Gradient stops
//                                         ),
//                                         borderRadius: BorderRadius.all(
//                                             Radius.circular(20)),
//                                         color: color.bluePrimary),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(10.0),
//                                       child: Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Expanded(
//                                                 child: Container(
//                                                   decoration: decoration1,
//                                                   child: _pdfFileResult
//                                                           .files.isEmpty
//                                                       ? boxContent(
//                                                           context,
//                                                           "Select PDF File",
//                                                           "1",
//                                                           "assets/images/cnic_icon.png")
//                                                       : _pdfFileResult
//                                                               .files.isEmpty
//                                                           ? const SizedBox()
//                                                           : _isPDFReadable
//                                                               ? Padding(
//                                                                   padding:
//                                                                       const EdgeInsets
//                                                                           .all(
//                                                                           10.0),
//                                                                   child: Column(
//                                                                     children: [
//                                                                       Row(
//                                                                         mainAxisAlignment:
//                                                                             MainAxisAlignment.spaceBetween,
//                                                                         children: [
//                                                                           Text(
//                                                                             "Preview",
//                                                                             style:
//                                                                                 GoogleFonts.poppins(color: Colors.black, fontSize: 15),
//                                                                           ),
//                                                                           GestureDetector(
//                                                                             onTap:
//                                                                                 () {
//                                                                               // Handle delete action
//
//                                                                               setState(() {
//                                                                                 _pdfFileResult = const FilePickerResult([]);
//                                                                                 _isPDFReadable = true;
//                                                                               });
//                                                                             },
//                                                                             child:
//                                                                                 Container(
//                                                                               padding: const EdgeInsets.all(4.0),
//                                                                               decoration: const BoxDecoration(
//                                                                                 shape: BoxShape.circle,
//                                                                                 color: Colors.red,
//                                                                               ),
//                                                                               child: const Icon(
//                                                                                 Icons.delete,
//                                                                                 color: Colors.white,
//                                                                               ),
//                                                                             ),
//                                                                           ),
//                                                                         ],
//                                                                       ),
//                                                                       SizedBox(
//                                                                         height:
//                                                                             150,
//                                                                         child:
//                                                                             Padding(
//                                                                           padding: const EdgeInsets
//                                                                               .all(
//                                                                               8.0),
//                                                                           child:
//                                                                               PDFView(
//                                                                             filePath:
//                                                                                 _pdfFileResult.files.single.path!,
//                                                                             onPageChanged:
//                                                                                 (int? page, int? total) {
//                                                                               setState(() {
//                                                                                 _pages = total!;
//                                                                                 _isPDFReadable = true;
//                                                                               });
//                                                                             },
//                                                                             onError:
//                                                                                 (error) {
//                                                                               setState(() {
//                                                                                 _isPDFReadable = false;
//                                                                               });
//                                                                             },
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                       provider.isLoadingPdfUploading ==
//                                                                               true
//                                                                           ? Center(
//                                                                               child: CircularProgressIndicator(),
//                                                                             )
//                                                                           : SizedBox(
//                                                                               width: MediaQuery.of(context).size.width / 2,
//                                                                               child: MaterialButton(
//                                                                                 onPressed: () {
//                                                                                   uploadPDF(context, widget!.hospitalAssessmentModel.assessment_id!, provider);
//                                                                                 },
//                                                                                 color: Colors.blue,
//                                                                                 elevation: 8,
//                                                                                 shape: RoundedRectangleBorder(
//                                                                                   borderRadius: BorderRadius.circular(13),
//                                                                                 ),
//                                                                                 child: const Padding(
//                                                                                   padding: EdgeInsets.symmetric(vertical: 14),
//                                                                                   child: Text(
//                                                                                     'Upload PDF',
//                                                                                     style: TextStyle(
//                                                                                       color: Colors.white,
//                                                                                       fontWeight: FontWeight.bold,
//                                                                                       fontSize: 15,
//                                                                                     ),
//                                                                                   ),
//                                                                                 ),
//                                                                               ),
//                                                                             )
//                                                                     ],
//                                                                   ),
//                                                                 )
//                                                               : const Center(
//                                                                   child: Text(
//                                                                       'PDF file is not readable.'),
//                                                                 ),
//                                                 ),
//                                               ),
//                                               SizedBox(
//                                                 width: 10,
//                                               ),
//                                             ],
//                                           ),
//                                           SizedBox(
//                                             height: 5,
//                                           ),
//                                           (provider.pdfData!.doc_id ?? "") != ''
//                                               ? Column(
//                                                   children: [
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment.start,
//                                                       children: [
//                                                         Text(
//                                                           'Uploaded Document',
//                                                           style: TextStyle(
//                                                               color: Colors.white),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment.center,
//                                                       children: [
//                                                         InkWell(
//                                                             onTap: () {
//                                                               print(
//                                                                   'object ${provider.pdfData!.doc_id}');
//                                                               openURL(
//                                                                   context,
//                                                                   provider
//                                                                       .pdfData!.doc_id!);
//                                                             },
//                                                             child: Text(
//                                                               'OPEN FILE',
//                                                               style: TextStyle(
//                                                                   color: Colors.white,
//                                                                   fontSize: 25,
//                                                                   decoration: TextDecoration
//                                                                       .underline,
//                                                                   decorationColor:
//                                                                       Colors.white),
//                                                             )),
//                                                       ],
//                                                     ),
//                                                   ],
//                                                 )
//                                               : SizedBox()
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           )
//                         : Flexible(
//                             child: ListView.builder(
//                               itemCount: (provider.hasChild == true &&
//                                       provider.selectedIndexChild != -1)
//                                   ? provider
//                                       .sectionList![provider.selectedIndex]
//                                       .child![provider.selectedIndexChild]
//                                       .questions!
//                                       .length
//                                   : provider
//                                       .sectionList![provider.selectedIndex]
//                                       .questions!
//                                       .length,
//                               itemBuilder: (context, index) {
//                                 return (provider.hasChild == true &&
//                                         provider.selectedIndexChild != -1)
//                                     ? QuestionWidget(
//                                         key: Key(provider
//                                             .sectionList![
//                                                 provider.selectedIndex]
//                                             .child![provider.selectedIndexChild]
//                                             .questions![index]
//                                             .q_id!),
//                                         sid: provider
//                                             .sectionList![
//                                                 provider.selectedIndex]
//                                             .child![provider.selectedIndexChild]
//                                             .id,
//                                         question: provider
//                                             .sectionList![
//                                                 provider.selectedIndex]
//                                             .child![provider.selectedIndexChild]
//                                             .questions![index],
//                                         type: provider
//                                                 .sectionList![
//                                                     provider.selectedIndex]
//                                                 .type_id ??
//                                             '',
//                                         aid: widget.hospitalAssessmentModel!
//                                             .assessment_id!,
//                                         provider: provider,
//                                         fullTimeController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .type_id ==
//                                                     "1" &&
//                                                 _fullTimeControllers.isNotEmpty)
//                                             ? _fullTimeControllers[index]
//                                             : TextEditingController(),
//                                         partTimeController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .type_id ==
//                                                     "1" &&
//                                                 _partTimeControllers.isNotEmpty)
//                                             ? _partTimeControllers[index]
//                                             : TextEditingController(),
//                                         maleController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .type_id ==
//                                                     "2" &&
//                                                 _maleControllers.isNotEmpty)
//                                             ? _maleControllers[index]
//                                             : TextEditingController(),
//                                         femaleController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .type_id ==
//                                                     "2" &&
//                                                 _femaleControllers.isNotEmpty)
//                                             ? _femaleControllers[index]
//                                             : TextEditingController(),
//                                         responseTextController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .type_id ==
//                                                     " " &&
//                                                 _responseTextControllers
//                                                     .isNotEmpty)
//                                             ? _responseTextControllers[index]
//                                             : TextEditingController(),
//                                       )
//                                     : QuestionWidget(
//                                         key: Key(provider
//                                             .sectionList![
//                                                 provider.selectedIndex]
//                                             .questions![index]
//                                             .q_id!),
//                                         sid: provider
//                                             .sectionList![
//                                                 provider.selectedIndex]
//                                             .id,
//                                         question: provider
//                                             .sectionList![
//                                                 provider.selectedIndex]
//                                             .questions![index],
//                                         type: provider
//                                                 .sectionList![
//                                                     provider.selectedIndex]
//                                                 .type_id ??
//                                             '',
//                                         aid: widget.hospitalAssessmentModel!
//                                             .assessment_id!,
//                                         provider: provider,
//                                         fullTimeController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .type_id ==
//                                                     "1" &&
//                                                 _fullTimeControllers.isNotEmpty)
//                                             ? _fullTimeControllers[index]
//                                             : TextEditingController(),
//                                         partTimeController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .type_id ==
//                                                     "1" &&
//                                                 _partTimeControllers.isNotEmpty)
//                                             ? _partTimeControllers[index]
//                                             : TextEditingController(),
//                                         maleController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .type_id ==
//                                                     "2" &&
//                                                 _maleControllers.isNotEmpty)
//                                             ? _maleControllers[index]
//                                             : TextEditingController(),
//                                         femaleController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .type_id ==
//                                                     "2" &&
//                                                 _femaleControllers.isNotEmpty)
//                                             ? _femaleControllers[index]
//                                             : TextEditingController(),
//                                         responseTextController: (provider
//                                                         .sectionList![provider
//                                                             .selectedIndex]
//                                                         .questions !=
//                                                     [] &&
//                                                 provider
//                                                     .sectionList![
//                                                         provider.selectedIndex]
//                                                     .questions!
//                                                     .isNotEmpty)
//                                             ? (provider
//                                                             .sectionList![provider
//                                                                 .selectedIndex]
//                                                             .type_id ==
//                                                         " " &&
//                                                     provider
//                                                             .sectionList![provider
//                                                                 .selectedIndex]
//                                                             .questions![0]
//                                                             .question_type ==
//                                                         'text')
//                                                 ? _responseTextControllers[
//                                                     index]
//                                                 : TextEditingController()
//                                             : TextEditingController(),
//                                       );
//                               },
//                             ),
//                           ),
//           const SizedBox(
//             height: 8,
//           ),
//           provider.selectedIndex == -1
//               ? const SizedBox()
//               : Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     provider.isLoadingSubmitSection == true
//                         ? const Center(
//                             child: CircularProgressIndicator(),
//                           )
//                         : provider.sectionList![provider.selectedIndex]
//                                     .type_id ==
//                                 "3"
//                             ? SizedBox()
//                             : SizedBox(
//                                 width: MediaQuery.of(context).size.width / 2,
//                                 child: MaterialButton(
//                                   onPressed: () {
//                                     submitSection(
//                                       provider,
//                                       context,
//                                     );
//                                   },
//                                   color: Colors.blue,
//                                   elevation: 8,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(13),
//                                   ),
//                                   child: const Padding(
//                                     padding: EdgeInsets.symmetric(vertical: 14),
//                                     child: Text(
//                                       'Submit Section',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 15,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                     const SizedBox(
//                       height: 10,
//                     ),
//                     provider.isLoadingCompleteAssessment == true
//                         ? Center(
//                             child: CircularProgressIndicator(),
//                           )
//                         : SizedBox(
//                             width: MediaQuery.of(context).size.width / 1.8,
//                             child: MaterialButton(
//                               onPressed: () {
//                                 completeAssessment(
//                                     context,
//                                     provider,
//                                     widget.hospitalAssessmentModel
//                                         .assessment_id!);
//                               },
//                               color: Colors.blue,
//                               elevation: 8,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(13),
//                               ),
//                               child: const Padding(
//                                 padding: EdgeInsets.symmetric(vertical: 14),
//                                 child: Text(
//                                   'Complete Assessment',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 15,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                   ],
//                 )
//         ],
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
//             .child![provider.selectedIndexChild].questions!) {
//       if (question.response_ids != null) {
//         final optionDescription = question.options!
//             .firstWhere((option) => option.id == question.response_ids,
//                 orElse: () => Option(id: "", description: ""))
//             .description;
//         responses.add({
//           'qid': question.q_id!,
//           'response': optionDescription,
//           'response_ids': question.response_ids!.trim(),
//         });
//       }
//     }
//     // for (var child in provider.sectionList![provider.selectedIndex].child ?? []) {
//     //   for (var question in child[provider.selectedIndexChild].questions ?? []) {
//     //     if (question.response_ids != null) {
//     //       final optionDescription = question.options!.firstWhere(
//     //               (option) => option.id == question.response_ids,
//     //           orElse: () => Option(id: "", description: "")).description;
//     //       responses.add({
//     //         'qid': question.q_id,
//     //         'response': optionDescription,
//     //         'response_ids': question.response_ids!,
//     //       });
//     //     }
//     //   }
//     // }
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
//             .child![provider.selectedIndexChild].questions!) {
//       responses.add({
//         'qid': question.q_id!,
//         'response': question.response!,
//         'response_ids': question.response_ids!.trim(),
//       });
//     }
//     // for (var child in provider.sectionList![provider.selectedIndex].child ?? []) {
//     //   for (var question in child[provider.selectedIndexChild].questions ?? []) {
//     //     if (question.response_ids != null) {
//     //       final optionDescription = question.options!.firstWhere(
//     //               (option) => option.id == question.response_ids,
//     //           orElse: () => Option(id: "", description: "")).description;
//     //       responses.add({
//     //         'qid': question.q_id,
//     //         'response': optionDescription,
//     //         'response_ids': question.response_ids!,
//     //       });
//     //     }
//     //   }
//     // }
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
//     // for (var child in provider.sectionList![provider.selectedIndex].child ?? []) {
//     //   for (var question in child[provider.selectedIndexChild].questions ?? []) {
//     //     if (question.response_ids != null) {
//     //       final optionDescription = question.options!.firstWhere(
//     //               (option) => option.id == question.response_ids,
//     //           orElse: () => Option(id: "", description: "")).description;
//     //       responses.add({
//     //         'qid': question.q_id,
//     //         'response': optionDescription,
//     //         'response_ids': question.response_ids!,
//     //       });
//     //     }
//     //   }
//     // }
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
//             question.full_time == 0 ? '' : question.full_time!.toString(),
//         'part_time':
//             question.part_time == 0 ? '' : question.part_time!.toString(),
//         'qid': question.q_id!,
//       });
//     }
//     // for (var child in provider.sectionList![provider.selectedIndex].child ?? []) {
//     //   for (var question in child[provider.selectedIndexChild].questions ?? []) {
//     //     if (question.response_ids != null) {
//     //       final optionDescription = question.options!.firstWhere(
//     //               (option) => option.id == question.response_ids,
//     //           orElse: () => Option(id: "", description: "")).description;
//     //       responses.add({
//     //         'qid': question.q_id,
//     //         'response': optionDescription,
//     //         'response_ids': question.response_ids!,
//     //       });
//     //     }
//     //   }
//     // }
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
//               child: CircularProgressIndicator(),
//             )
//           : ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount:
//                   provider.sectionList![provider.selectedIndex].child!.length,
//               itemBuilder: (context, index) {
//                 var items =
//                     provider.sectionList![provider.selectedIndex].child![index];
//                 return InkWell(
//                   onTap: () {
//                     provider.setChildIndex(index);
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           width: 70, // Width of the circular background
//                           height: 70, // Height of the circular background
//                           decoration: BoxDecoration(
//                             color: provider.selectedIndexChild == index
//                                 ? Colors.blue
//                                 : getCheckChild(provider, index) == 1
//                                     ? Colors.green
//                                     : getCheckChild(provider, index) == 2
//                                         ? Colors.redAccent
//                                         : Colors.grey, // Background color
//                             shape: BoxShape.circle, // Circular shape
//                           ),
//                           child: Center(
//                             child: Padding(
//                               padding: const EdgeInsets.all(5.0),
//                               child: Text(
//                                 "${items.list_title}",
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: 8.0, // Font size
//                                   fontWeight: FontWeight.bold, // Font weight
//                                   color: provider.selectedIndexChild == index
//                                       ? Colors.white
//                                       : Colors.black, // Text color
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
//
//   Widget header(AssessmentProvider provider) {
//     return SizedBox(
//       height: 120, // Adjust the height as needed
//       child: provider.isLoading == true
//           ? const Center(
//               child: CircularProgressIndicator(),
//             )
//           : ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: provider.sectionList!.length,
//               itemBuilder: (context, index) {
//                 var items = provider.sectionList![index];
//                 return InkWell(
//                   onTap: () {
//                     provider.setChildRemovedOnBack();
//                     if (provider.sectionList![index].type_id == "1") {
//                       clearTextFields();
//                       getStaffData(provider, index);
//                     }
//                     if (provider.sectionList![index].type_id == "2") {
//                       clearTextFields();
//                       getBedData(provider, index);
//                     }
//                     if (provider.sectionList![index].type_id == "3") {
//                       clearTextFields();
//                       getPDFData(provider);
//                     }
//                     if (provider.sectionList![index].questions != [] &&
//                         provider.sectionList![index].questions!.isNotEmpty) {
//                       if (provider.sectionList![index].type_id == " " &&
//                           provider.sectionList![index].questions![0]
//                                   .question_type ==
//                               'text') {
//                         clearTextFields();
//                         getTextData(provider, index);
//                       }
//                     }
//                     if (provider.sectionList![index].questions != [] &&
//                         provider.sectionList![index].questions!.isNotEmpty) {
//                       if (provider.sectionList![index].type_id == " " &&
//                           provider.sectionList![index].questions![0]
//                                   .question_type ==
//                               'files') {
//                         clearTextFields();
//                         getPictureData(provider, index);
//                       }
//                     }
//                     if (items.child!.isNotEmpty) {
//                       provider.setHasChild(true, index);
//                     } else {
//                       provider.setHasChild(false, index);
//                     }
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           width: 70, // Width of the circular background
//                           height: 70, // Height of the circular background
//                           decoration: BoxDecoration(
//                             color: provider.selectedIndex == index
//                                 ? Colors.blue
//                                 : getCheck(provider, index) == 1
//                                     ? Colors.green
//                                     : getCheck(provider, index) == 2
//                                         ? Colors.redAccent
//                                         : Colors.grey, // Background color
//                             shape: BoxShape.circle, // Circular shape
//                           ),
//                           child: Center(
//                             child: Padding(
//                               padding: const EdgeInsets.all(5.0),
//                               child: Text(
//                                 "${items.list_title}",
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: 8.0, // Font size
//                                   fontWeight: FontWeight.bold, // Font weight
//                                   color: provider.selectedIndex == index
//                                       ? Colors.white
//                                       : Colors.black, // Text color
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
//
//   Toast toast = Toast();
//
//   final DatabaseHelper _dbHelper = DatabaseHelper();
//   final CheckConnectivity _connectivityService = CheckConnectivity();
//
//   submitSection(AssessmentProvider provider, BuildContext context) async {
//     if (provider.sectionList![provider.selectedIndex].type_id == "1") {
//       final responses = gatherStaffResponses(provider);
//       final json = generateJson(responses, provider);
//       print(jsonEncode(json));
//       APIResponse res = await provider.submitStaffSection(
//           widget.hospitalAssessmentModel.criteria_type_id!,
//           widget.hospitalAssessmentModel.assessment_id!,
//           provider.selectedIndexChild == -1
//               ? provider.sectionList![provider.selectedIndex].id!
//               : provider.sectionList![provider.selectedIndex]
//                   .child![provider.selectedIndexChild].id!,
//           widget.hospitalAssessmentModel.sp_id!,
//           json);
//       if (res.status!.toLowerCase() == 'success') {
//         toast.showSuccessToast(res.message ?? "");
//         clearTextFields();
//         provider.disposeValues();
//         getData();
//       } else {
//         toast.showErrorToast(res.message ?? '');
//       }
//     } else if (provider.sectionList![provider.selectedIndex].type_id == "2") {
//       //bed capacity
//       final responses = gatherBedResponses(provider);
//       final json = generateJson(responses, provider);
//       print(jsonEncode(json));
//       APIResponse res = await provider.submitBedSection(
//           widget.hospitalAssessmentModel.criteria_type_id!,
//           widget.hospitalAssessmentModel.assessment_id!,
//           provider.selectedIndexChild == -1
//               ? provider.sectionList![provider.selectedIndex].id!
//               : provider.sectionList![provider.selectedIndex]
//                   .child![provider.selectedIndexChild].id!,
//           widget.hospitalAssessmentModel.sp_id!,
//           json);
//       if (res.status!.toLowerCase() == 'success') {
//         toast.showSuccessToast(res.message ?? "");
//         clearTextFields();
//         provider.disposeValues();
//         getData();
//       } else {
//         toast.showErrorToast(res.message ?? '');
//       }
//     } else if (provider.sectionList![provider.selectedIndex].questions != [] &&
//         provider.sectionList![provider.selectedIndex].questions!.isNotEmpty) {
//       if (provider.sectionList![provider.selectedIndex].type_id == " " &&
//           provider.sectionList![provider.selectedIndex].questions![0]
//                   .question_type ==
//               'text') {
//         final responses = gatherTextResponses(provider);
//         final json = generateJson(responses, provider);
//         print(jsonEncode(json)); // You can handle the JSON as needed
//         resetResponses(provider); // Reset responses after gathering
//
//         APIResponse res = await provider.submitSection(
//             widget.hospitalAssessmentModel.criteria_type_id!,
//             widget.hospitalAssessmentModel.assessment_id!,
//             provider.selectedIndexChild == -1
//                 ? provider.sectionList![provider.selectedIndex].id!
//                 : provider.sectionList![provider.selectedIndex]
//                     .child![provider.selectedIndexChild].id!,
//             json);
//         if (res.status!.toLowerCase() == 'success') {
//           toast.showSuccessToast(res.message ?? "");
//           clearTextFields();
//           provider.disposeValues();
//           getData();
//         } else {
//           toast.showErrorToast(res.message ?? '');
//         }
//       } else {
//         print(
//             'ssa12 ${provider.sectionList![provider.selectedIndex].questions![0].question_type}');
//         final responses = gatherResponses(provider);
//         final json = generateJson(responses, provider);
//         print(jsonEncode(json)); // You can handle the JSON as needed
//         resetResponses(provider); // Reset responses after gathering
//
//         APIResponse res = await provider.submitSection(
//             widget.hospitalAssessmentModel.criteria_type_id!,
//             widget.hospitalAssessmentModel.assessment_id!,
//             provider.selectedIndexChild == -1
//                 ? provider.sectionList![provider.selectedIndex].id!
//                 : provider.sectionList![provider.selectedIndex]
//                     .child![provider.selectedIndexChild].id!,
//             json);
//         if (res.status!.toLowerCase() == 'success') {
//           toast.showSuccessToast(res.message ?? "");
//           clearTextFields();
//           provider.disposeValues();
//           getData();
//         } else {
//           toast.showErrorToast(res.message ?? '');
//         }
//       }
//     }
//   }
//
//   getStaffData(AssessmentProvider provider, int index) async {
//     await provider.getStaffList(
//         context,
//         widget.hospitalAssessmentModel.assessment_id!,
//         widget.hospitalAssessmentModel.criteria_type_id!,
//         widget.hospitalAssessmentModel.sp_id!,
//         provider.sectionList![index].id!);
//
//     if (provider.staffList != []) {
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
//     await provider.getBedCapacityList(
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
//         final controller =
//             TextEditingController(text: staff.response.toString());
//         controller.addListener(() {
//           if (controller.text.isNotEmpty) {
//             setState(() {
//               staff.response = controller.text;
//             });
//           }
//         });
//         return controller;
//       }).toList();
//     }
//   }
//
//   getPictureData(AssessmentProvider provider, int index) async {
//     await provider.getPicturesList(
//       context,
//       widget.hospitalAssessmentModel.assessment_id!,
//     );
//   }
//
//   getPDFData(AssessmentProvider provider) async {
//     await provider.getPDF(
//       context,
//       widget.hospitalAssessmentModel.assessment_id!,
//     );
//   }
//
//   completeAssessment(BuildContext context, AssessmentProvider provider,
//       String assessment_id) async {
//     APIResponse response = await provider.completeAssessment(assessment_id);
//     if (response.status!.toLowerCase() == 'success') {
//       toast.showSuccessToast('${response.message}');
//       Get.back(result: [
//         {"backValue": "done"}
//       ]);
//     } else {
//       showErrorDialogCompleteAssessment(context, response);
//     }
//   }
//
//   Widget boxContent(
//       BuildContext context, String name, String no, String image) {
//     return GestureDetector(
//       onTap: () {
//         _pickPDFFile();
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
//                             const Offset(2, 4), // Offset (vertical, horizontal)
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
//                       decoration: const BoxDecoration(
//                           borderRadius: BorderRadius.all(Radius.circular(10)),
//                           color: Colors.white),
//                       child: Padding(
//                         padding: const EdgeInsets.all(2.0),
//                         child: Text(
//                           "UPLOAD",
//                           style: GoogleFonts.poppins(
//                               color: color.bluePrimary,
//                               fontSize: 12.sp,
//                               fontWeight: FontWeight.w600),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     )),
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
//   Future<void> _pickPDFFile() async {
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
//         setState(() {
//           _pdfFileResult = result;
//         });
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
//     if (_isPDFReadable != true) {
//       toast.showErrorToast('PDF File is corrupted');
//     } else {
//       File file = File(_pdfFileResult.files.single.path!);
//       if (file.existsSync()) {
//         Uint8List image = await file.readAsBytes();
//         print('object321 ${_pdfFileResult.files.single.size}');
//         APIResponse? res = await provider.pickPDF(
//             context,
//             aid,
//             provider.sectionList![provider.selectedIndex].id!,
//             _pdfFileResult.files.single.name,
//             image);
//         if (res!.status!.toLowerCase() == 'success') {
//           toast.showSuccessToast(res.message ?? "");
//           setState(() {
//             _pdfFileResult = const FilePickerResult([]);
//             _isPDFReadable = true;
//           });
//           getPDFData(provider);
//         } else {
//           toast.showErrorToast(res.message ?? '');
//         }
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
//       if (_pdfFileResult.files.isEmpty) {
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
//               .where((element) => element.response != " ")
//               .length)) {
//         return 1;
//       }
//       if (provider.sectionList![index].questions!
//           .where((element) => element.response != " ")
//           .isNotEmpty) {
//         return 2;
//       }
//       if (provider.sectionList![index].questions!
//           .where((element) => element.response != " ")
//           .isEmpty) {
//         return 0;
//       }
//     }
//   }
//
//   getCheckChild(AssessmentProvider provider, int index) {
//     if ((provider.sectionList![provider.selectedIndex].child![index].questions!
//             .length) ==
//         provider.sectionList![provider.selectedIndex].child![index].questions!
//             .where((element) => element.response != " ")
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
// }
//
// class QuestionWidget extends StatefulWidget {
//   final Question question;
//   final String type;
//   String? aid;
//   String? sid;
//   final AssessmentProvider provider;
//   TextEditingController? fullTimeController;
//   TextEditingController? partTimeController;
//   TextEditingController? maleController;
//   TextEditingController? femaleController;
//   TextEditingController? responseTextController;
//
//   QuestionWidget(
//       {required Key key,
//       required this.question,
//       required this.type,
//       this.aid,
//       this.sid,
//       required this.provider,
//       this.fullTimeController,
//       this.partTimeController,
//       this.maleController,
//       this.femaleController,
//       this.responseTextController})
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
//     await provider.getPicturesList(
//       context,
//       widget.aid!,
//     );
//   }
//
//   getPDFData(BuildContext context, AssessmentProvider provider) async {}
//
//   Toast toast = Toast();
//
//   showBottomSheetNew(BuildContext context, String aid, String qid,
//       String cSectionID, AssessmentProvider provider) async {
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
//                       await ImagePicker().pickImage(source: ImageSource.camera);
//                   if (pickedFile != null) {
//                     // Do something with the picked image
//                     XFile imageFile = XFile(pickedFile.path);
//                     APIResponse? res = await provider.pickImage(
//                         context, aid, qid, cSectionID, imageFile.name, imageFile);
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
//                       await ImagePicker().pickImage(source: ImageSource.gallery);
//                   if (pickedFile != null) {
//                     XFile imageFile = XFile(pickedFile.path);
//                     APIResponse? res = await provider.pickImage(
//                         context, aid, qid, cSectionID, imageFile.name, imageFile);
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
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.all(8.0),
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
//                       child: TextFormField(
//                         textAlign: TextAlign.center,
//                         controller: widget.maleController,
//                         keyboardType: TextInputType.number,
//                         onChanged: (val) {
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
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: widget.question.options!.length,
//                     itemBuilder: (context, index) {
//                       final option = widget.question.options![index];
//
//                       return RadioListTile<String>(
//                         title: Text(option.description),
//                         value: option.id,
//                         groupValue: selectedOption,
//                         onChanged: (value) {
//                           setState(() {
//                             selectedOption = value;
//                             widget.question.response_ids = value;
//                           });
//                         },
//                       );
//                     },
//                   )
//                 : widget.question.question_type == 'files'
//                     ? Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           widget.provider.picsList != []
//                               ? widget.provider.picsList!
//                                       .where(
//                                           (e) => e.qid == widget.question!.q_id)
//                                       .isNotEmpty
//                                   ? GestureDetector(
//                                       onTap: () {
//                                         showDialog(
//                                           context: context,
//                                           builder: (BuildContext context) {
//                                             return Dialog(
//                                               child: Container(
//                                                 width: double.infinity,
//                                                 height: double.infinity,
//                                                 color: Colors.black,
//                                                 child: GestureDetector(
//                                                   onTap: () {
//                                                     Navigator.of(context).pop();
//                                                   },
//                                                   child: Image.network(
//                                                     'https://apps.slichealth.com/ords/ihmis_admin/assesment/image?doc_id=${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}',
//                                                     fit: BoxFit.contain,
//                                                   ),
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         );
//                                       },
//                                       child: SizedBox(
//                                         height: 150,
//                                         width: 150,
//                                         child: Stack(
//                                           alignment: Alignment.center,
//                                           children: [
//                                             const CircularProgressIndicator(),
//                                             Image.network(
//                                               'https://apps.slichealth.com/ords/ihmis_admin/assesment/image?doc_id=${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}',
//                                               key: ValueKey(
//                                                 'https://apps.slichealth.com/ords/ihmis_admin/assesment/image?doc_id=${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}',
//                                               ),
//                                               fit: BoxFit.cover,
//                                               loadingBuilder:
//                                                   (BuildContext context,
//                                                       Widget child,
//                                                       ImageChunkEvent?
//                                                           loadingProgress) {
//                                                 if (loadingProgress == null) {
//                                                   return child;
//                                                 } else {
//                                                   return Center(
//                                                     child:
//                                                         CircularProgressIndicator(
//                                                       value: loadingProgress
//                                                                   .expectedTotalBytes !=
//                                                               null
//                                                           ? loadingProgress
//                                                                   .cumulativeBytesLoaded /
//                                                               (loadingProgress
//                                                                       .expectedTotalBytes ??
//                                                                   1)
//                                                           : null,
//                                                     ),
//                                                   );
//                                                 }
//                                               },
//                                               errorBuilder:
//                                                   (BuildContext context,
//                                                       Object error,
//                                                       StackTrace? stackTrace) {
//                                                 return const Icon(Icons.error);
//                                               },
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     )
//                                   : const SizedBox()
//                               : const SizedBox(),
//                           Column(
//                             children: [
//                               widget.provider.picsList != []
//                                   ? widget.provider.picsList!
//                                           .where((e) =>
//                                               e.qid == widget.question!.q_id)
//                                           .isEmpty
//                                       ? SizedBox(
//                                           child: MaterialButton(
//                                             onPressed: () {
//                                               showBottomSheetNew(
//                                                   context,
//                                                   widget.aid!,
//                                                   widget.question.q_id!,
//                                                   widget.sid!,
//                                                   widget.provider);
//                                             },
//                                             color: Colors.grey,
//                                             elevation: 8,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(13),
//                                             ),
//                                             child: const Padding(
//                                               padding: EdgeInsets.symmetric(
//                                                   vertical: 14),
//                                               child: Text(
//                                                 'Upload Picture',
//                                                 style: TextStyle(
//                                                   color: Colors.white,
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 10,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         )
//                                       : const SizedBox()
//                                   : const SizedBox(),
//                               widget.provider.picsList != []
//                                   ? widget.provider.picsList!
//                                           .where((e) =>
//                                               e.qid == widget.question!.q_id)
//                                           .isNotEmpty
//                                       ? (widget.provider.isLoadingDelete ==
//                                               true)
//                                           ? const Center(
//                                               child:
//                                                   CircularProgressIndicator(),
//                                             )
//                                           : SizedBox(
//                                               child: MaterialButton(
//                                                 onPressed: () {
//                                                   deletePicture(
//                                                       context,
//                                                       widget.aid!,
//                                                       widget.question.q_id!,
//                                                       widget.provider);
//                                                 },
//                                                 color: Colors.red,
//                                                 elevation: 8,
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(13),
//                                                 ),
//                                                 child: const Padding(
//                                                   padding: EdgeInsets.symmetric(
//                                                       vertical: 14),
//                                                   child: Text(
//                                                     'Delete Picture',
//                                                     style: TextStyle(
//                                                       color: Colors.white,
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                       fontSize: 10,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                             )
//                                       : const SizedBox()
//                                   : const SizedBox(),
//                             ],
//                           ),
//                         ],
//                       )
//                     : (widget.question.question_type == "text" &&
//                             widget.type == " ")
//                         ? Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Flexible(
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(2.0),
//                                   child: TextField(
//                                     textAlign: TextAlign.center,
//                                     controller: widget.responseTextController,
//                                     keyboardType: TextInputType.text,
//                                     decoration: InputDecoration(
//                                       hintText: '',
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                       filled: true,
//                                       contentPadding: const EdgeInsets.all(10),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           )
//                         : const SizedBox(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   deletePicture(BuildContext context, String aid, String qid,
//       AssessmentProvider provider) async {
//     APIResponse res = await provider.deletePicture(context, aid, qid);
//
//     if (res.status!.toLowerCase() == 'success') {
//       getPictureData(context, provider);
//     }
//   }
// }
