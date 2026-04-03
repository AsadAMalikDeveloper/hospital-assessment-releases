import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Utils/CheckInternetConnection.dart';
import '../../../Utils/Colors.dart';
import '../../../Utils/ToastMessages.dart';
import '../../../Utils/globle_controller.dart';
import '../../../db_services/db_helper.dart';
import '../../../models/api_response_model.dart';
import '../../../models/assessment_hospital_model.dart';
import '../../../models/picture_get_model.dart';
import '../../../models/section_model.dart';
import '../../../models/video_section_model.dart';
import '../../../providers/assessment_provider.dart';
import '../../../widgets/video_question_widget.dart';

class AssessmentScreenOfflineWC extends StatefulWidget {
  final HospitalAssessmentModel hospitalAssessmentModel;

  AssessmentScreenOfflineWC({super.key, required this.hospitalAssessmentModel});

  @override
  State<AssessmentScreenOfflineWC> createState() =>
      _AssessmentScreenOfflineWCState();
}

class _AssessmentScreenOfflineWCState extends State<AssessmentScreenOfflineWC> {
  List<TextEditingController> _fullTimeControllers = [];
  List<TextEditingController> _partTimeControllers = [];
  List<TextEditingController> _maleControllers = [];
  List<TextEditingController> _femaleControllers = [];
  List<TextEditingController> _responseTextControllers = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    _fullTimeControllers = [];
    _partTimeControllers = [];
    _maleControllers = [];
    _femaleControllers = [];
    _responseTextControllers = [];
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final provider = Provider.of<AssessmentProvider>(context, listen: false);
      await provider.getSectionListOffline(
          context,
          widget.hospitalAssessmentModel.criteria_type_id ?? "",
          widget.hospitalAssessmentModel.assessment_id ?? "");
      await provider.getPicturesListOffline(
          // ← ADD THIS
          context,
          widget.hospitalAssessmentModel.assessment_id!);
      await provider.getVideosListOffline(
          context, widget.hospitalAssessmentModel.assessment_id ?? "");
      await provider.getStaffListOffline(
          context,
          widget.hospitalAssessmentModel.assessment_id ?? "",
          widget.hospitalAssessmentModel.criteria_type_id!,
          widget.hospitalAssessmentModel.sp_id!,
          provider.sectionList!
                  .firstWhere(
                    (test) => test.type_id == "1",
                    orElse: () => SectionModel(), // empty model
                  )
                  .id ??
              "");
      await provider.getBedCapacityListOffline(
          context,
          widget.hospitalAssessmentModel.assessment_id ?? "",
          widget.hospitalAssessmentModel.criteria_type_id!,
          widget.hospitalAssessmentModel.sp_id!,
          provider.sectionList!
                  .firstWhere(
                    (test) => test.type_id == "2",
                    orElse: () => SectionModel(), // empty model
                  )
                  .id ??
              "");
      await provider.getVideosListOffline(
          context, widget.hospitalAssessmentModel.assessment_id ?? "");

