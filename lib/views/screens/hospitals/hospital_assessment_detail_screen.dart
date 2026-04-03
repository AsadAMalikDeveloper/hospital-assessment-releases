import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../Utils/CheckInternetConnection.dart';
import '../../../Utils/ToastMessages.dart';
import '../../../Utils/globle_controller.dart';
import '../../../db_services/db_helper.dart';
import '../../../models/api_response_model.dart';
import '../../../models/assessment_hospital_model.dart';
import '../../../models/bed_capacity_model.dart';
import '../../../models/hospital_model.dart';
import '../../../models/section_model.dart';
import '../../../models/staff_model.dart';
import '../../../providers/assessment_provider.dart';
import '../../../providers/hospital_assessment_detail_provider.dart';
import '../assessment/offline_with_sub_child_new.dart';
import '../assessment/score_document.dart';
import '../assessment/special_document_form.dart';

class HospitalAssessmentDetailScreen extends StatefulWidget {
  final HospitalModel hospitalModel;

  const HospitalAssessmentDetailScreen(
      {super.key, required this.hospitalModel});

  @override
  State<HospitalAssessmentDetailScreen> createState() =>
      _HospitalAssessmentDetailScreenState();
}

class _HospitalAssessmentDetailScreenState
    extends State<HospitalAssessmentDetailScreen> {
  @override
  void initState() {
    // TODO: implement initState
    getData();
    super.initState();
  }

  final CheckConnectivity _connectivityService = CheckConnectivity();

  Future getData() async {
    if (await _connectivityService.checkConnection() == true) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        cID = '';
        final provider = Provider.of<HospitalAssessmentDetailProvider>(context,
            listen: false);
        await provider.getHospitalAssessmentDetail(
            context, widget.hospitalModel.sp_id!);

        await Glob().checkToken(context);
      });
    } else {
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return PopScope(
              canPop: false,
              child: Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.signal_cellular_connected_no_internet_0_bar,
                            size: 30,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                                'You need internet connection to start the assessment',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: Colors.black)),
                          ),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                                'Turn on internet and click on check button',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                    color: Colors.black)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: buildDialogButton(
                                  buttonText: 'CHECK',
                                  textColor: Colors.black,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    getData();
                                  },
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )),
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HospitalAssessmentDetailProvider>(context);
    final providerAssessment = Provider.of<AssessmentProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Assessments",
          style: GoogleFonts.poppins(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          fetchCriteria(context, provider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 15,
          ),
          Expanded(
            child: Builder(
              builder: (_) {
                if (provider.isLoading == true) {
                  return showShimmer();
                }
                if (provider.hospitalAssessmentDetailList!.isEmpty) {
                  return noCustomerScreen(
                      context, provider, widget.hospitalModel);
                }
                return RefreshIndicator(
                  onRefresh: getData,
                  child: provider.hospitalAssessmentDetailList!.isNotEmpty
                      ? Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: ListView.separated(
                                  itemBuilder: (_, index) {
                                    return buildTripCard(
                                        context,
                                        provider.hospitalAssessmentDetailList![
                                            index],
                                        providerAssessment);
                                  },
                                  separatorBuilder: (_, __) => const Divider(
                                        height: 2,
                                        color: Colors.grey,
                                      ),
                                  itemCount: provider
                                      .hospitalAssessmentDetailList!.length),
                            ),
                          ],
                        )
                      : noCustomerScreen(
                          context, provider, widget!.hospitalModel),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  goToAssessmentScreen(
      BuildContext context1,
      HospitalAssessmentModel hospitalAssessmentModel,
      AssessmentProvider providerAssessment) async {
    await providerAssessment.getSectionList(
        context,
        hospitalAssessmentModel.criteria_type_id ?? "",
        hospitalAssessmentModel.assessment_id ?? "");
    data(context1, providerAssessment, hospitalAssessmentModel);
  }

  void _showStartAssessmentDialog(
      BuildContext context1,
      HospitalAssessmentModel hospitalAssessmentModel,
      AssessmentProvider providerAssessment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start Assessment'),
          content: Text('Choose how you want to start the assessment.'),
          actions: [
            // TextButton(
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //     // Add your start assessment online logic here
            //     goToAssessment(providerAssessment, hospitalAssessmentModel);
            //   },
            //   child: Text('Start Assessment Online'),
            // ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add your start assessment offline logic here
                goToAssessmentScreen(
                    context1, hospitalAssessmentModel, providerAssessment);
              },
              child: Text('Start Assessment Offline'),
            ),
          ],
        );
      },
    );
  }

  void _showSelectAssessmentDialog(
      BuildContext context1,
      HospitalAssessmentModel hospitalAssessmentModel,
      AssessmentProvider providerAssessment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Download Documents'),
          content: Text('Choose which document you want to download'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add your start assessment online logic here
                callAPIandGoToPdf(
                    context, providerAssessment, hospitalAssessmentModel);
              },
              child: Text('Special Document'),
            ),
            // TextButton(
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //     // Add your start assessment offline logic here
            //     getScoreDocumnet(context1);
            //   },
            //   child: Text('Total Score'),
            // ),
          ],
        );
      },
    );
  }

  void _showSpecialDocumentDialog(
      BuildContext context1,
      HospitalAssessmentModel hospitalAssessmentModel,
      AssessmentProvider providerAssessment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start Assessment'),
          content: Text('Choose how you want to start the assessment.'),
          actions: [
            // TextButton(
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //     // Add your start assessment online logic here
            //     goToAssessment(providerAssessment, hospitalAssessmentModel);
            //   },
            //   child: Text('Start Assessment Online'),
            // ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add your start assessment offline logic here
                goToAssessmentScreen(
                    context1, hospitalAssessmentModel, providerAssessment);
              },
              child: Text('Start Assessment Offline'),
            ),
          ],
        );
      },
    );
  }

  void _showLoaderDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Downloading data..."),
              ],
            ),
          ),
        );
      },
    );
  }

  data(BuildContext context1, AssessmentProvider providerAssessment,
      HospitalAssessmentModel hospitalAssessmentModel) async {
    _showLoaderDialog(context1);

    bool exists =
        await DatabaseHelper().assessmentExists(hospitalAssessmentModel);
    if (exists) {
      toast.showErrorToast(
          'You already have offline assessment in pending, you cant enter more');

      Navigator.of(context1).pop(); // Close the loader dialog
      return;
    } else {
      //await DatabaseHelper().insertAssessmentOffline(hospitalAssessmentModel);
      final sectionList = providerAssessment.sectionList as List<dynamic>;

      for (var sectionJson in sectionList) {
        SectionModel section;

        if (sectionJson is Map<String, dynamic>) {
          // If sectionJson is a Map, convert it to SectionModel
          section = SectionModel.fromJson(sectionJson);
        } else if (sectionJson is SectionModel) {
          // If sectionJson is already a SectionModel
          section = sectionJson;
        } else {
          Navigator.of(context1, rootNavigator: true).pop();
          // If sectionJson is neither, throw an error or handle it as needed
          throw Exception('Invalid section format');
        }

        if (section.type_id == "1") {
          await providerAssessment.getStaffList(
              context,
              hospitalAssessmentModel.assessment_id!,
              hospitalAssessmentModel.criteria_type_id!,
              hospitalAssessmentModel.sp_id!,
              section.id!);
          if (providerAssessment.staffList != []) {
            for (StaffModel model in providerAssessment.staffList!) {
              await DatabaseHelper().insertOrUpdateStaffingList(model);
            }
          }
        }

        if (section.type_id == "2") {
          await providerAssessment.getBedCapacityList(
              context,
              hospitalAssessmentModel.assessment_id!,
              hospitalAssessmentModel.criteria_type_id!,
              hospitalAssessmentModel.sp_id!,
              section.id!);
          if (providerAssessment.bedList != []) {
            for (BedCapacityModel model in providerAssessment.bedList!) {
              await DatabaseHelper().insertOrUpdateBedCapacityList(model);
            }
          }
        }
        await DatabaseHelper().addItemList(hospitalAssessmentModel, section);
      }
      Navigator.of(context1).pop(); // Close the loader dialog

      // After downloading data, you can navigate to another screen or show a success message
      ScaffoldMessenger.of(context1).showSnackBar(
        SnackBar(content: Text('Data downloaded successfully!')),
      );
      final result = await Get.to(() => AssessmentScreenOfflineWC(
          hospitalAssessmentModel: hospitalAssessmentModel));
      if (result != null) {
        if (result[0]["backValue"] == "done") {
          await clearYourTable();
        }
      }
    }
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> clearYourTable() async {
    await _dbHelper.clearAssessmentTable();
    getData();
  }

  Widget buildTripCard(
      BuildContext context1,
      HospitalAssessmentModel hospitalAssessmentModel,
      AssessmentProvider providerAssessment) {
    return InkWell(
      onTap: () {
        ((hospitalAssessmentModel.assessment_status ?? '').toLowerCase() ==
                "completed")
            ? _showSelectAssessmentDialog(context, hospitalAssessmentModel,
                providerAssessment) //getDataPdf() //toast.showSuccessToast('Can\'t edit completed assessment')
            : _showStartAssessmentDialog(
                context, hospitalAssessmentModel, providerAssessment);
        //goToAssessmentScreen(context1, hospitalAssessmentModel, providerAssessment);
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Card(
          elevation: 8.0,
          child: SizedBox(
            child: providerAssessment.isLoadingSpecialDocument == true
                ? Center(
                    child: SizedBox(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 5, right: 5, top: 8.0, bottom: 10.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: 'Hospital: ',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            hospitalAssessmentModel.hospital ??
                                                "",
                                        style: GoogleFonts.poppins(
                                            color: Colors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: 'Criteria: ',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            hospitalAssessmentModel.criteria ??
                                                "",
                                        style: GoogleFonts.poppins(
                                            color: Colors.lightBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 5, right: 5, top: 8.0, bottom: 12.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: 'Status: ',
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 12),
                                    children: [
                                      TextSpan(
                                        text: hospitalAssessmentModel
                                                .assessment_status ??
                                            "",
                                        style: GoogleFonts.poppins(
                                            color: getColor(
                                                hospitalAssessmentModel
                                                        .assessment_status ??
                                                    ''),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                      ),
                      hospitalAssessmentModel.completion_date!
                                  .trim()
                                  .toString() ==
                              ""
                          ? const SizedBox()
                          : Padding(
                              padding: const EdgeInsets.only(
                                  left: 5, right: 5, top: 8.0, bottom: 10.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          text: 'Completion Date: ',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 10,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: hospitalAssessmentModel
                                                      .completion_date ??
                                                  "",
                                              style: const TextStyle(
                                                  color: Colors.teal,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ]),
                            ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget noCustomerScreen(BuildContext context,
      HospitalAssessmentDetailProvider provider, HospitalModel hospitalModel) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: <Widget>[
            Lottie.asset('assets/lottie/assessment_lottie.json'),
            const Center(
              child: Text(
                "No Assessment Found",
                style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'UBUNTU',
                ),
              ),
            ),
            const SizedBox(
              height: 30.0,
            ),
            InkWell(
              onTap: () => {showDialogForAddingAssessment(context, provider)},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.add,
                    color: Colors.green,
                  ),
                  Text(
                    "Add Assessment",
                    style: TextStyle(
                      fontSize: 25.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'UBUNTU',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  showShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white38,
      highlightColor: Colors.grey,
      enabled: true,
      child: ListView.builder(
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48.0,
                height: 48.0,
                color: Colors.white,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 8.0,
                      color: Colors.white,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.0),
                    ),
                    Container(
                      width: double.infinity,
                      height: 8.0,
                      color: Colors.white,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.0),
                    ),
                    Container(
                      width: 40.0,
                      height: 8.0,
                      color: Colors.white,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        itemCount: 10,
      ),
    );
  }

  getColor(String? assessment_status) {
    if (assessment_status!.toLowerCase() == "pending") {
      return Colors.orange;
    } else if (assessment_status!.toLowerCase() == "completed") {
      return Colors.green;
    } else if (assessment_status!.toLowerCase() == "disqualified") {
      return Colors.red;
    }
  }

  fetchCriteria(
      BuildContext context, HospitalAssessmentDetailProvider provider) async {
    await provider.getCriteriaType(context);
    showDialogForAddingAssessment(context, provider);
  }

  String cID = '';

  showDialogForAddingAssessment(
      BuildContext context, HospitalAssessmentDetailProvider provider) {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'New Assessment',
            style: GoogleFonts.poppins(),
          ),
          content: SizedBox(
            height: 200,
            child: Consumer<HospitalAssessmentDetailProvider>(
              builder: (context, data, child) {
                if (data.isLoadingCriteria == true) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.lightBlue,
                    ),
                  );
                } else if (data.criteriaTypeList!.isEmpty) {
                  return const Center(
                    child: Text("No Criteria found"),
                  );
                } else {
                  return Column(
                    children: [
                      DropdownButtonFormField(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Criteria Type ID",
                          hintText: "Select Criteria",
                          hintStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w300,
                            color: Colors.grey,
                            fontSize: 14.0.sp,
                          ),
                          labelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.0.sp,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        items: data.criteriaTypeList!
                            .map((e) => DropdownMenuItem(
                                  value: e.criteria_type_id.toString(),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      e.description!,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.0.sp,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (selectedCategory) {
                          cID = selectedCategory.toString();
                        },
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Close",
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              onPressed: () {
                cID = '';
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "Create",
                style: GoogleFonts.poppins(color: Colors.blue),
              ),
              onPressed: () {
                if (cID == '') {
                  toast.showErrorToast('Please select criteria');
                } else {
                  Navigator.of(context).pop();
                  createAssessment(context, provider, widget.hospitalModel!);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Toast toast = Toast();

  createAssessment(
      BuildContext context,
      HospitalAssessmentDetailProvider provider,
      HospitalModel hospitalModel) async {
    APIResponse res =
        await provider.createAssessment(context, hospitalModel.sp_id!, cID);
    if (res.status!.toLowerCase() == 'success') {
      toast.showSuccessToast(res.message ?? "");
      getData();
    } else {
      toast.showErrorToast(res.message ?? '');
    }
  }

  getDataPdf() async {
    final Uint8List pdfBytes = await createPdf();
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  Future<Uint8List> createPdf() async {
    // Load the existing PDF from assets
    final ByteData firstPagePdfData =
        await rootBundle.load('assets/images/assessment_criteria.pdf');
    final Uint8List firstPageBytes = firstPagePdfData.buffer.asUint8List();

    // Load the existing PDF document
    PdfDocument existingPdf = PdfDocument(inputBytes: firstPageBytes);

    // Create a new PDF document
    PdfDocument newPdf = PdfDocument();

    // Copy the pages from the existing PDF to the new document
    for (int i = 0; i < existingPdf.pages.count; i++) {
      PdfPage oldPage = existingPdf.pages[i];
      PdfPage newPage = newPdf.pages.add(
          // Ensure the new page has the same size as the original
          //PdfPageSize(width: oldPage.size.width, height: oldPage.size.height),
          );
      newPage.graphics.drawPdfTemplate(
        oldPage.createTemplate(),
        Offset(0, 0),
        // Set the size to match the original page
        Size(oldPage.size.width, oldPage.size.height),
      );
    }

    // // Add custom content (table) to the new PDF document
    // PdfPage contentPage = newPdf.pages.add();
    // PdfGrid grid = PdfGrid();
    // grid.columns.add(count: 5);
    // grid.headers.add(1);
    // PdfGridRow header = grid.headers[0];
    // header.cells[0].value = 'Sr.';
    // header.cells[1].value = 'Points';
    // header.cells[2].value = 'Yes';
    // header.cells[3].value = 'No';
    // header.cells[4].value = 'Remarks';
    //
    // // Add rows to the grid (you can add more rows as needed)
    // List<List<String>> data = [
    //   ['1', 'Hospital found Functional', '', '', ''],
    //   ['2', 'Registration with Health Care Commission', '', '', ''],
    //   // Add more rows here as necessary...
    // ];
    // for (var row in data) {
    //   PdfGridRow gridRow = grid.rows.add();
    //   gridRow.cells[0].value = row[0];
    //   gridRow.cells[1].value = row[1];
    //   gridRow.cells[2].value = row[2];
    //   gridRow.cells[3].value = row[3];
    //   gridRow.cells[4].value = row[4];
    // }
    //
    // // Draw the grid onto the new page
    // grid.draw(
    //   page: contentPage,
    //   bounds: const Rect.fromLTWH(0, 0, 500, 200),
    // );

    // Save the new document and return the bytes
    final List<int> bytes = newPdf.saveSync();
    newPdf.dispose();
    return Uint8List.fromList(bytes);
  }

  void getScoreDocumnet(BuildContext context1) {
    final data = [
      {
        "q_id": 181,
        "description": "Accessible through motorable road ?",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 182,
        "description": "The entrance is wheelchair/stretcher accessible?",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 183,
        "description":
            "Ramp or Bed elevator availible (In case of multi floors)?",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 184,
        "description":
            "Functional & 24 hrs operational Bed elevator having generator support available  ?",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 185,
        "description": "Bed elevator operator available ?",
        "max_marks": 0,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 186,
        "description": "Ramp (if ''Yes''  may have following criteria)?",
        "max_marks": 7,
        "achieved": "7",
        "response": "Ramp wide enough for Stretcher and wheel Chair"
      },
      {
        "q_id": 187,
        "description": "Accessibility through Public transport?",
        "max_marks": 5,
        "achieved": "5",
        "response": "within 500 meter"
      },
      {
        "q_id": 192,
        "description": "A landline phone connection is available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 200,
        "description": "Building Ownership",
        "max_marks": 3,
        "achieved": "3",
        "response": "Owner"
      },
      {
        "q_id": 201,
        "description": "Are Sanitation Equipment Available ?",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 205,
        "description": "Is Heating and Cooling System available at Hospital ?",
        "max_marks": 5,
        "achieved": "5",
        "response": "Centralized"
      },
      {
        "q_id": 206,
        "description": "Are Functional Fans/Heaters available at Hospital ?",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 208,
        "description": "Are General Male & Female Wards Available ?",
        "max_marks": 6,
        "achieved": "6",
        "response": "More than 30 Beds"
      },
      {
        "q_id": 210,
        "description": "How many Beds in Gynae Ward ?",
        "max_marks": 6,
        "achieved": "6",
        "response": "More than 10 Beds"
      },
      {
        "q_id": 213,
        "description": "How many Beds in Nephrology Ward?",
        "max_marks": 6,
        "achieved": "6",
        "response": "More than 10 Beds"
      },
      {
        "q_id": 214,
        "description": "How many Beds in Orthopedic Ward?",
        "max_marks": 6,
        "achieved": "6",
        "response": "More than 10 Beds"
      },
      {"q_id": 216, "description": "Hospital Front Picture", "max_marks": 0},
      {"q_id": 217, "description": "Emergency Picture", "max_marks": 0},
      {
        "q_id": 218,
        "description": "Female General Ward Picture",
        "max_marks": 0
      },
      {"q_id": 219, "description": "OT Pictures", "max_marks": 0},
      {"q_id": 221, "description": "NICU Picture", "max_marks": 0},
      {"q_id": 223, "description": "Laboratory Picture", "max_marks": 0},
      {"q_id": 227, "description": "Any Other Pictures", "max_marks": 0},
      {"q_id": 228, "description": "Waiting Area Picture", "max_marks": 0},
      {
        "q_id": 235,
        "description":
            "Is Running water available at points of service, for hand hygiene/washing (wards, OT, and clinics) ?",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 238,
        "description": "Number of Consultants for Maternity Services",
        "max_marks": 5,
        "achieved": "5",
        "response": "2 or More"
      },
      {
        "q_id": 246,
        "description": "E&C set available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 248,
        "description": "Vacuum suction machine available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 251,
        "description": "An ultrasound machine is available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 252,
        "description": "fetal weight machine available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 253,
        "description": "Fetoscope available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 254,
        "description": "Instrument Sterilization available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 266,
        "description": "Inj Magnesium Sulphate",
        "max_marks": 0.5,
        "achieved": "0",
        "response": "No"
      },
      {
        "q_id": 267,
        "description": "Inj. Lignocaine",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 270,
        "description": "Post/Ante Natal Ward with at least 2 beds",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 276,
        "description": "Suction Machine",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 278,
        "description": "Disposable Syringes",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 282,
        "description": "Wheel Chair/Stretcher Available inside Hospital",
        "max_marks": 2,
        "achieved": "0",
        "response": "No"
      },
      {
        "q_id": 288,
        "description":
            "Separate Seatings arranged for male & Female patients and attendants in clinical/ waiting areas",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 291,
        "description": "Patient admission forms is available",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 292,
        "description": "Patient Discharge Form Available",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 294,
        "description": "Death certificate templates available",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 296,
        "description": "Number of Consultants",
        "max_marks": 5,
        "achieved": "5",
        "response": "2 or more"
      },
      {
        "q_id": 299,
        "description": "24/7 medical officer available in ward (per shift)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 306,
        "description":
            "own/contracted out an ambulance Services (MOU must be provided)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 307,
        "description": "The ambulance is equipped with Oxygen supply",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 321,
        "description": "Numbers of Baby Warmers",
        "max_marks": 2,
        "achieved": "2",
        "response": "5 or more"
      },
      {
        "q_id": 322,
        "description": "Thermometer",
        "max_marks": 0,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 323,
        "description": "Suction machine",
        "max_marks": 0,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 324,
        "description": "Portable X-Ray available",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 325,
        "description": "Neonatal Ventilator Support available",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 326,
        "description": "Infusion pump available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 328,
        "description": "NG/OG tube",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 332,
        "description": "Disposible Syringes",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 335,
        "description": "Minimum Space between beds",
        "max_marks": 2,
        "achieved": "2",
        "response": "5 Feet or Above"
      },
      {
        "q_id": 341,
        "description": "At least 1 toilet per 5 patients in each ward",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 343,
        "description": "Wards are well ventilated",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 351,
        "description": "Cranial ultrasound available",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 352,
        "description": "Bp monitor available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 356,
        "description": "A room for breastfeeding is available",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 358,
        "description": "Number of Medical Officers available",
        "max_marks": 4,
        "achieved": "0",
        "response": "0 Medical Officer"
      },
      {
        "q_id": 362,
        "description":
            "Qualified Dialysis technicians are available 24/7 (per shift)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 364,
        "description": "Hemodialysis machines",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 366,
        "description": "Separate Hep. B/C positive machine available",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 370,
        "description": "Dialysis through Dialysis Solution",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 371,
        "description": "Pharma Cath catheter",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 372,
        "description": "A.V fistula available",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 374,
        "description":
            "Screening schedule of new & old patients available (Document needed)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 381,
        "description":
            "A functional cardiac defibrillator is available & plugged-in",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 382,
        "description": "Inj. Epogen (erythropoietin)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 384,
        "description": "Inj. Heparin",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 387,
        "description":
            "Urethrograms/ Retrograde Urethrograms (RUG) are performed at the facility",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 389,
        "description": "Number of Medical Officers available per shift",
        "max_marks": 4,
        "achieved": "0",
        "response": "0 Medical officer"
      },
      {
        "q_id": 391,
        "description":
            "Emergency Management plan/sub plan in place (GCS score, document needed)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 393,
        "description": "Anesthesia facility",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 394,
        "description":
            "An infection prevention and control committee is notified (Documents shoud be provided meetings with minutes",
        "max_marks": 6,
        "achieved": "6",
        "response": "Yes"
      },
      {
        "q_id": 395,
        "description": "At source segrigation of hospital waste",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 398,
        "description":
            "A clear guide for waste segrigation & Storage is visible posted available",
        "max_marks": 2,
        "achieved": "0",
        "response": "No"
      },
      {
        "q_id": 400,
        "description": "Availability of Functional Incinerator ?",
        "max_marks": 5,
        "achieved": "5",
        "response": "InHouse"
      },
      {
        "q_id": 403,
        "description": "infected patient beds tagging(HBS & HCV)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 407,
        "description":
            "Treatment documents like prescriptions,diagnostics records, treatment charts are maintained",
        "max_marks": 2,
        "achieved": "2",
        "response": "Electronic Record"
      },
      {
        "q_id": 414,
        "description": "Organogram of staff available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 425,
        "description":
            "How many NeuroSurgeons perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 427,
        "description":
            "How many Pulmonologists perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 428,
        "description":
            "How many Gastroenterologists perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 429,
        "description": "Qualification of Hospital Administrator",
        "max_marks": 3,
        "achieved": "3",
        "response": "Masters in Administration/Management"
      },
      {
        "q_id": 435,
        "description": "Midwives",
        "max_marks": 1,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 436,
        "description": "Receptionists",
        "max_marks": 1,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 449,
        "description": "BP apparatus",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 450,
        "description": "Statoscope",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 454,
        "description": "endotracheal tubes",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 455,
        "description": "Oxygen masks",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 458,
        "description": "Drip Set",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 461,
        "description": "Gauze",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 462,
        "description": "Alcohol preps",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 466,
        "description": "Tab Narcan (opioid Anti dote)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 473,
        "description": "Inj lasix (Frusemide)(Diuretic)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 476,
        "description":
            "Minor emergency Operation theatre (within A&E) (assess if yes)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 477,
        "description": "Couch/OT table available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 479,
        "description": "Sutures",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 480,
        "description": "Spot light/lamp available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 481,
        "description": "Emergency tray available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 482,
        "description": "Bandages available",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 485,
        "description": "Number of Medical Officers",
        "max_marks": 4,
        "achieved": "0",
        "response": "Less than 2"
      },
      {
        "q_id": 487,
        "description": "Number of Nurses",
        "max_marks": 3,
        "achieved": "0",
        "response": "Less than 2"
      },
      {
        "q_id": 495,
        "description": "disposable Syringes",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 497,
        "description": "All beds are wheeled/moveable",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 499,
        "description":
            "Funtional fans per 2 beds, if not centrally cooled/Heating system for cold areas",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 504,
        "description": "Operation Theatres available?",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 505,
        "description":
            "Qualified Anesthetist (MBBS with post graduation in anesthesia) for O.T",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 507,
        "description": "Reception Area",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 512,
        "description": "Sanitation Staff (Seperatly)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 514,
        "description": "Electric Autoclave",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 521,
        "description": "Separete resterilization passage",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 523,
        "description": "OT is properly sealed from external atmosphere",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 524,
        "description": "O.R equipped with anesthesia machine",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 525,
        "description":
            "Qualified Technician 1 per table available (in case multi tables OT)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 526,
        "description":
            "The operating room (O.R) have a height-adjustable operating table (Per table)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 527,
        "description": "Fumigation",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 528,
        "description":
            "An overhead, cold and shadowless operating light in place installed",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 539,
        "description":
            "Baby Warmer (In case Gynecologic procedures are also performed at general O.T)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 542,
        "description": "Waste bins",
        "max_marks": 2,
        "achieved": ".5",
        "response": "Simple"
      },
      {
        "q_id": 554,
        "description":
            "The operating room (O.R) has got a height-adjustable operating table",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 560,
        "description": "Defibrillator machine is available",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 562,
        "description": "Cardiac monitors",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 564,
        "description": "Availability of HEPA filters",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 566,
        "description": "Is there any I.C.U in the facility?",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 567,
        "description": "ICU is headed by an intensivist",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 568,
        "description": "ICU is headed by an Anesthesia Specialist",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 573,
        "description": "Air conditioning/ heating systems are in place",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 574,
        "description": "The ICU have a well-maintained crash cart",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 577,
        "description": "Sodium bicarbonate",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 578,
        "description": "Calcium chloride",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 579,
        "description": "Sodium chloride",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 582,
        "description": "Epinephrine",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 589,
        "description": "Normal saline",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 590,
        "description": "Nebulizer machine",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 592,
        "description": "Availability of NG Tube",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 593,
        "description": "Availability of Endotracheal tubes",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 600,
        "description": "Oxygen supply available at each bed is",
        "max_marks": 2,
        "achieved": "2",
        "response": "Centralized"
      },
      {
        "q_id": 604,
        "description": "Pulse oximeters are available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 636,
        "description": "Availability of Microbiology services",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 637,
        "description": "Automatic centrifuges",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 640,
        "description": "florescent/UV viewing chambers",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 641,
        "description": "Autoclave Antibiotics",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 642,
        "description": "Anerobic chambers",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 644,
        "description": "Hard air owns",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 645,
        "description": "Incubators",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 651,
        "description": "Inoculation loops",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 700,
        "description": "Hospital Address (GPS coordinates)",
        "max_marks": 0,
        "achieved": "0",
        "response": " gps"
      },
      {
        "q_id": 701,
        "description": "Name of Focal Person",
        "max_marks": 0,
        "achieved": "0",
        "response": " focal"
      },
      {
        "q_id": 702,
        "description": "Designation",
        "max_marks": 0,
        "achieved": "0",
        "response": " designq"
      },
      {
        "q_id": 703,
        "description": "Hospital ownership",
        "max_marks": 0,
        "achieved": "0",
        "response": " hospital"
      },
      {
        "q_id": 705,
        "description": "Official Phone number",
        "max_marks": 0,
        "achieved": "0",
        "response": " official"
      },
      {"q_id": 188, "description": "Male General Ward Picture", "max_marks": 0},
      {
        "q_id": 189,
        "description":
            "The hospital has electricity connection from the national grid",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 193,
        "description":
            "The hospital is equipped with high speed/broadband internet as per hospital requirment at least 15 to 20 mbps",
        "max_marks": 4,
        "achieved": "4",
        "response": "Yes"
      },
      {
        "q_id": 194,
        "description": "Hospital Management Information Systems (HMIS)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 197,
        "description": "ICD Coding is used for Diagnosis",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 199,
        "description": "Is Hospital Purpose Built ?",
        "max_marks": 10,
        "achieved": "10",
        "response": "Yes"
      },
      {
        "q_id": 202,
        "description": "How much is the corridor space ?",
        "max_marks": 7,
        "achieved": "7",
        "response": "8ft and above"
      },
      {
        "q_id": 203,
        "description": "Are floor surfaces even and non-slippery?",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 207,
        "description": "Is Laundry System Available ?",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 212,
        "description": "How many Beds in Medicine Ward?",
        "max_marks": 6,
        "achieved": "6",
        "response": "More than 10 Beds"
      },
      {"q_id": 222, "description": "Pharmacy Picture", "max_marks": 0},
      {"q_id": 224, "description": "Reception/Counter Picture", "max_marks": 0},
      {"q_id": 226, "description": "HFO Counter Picture", "max_marks": 0},
      {
        "q_id": 230,
        "description":
            "The hospital has a water supply from the public water supply channel/water pump for extracting the fresh/groundwater",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 232,
        "description": "Is there Public Supply of Water ?",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 233,
        "description":
            "Is there Drinking Water Facility Available at Hospital ?",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes with Filters"
      },
      {
        "q_id": 234,
        "description":
            "Is there water under ground storage tank present in the Hospital ?",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 236,
        "description": "Are Washrooms available at OPD/General Area ?",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 240,
        "description": "24/7 nurses/LHVs are available (Per Shift)",
        "max_marks": 3,
        "achieved": "0",
        "response": "0 Nurse/LHV"
      },
      {
        "q_id": 241,
        "description":
            "The facility has a functional & independent Labour room (If yes then asses the following)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 242,
        "description": "No of labor room's dedicated staff",
        "max_marks": 3,
        "achieved": "0",
        "response": "Less than 2"
      },
      {
        "q_id": 244,
        "description": "Delivery forceps",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 245,
        "description": "D&C set available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 250,
        "description": "Fetal cardiac monitor available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 255,
        "description": "Attached washroom available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 256,
        "description": "Oxygen Supply",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 257,
        "description": "Spot light/lamp available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 258,
        "description":
            "Labor room Privacy (mark if having Separate gynae block)",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 259,
        "description":
            "Waste Disposal system in place (bucket for soiled pad and swabs)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 260,
        "description": "Container for sharp disposal available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 261,
        "description": "Hand washing Area available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 262,
        "description": "Emergency Drug Tray available",
        "max_marks": 0.5,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 269,
        "description": "Baby Warmer",
        "max_marks": 2,
        "achieved": "0",
        "response": "Less than 2"
      },
      {
        "q_id": 271,
        "description": "Post Natal Counselling Brochure for Family Planning",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 272,
        "description": "Post Natal Counselling Brochure for Imunization",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 273,
        "description": "Post Natal Counselling Brochure for Nutrition",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 274,
        "description": "Functional BP Apparatus",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 275,
        "description": "Thermometer",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 277,
        "description": "Disposable Gloves",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 280,
        "description": "Funtional Wheel chairs & stretchers",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 281,
        "description":
            "Wheel Chair/Stretcher Available at Emergency Entrance (Critical)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 284,
        "description":
            "Signage allows safe passage through the hospital & exit from the hospital in case if emergency, disaster or fire are availiable",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 287,
        "description": "Complaint Box",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 289,
        "description": "All waiting areas are ventilated",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 293,
        "description": "Birth certificate templates availiable",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 298,
        "description": "Number of Medical Officer",
        "max_marks": 4,
        "achieved": "0",
        "response": "0 Medical officer"
      },
      {
        "q_id": 300,
        "description": "Number of Medical Officers",
        "max_marks": 4,
        "achieved": "0",
        "response": "Less than 2"
      },
      {
        "q_id": 303,
        "description": "Ambulance Access to Emergency department",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 304,
        "description": "Number of Nurses Per Shift",
        "max_marks": 3,
        "achieved": "0",
        "response": "0  nurse"
      },
      {
        "q_id": 305,
        "description": "Are Ambulance Services Available ?",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 311,
        "description":
            "The hospital has clear indications for referral to another facility",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 314,
        "description":
            "The hospital uses a standardised form for making referrals",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 315,
        "description":
            "The hospital keeps a register/record of all referrals it makes",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 317,
        "description":
            "The hospitals has a list of hospitals where it makes referrals",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 319,
        "description": "Baby Warmer",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 330,
        "description": "Disposible gloves",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 336,
        "description":
            "Funtional fans per 2 beds, if not centrally cooled/Heating system for cold areas",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 337,
        "description": "Temperature probe",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 342,
        "description": "extracorporeal membrane oxygenator (ECMO) Available",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 346,
        "description": "endotracheal tube available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 347,
        "description": "Urinary catheter available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 348,
        "description": "CPAP available",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 349,
        "description": "Cardio respiratory monitor available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 354,
        "description": "AMBU bag availiable",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 355,
        "description": "Suction Machine with tubing available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 357,
        "description": "24/7 Medical officers available",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 360,
        "description": "Number of Nurses available in the Ward (Per Shift)",
        "max_marks": 3,
        "achieved": "0",
        "response": "0 Nurse Available"
      },
      {
        "q_id": 363,
        "description":
            "Numbers of Qualified Dialysis technicians are available 24/7 (per shift)",
        "max_marks": 3,
        "achieved": "0",
        "response": "0 Technician"
      },
      {
        "q_id": 365,
        "description": "Number of Hemodialysis machines",
        "max_marks": 3,
        "achieved": "0",
        "response": "0-4"
      },
      {
        "q_id": 367,
        "description":
            "Each dialysis machine has an adjacent cardiac monitor attached",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 373,
        "description": "Double lumen catheters available",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 375,
        "description":
            "Mechanical maintenance of dialysis machines are outsourced (Document needed)",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 376,
        "description":
            "Disinfection of dialysis machines policy in place(Documents needed)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 377,
        "description": "A portable ultrasound machine is available at unit",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 378,
        "description": "A fully stocked crash cart is available",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 379,
        "description": "Stocked with emergency medicines",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 380,
        "description": "Equipment for intubation",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 383,
        "description": "Inj Venofer",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 385,
        "description": "Inj. Furosemide",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 386,
        "description": "X-ray machine for KUB is available",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 388,
        "description":
            "24/7 Medical officer available per shift  (Document needed)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 390,
        "description": "A&E unit is present at the ground floor",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 401,
        "description": "Syringe cutters available in clinical areas",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 402,
        "description": "Wastebaskets available for every bed",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 404,
        "description":
            "A designated bank account in the name of the facility exists",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 405,
        "description":
            "A valid NTN/FTN or tax exemption certificate is available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 406,
        "description": "A designated Accountant available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 409,
        "description": "Payment of Staff Salaries (with Record)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Through Bank"
      },
      {
        "q_id": 410,
        "description": "MBBS with postgraduation",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 411,
        "description":
            "The facility works under the supervision of a full-time administrator.",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 412,
        "description": "Written job descriptions are available for all posts",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 413,
        "description": "Written Contracts for all employees are available",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 415,
        "description":
            "How many General Surgeons perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 416,
        "description":
            "How many Medical Specialist perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 417,
        "description":
            "How many Orthopedic Surgeons perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 418,
        "description": "MBBS with Experience in anesthesia department",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 419,
        "description":
            "How many Opthalmologist  perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 420,
        "description": "Qualified Anesthesia technician",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 421,
        "description":
            "How many ENT Specialists perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 422,
        "description": "Oxygen Supply at all beds",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 423,
        "description":
            "How many Urologists perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 424,
        "description":
            "How many Neurologists perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 426,
        "description":
            "How many Nephrologists perform OPD 3 or more days at Hospital ?",
        "max_marks": 8,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 432,
        "description": "Sanitation Staff",
        "max_marks": 3,
        "achieved": "0",
        "response": "No Sanitation Staff"
      },
      {
        "q_id": 434,
        "description": "Helper/Ward Boy",
        "max_marks": 3,
        "achieved": "0",
        "response": "No Helpers/Ward Boys"
      },
      {
        "q_id": 437,
        "description": "Physiotherapist",
        "max_marks": 5,
        "achieved": "0",
        "response": "No Physiotherapist"
      },
      {
        "q_id": 439,
        "description": "Oxygen Supply",
        "max_marks": 1,
        "achieved": "1",
        "response": "Central"
      },
      {
        "q_id": 440,
        "description": "Emergency Couches available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 445,
        "description": "Laryngoscope",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 446,
        "description": "Monitor",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 448,
        "description": "Defibrillator",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 456,
        "description": "Nasal cannula (adult and pediatric)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 463,
        "description": "Dextrose 25% (pediatrics)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 464,
        "description": "Dextrose 50% (adults)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 468,
        "description": "Tab Aspirin",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 486,
        "description": "24/7 nurses are available in ward (total per shift)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 488,
        "description":
            "Hospital has got sperate wards for atleast 3 specialities (Medicine & Allied, Surgery & Allied, Gynaecology, etc)",
        "max_marks": 10,
        "achieved": "10",
        "response": "Yes"
      },
      {
        "q_id": 489,
        "description": "Ward has a nursing counter (If yes asses below items)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 491,
        "description": "Funtional BP appratus",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 492,
        "description": "Thermometer",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 498,
        "description": "All beds are height-adjustable",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 501,
        "description": "At least 1 toilet per 5 patients in each ward",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 502,
        "description": "The wards are well ventilated",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 503,
        "description": "The wards are well illuminated",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 506,
        "description":
            "Qualified Anesthetist (MBBS with post graduation in anesthesia)",
        "max_marks": 10,
        "achieved": "0",
        "response": "No"
      },
      {
        "q_id": 510,
        "description": "Scrubing Area",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 511,
        "description": "Recovery Room/Area",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 513,
        "description": "Sterilization system available & compliance being done",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 517,
        "description":
            "All surgeries performed are entered on a dedicated register/MIS (time of shifting from ward to OT)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 520,
        "description": "Fumigation Machine availiable",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 522,
        "description": "Functional General O.T available",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 529,
        "description": "O.R equipped with AC/ heating systems",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 534,
        "description": "Availability of Suction machine",
        "max_marks": 2,
        "achieved": "1",
        "response": "Simple"
      },
      {
        "q_id": 535,
        "description": "Availability of Cardiac monitors",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 538,
        "description": "Availability of Laparoscope",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 545,
        "description": "Availability of C-arm fluoroscopy machine",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 546,
        "description": "Availability of Cast opener/ Cast saw",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 549,
        "description": "Availability of HCV kit",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 551,
        "description":
            "The OBS/GYN unit is heading by a qualified consultant [FCPS, MCPS, DGO or equivalent]",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 552,
        "description": "O.R equipped with anesthesia machine",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 556,
        "description":
            "An overhead, cold and shadowless operating light is installed",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 557,
        "description": "O.T is equipped with AC/ heating systems",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 558,
        "description": "Oxygen/backup Gases supply is",
        "max_marks": 2,
        "achieved": "2",
        "response": "Central"
      },
      {
        "q_id": 559,
        "description":
            "O.T is equipped with cardiopulmonary resuscitation equipment (crash cart)",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 561,
        "description": "Availability of Suction machine",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 563,
        "description": "Availability of Diathermy machine",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 575,
        "description": "Amiodarone",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 581,
        "description": "Dopamine",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 583,
        "description": "Sterile water",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 588,
        "description": "Tab disprin",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 594,
        "description": "Ambu Bags",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 599,
        "description": "Equipment for Emergency tracheostomy",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 603,
        "description": "An ECG machine is available at ICU",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 607,
        "description": "Portable X-Ray machine",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 610,
        "description":
            "Are the blood bank BTA registration services sourced-out?",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 611,
        "description":
            "The Blood bank is supervised by a qualified doctor [MBBS with post-graduation in pathology or hematology]",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 612,
        "description": "Number of qualified lab technologists working 24/7",
        "max_marks": 0,
        "achieved": "1",
        "response": "2 or More"
      },
      {
        "q_id": 652,
        "description": "Availability of Hematology services at hospital",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 654,
        "description": "DLC counter",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 655,
        "description": "Elisa plate reader",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 657,
        "description": "Lab Refrigerator",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 658,
        "description": "Hematology analyzer",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 659,
        "description": "HB1AC analyzer",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 660,
        "description": "Hot Plate stirrer",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 661,
        "description": "Immulyte 1000",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 662,
        "description": "Incubator",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 663,
        "description": "Microscope",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 664,
        "description": "Neubar chambers",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 665,
        "description": "Selectra junior water bath",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 666,
        "description": "Advanced Hematology Analyzer",
        "max_marks": 4,
        "achieved": "4",
        "response": "Yes"
      },
      {
        "q_id": 667,
        "description": "Micro lab 300",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 668,
        "description": "ELISA machine",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 669,
        "description": "Are Histopathology services available at the hospital?",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 670,
        "description": "Microtome",
        "max_marks": 4,
        "achieved": "4",
        "response": "Yes"
      },
      {
        "q_id": 673,
        "description": "Availability of Radiology services at the hospital",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 674,
        "description":
            "The radiology services are licensed from the Pakistan Nuclear Regulatory Authority",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 676,
        "description":
            "If the facility doesn’t have its radiology services, contractual services are in place",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 678,
        "description": "In case of online reporting consultant",
        "max_marks": 3,
        "achieved": "1",
        "response": "Digital Xray is available"
      },
      {
        "q_id": 679,
        "description":
            "Reporting time based on urgency of the situation are reported within one hour & routine within 24hrs available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 680,
        "description":
            "A qualified radiographer administer the radiology services",
        "max_marks": 2,
        "achieved": "1",
        "response": "Less than 2"
      },
      {
        "q_id": 681,
        "description": "Radiology lab safety policy is available in form of",
        "max_marks": 4,
        "achieved": "4",
        "response": "Lead line walls are installed"
      },
      {
        "q_id": 682,
        "description":
            "A female attendant accompanies female patients during radiological examination",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 683,
        "description": "The facility has an ultrasound machine",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 684,
        "description": "Availability of C.T scan",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 685,
        "description": "Availability of M.R.I",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 686,
        "description": "An in-house 24/7 registered pharmacy is present",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 688,
        "description":
            "The pharmacy is headed by a qualified pharmacist  (Name & pharmacy council Registration No)",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 689,
        "description": "Qualified pharmacy technician present 24/7",
        "max_marks": 0,
        "achieved": ".5",
        "response": "Less than 2"
      },
      {
        "q_id": 690,
        "description":
            "The pharmacy dispenses medication upon the signed prescription of a qualified doctor",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 691,
        "description":
            "Pharmacy is accessable through Central HMIS of hospital",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 694,
        "description": "Medicines are stored in labelled shelves",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 695,
        "description": "Lockable cupboards for controlled drugs",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 697,
        "description": "Life saving drugs were available on random check",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 699,
        "description": "Hospital Name",
        "max_marks": 0,
        "achieved": "0",
        "response": "name "
      },
      {
        "q_id": 704,
        "description": "Year of establishment",
        "max_marks": 0,
        "achieved": "0",
        "response": " year"
      },
      {
        "q_id": 706,
        "description": "Official email",
        "max_marks": 0,
        "achieved": "0",
        "response": " emaol"
      },
      {
        "q_id": 707,
        "description": "HCC registration number",
        "max_marks": 0,
        "achieved": "0",
        "response": " hcc"
      },
      {
        "q_id": 708,
        "description": "FBR NTN/FTN Number",
        "max_marks": 0,
        "achieved": "0",
        "response": " fbr"
      },
      {
        "q_id": 958,
        "description": "Alcohol Swabs (For ICU)",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 190,
        "description":
            "Alternative electricity generator is present atleast 10 KVA",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 191,
        "description": "Solar system/UPS at least 3KVA to run OT,s",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 195,
        "description":
            "Is HMIS Centralized ( primary key of indoor/outdoor patients) ?",
        "max_marks": 10,
        "achieved": "10",
        "response": "Yes"
      },
      {
        "q_id": 196,
        "description":
            "Is Departmental wise (deleted if not full automatozed HMIS through primry Key ?",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 198,
        "description": "CPT coding is used for treatment procedures",
        "max_marks": 8,
        "achieved": "8",
        "response": "Yes"
      },
      {
        "q_id": 204,
        "description": "Are Functional Fire Extinguishers available ?",
        "max_marks": 6,
        "achieved": "6",
        "response": "Available on Each Floor, Block and Department"
      },
      {
        "q_id": 209,
        "description": "How many Beds in Surgery & Allied Ward ?",
        "max_marks": 6,
        "achieved": "6",
        "response": "More than 10 Beds"
      },
      {
        "q_id": 211,
        "description": "How many Beds in Paeds Ward",
        "max_marks": 6,
        "achieved": "6",
        "response": "More than 10 Beds"
      },
      {
        "q_id": 215,
        "description": "How many Beds in Emergency Ward ?",
        "max_marks": 6,
        "achieved": "6",
        "response": "10 or more Beds"
      },
      {"q_id": 220, "description": "ICU Picture", "max_marks": 0},
      {"q_id": 225, "description": "Dialysis Picture", "max_marks": 0},
      {
        "q_id": 229,
        "description":
            "Upload Assessment Proforma, Signed by Assessment Team and PMO.",
        "max_marks": 0
      },
      {
        "q_id": 231,
        "description": "Is there a Water Pump ?",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 237,
        "description":
            "The OB/GYN unit is heading by a consultant [FCPS, MCPS, DGO or equivalent]",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 239,
        "description": "24/7 female medical officer available (Per ward)",
        "max_marks": 6,
        "achieved": "0",
        "response": "0 female medical officer"
      },
      {
        "q_id": 243,
        "description": "A standard delivery bed is available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 247,
        "description": "Surgical set for episiotomy available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 249,
        "description": "Mcintosh sheet available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 263,
        "description": "Availability of Emergency Drug Tray",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 264,
        "description": "Inj Oxytocin",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 265,
        "description": "Inj Diazepam",
        "max_marks": 0.5,
        "achieved": "0",
        "response": "No"
      },
      {
        "q_id": 268,
        "description": "Tab Nefidipine",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 279,
        "description":
            "Hospital reception/Information counter available at/close to the main entrance",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 283,
        "description": "Signopostage",
        "max_marks": 2,
        "achieved": "2",
        "response": "Services wise at the entrance"
      },
      {
        "q_id": 285,
        "description": "Patients grievances redressal committee",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 286,
        "description": "Grievances redressal focal person",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 290,
        "description":
            "Each patient entered on the HMIS, using the unique Number ( i.e patient treatment recorded in database)",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 295,
        "description":
            "The pediatric unit is headed by a consultant pediatrician/Neonatologist [FCPS, MCPS or equivalent]",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 297,
        "description": "24/7 medical officer available (Per Ward)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 301,
        "description": "24/7 qualified nurses are available (Per Shift)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 302,
        "description": "24/7 nurses are available in ward (total per shift)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 308,
        "description": "The ambulance has a disembarkable strecher",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 309,
        "description": "Number of Nurses/LHVs",
        "max_marks": 3,
        "achieved": "0",
        "response": "Less than 2"
      },
      {
        "q_id": 310,
        "description": "Number of incubators",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 312,
        "description":
            "Hospital has got sperate wards for atleast 3 specialities (Medicine & Allied, Surgery & Allied, Gynaecology, etc)",
        "max_marks": 10,
        "achieved": "0",
        "response": "No"
      },
      {
        "q_id": 313,
        "description": "Number of incubators",
        "max_marks": 2,
        "achieved": "0",
        "response": "0 - 1"
      },
      {
        "q_id": 316,
        "description": "Ward has a nursing counter (If yes asses below items)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 318,
        "description": "Nursing counter available with bell",
        "max_marks": 0,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 320,
        "description": "Funtional BP appratus",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 327,
        "description": "intracranial pressure monitor",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 329,
        "description": "Pulse Oximeter",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 333,
        "description": "All beds are wheeled/moveable",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 334,
        "description": "All beds are height-adjustable",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 340,
        "description": "Individual tagging at every bed",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 344,
        "description": "The wards are well illuminated",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 350,
        "description": "laryngoscope with all size blades  available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 353,
        "description": "Portable light available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 359,
        "description": "24/7 nurses are available in the ward (per Shift)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 361,
        "description":
            "The unit functions in at least 24/7 shifts with minimum 4 machines",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 368,
        "description":
            "The facility has comfortable dialysis chairs, kept in a hygienic condition",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 369,
        "description": "Dialysis through B-Bag(disposable)",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 392,
        "description": "List of Emergency contacts info available",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 396,
        "description":
            "Sanitation committee available (Documented should be provided)",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 397,
        "description": "Protected Waste dumping area (Saficant)",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 399,
        "description":
            "Colour-coded waste bins available at each ward/clinical area",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 408,
        "description": "Availability of E-Claims Facility",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 430,
        "description": "How many OTAs at Hospital ?",
        "max_marks": 2,
        "achieved": ".5",
        "response": "Part time or On Call"
      },
      {
        "q_id": 431,
        "description": "How many Anesthesia Technician at Hospital ?",
        "max_marks": 2,
        "achieved": ".5",
        "response": "Part Time or On Call"
      },
      {
        "q_id": 433,
        "description": "Staff for IT & Record Keeping",
        "max_marks": 1,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 438,
        "description": "Security Staff",
        "max_marks": 1,
        "achieved": "0",
        "response": "less than 2"
      },
      {
        "q_id": 441,
        "description": "Minimum Space between beds (if ward available)",
        "max_marks": 2,
        "achieved": "2",
        "response": "5 ft or above"
      },
      {
        "q_id": 442,
        "description": "Crash Cart (asses following items)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 443,
        "description": "Nebulizer machine available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 444,
        "description": "Suction machine",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 447,
        "description": "Suction catheters",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 451,
        "description": "Ambubag",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 452,
        "description": "Gloves",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 453,
        "description": "Airway (oral and nasal)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 457,
        "description": "Normal saline solution",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 459,
        "description": "Cannula (various sizes)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 460,
        "description": "10ml normal saline flush syringes",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 465,
        "description": "Inj Epinephrine (Alpha- and beta-adrenergic agonists)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 467,
        "description": "Tab Nitroglycerin(Sublingual or Spray)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 469,
        "description": "Inj Atropine Sulfate",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 470,
        "description": "Inj Amiodarone (Beta blocker)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 471,
        "description": "Inj Decadron (Steroid)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 472,
        "description": "Inj Solu-Cortef (Seriod)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 474,
        "description": "Salbutamol (bronchodilator)",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 475,
        "description": "ACS protocol & Drugs available (Document needed)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 478,
        "description": "instruments tray (for local anesthesia) Available",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 483,
        "description": "Waste bin available",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 484,
        "description": "Oxygen Supply available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 490,
        "description": "Nursing counter available with bell",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 493,
        "description": "Suction machine",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 494,
        "description": "disposable gloves",
        "max_marks": 1,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 496,
        "description": "Minimum Space between beds",
        "max_marks": 2,
        "achieved": "0",
        "response": "Less than 5 Feet"
      },
      {
        "q_id": 500,
        "description": "Individual patient tagging at every bed",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 508,
        "description": "Changing Room",
        "max_marks": 2,
        "achieved": "1",
        "response": "General"
      },
      {
        "q_id": 509,
        "description": "Retiring Room",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 515,
        "description": "Gas Autoclave",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 516,
        "description": "Boiling Autoclave",
        "max_marks": 0.75,
        "achieved": ".75",
        "response": "Yes"
      },
      {
        "q_id": 518,
        "description": "OT protocols displayed availiable",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 519,
        "description": "Separate Record for HIV cases available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 530,
        "description": "Oxygen/backup Gases supply",
        "max_marks": 2,
        "achieved": "2",
        "response": "Central"
      },
      {
        "q_id": 531,
        "description":
            "O.R equipped with cardiopulmonary resuscitation equipment [crash cart]",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 533,
        "description": "Availability of Defibrillator",
        "max_marks": 1.5,
        "achieved": "1.5",
        "response": "Yes"
      },
      {
        "q_id": 536,
        "description": "Availability of Endoscope",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 537,
        "description": "Availability of Diathermy Machine",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 541,
        "description": "Availability of HEPA filters",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 543,
        "description": "Availability of X-Ray viewer Box",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 544,
        "description":
            "Availability of Arthroscope machine (In case orthopedic surgeries are being performed in general O.T)",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 547,
        "description": "Availability of  HCV/HBS/HIV Separate OT",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 548,
        "description": "Drape set (if separate OT is not available)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 550,
        "description":
            "Hospital has got specialty wise separate Operation Theatres",
        "max_marks": 10,
        "achieved": "10",
        "response": "Yes"
      },
      {
        "q_id": 553,
        "description": "Qualified Technician (1 per table) available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 555,
        "description": "A system for Fumigation of O.T is available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 565,
        "description": "Availability of Waste bins",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 569,
        "description": "The I.C.U has a central monitoring/ nursing counter",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 570,
        "description":
            "At least one doctor is available 24/7, to attend the I.C.U patients under the supervision of a consultant",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 571,
        "description":
            "At least two nurses are available 24/7, to attend the I.C.U patients",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 572,
        "description":
            "Beds are I.C.U specific\r\n( with side rails & height adjustment)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 576,
        "description": "Atropine",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 580,
        "description": "Dextrose",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 584,
        "description": "Lignocaine",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 585,
        "description": "Vasopressin",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 586,
        "description": "Solu-cortef",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 587,
        "description": "Furosemide",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 591,
        "description": "Foley's Catheters",
        "max_marks": 0.25,
        "achieved": ".25",
        "response": "Yes"
      },
      {
        "q_id": 601,
        "description": "Total Number of Beds at ICU",
        "max_marks": 3,
        "achieved": "1",
        "response": "Less than 5"
      },
      {
        "q_id": 602,
        "description": "ventilators per beds",
        "max_marks": 3,
        "achieved": "3",
        "response": "Per 5 Beds"
      },
      {
        "q_id": 605,
        "description": "All beds equipped with cardiac monitors",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 606,
        "description": "Arterial Blood Gas Machine available at ICU",
        "max_marks": 3,
        "achieved": "6",
        "response": "Yes"
      },
      {
        "q_id": 608,
        "description": "Availability of Infusion Pump",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 609,
        "description":
            "Availability of a blood bank in the facility, registered with BTA (provisionally critical)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 613,
        "description":
            "Room with couch with functional scale machine is available for collecting blood",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 614,
        "description": "Cross Matching facility available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 615,
        "description": "Blood screening facility available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 616,
        "description":
            "Functional Blook-bank specific refrigerator is available (3°C to 6°C)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 617,
        "description": "Plasma separator is available",
        "max_marks": 4.5,
        "achieved": "4.5",
        "response": "Yes"
      },
      {
        "q_id": 618,
        "description": "Blood warmer is available",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 619,
        "description": "A microscope is available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 620,
        "description": "BP apparatus is available?",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 621,
        "description": "Computerized inventory of blood products is maintained",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 622,
        "description": "A pathology lab available in the facility",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 623,
        "description": "Pathology services being sourced-out (If not in-house)",
        "max_marks": 0,
        "achieved": "0",
        "response": "Yes"
      },
      {
        "q_id": 624,
        "description":
            "The lab is operated under the supervision of a qualified pathologist",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 625,
        "description": "Availability of qualified laboratory technologist 24/7",
        "max_marks": 2,
        "achieved": "0",
        "response": "0"
      },
      {
        "q_id": 626,
        "description":
            "There are designated areas for storage of specimens, reagents and records",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 627,
        "description": "The expected report time for test results is specified",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 628,
        "description":
            "The lab has established reference ranges for each investigation",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 629,
        "description":
            "The lab has displayed price-list for all investigations",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 630,
        "description":
            "ICT(immunochromatographic) technique for HBS/HCV/HIV is available",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 631,
        "description": "The lab is equipped with a PCR machine",
        "max_marks": 3,
        "achieved": "3",
        "response": "Yes"
      },
      {
        "q_id": 632,
        "description": "A lab safety policy is in place",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 633,
        "description":
            "Collected samples are labelled with patient identification with date & time",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 634,
        "description": "All investigations are recorded in",
        "max_marks": 2,
        "achieved": "2",
        "response": "HMIS"
      },
      {
        "q_id": 635,
        "description":
            "Inhouse or Out Sourced qualified staff for maintenance of Lab Equipment available",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 638,
        "description": "Electric water bath",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 639,
        "description": "Colony Counters",
        "max_marks": 5,
        "achieved": "5",
        "response": "Yes"
      },
      {
        "q_id": 643,
        "description": "Growth medium",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 646,
        "description": "Micrometers",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 647,
        "description": "Preservatives",
        "max_marks": 1.5,
        "achieved": "1.5",
        "response": "Yes"
      },
      {
        "q_id": 648,
        "description": "Measuring glass wear",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 649,
        "description": "Lab refrigerators",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 650,
        "description": "Inoculation chambers",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 653,
        "description": "Coagulation analyzer",
        "max_marks": 2,
        "achieved": "2",
        "response": "Yes"
      },
      {
        "q_id": 656,
        "description": "ESR stand",
        "max_marks": 0.5,
        "achieved": ".5",
        "response": "Yes"
      },
      {
        "q_id": 671,
        "description": "Tissue processor",
        "max_marks": 4,
        "achieved": "4",
        "response": "Yes"
      },
      {
        "q_id": 672,
        "description": "Microscope (Oil Immersion)",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 677,
        "description": "All radiological diagnostics reported by",
        "max_marks": 3,
        "achieved": "3",
        "response": "In-house consultant"
      },
      {
        "q_id": 687,
        "description":
            "Pharmacy services can be either in-house or contracted out.",
        "max_marks": 0,
        "achieved": "0",
        "response": "In-house"
      },
      {
        "q_id": 693,
        "description":
            "The pharmacy is equipped with a refrigerator for heat-sensitive medicines",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 696,
        "description":
            "A computer-based inventory for stock-in and stock-out is maintained",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 698,
        "description":
            "No expired medicines found on random check at the time of visit",
        "max_marks": 1,
        "achieved": "1",
        "response": "Yes"
      },
      {
        "q_id": 880,
        "description": "Administration Ownership",
        "max_marks": 5,
        "achieved": "5",
        "response": "Company/Trust"
      }

      // Add more rows here
    ];

    final pdfGenerator = PdfGenerator(data: data);
    pdfGenerator.generatePdf(context);
  }

  void callAPIandGoToPdf(
    BuildContext context,
    AssessmentProvider assessmentProvider,
    HospitalAssessmentModel hospitalAssessmentModel,
  ) async {
    await assessmentProvider.getSpecialDocument(
        context,
        hospitalAssessmentModel.criteria_type_id!,
        hospitalAssessmentModel.assessment_id!,
        hospitalAssessmentModel.sp_id!);

    //print('object123 ${assessmentProvider.specialDocumentModel!.SECTIONS![0].section_name}');

    if (assessmentProvider.specialDocumentModel!.SECTIONS!.isNotEmpty) {
      getSpecialDocumentPDF(assessmentProvider.specialDocumentModel!);
    }
  }
}