      //await Glob().checkToken(context);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    for (var controller in _fullTimeControllers) {
      controller.dispose();
    }
    for (var controller in _partTimeControllers) {
      controller.dispose();
    }
    for (var controller in _maleControllers) {
      controller.dispose();
    }
    for (var controller in _femaleControllers) {
      controller.dispose();
    }
    for (var controller in _responseTextControllers) {
      controller.dispose();
    }
  }

  int _countPicsAnswered(
      AssessmentProvider provider, List<Question> questions) {
    if (provider.picsList == null) return 0;
    return questions
        .where((q) =>
            q.question_type == 'files' &&
            q.file_type != 'video' &&
            provider.picsList!.any((p) => p.qid == q.q_id))
        .length;
  }

  int _countVideosAnswered(
      AssessmentProvider provider, List<Question> questions) {
    if (provider.videoList == null) return 0;
    return questions
        .where((q) =>
            q.question_type == 'files' &&
            q.file_type == 'video' &&
            provider.videoList!.any((v) => v.qid == q.q_id))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AssessmentProvider>(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.hospitalAssessmentModel.hospital} (${widget.hospitalAssessmentModel.criteria})',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Material(
                      elevation: 8,
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            color: Colors.blue),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            "Selected",
                            style: TextStyle(
                                fontFamily: 'HEL',
                                color: Colors.white,
                                fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Material(
                      elevation: 8,
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            color: Colors.red),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            "Partial Completed",
                            style: TextStyle(
                                fontFamily: 'HEL',
                                color: Colors.white,
                                fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Material(
                      elevation: 8,
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            color: Colors.green),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            "Completed",
                            style: TextStyle(
                                fontFamily: 'HEL',
                                color: Colors.white,
                                fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Material(
                      elevation: 8,
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            color: Colors.grey),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            "Pending",
                            style: TextStyle(
                                fontFamily: 'HEL',
                                color: Colors.white,
                                fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // provider.sectionList == null || provider.sectionList!.isEmpty
            //     ? const Center(child: CircularProgressIndicator())
            //     : header(provider),
            // provider.hasChild == true ? child(provider) : const SizedBox(),
            // provider.hasSubChild == true
            //     ? subChild(provider)
            //     : const SizedBox(),
            SectionNavWidget(
              provider: provider,
              getCheck: getCheck,
              getCheckChild: getCheckChild,
              getCheckSubChild: getCheckSubChild,
              onSectionTap: (rootIdx) {
                provider.setChildRemovedOnBack();
                final section = provider.sectionList![rootIdx];
                if (section.type_id == "1") { clearTextFields(); getStaffData(provider, rootIdx); }
                if (section.type_id == "2") { clearTextFields(); getBedData(provider, rootIdx); }
                if (section.type_id == "3") { clearTextFields(); getPDFData(provider); }
                if (section.questions != null && section.questions!.isNotEmpty) {
                  if (section.type_id == " " && section.questions![0].question_type == 'text') {
                    clearTextFields(); getTextData(provider, rootIdx);
                  }
                  if (section.type_id == " " && section.questions![0].question_type == 'files') {
                    clearTextFields(); getPictureData(provider, rootIdx);
                  }
                }
                if (section.child!.isNotEmpty) {
                  provider.setHasChild(true, rootIdx);
                } else {
                  provider.setHasChild(false, rootIdx);
                }
              },
              onChildTap: (rootIdx, childIdx) {
                final child = provider.sectionList![rootIdx].child![childIdx];
                if (child.child!.isNotEmpty) {
                  provider.setHasSubChild(true, childIdx);
                } else {
                  provider.setHasSubChild(false, childIdx);
                }
              },
              onSubChildTap: (rootIdx, childIdx, subIdx) {
                provider.setSubChildIndex(subIdx);
              },
            ),
            provider.selectedIndex == -1
                ? const SizedBox()
                : (provider.isLoadingStaff == true ||
                        provider.isLoadingPictureSection == true)
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : (provider.sectionList![provider.selectedIndex].type_id ==
                            "3")
                        ? //Assessment Form
                        Expanded(
                            child: SingleChildScrollView(
                              child: SizedBox(
                                // height: 0.45.sh,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 15),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            color.blue,
                                            color.bluePrimary
                                          ],
                                          // Gradient colors
                                          begin: Alignment.centerLeft,
                                          // Gradient start position
                                          end: Alignment.center,
                                          // Gradient end position
                                          stops: [0.0, 1.0], // Gradient stops
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                        color: color.bluePrimary),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                    decoration: decoration1,
                                                    child: provider
                                                                .isLoadingPictureSection ==
                                                            true
                                                        ? Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          )
                                                        : provider.pdfOffline!
                                                                .isEmpty
                                                            ? boxContent(
                                                                context,
                                                                "Select PDF File",
                                                                "1",
                                                                "assets/images/cnic_icon.png",
                                                                provider,
                                                                widget
                                                                    .hospitalAssessmentModel
                                                                    .assessment_id!)
                                                            : Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        10.0),
                                                                child: Column(
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Text(
                                                                          "Preview",
                                                                          style: GoogleFonts.poppins(
                                                                              color: Colors.black,
                                                                              fontSize: 15),
                                                                        ),
                                                                        GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            deletePdfOffline(
                                                                                context,
                                                                                provider,
                                                                                widget.hospitalAssessmentModel.assessment_id!);
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.all(4.0),
                                                                            decoration:
                                                                                const BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              color: Colors.red,
                                                                            ),
                                                                            child:
                                                                                const Icon(
                                                                              Icons.delete,
                                                                              color: Colors.white,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          150,
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            PDFView(
                                                                          filePath: provider
                                                                              .pdfOffline![0]
                                                                              .doc_id!,
                                                                          onPageChanged:
                                                                              (int? page, int? total) {
                                                                            setState(() {
                                                                              _pages = total!;
                                                                              _isPDFReadable = true;
                                                                            });
                                                                          },
                                                                          onError:
                                                                              (error) {
                                                                            setState(() {
                                                                              _isPDFReadable = false;
                                                                            });
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              )),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          (provider.pdfData!.doc_id ?? "") != ''
                                              ? Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            '1 Document is already uploaded',
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            'Uploading the new document will replace the previous one',
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              : SizedBox()
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Flexible(
                            child: ListView.builder(
                              itemCount: (provider.hasChild == true &&
                                      provider.selectedIndexChild != -1)
                                  ? provider
                                          .sectionList![provider.selectedIndex]
                                          .child![provider.selectedIndexChild]
                                          .questions!
                                          .isEmpty
                                      ? (provider.hasSubChild == true &&
                                              provider.selectedIndexSubChild !=
                                                  -1)
                                          ? provider
                                              .sectionList![
                                                  provider.selectedIndex]
                                              .child![
                                                  provider.selectedIndexChild]
                                              .child![provider
                                                  .selectedIndexSubChild]
                                              .questions!
                                              .length
                                          : provider
                                              .sectionList![
                                                  provider.selectedIndex]
                                              .child![
                                                  provider.selectedIndexChild]
                                              .questions!
                                              .length
                                      : provider
                                          .sectionList![provider.selectedIndex]
                                          .child![provider.selectedIndexChild]
                                          .questions!
                                          .length
                                  : provider
                                      .sectionList![provider.selectedIndex]
                                      .questions!
                                      .length,
                              itemBuilder: (context, index) {
                                return (provider.hasChild == true &&
                                        provider.selectedIndexChild != -1)
                                    ? provider
                                            .sectionList![
                                                provider.selectedIndex]
                                            .child![provider.selectedIndexChild]
                                            .questions!
                                            .isEmpty
                                        ? QuestionWidget(
                                            key: Key(provider
                                                .sectionList![
                                                    provider.selectedIndex]
                                                .child![
                                                    provider.selectedIndexChild]
                                                .child![provider
                                                    .selectedIndexSubChild]
                                                .questions![index]
                                                .q_id!),
                                            question: provider
                                                .sectionList![
                                                    provider.selectedIndex]
                                                .child![
                                                    provider.selectedIndexChild]
                                                .child![provider
                                                    .selectedIndexSubChild]
                                                .questions![index],
                                            type: provider
                                                    .sectionList![
                                                        provider.selectedIndex]
                                                    .type_id ??
                                                '',
                                            aid: widget.hospitalAssessmentModel!
                                                .assessment_id!,
                                            provider: provider,
                                            fullTimeController: (provider
                                                            .sectionList![provider
                                                                .selectedIndex]
                                                            .type_id ==
                                                        "1" &&
                                                    _fullTimeControllers
                                                        .isNotEmpty)
                                                ? _fullTimeControllers[index]
                                                : TextEditingController(),
                                            partTimeController: (provider
                                                            .sectionList![provider
                                                                .selectedIndex]
                                                            .type_id ==
                                                        "1" &&
                                                    _partTimeControllers
                                                        .isNotEmpty)
                                                ? _partTimeControllers[index]
                                                : TextEditingController(),
                                            maleController: (provider
                                                            .sectionList![provider
                                                                .selectedIndex]
                                                            .type_id ==
                                                        "2" &&
                                                    _maleControllers.isNotEmpty)
                                                ? _maleControllers[index]
                                                : TextEditingController(),
                                            femaleController: (provider
                                                            .sectionList![provider
                                                                .selectedIndex]
                                                            .type_id ==
                                                        "2" &&
                                                    _femaleControllers
                                                        .isNotEmpty)
                                                ? _femaleControllers[index]
                                                : TextEditingController(),
                                            responseTextController: (provider
                                                            .sectionList![provider
                                                                .selectedIndex]
                                                            .type_id ==
                                                        " " &&
                                                    _responseTextControllers
                                                        .isNotEmpty)
                                                ? _responseTextControllers[
                                                    index]
                                                : TextEditingController(),
                                          )
                                        : (provider.hasSubChild == true &&
                                                provider.selectedIndexSubChild !=
                                                    -1)
                                            ? QuestionWidget(
                                                key: Key(provider
                                                    .sectionList![
                                                        provider.selectedIndex]
                                                    .child![provider
                                                        .selectedIndexChild]
                                                    .questions![index]
                                                    .q_id!),
                                                question: provider
                                                    .sectionList![
                                                        provider.selectedIndex]
                                                    .child![provider
                                                        .selectedIndexChild]
                                                    .questions![index],
                                                type: provider
                                                        .sectionList![provider
                                                            .selectedIndex]
                                                        .type_id ??
                                                    '',
                                                aid: widget
                                                    .hospitalAssessmentModel!
                                                    .assessment_id!,
                                                provider: provider,
                                                fullTimeController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            "1" &&
                                                        _fullTimeControllers
                                                            .isNotEmpty)
                                                    ? _fullTimeControllers[
                                                        index]
                                                    : TextEditingController(),
                                                partTimeController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            "1" &&
                                                        _partTimeControllers
                                                            .isNotEmpty)
                                                    ? _partTimeControllers[
                                                        index]
                                                    : TextEditingController(),
                                                maleController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            "2" &&
                                                        _maleControllers
                                                            .isNotEmpty)
                                                    ? _maleControllers[index]
                                                    : TextEditingController(),
                                                femaleController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            "2" &&
                                                        _femaleControllers
                                                            .isNotEmpty)
                                                    ? _femaleControllers[index]
                                                    : TextEditingController(),
                                                responseTextController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            " " &&
                                                        _responseTextControllers
                                                            .isNotEmpty)
                                                    ? _responseTextControllers[
                                                        index]
                                                    : TextEditingController(),
                                              )
                                            : QuestionWidget(
                                                key: Key(provider
                                                    .sectionList![
                                                        provider.selectedIndex]
                                                    .child![provider
                                                        .selectedIndexChild]
                                                    .questions![index]
                                                    .q_id!),
                                                question: provider
                                                    .sectionList![
                                                        provider.selectedIndex]
                                                    .child![provider
                                                        .selectedIndexChild]
                                                    .questions![index],
                                                type: provider
                                                        .sectionList![provider
                                                            .selectedIndex]
                                                        .type_id ??
                                                    '',
                                                aid: widget
                                                    .hospitalAssessmentModel!
                                                    .assessment_id!,
                                                provider: provider,
                                                fullTimeController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            "1" &&
                                                        _fullTimeControllers
                                                            .isNotEmpty)
                                                    ? _fullTimeControllers[
                                                        index]
                                                    : TextEditingController(),
                                                partTimeController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            "1" &&
                                                        _partTimeControllers
                                                            .isNotEmpty)
                                                    ? _partTimeControllers[
                                                        index]
                                                    : TextEditingController(),
                                                maleController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            "2" &&
                                                        _maleControllers
                                                            .isNotEmpty)
                                                    ? _maleControllers[index]
                                                    : TextEditingController(),
                                                femaleController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            "2" &&
                                                        _femaleControllers
                                                            .isNotEmpty)
                                                    ? _femaleControllers[index]
                                                    : TextEditingController(),
                                                responseTextController: (provider
                                                                .sectionList![
                                                                    provider
                                                                        .selectedIndex]
                                                                .type_id ==
                                                            " " &&
                                                        _responseTextControllers
                                                            .isNotEmpty)
                                                    ? _responseTextControllers[
                                                        index]
                                                    : TextEditingController(),
                                              )
                                    : QuestionWidget(
                                        key: Key(provider
                                            .sectionList![
                                                provider.selectedIndex]
                                            .questions![index]
                                            .q_id!),
                                        question: provider
                                            .sectionList![
                                                provider.selectedIndex]
                                            .questions![index],
                                        type: provider
                                                .sectionList![
                                                    provider.selectedIndex]
                                                .type_id ??
                                            '',
                                        aid: widget.hospitalAssessmentModel!
                                            .assessment_id!,
                                        provider: provider,
                                        fullTimeController: (provider
                                                        .sectionList![provider
                                                            .selectedIndex]
                                                        .type_id ==
                                                    "1" &&
                                                _fullTimeControllers.isNotEmpty)
                                            ? _fullTimeControllers[index]
                                            : TextEditingController(),
                                        partTimeController: (provider
                                                        .sectionList![provider
                                                            .selectedIndex]
                                                        .type_id ==
                                                    "1" &&
                                                _partTimeControllers.isNotEmpty)
                                            ? _partTimeControllers[index]
                                            : TextEditingController(),
                                        maleController: (provider
                                                        .sectionList![provider
                                                            .selectedIndex]
                                                        .type_id ==
                                                    "2" &&
                                                _maleControllers.isNotEmpty)
                                            ? _maleControllers[index]
                                            : TextEditingController(),
                                        femaleController: (provider
                                                        .sectionList![provider
                                                            .selectedIndex]
                                                        .type_id ==
                                                    "2" &&
                                                _femaleControllers.isNotEmpty)
                                            ? _femaleControllers[index]
                                            : TextEditingController(),
                                        responseTextController: (provider
                                                        .sectionList![provider
                                                            .selectedIndex]
                                                        .questions !=
                                                    [] &&
                                                provider
                                                    .sectionList![
                                                        provider.selectedIndex]
                                                    .questions!
                                                    .isNotEmpty)
                                            ? (provider
                                                            .sectionList![provider
                                                                .selectedIndex]
                                                            .type_id ==
                                                        " " &&
                                                    provider
                                                            .sectionList![provider
                                                                .selectedIndex]
                                                            .questions![0]
                                                            .question_type ==
                                                        'text')
                                                ? _responseTextControllers[
                                                    index]
                                                : TextEditingController()
                                            : TextEditingController(),
                                      );
                              },
                            ),
                          ),
            const SizedBox(
              height: 8,
            ),
            provider.selectedIndex == -1
                ? const SizedBox()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      provider.isLoadingSubmitSection == true
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : provider.sectionList![provider.selectedIndex]
                                      .type_id ==
                                  "3"
                              ? SizedBox()
                              : SizedBox(
                                  width: MediaQuery.of(context).size.width / 2,
                                  child: MaterialButton(
                                    onPressed: () {
                                      submitSectionOffline(
                                        provider,
                                        context,
                                      );
                                    },
                                    color: Colors.blue,
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      child: Text(
                                        'Submit Section',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                      const SizedBox(
                        height: 10,
                      ),
                      provider.isLoadingCompleteAssessment == true
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : SizedBox(
                              width: MediaQuery.of(context).size.width / 1.8,
                              child: MaterialButton(
                                onPressed: () {
                                  completeAssessment(
                                      context,
                                      provider,
                                      widget.hospitalAssessmentModel
                                          .assessment_id!);
                                },
                                color: Colors.blue,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Text(
                                    'Complete Assessment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  )
          ],
        ),
      ),
    );
  }

  Decoration decoration1 = const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(20)), color: Colors.white);

  List<Map<String, String>> gatherResponses(AssessmentProvider provider) {
    List<Map<String, String>> responses = [];

    for (var question in provider.selectedIndexChild == -1
        ? provider.sectionList![provider.selectedIndex].questions!
        : provider.sectionList![provider.selectedIndex]
            .child![provider.selectedIndexChild].questions!) {
      if (question.response_ids != null) {
        final optionDescription = question.options!
            .firstWhere((option) => option.id == question.response_ids,
                orElse: () => Option(id: "", description: ""))
            .description;
        responses.add({
          'qid': question.q_id!,
          'response': optionDescription,
          'response_ids': question.response_ids!.trim(),
        });
      }
    }

    return responses;
  }

  List<Map<String, String>> gatherResponsesOnline(List<Question> questions) {
    List<Map<String, String>> responses = [];
    print('12121212 ${questions.length}');
    for (var question in questions) {
      if (question.response_ids != null) {
        final optionDescription = question.options!
            .firstWhere((option) => option.id == question.response_ids,
                orElse: () => Option(id: "", description: ""))
            .description;
        responses.add({
          'qid': question.q_id!,
          'response': optionDescription,
          'response_ids': question.response_ids!.trim(),
        });
      }
    }

    return responses;
  }

  List<Map<String, String>> gatherTextResponses(AssessmentProvider provider) {
    List<Map<String, String>> responses = [];

    for (var question in provider.selectedIndexChild == -1
        ? provider.sectionList![provider.selectedIndex].questions!
        : provider.sectionList![provider.selectedIndex]
            .child![provider.selectedIndexChild].questions!) {
      responses.add({
        'qid': question.q_id!,
        'response': question.response!,
        'response_ids': question.response_ids!.trim() ?? "",
      });
    }

    return responses;
  }

  List<Map<String, String>> gatherTextResponsesOnline(
      List<Question> questions) {
    List<Map<String, String>> responses = [];

    for (Question question in questions) {
      responses.add({
        'qid': question.q_id!,
        'response': question.response!,
        'response_ids': question.response_ids!.trim() ?? "",
      });
    }

    return responses;
  }

  List<Map<String, String>> gatherBedResponses(AssessmentProvider provider) {
    List<Map<String, String>> responses = [];

    for (var question in provider.bedList!) {
      responses.add({
        'male': question.male == 0 ? '' : question.male!.toString(),
        'female': question.female == 0 ? '' : question.female!.toString(),
        'qid': question.q_id!,
      });
    }

    return responses;
  }

  List<Map<String, String>> gatherStaffResponses(AssessmentProvider provider) {
    List<Map<String, String>> responses = [];

    for (var question in provider.staffList!) {
      responses.add({
        'full_time':
            question.full_time == 0 ? '' : question.full_time!.toString(),
        'part_time':
            question.part_time == 0 ? '' : question.part_time!.toString(),
        'qid': question.q_id!,
      });
    }

    return responses;
  }

  Map<String, dynamic> generateJson(
      List<Map<String, String>> responses, AssessmentProvider provider) {
    return {
      'responses': responses,
    };
  }

  void resetResponses(AssessmentProvider provider) {
    for (var section in provider.sectionList!) {
      for (var question in section.questions!) {
        question.response_ids = null;
      }
      for (var child in section.child ?? []) {
        for (var question in child.questions ?? []) {
          question.response_ids = null;
        }
      }
    }
  }

  void resetBedResponses(AssessmentProvider provider) {}

  void moveToNextSection(AssessmentProvider provider) {
    // Implement the logic to move to the next section
    if (provider.selectedIndex < provider.sectionList!.length - 1) {
      provider.setChildRemovedOnBack();
      provider.setSelectedIndex(provider.selectedIndex + 1);
    } else {
      // Handle completion of all sections
    }
  }

  Widget header(AssessmentProvider provider) {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: provider.isLoading == true
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.sectionList!.length,
                  itemBuilder: (context, index) {
                    final items = provider.sectionList![index];
                    final isSelected = provider.selectedIndex == index;
                    final statusCode = getCheck(provider, index);
                    final bgColor =
                        isSelected ? Colors.blue : _statusColor(statusCode);
                    final badge = _sectionBadgeLabel(provider, index);

                    return InkWell(
                      onTap: () {
                        provider.setChildRemovedOnBack();
                        if (provider.sectionList![index].type_id == "1") {
                          clearTextFields();
                          getStaffData(provider, index);
                        }
                        if (provider.sectionList![index].type_id == "2") {
                          clearTextFields();
                          getBedData(provider, index);
                        }
                        if (provider.sectionList![index].type_id == "3") {
                          clearTextFields();
                          getPDFData(provider);
                        }
                        if (provider.sectionList![index].questions != null &&
                            provider
                                .sectionList![index].questions!.isNotEmpty) {
                          if (provider.sectionList![index].type_id == " " &&
                              provider.sectionList![index].questions![0]
                                      .question_type ==
                                  'text') {
                            clearTextFields();
                            getTextData(provider, index);
                          }
                          if (provider.sectionList![index].type_id == " " &&
                              provider.sectionList![index].questions![0]
                                      .question_type ==
                                  'files') {
                            clearTextFields();
                            getPictureData(provider, index);
                          }
                        }
                        if (items.child!.isNotEmpty) {
                          provider.setHasChild(true, index);
                        } else {
                          provider.setHasChild(false, index);
                        }
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ── Circle ──────────────────────────────────────
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.35),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${items.list_title}',
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 8.0,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      // Badge line
                                      if (badge.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.18),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            badge,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // ── Status dot ──────────────────────────────────
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : bgColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

// ═══════════════════════════════════════════════════════════════════════════
// IMPROVED child() widget — same badge treatment for child circles
// ═══════════════════════════════════════════════════════════════════════════

  Widget child(AssessmentProvider provider) {
    return SizedBox(
      height: 120,
      child: provider.isLoading == true
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  provider.sectionList![provider.selectedIndex].child!.length,
              itemBuilder: (context, index) {
                final items =
                    provider.sectionList![provider.selectedIndex].child![index];
                final isSelected = provider.selectedIndexChild == index;
                final statusCode = getCheckChild(provider, index);
                final bgColor =
                    isSelected ? Colors.blue : _statusColor(statusCode);
                final badge = _sectionBadgeLabel(
                    provider, provider.selectedIndex,
                    childIndex: index);

                return InkWell(
                  onTap: () {
                    if (items.child!.isNotEmpty) {
                      provider.setHasSubChild(true, index);
                    } else {
                      provider.setHasSubChild(false, index);
                    }
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${items.list_title}',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  if (badge.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badge,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

// ═══════════════════════════════════════════════════════════════════════════
// IMPROVED subChild() widget — same badge treatment
// ═══════════════════════════════════════════════════════════════════════════

  Widget subChild(AssessmentProvider provider) {
    return SizedBox(
      height: 120,
      child: provider.isLoading == true
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.sectionList![provider.selectedIndex]
                  .child![provider.selectedIndexChild].child!.length,
              itemBuilder: (context, index) {
                final items = provider.sectionList![provider.selectedIndex]
                    .child![provider.selectedIndexChild].child![index];
                final isSelected = provider.selectedIndexSubChild == index;
                final statusCode = getCheckSubChild(provider, index);
                final bgColor =
                    isSelected ? Colors.blue : _statusColor(statusCode);
                final badge = _sectionBadgeLabel(
                  provider,
                  provider.selectedIndex,
                  childIndex: provider.selectedIndexChild,
                  subIndex: index,
                );

                return InkWell(
                  onTap: () {
                    provider.setSubChildIndex(index);
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${items.list_title}',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  if (badge.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badge,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Toast toast = Toast();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CheckConnectivity _connectivityService = CheckConnectivity();

  submitSectionOffline(
      AssessmentProvider provider, BuildContext context) async {
    if (provider.sectionList![provider.selectedIndex].type_id == "1") {
      final responses = gatherStaffResponses(provider);
      final json = generateJson(responses, provider);
      print("STAFFJSON ${jsonEncode(json)}");
      for (var data in json['responses']) {
        await DatabaseHelper().updateStaffing(
            data['qid']!,
            int.parse(data['full_time'] == "" ? "0" : data['full_time']!),
            int.parse(data['part_time'] == "" ? "0" : data['part_time']!));
      }
      clearTextFields();
      provider.disposeValues();
      await provider.getPicturesListOffline(
          // ← ADD THIS
          context,
          widget.hospitalAssessmentModel.assessment_id!);

      getData();
    } else if (provider.sectionList![provider.selectedIndex].type_id == "2") {
      //bed capacity
      final responses = gatherBedResponses(provider);
      final json = generateJson(responses, provider);
      print("BEDJSON ${jsonEncode(json)}");
      for (var data in json['responses']) {
        await DatabaseHelper().updateBedCapacity(
            data['qid']!,
            int.parse(data['male'] == "" ? "0" : data['male']!),
            int.parse(data['female'] == "" ? "0" : data['female']!));
      }
      clearTextFields();
      provider.disposeValues();
      await provider.getPicturesListOffline(
          // ← ADD THIS
          context,
          widget.hospitalAssessmentModel.assessment_id!);
      getData();
    } else if (provider.sectionList![provider.selectedIndex].questions != [] &&
        provider.sectionList![provider.selectedIndex].questions!.isNotEmpty) {
      if (provider.sectionList![provider.selectedIndex].type_id == " " &&
          provider.sectionList![provider.selectedIndex].questions![0]
                  .question_type ==
              'text') {
        final responses = gatherTextResponses(provider);
        final json = generateJson(responses, provider);
        print(jsonEncode(json)); // You can handle the JSON as needed
        for (var data in json['responses']) {
          await DatabaseHelper().updateQuestionInSectionData(
              provider.selectedIndexChild == -1
                  ? provider.sectionList![provider.selectedIndex].id!
                  : provider.sectionList![provider.selectedIndex]
                      .child![provider.selectedIndexChild].id!,
              data['qid']!,
              data['response']!,
              data['response_ids']!);
        }
        resetResponses(provider); // Reset responses after gathering
        clearTextFields();
        provider.disposeValues();
        await provider.getPicturesListOffline(
            // ← ADD THIS
            context,
            widget.hospitalAssessmentModel.assessment_id!);
        getData();
      } else {
        print(
            'ssa12 ${provider.sectionList![provider.selectedIndex].questions![0].question_type}');
        final responses = gatherResponses(provider);
        final json = generateJson(responses, provider);
        print(jsonEncode(json)); // You can handle the JSON as needed
        for (var data in json['responses']) {
          await DatabaseHelper().updateQuestionInSectionData(
              provider.selectedIndexChild == -1
                  ? provider.sectionList![provider.selectedIndex].id!
                  : provider.sectionList![provider.selectedIndex]
                      .child![provider.selectedIndexChild].id!,
              data['qid']!,
              data['response']!,
              data['response_ids']!);
        }
        resetResponses(provider); // Reset responses after gathering
        clearTextFields();
        provider.disposeValues();
        await provider.getPicturesListOffline(
            // ← ADD THIS
            context,
            widget.hospitalAssessmentModel.assessment_id!);
        getData();
      }
    }
  }

  getStaffData(AssessmentProvider provider, int index) async {
    print('object');
    await provider.getStaffListOffline(
        context,
        widget.hospitalAssessmentModel.assessment_id!,
        widget.hospitalAssessmentModel.criteria_type_id!,
        widget.hospitalAssessmentModel.sp_id!,
        provider.sectionList![index].id!);
    print('Staff list order:');
    for (int i = 0; i < provider.staffList!.length; i++) {
      print(
          '  $i: ${provider.staffList![i].question} (q_id: ${provider.staffList![i].q_id})');
    }
    if (provider.staffList!.isNotEmpty) {
      _fullTimeControllers = [];
      _partTimeControllers = [];
      _fullTimeControllers = provider.staffList!.map((staff) {
        final controller = TextEditingController(
            text: staff.full_time == 0 ? '' : staff.full_time.toString());
        controller.addListener(() {
          if (controller.text.isNotEmpty) {
            setState(() {
              staff.full_time = int.parse(controller.text);
            });
          }
        });
        return controller;
      }).toList();
      _partTimeControllers = provider.staffList!.map((staff) {
        final controller = TextEditingController(
            text: staff.part_time == 0 ? '' : staff.part_time.toString());
        controller.addListener(() {
          if (controller.text.isNotEmpty) {
            setState(() {
              staff.part_time = int.parse(controller.text);
            });
          }
        });
        return controller;
      }).toList();
    }
  }

  getBedData(AssessmentProvider provider, int index) async {
    print('1212122');
    await provider.getBedCapacityListOffline(
        context,
        widget.hospitalAssessmentModel.assessment_id!,
        widget.hospitalAssessmentModel.criteria_type_id!,
        widget.hospitalAssessmentModel.sp_id!,
        provider.sectionList![index].id!);

    if (provider.bedList != []) {
      _maleControllers = [];
      _femaleControllers = [];
      _maleControllers = provider.bedList!.map((staff) {
        final controller = TextEditingController(
            text: staff.male == 0 ? '' : staff.male.toString());
        controller.addListener(() {
          if (controller.text.isNotEmpty) {
            setState(() {
              staff.male = int.parse(controller.text);
            });
          }
        });
        return controller;
      }).toList();
      _femaleControllers = provider.bedList!.map((staff) {
        final controller = TextEditingController(
            text: staff.female == 0 ? '' : staff.female.toString());
        controller.addListener(() {
          if (controller.text.isNotEmpty) {
            setState(() {
              staff.female = int.parse(controller.text);
            });
          }
        });
        return controller;
      }).toList();
    }
  }

  getTextData(AssessmentProvider provider, int index) {
    if (provider.sectionList != []) {
      _responseTextControllers = [];
      _responseTextControllers =
          provider.sectionList![index].questions!.map((staff) {
        final controller =
            TextEditingController(text: staff.response.toString());
        controller.addListener(() {
          if (controller.text.isNotEmpty) {
            setState(() {
              staff.response = controller.text;
            });
          }
        });
        return controller;
      }).toList();
    }
  }

  getPictureData(AssessmentProvider provider, int index) async {
    await provider.getPicturesListOffline(
      context,
      widget.hospitalAssessmentModel.assessment_id!,
    );
  }

  getPDFData(AssessmentProvider provider) async {
    await provider.getPdfOffline(
      context,
      widget.hospitalAssessmentModel.assessment_id!,
    );
  }

  void showLoaderDialog(BuildContext context, String message) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Flexible(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  void updateLoaderMessage(BuildContext context, String message) {
    Navigator.of(context).pop();
    showLoaderDialog(context, message);
  }

  Future<void> completeAssessment(
    BuildContext context,
    AssessmentProvider provider,
    String assessment_id,
  ) async {
    // ── 1. Connectivity ───────────────────────────────────────────────────────
    if (await _connectivityService.checkConnection() == false) {
      toast.showErrorToast(
          'No internet connection. Please connect and try again.');
      return;
    }

    // ── 2. Load all offline data ──────────────────────────────────────────────
    final APIResponse jsonResponse = await DatabaseHelper().getALLItemList();
    if (jsonResponse.data == null || jsonResponse.data!.isEmpty) {
      toast.showErrorToast('No assessment data found to upload.');
      return;
    }
    final sections = jsonResponse.data! as List<SectionModel>;

    // ── 3. Pre-build item list ────────────────────────────────────────────────
    //    Every item registered upfront → user sees full list greyed out
    //    before upload starts, then items light up one by one.
    final items = <_UploadItem>[];
    int _idSeq = 0;
    String _nextId() => '${_idSeq++}';

    for (final s in sections) {
      final sl = s.list_title ?? s.id ?? 'Section';
      final typeLabel = _sectionTypeLabel(s);
      items.add(
          _UploadItem(id: _nextId(), label: '$typeLabel — $sl', indent: ''));

      for (final c in s.child ?? []) {
        items.add(_UploadItem(
            id: _nextId(),
            label: c.list_title ?? c.id ?? 'Sub-section',
            indent: '  └ '));
        for (final sub in c.child ?? []) {
          items.add(_UploadItem(
              id: _nextId(),
              label: sub.list_title ?? sub.id ?? 'Item',
              indent: '    └ '));
        }
      }
    }

    // ── 4. Show dialog ────────────────────────────────────────────────────────
    final ctrl = _ProgressController(context);
    ctrl.register(items);
    ctrl.show();

    // Cursor walks items in the exact same order as the loop below
    int cursor = 0;

    // ── Inner helpers (defined here to close over ctrl/provider/widget) ───────

    Future<void> submitQuestions(
      String itemId,
      String sectionId,
      List<Question> questions,
      String qType,
    ) async {
      if (questions.isEmpty) {
        ctrl.finish(itemId, success: true);
        return;
      }
      final responses = qType == 'text'
          ? gatherTextResponsesOnline(questions)
          : gatherResponsesOnline(questions);
      final json = generateJson(responses, provider);
      final res = await provider.submitSection(
        widget.hospitalAssessmentModel.criteria_type_id!,
        widget.hospitalAssessmentModel.assessment_id!,
        sectionId,
        json,
      );
      final ok = res.status!.toLowerCase() == 'success';
      ctrl.finish(itemId, success: ok, error: ok ? null : res.message);
    }

    Future<void> submitStaff(String itemId, String sectionId) async {
      await provider.getStaffListOffline(
        context,
        widget.hospitalAssessmentModel.assessment_id!,
        widget.hospitalAssessmentModel.criteria_type_id!,
        widget.hospitalAssessmentModel.sp_id!,
        sectionId,
      );
      final res = await provider.submitStaffSection(
        widget.hospitalAssessmentModel.criteria_type_id!,
        widget.hospitalAssessmentModel.assessment_id!,
        sectionId,
        widget.hospitalAssessmentModel.sp_id!,
        generateJson(gatherStaffResponses(provider), provider),
      );
      final ok = res.status!.toLowerCase() == 'success';
      ctrl.finish(itemId, success: ok, error: ok ? null : res.message);
    }

    Future<void> submitBed(String itemId, String sectionId) async {
      await provider.getBedCapacityListOffline(
        context,
        widget.hospitalAssessmentModel.assessment_id!,
        widget.hospitalAssessmentModel.criteria_type_id!,
        widget.hospitalAssessmentModel.sp_id!,
        sectionId,
      );
      final res = await provider.submitBedSection(
        widget.hospitalAssessmentModel.criteria_type_id!,
        widget.hospitalAssessmentModel.assessment_id!,
        sectionId,
        widget.hospitalAssessmentModel.sp_id!,
        generateJson(gatherBedResponses(provider), provider),
      );
      final ok = res.status!.toLowerCase() == 'success';
      ctrl.finish(itemId, success: ok, error: ok ? null : res.message);
    }

    // ── 5. Upload loop ────────────────────────────────────────────────────────
    try {
      for (final section in sections) {
        final rootId = items[cursor].id;
        cursor++;

        // ════════════════════════════════════════════════════════════════════
        // STAFF
        // ════════════════════════════════════════════════════════════════════
        if (section.type_id == "1") {
          ctrl.begin(rootId,
              stage: 'Uploading staff', detail: section.list_title ?? '');
          await submitStaff(rootId, section.id!);

          for (final child in section.child ?? []) {
            final cId = items[cursor].id;
            cursor++;
            ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
            await submitStaff(cId, child.id!);

            for (final sub in child.child ?? []) {
              final sId = items[cursor].id;
              cursor++;
              ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
              await submitStaff(sId, sub.id!);
              await Future.delayed(const Duration(milliseconds: 300));
            }
            await Future.delayed(const Duration(milliseconds: 300));
          }

          // ════════════════════════════════════════════════════════════════════
          // BED CAPACITY
          // ════════════════════════════════════════════════════════════════════
        } else if (section.type_id == "2") {
          ctrl.begin(rootId,
              stage: 'Uploading bed capacity',
              detail: section.list_title ?? '');
          await submitBed(rootId, section.id!);

          for (final child in section.child ?? []) {
            final cId = items[cursor].id;
            cursor++;
            ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
            await submitBed(cId, child.id!);

            for (final sub in child.child ?? []) {
              final sId = items[cursor].id;
              cursor++;
              ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
              await submitBed(sId, sub.id!);
              await Future.delayed(const Duration(milliseconds: 300));
            }
            await Future.delayed(const Duration(milliseconds: 300));
          }

          // ════════════════════════════════════════════════════════════════════
          // PDF
          // ════════════════════════════════════════════════════════════════════
        } else if (section.type_id == "3") {
          ctrl.begin(rootId, stage: 'Uploading PDF', detail: '');
          // Reload — disposeValues() clears pdfOffline between sections
          await provider.getPdfOffline(
              context, widget.hospitalAssessmentModel.assessment_id!);
          if (provider.pdfOffline != null && provider.pdfOffline!.isNotEmpty) {
            await uploadPDF(context,
                widget.hospitalAssessmentModel.assessment_id!, provider);
          }
          ctrl.finish(rootId, success: true);

          // ════════════════════════════════════════════════════════════════════
          // QUESTION SECTIONS
          // ════════════════════════════════════════════════════════════════════
        } else if (section.questions != null && section.questions!.isNotEmpty) {
          final qType = section.questions![0].question_type ?? '';
          final fileType = section.questions![0].file_type ?? '';

          // ── VIDEO ────────────────────────────────────────────────────────
          if (qType == 'files' && fileType == 'video') {
            ctrl.begin(rootId,
                stage: 'Uploading videos', detail: section.list_title ?? '');
            // Reload offline videos so we have the latest file paths
            await provider.getVideosListOffline(
                context, widget.hospitalAssessmentModel.assessment_id!);
            await uploadVideosOnline(context, provider, section);
            ctrl.finish(rootId, success: true);

            for (final child in section.child ?? []) {
              final cId = items[cursor].id;
              cursor++;
              ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
              if (child.questions != null && child.questions!.isNotEmpty) {
                await submitQuestions(cId, child.id!, child.questions!,
                    child.questions![0].question_type ?? '');
              } else {
                ctrl.finish(cId, success: true);
              }
              for (final sub in child.child ?? []) {
                final sId = items[cursor].id;
                cursor++;
                ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
                if (sub.questions != null && sub.questions!.isNotEmpty) {
                  await submitQuestions(sId, sub.id!, sub.questions!,
                      sub.questions![0].question_type ?? '');
                } else {
                  ctrl.finish(sId, success: true);
                }
                await Future.delayed(const Duration(milliseconds: 300));
              }
              await Future.delayed(const Duration(milliseconds: 300));
            }

            // ── IMAGES ───────────────────────────────────────────────────────
          } else if (qType == 'files') {
            ctrl.begin(rootId,
                stage: 'Uploading images', detail: section.list_title ?? '');
            await getPictureData(provider, 0);
            await uploadPicturesOnline(context, provider, section);
            ctrl.finish(rootId, success: true);

            for (final child in section.child ?? []) {
              final cId = items[cursor].id;
              cursor++;
              ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
              if (child.questions != null && child.questions!.isNotEmpty) {
                await submitQuestions(cId, child.id!, child.questions!,
                    child.questions![0].question_type ?? '');
              } else {
                ctrl.finish(cId, success: true);
              }
              for (final sub in child.child ?? []) {
                final sId = items[cursor].id;
                cursor++;
                ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
                if (sub.questions != null && sub.questions!.isNotEmpty) {
                  await submitQuestions(sId, sub.id!, sub.questions!,
                      sub.questions![0].question_type ?? '');
                } else {
                  ctrl.finish(sId, success: true);
                }
                await Future.delayed(const Duration(milliseconds: 300));
              }
              await Future.delayed(const Duration(milliseconds: 300));
            }

            // ── TEXT ─────────────────────────────────────────────────────────
          } else if (qType == 'text') {
            ctrl.begin(rootId,
                stage: 'Uploading text responses',
                detail: section.list_title ?? '');
            await submitQuestions(
                rootId, section.id!, section.questions!, 'text');

            for (final child in section.child ?? []) {
              final cId = items[cursor].id;
              cursor++;
              ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
              if (child.questions != null && child.questions!.isNotEmpty) {
                await submitQuestions(cId, child.id!, child.questions!, 'text');
              } else {
                ctrl.finish(cId, success: true);
              }
              for (final sub in child.child ?? []) {
                final sId = items[cursor].id;
                cursor++;
                ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
                if (sub.questions != null && sub.questions!.isNotEmpty) {
                  await submitQuestions(sId, sub.id!, sub.questions!, 'text');
                } else {
                  ctrl.finish(sId, success: true);
                }
                await Future.delayed(const Duration(milliseconds: 300));
              }
              await Future.delayed(const Duration(milliseconds: 300));
            }

            // ── RADIO / OTHER ─────────────────────────────────────────────────
          } else {
            ctrl.begin(rootId,
                stage: 'Uploading responses', detail: section.list_title ?? '');
            await submitQuestions(
                rootId, section.id!, section.questions!, qType);

            for (final child in section.child ?? []) {
              final cId = items[cursor].id;
              cursor++;
              ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
              if (child.questions != null && child.questions!.isNotEmpty) {
                await submitQuestions(cId, child.id!, child.questions!,
                    child.questions![0].question_type ?? '');
              } else {
                ctrl.finish(cId, success: true);
              }
              for (final sub in child.child ?? []) {
                final sId = items[cursor].id;
                cursor++;
                ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
                if (sub.questions != null && sub.questions!.isNotEmpty) {
                  await submitQuestions(sId, sub.id!, sub.questions!,
                      sub.questions![0].question_type ?? '');
                } else {
                  ctrl.finish(sId, success: true);
                }
                await Future.delayed(const Duration(milliseconds: 300));
              }
              await Future.delayed(const Duration(milliseconds: 300));
            }
            await Future.delayed(const Duration(milliseconds: 300));
          }

          // ════════════════════════════════════════════════════════════════════
          // NO-QUESTION SECTIONS  (children only)
          // ════════════════════════════════════════════════════════════════════
        } else if (section.child != null && section.child!.isNotEmpty) {
          ctrl.begin(rootId,
              stage: 'Uploading section', detail: section.list_title ?? '');
          ctrl.finish(rootId, success: true);

          for (final child in section.child ?? []) {
            final cId = items[cursor].id;
            cursor++;
            ctrl.begin(cId, detail: child.list_title ?? child.id ?? '');
            if (child.questions != null && child.questions!.isNotEmpty) {
              await submitQuestions(cId, child.id!, child.questions!,
                  child.questions![0].question_type ?? '');
            } else {
              ctrl.finish(cId, success: true);
            }
            for (final sub in child.child ?? []) {
              final sId = items[cursor].id;
              cursor++;
              ctrl.begin(sId, detail: sub.list_title ?? sub.id ?? '');
              if (sub.questions != null && sub.questions!.isNotEmpty) {
                await submitQuestions(sId, sub.id!, sub.questions!,
                    sub.questions![0].question_type ?? '');
              } else {
                ctrl.finish(sId, success: true);
              }
              await Future.delayed(const Duration(milliseconds: 300));
            }
            await Future.delayed(const Duration(milliseconds: 300));
          }
        } else {
          // Completely unhandled — skip silently
          if (cursor > 0) ctrl.finish(items[cursor - 1].id, success: true);
        }
      }

      // ── 6. Complete assessment on server ──────────────────────────────────
      ctrl.setStage('Completing assessment...', 'Sending final request');

      final APIResponse response =
          await provider.completeAssessment(assessment_id);

      ctrl.dismiss();

      if (response.status!.toLowerCase() == 'success') {
        toast.showSuccessToast(response.message ?? 'Assessment completed');
        Get.back(result: [
          {'backValue': 'completed'}
        ]);
      } else {
        showErrorDialogCompleteAssessment(context, response);
      }
    } catch (e, stack) {
      ctrl.dismiss();
      debugPrint('completeAssessment ERROR: $e\n$stack');
      toast.showErrorToast('Unexpected error: ${e.toString()}');
    }
  }

// ── Section type label (used to build the pre-rendered list) ──────────────
  String _sectionTypeLabel(SectionModel s) {
    if (s.type_id == "1") return 'Staff';
    if (s.type_id == "2") return 'Bed capacity';
    if (s.type_id == "3") return 'PDF';
    if (s.questions == null || s.questions!.isEmpty) return 'Responses';
    final qt = s.questions![0].question_type ?? '';
    final ft = s.questions![0].file_type ?? '';
    if (qt == 'files' && ft == 'video') return '🎥 Video';
    if (qt == 'files') return '🖼 Images';
    if (qt == 'text') return 'Text';
    return 'Responses';
  }

  Future<void> completeAssessmentWorking(BuildContext context,
      AssessmentProvider provider, String assessment_id) async {
    if (await _connectivityService.checkConnection() == true) {
      showLoaderDialog(context, 'Starting upload...');
      final APIResponse jsonResponse = await DatabaseHelper().getALLItemList();
      if (jsonResponse.data != []) {
        bool allSectionsSuccess = true;
        for (SectionModel sectionModel in jsonResponse.data!) {
          if (sectionModel.type_id == "1") {
            updateLoaderMessage(context, 'Uploading staff section...');
            await provider.getStaffListOffline(
                context,
                widget.hospitalAssessmentModel.assessment_id!,
                widget.hospitalAssessmentModel.criteria_type_id!,
                widget.hospitalAssessmentModel.sp_id!,
                sectionModel.id!);
            final responses = gatherStaffResponses(provider);
            final json = generateJson(responses, provider);
            print(jsonEncode(json));
            APIResponse res = await provider.submitStaffSection(
                widget.hospitalAssessmentModel.criteria_type_id!,
                widget.hospitalAssessmentModel.assessment_id!,
                sectionModel.id!,
                widget.hospitalAssessmentModel.sp_id!,
                json);
            if (res.status!.toLowerCase() != 'success') {
              toast.showErrorToast('STAFF ${res.message}' ?? '');
              allSectionsSuccess = false;
              break;
            }
          } else if (sectionModel.type_id == "2") {
            updateLoaderMessage(context, 'Uploading bed capacity...');
            await provider.getBedCapacityListOffline(
                context,
                widget.hospitalAssessmentModel.assessment_id!,
                widget.hospitalAssessmentModel.criteria_type_id!,
                widget.hospitalAssessmentModel.sp_id!,
                sectionModel.id!);
            final responses = gatherBedResponses(provider);
            final json = generateJson(responses, provider);
            print(jsonEncode(json));
            APIResponse res = await provider.submitBedSection(
                widget.hospitalAssessmentModel.criteria_type_id!,
                widget.hospitalAssessmentModel.assessment_id!,
                sectionModel.id!,
                widget.hospitalAssessmentModel.sp_id!,
                json);
            if (res.status!.toLowerCase() != 'success') {
              toast.showErrorToast('BED ${res.message}' ?? '');
              allSectionsSuccess = false;
              break;
            }
          } else if (sectionModel.type_id == "3") {
            updateLoaderMessage(context, 'Uploading PDF...');
            uploadPDF(context, widget.hospitalAssessmentModel.assessment_id!,
                provider);
          } else if (sectionModel.type_id == " " &&
              sectionModel.questions![0].question_type == 'files') {
            updateLoaderMessage(context, 'Uploading pictures...');
            await getPictureData(provider, 0);
            await uploadPicturesOnline(context, provider, sectionModel);
          } else if (sectionModel.type_id == " " &&
              sectionModel.questions![0].question_type == 'text') {
            updateLoaderMessage(context, 'Uploading text responses...');
            final responses =
                gatherTextResponsesOnline(sectionModel.questions!);
            final json = generateJson(responses, provider);
            print(jsonEncode(json));
            APIResponse res = await provider.submitSection(
                widget.hospitalAssessmentModel.criteria_type_id!,
                widget.hospitalAssessmentModel.assessment_id!,
                sectionModel.id!,
                json);
            if (res.status!.toLowerCase() != 'success') {
              toast.showErrorToast('TEXT ${res.message}' ?? '');
              allSectionsSuccess = false;
              break;
            }
          } else {
            updateLoaderMessage(context, 'Uploading responses...');
            final responses = gatherResponsesOnline(sectionModel.questions!);
            final json = generateJson(responses, provider);
            print('ResponseJSON ${jsonEncode(json)}');
            APIResponse res = await provider.submitSection(
                widget.hospitalAssessmentModel.criteria_type_id!,
                widget.hospitalAssessmentModel.assessment_id!,
                sectionModel.id!,
                json);
            if (res.status!.toLowerCase() != 'success') {
              toast.showErrorToast('RESPONSE ${res.message}' ?? '');
              allSectionsSuccess = false;
              break;
            }
          }
          // Process child sections
          if (sectionModel.child != []) {
            for (SectionChildModel childModel in sectionModel.child!) {
              updateLoaderMessage(context, 'Uploading child section...');
              final responses = gatherResponsesOnline(childModel.questions!);
              final json = generateJson(responses, provider);
              print(jsonEncode(json));
              APIResponse res = await provider.submitSection(
                  widget.hospitalAssessmentModel.criteria_type_id!,
                  widget.hospitalAssessmentModel.assessment_id!,
                  childModel.id!,
                  json);
              if (res.status!.toLowerCase() != 'success') {
                toast.showErrorToast('RESPONSE ${res.message}' ?? '');
                allSectionsSuccess = false;
                break;
              }
            }
          }

          // If any section failed, break out of the main loop
          if (!allSectionsSuccess) break;
        }

        // After all sections are processed, complete the assessment if all sections were successful
        if (allSectionsSuccess) {
          updateLoaderMessage(context, 'Completing assessment...');
          APIResponse response =
              await provider.completeAssessment(assessment_id);
          Navigator.of(context, rootNavigator: true)
              .pop(); // Dismiss the dialog
          if (response.status!.toLowerCase() == 'success') {
            toast.showSuccessToast('${response.message}');
            Get.back(result: [
              {"backValue": "done"}
            ]);
          } else {
            showErrorDialogCompleteAssessment(context, response);
          }
        } else {
          Navigator.of(context, rootNavigator: true)
              .pop(); // Dismiss the dialog if any section failed
        }
      } else {
        Navigator.of(context, rootNavigator: true)
            .pop(); // Dismiss the dialog if no data to process
      }
    } else {
      toast.showErrorToast(
          'You need internet connection to upload this assessment');
    }
  }

  Future<void> uploadVideosOnline(BuildContext context,
      AssessmentProvider provider, SectionModel sectionModel) async {
    final videoList = provider.videoList;
    if (videoList == null || videoList.isEmpty) {
      print('uploadVideosOnline: no videos found for this section');
      return;
    }

    for (VideoSectionModel videoModel in videoList) {
      // Find the matching question in this section
      Question? matchingQuestion = sectionModel.questions!.firstWhere(
        (q) => q.q_id == videoModel.qid,
        orElse: () => Question(q_id: ''),
      );

      if (matchingQuestion.q_id == null || matchingQuestion.q_id!.isEmpty) {
        print(
            'uploadVideosOnline: no matching question for qid=${videoModel.qid}');
        continue;
      }

      // doc_id holds the local file path (set in insertVideo)
      final filePath = videoModel.doc_id;
      if (filePath == null || filePath.isEmpty) {
        print('uploadVideosOnline: empty file path for qid=${videoModel.qid}');
        continue;
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        toast.showErrorToast(
            'Video file missing for: ${matchingQuestion.description ?? matchingQuestion.q_id}');
        print('uploadVideosOnline: file not found at $filePath');
        continue; // skip missing file, don't block other uploads
      }

      final filename =
          'video_${matchingQuestion.q_id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      updateLoaderMessage(
        context,
        'Uploading video:\n${matchingQuestion.description ?? matchingQuestion.q_id}',
      );

      print(
          'uploadVideosOnline: uploading ${file.path} (${(file.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)');

      final APIResponse? res = await provider.uploadVideo(
        context,
        widget.hospitalAssessmentModel.assessment_id!,
        matchingQuestion.q_id!,
        sectionModel.id!, // csid
        filename,
        file,
      );

      if (res?.status?.toLowerCase() == 'success') {
        print('uploadVideosOnline: success for qid=${matchingQuestion.q_id}');
      } else {
        toast.showErrorToast(
            'VIDEO UPLOAD FAILED: ${res?.message ?? 'Unknown error'}');
        print(
            'uploadVideosOnline: failed for qid=${matchingQuestion.q_id} — ${res?.message}');
        // continue to next video — same behaviour as uploadPicturesOnline
      }

      // Small delay between uploads to avoid server overload
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> uploadPicturesOnline(BuildContext context,
      AssessmentProvider provider, SectionModel sectionModel) async {
    for (PicturesSectionModel picturesSectionModel in provider.picsList!) {
      // Find the corresponding question for the picture
      Question? matchingQuestion = sectionModel.questions!.firstWhere(
          (question) => question.q_id == picturesSectionModel.qid,
          orElse: () => Question(q_id: ''));

      if (matchingQuestion.q_id != '') {
        print('Uploading picture for question ${matchingQuestion.q_id}');
        final String filePath = picturesSectionModel.doc_id!;
        final bool isPdf = filePath.toLowerCase().endsWith('.pdf');
        final String contentType = isPdf ? 'application/pdf' : 'image/jpeg';
        XFile imageFile = XFile(picturesSectionModel.doc_id!);
        APIResponse? res = await provider.pickImage(
            context,
            widget.hospitalAssessmentModel.assessment_id!,
            matchingQuestion.q_id!,
            sectionModel.id!,
            imageFile.name,
            imageFile,contentType,isPdf);
        if (res!.status!.toLowerCase() != 'success') {
          toast.showErrorToast('TEXT ${res.message}' ?? '');
          break;
        }
      } else {
        print(
            'No matching question found for picture with doc_id ${picturesSectionModel.doc_id}');
      }
    }
  }

  Widget boxContent(BuildContext context, String name, String no, String image,
      AssessmentProvider provider, String aid) {
    return GestureDetector(
      onTap: () {
        _pickPDFFile(provider, aid);
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2), // Shadow color
                        spreadRadius: 2, // Spread radius
                        blurRadius: 5, // Blur radius
                        offset:
                            const Offset(2, 4), // Offset (vertical, horizontal)
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      image,
                      height: 0.04.sh,
                      width: 0.04.sh,
                    ),
                  )),
              SizedBox(height: 15.h),
              Text(
                name,
                style: GoogleFonts.poppins(fontSize: 12.sp),
              ),
              SizedBox(height: 2.0.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                        child: Container(
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(
                          "UPLOAD",
                          style: GoogleFonts.poppins(
                              color: color.bluePrimary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<int>? pdfBytes;
  FilePickerResult _pdfFileResult = const FilePickerResult([]);
  TextEditingController amountController = TextEditingController();

  Future<void> _pickPDFFile(AssessmentProvider provider, String aid) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowCompression: true,
        compressionQuality: 50,
        allowMultiple: false,
      );

      if (result != null) {
        // setState(() {
        //   _pdfFileResult = result;
        // });

        XFile pdfFile = XFile(result.files.single.path!);
        print('sdsadasd ${pdfFile.path}');
        APIResponse? res = await provider.pickPdfOffline(context, aid, pdfFile);
        if (res!.status!.toLowerCase() == 'success') {
          toast.showSuccessToast(res.message ?? "");
          getPDFData(provider);
        } else {
          toast.showErrorToast('ERROR: ${res.message}');
        }
      }
    } catch (e) {
      toast.showErrorToast("Error picking PDF file: $e");
    }
  }

  late int _pages;
  bool _isPDFReadable = true;

  uploadPDF(
      BuildContext context, String aid, AssessmentProvider provider) async {
    File file = File(provider.pdfOffline![0].doc_id!);
    if (file.existsSync()) {
      Uint8List image = await file.readAsBytes();
      APIResponse? res = await provider.pickPDF(
          context,
          aid,
          provider.sectionList!
              .firstWhere((o) => o.type_id == "3",
                  orElse: () => SectionModel(id: aid))
              .id!,
          'Special Document.pdf',
          image);
      if (res!.status!.toLowerCase() != 'success') {
        toast.showErrorToast('TEXT ${res.message}' ?? '');
      } else {
        toast.showErrorToast(res.message ?? '');
      }
    }
  }

  Future<void> openURL(BuildContext context, String docID) async {
    String url =
        "https://apps.slichealth.com/ords/ihmis_admin/assesment/pdf?doc_id=$docID";
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        toast.showErrorToast("Failed: Could not launch $url");
      }
    } catch (e) {
      toast.showErrorToast("Catch: Could not launch ${e.toString()}");
    }
  }

  void clearTextFields() {
    _fullTimeControllers.clear();
    _partTimeControllers.clear();
    _maleControllers.clear();
    _femaleControllers.clear();
    _responseTextControllers.clear();
  }

  int _countAnswered(AssessmentProvider provider, List<Question> questions) {
    int count = 0;
    for (final q in questions) {
      if (q.question_type == 'files' && q.file_type == 'video') {
        if (provider.videoList?.any((v) => v.qid == q.q_id) == true) count++;
      } else if (q.question_type == 'files') {
        if (provider.picsList?.any((p) => p.qid == q.q_id) == true) count++;
      } else {
        if ((q.response ?? '').trim().isNotEmpty) count++;
      }
    }
    return count;
  }

  int getCheck(AssessmentProvider provider, int index) {
    final section = provider.sectionList![index];

    // ── PDF section ────────────────────────────────────────────────────────────
    if (section.type_id == "3") {
      return (provider.pdfOffline != null && provider.pdfOffline!.isNotEmpty)
          ? 1
          : 0;
    }

    // ── Staff section ──────────────────────────────────────────────────────────
    if (section.type_id == "1") {
      if (provider.staffList == null || provider.staffList!.isEmpty) return 0;
      final filled = provider.staffList!
          .where((s) => (s.full_time ?? 0) > 0 || (s.part_time ?? 0) > 0)
          .length;
      if (filled == 0) return 0;
      return filled == provider.staffList!.length ? 1 : 2;
    }

    // ── Bed section ────────────────────────────────────────────────────────────
    if (section.type_id == "2") {
      if (provider.bedList == null || provider.bedList!.isEmpty) return 0;
      final filled = provider.bedList!
          .where((b) => (b.male ?? 0) > 0 || (b.female ?? 0) > 0)
          .length;
      if (filled == 0) return 0;
      return filled == provider.bedList!.length ? 1 : 2;
    }

    // ── Sections that have their own questions ─────────────────────────────────
    int totalQ = 0;
    int answeredQ = 0;

// parent questions
    if (section.questions != null && section.questions!.isNotEmpty) {
      totalQ += section.questions!.length;
      answeredQ += _countAnswered(provider, section.questions!);
    }

// children
    if (section.child != null && section.child!.isNotEmpty) {
      for (final child in section.child!) {
        if (child.questions != null && child.questions!.isNotEmpty) {
          totalQ += child.questions!.length;
          answeredQ += _countAnswered(provider, child.questions!);
        }

        if (child.child != null) {
          for (final sub in child.child!) {
            if (sub.questions != null && sub.questions!.isNotEmpty) {
              totalQ += sub.questions!.length;
              answeredQ += _countAnswered(provider, sub.questions!);
            }
          }
        }
      }
    }

    if (totalQ == 0) return 0;
    if (answeredQ == 0) return 0;
    return answeredQ == totalQ ? 1 : 2;

    // ── Fallback ───────────────────────────────────────────────────────────────
    return 0;
  }

  int getCheckChild(AssessmentProvider provider, int index) {
    final child = provider.sectionList![provider.selectedIndex].child![index];

    // If child has its own questions, check those
    if (child.questions != null && child.questions!.isNotEmpty) {
      final total = child.questions!.length;
      final answered = _countAnswered(provider, child.questions!);
      if (answered == 0) return 0;
      return answered == total ? 1 : 2;
    }

    // Child has no direct questions — check sub-children
    if (child.child != null && child.child!.isNotEmpty) {
      int totalQ = 0;
      int answeredQ = 0;
      for (final sub in child.child!) {
        if (sub.questions != null) {
          totalQ += sub.questions!.length;
          answeredQ += _countAnswered(provider, sub.questions!);
        }
      }
      if (totalQ == 0) return 0;
      if (answeredQ == 0) return 0;
      return answeredQ == totalQ ? 1 : 2;
    }

    return 0;
  }

// ── 3.  getCheckSubChild  ───────────────────────────────────────────────────

  int getCheckSubChild(AssessmentProvider provider, int index) {
    final sub = provider.sectionList![provider.selectedIndex]
        .child![provider.selectedIndexChild].child![index];

    if (sub.questions == null || sub.questions!.isEmpty) return 0;
    final total = sub.questions!.length;
    final answered = _countAnswered(provider, sub.questions!);
    if (answered == 0) return 0;
    return answered == total ? 1 : 2;
  }

// ── 4.  _sectionBadgeLabel  — text shown inside each section circle ─────────
//
// Returns a short string (max ~7 chars) to show inside the circular button.
// Called from header(), child(), and subChild() builders.

  String _sectionBadgeLabel(AssessmentProvider provider, int rootIndex,
      {int? childIndex, int? subIndex}) {
    // ── Sub-child badge ────────────────────────────────────────────────────────
    if (subIndex != null && childIndex != null) {
      final sub =
          provider.sectionList![rootIndex].child![childIndex].child![subIndex];
      if (sub.questions == null || sub.questions!.isEmpty) return '—';
      final total = sub.questions!.length;
      final answered = _countAnswered(provider, sub.questions!);
      return '$answered/$total';
    }

    // ── Child badge ────────────────────────────────────────────────────────────
    if (childIndex != null) {
      final child = provider.sectionList![rootIndex].child![childIndex];
      if (child.questions != null && child.questions!.isNotEmpty) {
        final total = child.questions!.length;
        final answered = _countAnswered(provider, child.questions!);
        return '$answered/$total';
      }
      // Show child count if no direct questions
      final subCount = child.child?.length ?? 0;
      if (subCount > 0) return '$subCount sub';
      return '—';
    }

    // ── Root section badge ─────────────────────────────────────────────────────
    final section = provider.sectionList![rootIndex];

    if (section.type_id == "3") {
      // PDF
      return (provider.pdfOffline != null && provider.pdfOffline!.isNotEmpty)
          ? 'PDF ✓'
          : 'No PDF';
    }

    if (section.type_id == "1") {
      // Staff
      if (provider.staffList == null || provider.staffList!.isEmpty) {
        return '0 staff';
      }
      final filled = provider.staffList!
          .where((s) => (s.full_time ?? 0) > 0 || (s.part_time ?? 0) > 0)
          .length;
      return '$filled/${provider.staffList!.length}';
    }

    if (section.type_id == "2") {
      // Bed
      if (provider.bedList == null || provider.bedList!.isEmpty) {
        return '0 beds';
      }
      final filled = provider.bedList!
          .where((b) => (b.male ?? 0) > 0 || (b.female ?? 0) > 0)
          .length;
      return '$filled/${provider.bedList!.length}';
    }

    if (section.questions != null && section.questions!.isNotEmpty) {
      final total = section.questions!.length;
      final answered = _countAnswered(provider, section.questions!);
      return '$answered/$total';
    }

    // Section with children only — count total child questions
    if (section.child != null && section.child!.isNotEmpty) {
      int totalQ = 0;
      int answeredQ = 0;
      for (final c in section.child!) {
        if (c.questions != null) {
          totalQ += c.questions!.length;
          answeredQ += _countAnswered(provider, c.questions!);
        }
        if (c.child != null) {
          for (final s in c.child!) {
            if (s.questions != null) {
              totalQ += s.questions!.length;
              answeredQ += _countAnswered(provider, s.questions!);
            }
          }
        }
      }
      if (totalQ == 0) return '${section.child!.length} ch';
      return '$answeredQ/$totalQ';
    }

    return '—';
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // getCheckChild(AssessmentProvider provider, int index) {
  //   if ((provider.sectionList![provider.selectedIndex].child![index].questions!
  //       .length) ==
  //       provider.sectionList![provider.selectedIndex].child![index].questions!
  //           .where((element) => element.response!.trim() != "")
  //           .length) {
  //     return 1;
  //   }
  //   if (provider.sectionList![provider.selectedIndex].child![index].questions!
  //       .isNotEmpty) {
  //     return 2;
  //   }
  //   if (provider.sectionList![provider.selectedIndex].child![index].questions!
  //       .isEmpty) {
  //     return 0;
  //   }
  // }
  //
  // getCheckSubChild(AssessmentProvider provider, int index) {
  //   if ((provider
  //       .sectionList![provider.selectedIndex]
  //       .child![provider.selectedIndexChild]
  //       .child![index]
  //       .questions!
  //       .length) ==
  //       provider.sectionList![provider.selectedIndex]
  //           .child![provider.selectedIndexChild].child![index].questions!
  //           .where((element) => element.response!.trim() != "")
  //           .length) {
  //     return 1;
  //   }
  //   if (provider
  //       .sectionList![provider.selectedIndex]
  //       .child![provider.selectedIndexChild]
  //       .child![index]
  //       .questions!
  //       .isNotEmpty) {
  //     return 2;
  //   }
  //   if (provider.sectionList![provider.selectedIndex]
  //       .child![provider.selectedIndexChild].child![index].questions!.isEmpty) {
  //     return 0;
  //   }
  // }

  Future<void> deletePdfOffline(
      BuildContext context, AssessmentProvider provider, String aid) async {
    APIResponse res = await DatabaseHelper().deletePdf(aid);

    if (res.status!.toLowerCase() == 'success') {
      getPDFData(provider);
    }
  }
}

class QuestionWidget extends StatefulWidget {
  final Question question;
  final String type;
  String? aid;
  final AssessmentProvider provider;
  TextEditingController? fullTimeController;
  TextEditingController? partTimeController;
  TextEditingController? maleController;
  TextEditingController? femaleController;
  TextEditingController? responseTextController;

  QuestionWidget(
      {required Key key,
      required this.question,
      required this.type,
      this.aid,
      required this.provider,
      this.fullTimeController,
      this.partTimeController,
      this.maleController,
      this.femaleController,
      this.responseTextController})
      : super(key: key);

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  String? selectedOption;

  getPictureData(BuildContext context, AssessmentProvider provider) async {
    await provider.getPicturesListOffline(
      context,
      widget.aid!,
    );
  }

  getPDFData(BuildContext context, AssessmentProvider provider) async {
    await provider.getPdfOffline(
      context,
      widget.aid!,
    );
  }

  Toast toast = Toast();

  showPdfPicker(
    BuildContext context,
    String aid,
    String qid,
    AssessmentProvider provider,
  ) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Select PDF'),
                onTap: () async {
                  Navigator.pop(context);

                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );

                  if (result != null) {
                    String path = result.files.single.path!;

                    XFile pdfFile = XFile(path);

                    APIResponse? res = await provider.pickImageOffline(
                      context,
                      aid,
                      qid,
                      pdfFile,
                    );

                    if (res!.status!.toLowerCase() == 'success') {
                      toast.showSuccessToast(res.message ?? "");
                      getPictureData(context, provider);
                    } else {
                      toast.showErrorToast(res.message ?? '');
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  showBottomSheetNew(BuildContext context, String aid, String qid,
      AssessmentProvider provider) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile =
                      await ImagePicker().pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    // Do something with the picked image
                    XFile imageFile = XFile(pickedFile.path);
                    APIResponse? res = await provider.pickImageOffline(
                        context, aid, qid, imageFile);
                    if (res!.status!.toLowerCase() == 'success') {
                      toast.showSuccessToast(res.message ?? "");
                      getPictureData(context, provider);
                    } else {
                      toast.showErrorToast(res.message ?? '');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    XFile imageFile = XFile(pickedFile.path);
                    APIResponse? res = await provider.pickImageOffline(
                        context, aid, qid, imageFile);
                    if (res!.status!.toLowerCase() == 'success') {
                      toast.showSuccessToast(res.message ?? "");
                      getPictureData(context, provider);
                    } else {
                      toast.showErrorToast(res.message ?? '');
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    print('object12131 ${widget.type}');
    selectedOption = widget.question.response_ids;
  }

  bool allQuestionsAnswered(Question question) {
    return question.response!.trim() != "";
  }

  // getCheck(AssessmentProvider provider, int index) {
  //   if ((provider.sectionList![index].questions!.length) ==
  //       (provider.sectionList![index].questions!
  //           .where((element) => element.response != " ")
  //           .length)) {
  //     return 1;
  //   }
  //   if (provider.sectionList![index].questions!
  //       .where((element) => element.response != " ")
  //       .isNotEmpty) {
  //     return 2;
  //   }
  //   if (provider.sectionList![index].questions!
  //       .where((element) => element.response != " ")
  //       .isEmpty) {
  //     return 0;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isPdf = widget.question.file_type == 'pdf';
    final isVideo = widget.question.file_type == 'video';
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: allQuestionsAnswered(widget.question)
          ? Colors.greenAccent
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question.description ?? "",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(),
            if (widget.type == "1") //Staffing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: widget.fullTimeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Full Time',
                          hintText: 'No.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: widget.partTimeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Part Time',
                          hintText: 'No.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (widget.type == "2") //Bed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: widget.maleController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          print('object ${val}');
                          if (val.isNotEmpty) {
                            widget.maleController!.text = val;
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Male',
                          hintText: 'No.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: widget.femaleController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            widget.femaleController!.text = val;
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Female',
                          hintText: 'No.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            widget.question.question_type == 'radio'
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.question.options!.length,
                    itemBuilder: (context, index) {
                      final option = widget.question.options![index];

                      return RadioListTile<String>(
                        title: Text(option.description),
                        value: option.id,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setData(value, option, widget.question);
                        },
                      );
                    },
                  )
                : widget.question.question_type == 'files'
                    // ── files branch: split on file_type ─────────────────────────
                    ? (isVideo)
                        // ── VIDEO ────────────────────────────────────────────────
                        ? VideoQuestionWidget(
                            key: ValueKey('video_${widget.question.q_id}'),
                            isOffline: true,
                            qid: widget.question.q_id!,
                            aid: widget.aid ?? '',
                            sid: (widget.provider.selectedIndexSubChild != -1
                                ? widget
                                    .provider
                                    .sectionList![widget.provider.selectedIndex]
                                    .child![widget.provider.selectedIndexChild]
                                    .child![
                                        widget.provider.selectedIndexSubChild]
                                    .id!
                                : widget.provider.selectedIndexChild != -1
                                    ? widget
                                        .provider
                                        .sectionList![
                                            widget.provider.selectedIndex]
                                        .child![
                                            widget.provider.selectedIndexChild]
                                        .id!
                                    : widget
                                        .provider
                                        .sectionList![
                                            widget.provider.selectedIndex]
                                        .id!),
                            questionDescription:
                                widget.question.description ?? '',
                            provider: widget.provider,
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              widget.provider.picsList != []
                                  ? widget.provider.picsList!
                                          .where((e) =>
                                              e.qid == widget.question!.q_id)
                                          .isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            print(
                                                'object321 ${File('${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}').path}');
                                            if (isPdf) {
                                              OpenFile.open(File(
                                                      '${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}')
                                                  .path);
                                            } else {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Dialog(
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      color: Colors.black,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: Image.file(
                                                          File(
                                                              '${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}'),
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }
                                          },
                                          child: SizedBox(
                                            height: 150,
                                            width: 150,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                const CircularProgressIndicator(),
                                                isPdf
                                                    ? GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () {
                                                          OpenFile.open(
                                                              '${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}');
                                                        },
                                                        child: Container(
                                                          height: 150,
                                                          width: 150,
                                                          color:
                                                              Colors.grey[200],
                                                          child: Center(
                                                            child: Icon(
                                                                Icons
                                                                    .picture_as_pdf,
                                                                color:
                                                                    Colors.red,
                                                                size: 50),
                                                          ),
                                                        ),
                                                      )
                                                    : Image.file(
                                                        File(
                                                            '${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}'),
                                                        key: ValueKey(
                                                          '${widget.provider.picsList!.where((e) => e.qid == widget.question!.q_id).first.doc_id}',
                                                        ),
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (BuildContext
                                                                    context,
                                                                Object error,
                                                                StackTrace?
                                                                    stackTrace) {
                                                          return const Icon(
                                                              Icons.error);
                                                        },
                                                      ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : const SizedBox()
                                  : const SizedBox(),
                              Column(
                                children: [
                                  widget.provider.picsList != []
                                      ? widget.provider.picsList!
                                              .where((e) =>
                                                  e.qid ==
                                                  widget.question!.q_id)
                                              .isEmpty
                                          ? SizedBox(
                                              child: MaterialButton(
                                                onPressed: () {
                                                  isPdf
                                                      ? showPdfPicker(
                                                          context,
                                                          widget.aid!,
                                                          widget.question.q_id!,
                                                          widget.provider,
                                                        )
                                                      : showBottomSheetNew(
                                                          context,
                                                          widget.aid!,
                                                          widget.question.q_id!,
                                                          widget.provider,
                                                        );
                                                },
                                                color: Colors.grey,
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(13),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 14),
                                                  child: Text(
                                                    isPdf
                                                        ? 'Upload Pdf'
                                                        : 'Upload Picture',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox()
                                      : const SizedBox(),
                                  widget.provider.picsList != []
                                      ? widget.provider.picsList!
                                              .where((e) =>
                                                  e.qid ==
                                                  widget.question!.q_id)
                                              .isNotEmpty
                                          ? (widget.provider.isLoadingDelete ==
                                                  true)
                                              ? const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              : SizedBox(
                                                  child: MaterialButton(
                                                    onPressed: () {
                                                      deletePicture(
                                                          context,
                                                          widget.aid!,
                                                          widget.question.q_id!,
                                                          widget.provider);
                                                    },
                                                    color: Colors.red,
                                                    elevation: 8,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              13),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 14),
                                                      child: Text(
                                                        isPdf
                                                            ? 'Delete PDF'
                                                            : 'Delete Picture',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                          : const SizedBox()
                                      : const SizedBox(),
                                ],
                              ),
                            ],
                          )
                    : (widget.question.question_type == "text" &&
                            widget.type == " ")
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: TextField(
                                    textAlign: TextAlign.center,
                                    controller: widget.responseTextController,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      hintText: '',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      contentPadding: const EdgeInsets.all(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(),
          ],
        ),
      ),
    );
  }

  deletePicture(BuildContext context, String aid, String qid,
      AssessmentProvider provider) async {
    //APIResponse res = await provider.deletePicture(context, aid, qid);
    APIResponse res = await DatabaseHelper().deleteImage(qid);

    if (res.status!.toLowerCase() == 'success') {
      getPictureData(context, provider);
    }
  }

  void setData(String? value, Option option, Question question) async {
    //print('qqwq ${question.options!.firstWhere((option1) => option1.id == option.id, orElse: () => Option(id: "", description: "")).description}');
    await DatabaseHelper().updateQuestionInSectionData(
        widget.provider.selectedIndexSubChild != -1
            ? widget
                .provider
                .sectionList![widget.provider.selectedIndex]
                .child![widget.provider.selectedIndexChild]
                .child![widget.provider.selectedIndexSubChild]
                .id!
            : widget.provider.selectedIndexChild != -1
                ? widget.provider.sectionList![widget.provider.selectedIndex]
                    .child![widget.provider.selectedIndexChild].id!
                : widget
                    .provider.sectionList![widget.provider.selectedIndex].id!,
        question.q_id!,
        question.options!
            .firstWhere((option1) => option1.id == option.id,
                orElse: () => Option(id: "", description: ""))
            .description,
        option.id);
    setState(() {
      selectedOption = value;
      widget.question.response_ids = value;
    });
  }
}

enum _UploadStatus { pending, running, done, failed }

class _UploadItem {
  final String id;
  final String label;
  final String indent;
  _UploadStatus status;
  String? errorMsg;

  _UploadItem({
    required this.id,
    required this.label,
    required this.indent,
    this.status = _UploadStatus.pending,
    this.errorMsg,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressController {
  final BuildContext rootContext;
  final _notifier = ValueNotifier<int>(0);

  String _stage = 'Preparing...';
  String _detail = '';
  int _done = 0;
  int _total = 0;
  final List<_UploadItem> _items = [];
  bool _isShowing = false;

  _ProgressController(this.rootContext);

  void register(List<_UploadItem> items) {
    _items.addAll(items);
    _total = items.length;
    _notify();
  }

  void begin(String itemId, {String? stage, String? detail}) {
    if (stage != null) _stage = stage;
    _detail = detail ?? '';
    final item = _find(itemId);
    if (item != null) item.status = _UploadStatus.running;
    _notify();
  }

  void finish(String itemId, {required bool success, String? error}) {
    final item = _find(itemId);
    if (item != null) {
      item.status = success ? _UploadStatus.done : _UploadStatus.failed;
      item.errorMsg = error;
    }
    _done++;
    _notify();
  }

  void setStage(String stage, [String detail = '']) {
    _stage = stage;
    _detail = detail;
    _notify();
  }

  _UploadItem? _find(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  void show() {
    _isShowing = true;
    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(ctrl: this),
    );
  }

  void dismiss() {
    if (_isShowing) {
      _isShowing = false;
      Navigator.of(rootContext, rootNavigator: true).pop();
    }
  }

  void _notify() => _notifier.value++;
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressDialog extends StatelessWidget {
  final _ProgressController ctrl;

  const _ProgressDialog({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        clipBehavior: Clip.antiAlias,
        child: ValueListenableBuilder<int>(
          valueListenable: ctrl._notifier,
          builder: (_, __, ___) {
            final total = ctrl._total;
            final done = ctrl._done;
            final progress = total > 0 ? done / total : null;
            final failed = ctrl._items
                .where((i) => i.status == _UploadStatus.failed)
                .length;
            final pct = progress != null ? '${(progress * 100).round()}%' : '';
            final headerColor =
                failed > 0 ? Colors.orange.shade600 : Colors.blue.shade600;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Colour header band ─────────────────────────────────
                Container(
                  width: double.infinity,
                  color: headerColor,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        done < total || total == 0
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle,
                                color: Colors.white, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ctrl._stage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        if (pct.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(pct,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ]),
                      if (ctrl._detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ctrl._detail,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$done / $total sections',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 10),
                          ),
                          if (failed > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$failed failed',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Section list ───────────────────────────────────────
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.36,
                    minHeight: 60,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: ctrl._items.length,
                    itemBuilder: (_, i) => _ItemRow(item: ctrl._items[i]),
                  ),
                ),

                // ── Bottom warning / spacer ────────────────────────────
                if (failed > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border(
                          top: BorderSide(
                              color: Colors.orange.shade200, width: 0.8)),
                    ),
                    child: Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$failed section(s) had errors — '
                          'assessment will still be submitted.',
                          style: TextStyle(
                              fontSize: 11, color: Colors.orange.shade800),
                        ),
                      ),
                    ]),
                  )
                else
                  const SizedBox(height: 6),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final _UploadItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isPending = item.status == _UploadStatus.pending;
    final isRunning = item.status == _UploadStatus.running;
    final isDone = item.status == _UploadStatus.done;
    final isFailed = item.status == _UploadStatus.failed;

    Widget leading;
    if (isRunning) {
      leading = SizedBox(
        width: 13,
        height: 13,
        child: CircularProgressIndicator(
            strokeWidth: 1.8, color: Colors.blue.shade500),
      );
    } else if (isDone) {
      leading = Icon(Icons.check_circle_rounded,
          size: 13, color: Colors.green.shade500);
    } else if (isFailed) {
      leading =
          Icon(Icons.cancel_rounded, size: 13, color: Colors.red.shade400);
    } else {
      leading = Icon(Icons.radio_button_unchecked,
          size: 13, color: Colors.grey.shade300);
    }

    final leftPad = item.indent.isEmpty
        ? 16.0
        : item.indent.length > 3
            ? 36.0
            : 26.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color:
          isRunning ? Colors.blue.shade50.withOpacity(0.5) : Colors.transparent,
      padding: EdgeInsets.fromLTRB(leftPad, 4, 16, 4),
      child: Row(children: [
        leading,
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isRunning ? FontWeight.w600 : FontWeight.w400,
                  color: isPending
                      ? Colors.grey.shade50 ?? Colors.grey.shade400
                      : isRunning
                          ? Colors.blue.shade700
                          : isFailed
                              ? Colors.red.shade600
                              : Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isFailed && item.errorMsg != null)
                Text(
                  item.errorMsg!,
                  style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Callback typedefs ─────────────────────────────────────────────────────────
typedef OnSectionTap   = void Function(int rootIndex);
typedef OnChildTap     = void Function(int rootIndex, int childIndex);
typedef OnSubChildTap  = void Function(int rootIndex, int childIndex, int subIndex);

// ═════════════════════════════════════════════════════════════════════════════
// SectionNavWidget
// Replaces the three stacked horizontal-scroll circle rows with a single
// 52-px breadcrumb bar + a sliding chip drawer.
// ═════════════════════════════════════════════════════════════════════════════

class SectionNavWidget extends StatefulWidget {
  final AssessmentProvider provider;
  final OnSectionTap    onSectionTap;
  final OnChildTap      onChildTap;
  final OnSubChildTap   onSubChildTap;

  final int Function(AssessmentProvider, int) getCheck;
  final int Function(AssessmentProvider, int) getCheckChild;
  final int Function(AssessmentProvider, int) getCheckSubChild;

  const SectionNavWidget({
    super.key,
    required this.provider,
    required this.onSectionTap,
    required this.onChildTap,
    required this.onSubChildTap,
    required this.getCheck,
    required this.getCheckChild,
    required this.getCheckSubChild,
  });

  @override
  State<SectionNavWidget> createState() => _SectionNavWidgetState();
}

class _SectionNavWidgetState extends State<SectionNavWidget>
    with SingleTickerProviderStateMixin {

  // null = closed, 0 = root list, 1 = child list, 2 = subchild list
  int? _openLevel;

  late final AnimationController _animCtrl;
  late final Animation<double>   _heightAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _heightAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── open / close ──────────────────────────────────────────────────────────

  void _toggleLevel(int level) {
    if (_openLevel == level) {
      _closeDrawer();
    } else {
      setState(() => _openLevel = level);
      _animCtrl.forward(from: 0);
    }
  }

  void _closeDrawer() {
    _animCtrl.reverse().then((_) {
      if (mounted) setState(() => _openLevel = null);
    });
  }

  // ── safe bool reads ───────────────────────────────────────────────────────
  // hasChild / hasSubChild are nullable in AssessmentProvider; treat null as false

  bool get _hasChild    => widget.provider.hasChild    == true;
  bool get _hasSubChild => widget.provider.hasSubChild == true;

  // Does the selected root section contain children in the model?
  bool get _sectionHasChildren {
    final p = widget.provider;
    if (p.sectionList == null || p.selectedIndex == -1) return false;
    final ch = p.sectionList![p.selectedIndex].child;
    return ch != null && ch.isNotEmpty;
  }

  // Does the selected child contain sub-children?
  bool get _childHasSubChildren {
    final p = widget.provider;
    if (!_hasChild || p.selectedIndexChild == -1) return false;
    if (p.sectionList == null || p.selectedIndex == -1) return false;
    final ch = p.sectionList![p.selectedIndex].child;
    if (ch == null || p.selectedIndexChild >= ch.length) return false;
    final subs = ch[p.selectedIndexChild].child;
    return subs != null && subs.isNotEmpty;
  }

  // ── label helpers ─────────────────────────────────────────────────────────

  String _rootLabel() {
    final p = widget.provider;
    if (p.sectionList == null || p.sectionList!.isEmpty || p.selectedIndex == -1) {
      return 'Sections';
    }
    return p.sectionList![p.selectedIndex].list_title ?? 'Section';
  }

  String? _childLabel() {
    final p = widget.provider;
    if (!_hasChild || p.selectedIndexChild == -1) return null;
    if (p.sectionList == null || p.selectedIndex == -1) return null;
    final ch = p.sectionList![p.selectedIndex].child;
    if (ch == null || p.selectedIndexChild >= ch.length) return null;
    return ch[p.selectedIndexChild].list_title ?? 'Sub-section';
  }

  String? _subChildLabel() {
    final p = widget.provider;
    if (!_hasSubChild || p.selectedIndexSubChild == -1) return null;
    if (!_hasChild    || p.selectedIndexChild    == -1) return null;
    if (p.sectionList == null || p.selectedIndex == -1) return null;
    final ch = p.sectionList![p.selectedIndex].child;
    if (ch == null || p.selectedIndexChild >= ch.length) return null;
    final subs = ch[p.selectedIndexChild].child;
    if (subs == null || p.selectedIndexSubChild >= subs.length) return null;
    return subs[p.selectedIndexSubChild].list_title ?? 'Item';
  }

  // ── colour helper ─────────────────────────────────────────────────────────

  Color _statusColor(int status) {
    if (status == 1) return const Color(0xFF43A047);
    if (status == 2) return const Color(0xFFE53935);
    return const Color(0xFF9E9E9E);
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    if (p.sectionList == null || p.sectionList!.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        // ── breadcrumb bar ─────────────────────────────────────────────────
        Container(
          height: 52,
          margin: const EdgeInsets.fromLTRB(10, 6, 10, 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [

              // root crumb — always visible, takes only what it needs
              Flexible(
                child: _Crumb(
                  label: _rootLabel(),
                  isActive: p.selectedIndex != -1,
                  isOpen: _openLevel == 0,
                  dotColor: p.selectedIndex != -1
                      ? _statusColor(widget.getCheck(p, p.selectedIndex))
                      : Colors.grey,
                  onTap: () => _toggleLevel(0),
                  isFirst: true,
                ),
              ),

              // child crumb
              if (_sectionHasChildren) ...[
                const _Sep(),
                Flexible(
                  child: _Crumb(
                    label: _childLabel() ?? 'Select…',
                    isActive: _childLabel() != null,
                    isOpen: _openLevel == 1,
                    dotColor: _childLabel() != null
                        ? _statusColor(
                        widget.getCheckChild(p, p.selectedIndexChild))
                        : Colors.grey.shade400,
                    onTap: () => _toggleLevel(1),
                  ),
                ),
              ],

              // subchild crumb
              if (_childHasSubChildren) ...[
                const _Sep(),
                Flexible(
                  child: _Crumb(
                    label: _subChildLabel() ?? 'Select…',
                    isActive: _subChildLabel() != null,
                    isOpen: _openLevel == 2,
                    dotColor: _subChildLabel() != null
                        ? _statusColor(
                        widget.getCheckSubChild(p, p.selectedIndexSubChild))
                        : Colors.grey.shade400,
                    onTap: () => _toggleLevel(2),
                  ),
                ),
              ],

              // answered / total badge — fixed width, never shrinks
              _AnsweredBadge(provider: p),
              const SizedBox(width: 10),
            ],
          ),
        ),

        // ── animated chip drawer ───────────────────────────────────────────
        SizeTransition(
          sizeFactor: _heightAnim,
          axisAlignment: -1,
          child: _openLevel == null
              ? const SizedBox()
              : _ChipDrawer(
            level:            _openLevel!,
            provider:         p,
            hasChild:         _hasChild,
            hasSubChild:      _hasSubChild,
            getCheck:         widget.getCheck,
            getCheckChild:    widget.getCheckChild,
            getCheckSubChild: widget.getCheckSubChild,
            statusColor:      _statusColor,
            onSelect: (lvl, rootIdx, childIdx, subIdx) {
              _closeDrawer();
              if (lvl == 0) {
                widget.onSectionTap(rootIdx);
              } else if (lvl == 1 && childIdx != null) {
                widget.onChildTap(rootIdx, childIdx);
              } else if (lvl == 2 && childIdx != null && subIdx != null) {
                widget.onSubChildTap(rootIdx, childIdx, subIdx);
              }
            },
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _Crumb
// ═════════════════════════════════════════════════════════════════════════════

class _Crumb extends StatelessWidget {
  final String       label;
  final bool         isActive;
  final bool         isOpen;
  final Color        dotColor;
  final VoidCallback onTap;
  final bool         isFirst;

  const _Crumb({
    required this.label,
    required this.isActive,
    required this.isOpen,
    required this.dotColor,
    required this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: isFirst ? 10 : 2, right: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 4),
              decoration:
              BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4),
                ),
              ),
            ),
            AnimatedRotation(
              turns: isOpen ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) => Icon(
    Icons.chevron_right,
    size: 15,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _AnsweredBadge
// ═════════════════════════════════════════════════════════════════════════════

class _AnsweredBadge extends StatelessWidget {
  final AssessmentProvider provider;
  const _AnsweredBadge({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider;
    if (p.selectedIndex == -1 || p.sectionList == null) return const SizedBox();

    List<Question>? qs;

    // deepest active level wins
    final hasChild    = p.hasChild    == true;
    final hasSubChild = p.hasSubChild == true;

    if (hasSubChild &&
        p.selectedIndexSubChild != -1 &&
        hasChild &&
        p.selectedIndexChild != -1) {
      final ch = p.sectionList![p.selectedIndex].child;
      if (ch != null && p.selectedIndexChild < ch.length) {
        final subs = ch[p.selectedIndexChild].child;
        if (subs != null && p.selectedIndexSubChild < subs.length) {
          qs = subs[p.selectedIndexSubChild].questions;
        }
      }
    } else if (hasChild && p.selectedIndexChild != -1) {
      final ch = p.sectionList![p.selectedIndex].child;
      if (ch != null && p.selectedIndexChild < ch.length) {
        qs = ch[p.selectedIndexChild].questions;
      }
    } else {
      qs = p.sectionList![p.selectedIndex].questions;
    }

    if (qs == null || qs.isEmpty) return const SizedBox();

    final answered =
        qs.where((q) => (q.response ?? '').trim().isNotEmpty).length;
    final total = qs.length;
    final done  = answered == total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFF43A047).withOpacity(0.1)
            : Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done
              ? const Color(0xFF43A047).withOpacity(0.4)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Text(
        '$answered / $total',
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: done ? const Color(0xFF2E7D32) : Colors.blue.shade700,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _ChipDrawer
// ═════════════════════════════════════════════════════════════════════════════

class _ChipDrawer extends StatelessWidget {
  final int            level;
  final AssessmentProvider provider;
  final bool           hasChild;
  final bool           hasSubChild;
  final int  Function(AssessmentProvider, int) getCheck;
  final int  Function(AssessmentProvider, int) getCheckChild;
  final int  Function(AssessmentProvider, int) getCheckSubChild;
  final Color Function(int) statusColor;
  final void Function(int lvl, int rootIdx, int? childIdx, int? subIdx) onSelect;

  const _ChipDrawer({
    required this.level,
    required this.provider,
    required this.hasChild,
    required this.hasSubChild,
    required this.getCheck,
    required this.getCheckChild,
    required this.getCheckSubChild,
    required this.statusColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p     = provider;
    final items = <_ChipItem>[];

    // ── root sections ─────────────────────────────────────────────────────
    if (level == 0 && p.sectionList != null) {
      for (int i = 0; i < p.sectionList!.length; i++) {
        items.add(_ChipItem(
          label:      p.sectionList![i].list_title ?? 'Section',
          statusCode: getCheck(p, i),
          isSelected: p.selectedIndex == i,
          onTap: ()   => onSelect(0, i, null, null),
        ));
      }
    }

    // ── children of selected root ─────────────────────────────────────────
    else if (level == 1 && p.sectionList != null && p.selectedIndex != -1) {
      final children = p.sectionList![p.selectedIndex].child;
      if (children != null) {
        for (int i = 0; i < children.length; i++) {
          items.add(_ChipItem(
            label:      children[i].list_title ?? 'Sub-section',
            statusCode: getCheckChild(p, i),
            isSelected: hasChild && p.selectedIndexChild == i,
            onTap: ()   => onSelect(1, p.selectedIndex, i, null),
          ));
        }
      }
    }

    // ── sub-children of selected child ────────────────────────────────────
    else if (level == 2 &&
        p.sectionList != null &&
        p.selectedIndex != -1 &&
        hasChild &&
        p.selectedIndexChild != -1) {
      final children = p.sectionList![p.selectedIndex].child;
      if (children != null && p.selectedIndexChild < children.length) {
        final subs = children[p.selectedIndexChild].child;
        if (subs != null) {
          for (int i = 0; i < subs.length; i++) {
            items.add(_ChipItem(
              label:      subs[i].list_title ?? 'Item',
              statusCode: getCheckSubChild(p, i),
              isSelected: hasSubChild && p.selectedIndexSubChild == i,
              onTap: ()   => onSelect(2, p.selectedIndex, p.selectedIndexChild, i),
            ));
          }
        }
      }
    }

    if (items.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final bg = item.isSelected
                ? Colors.blue
                : statusColor(item.statusCode);
            return GestureDetector(
              onTap: item.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: item.isSelected
                      ? [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _icon(item.statusCode, item.isSelected),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _icon(int status, bool isSelected) {
    if (isSelected) {
      return const Icon(Icons.radio_button_checked,
          size: 13, color: Colors.white);
    }
    if (status == 1) {
      return const Icon(Icons.check_circle_rounded,
          size: 13, color: Colors.white);
    }
    if (status == 2) {
      return const Icon(Icons.error_rounded, size: 13, color: Colors.white);
    }
    return Icon(Icons.circle_outlined,
        size: 13, color: Colors.white.withOpacity(0.7));
  }
}

// ── data model ────────────────────────────────────────────────────────────────

class _ChipItem {
  final String       label;
  final int          statusCode;
  final bool         isSelected;
  final VoidCallback onTap;
  const _ChipItem({
    required this.label,
    required this.statusCode,
    required this.isSelected,
    required this.onTap,
  });
}

/*
════════════════════════════════════════════════════════════════════════════════
INTEGRATION — replace three rows in AssessmentScreenOfflineWC.build()
════════════════════════════════════════════════════════════════════════════════

REMOVE:
  header(provider),
  provider.hasChild == true ? child(provider) : const SizedBox(),
  provider.hasSubChild == true ? subChild(provider) : const SizedBox(),

ADD:
  SectionNavWidget(
    provider:         provider,
    getCheck:         getCheck,
    getCheckChild:    getCheckChild,
    getCheckSubChild: getCheckSubChild,

    onSectionTap: (rootIdx) {
      provider.setChildRemovedOnBack();
      final section = provider.sectionList![rootIdx];
      if (section.type_id == "1") { clearTextFields(); getStaffData(provider, rootIdx); }
      if (section.type_id == "2") { clearTextFields(); getBedData(provider, rootIdx); }
      if (section.type_id == "3") { clearTextFields(); getPDFData(provider); }
      if ((section.questions ?? []).isNotEmpty) {
        if (section.type_id == " " && section.questions![0].question_type == 'text') {
          clearTextFields(); getTextData(provider, rootIdx);
        }
        if (section.type_id == " " && section.questions![0].question_type == 'files') {
          clearTextFields(); getPictureData(provider, rootIdx);
        }
      }
      if ((section.child ?? []).isNotEmpty) {
        provider.setHasChild(true, rootIdx);
      } else {
        provider.setHasChild(false, rootIdx);
      }
    },

    onChildTap: (rootIdx, childIdx) {
      final ch = provider.sectionList![rootIdx].child ?? [];
      if (childIdx < ch.length) {
        if ((ch[childIdx].child ?? []).isNotEmpty) {
          provider.setHasSubChild(true, childIdx);
        } else {
          provider.setHasSubChild(false, childIdx);
        }
      }
    },

    onSubChildTap: (rootIdx, childIdx, subIdx) {
      provider.setSubChildIndex(subIdx);
    },
  ),
════════════════════════════════════════════════════════════════════════════════
*/