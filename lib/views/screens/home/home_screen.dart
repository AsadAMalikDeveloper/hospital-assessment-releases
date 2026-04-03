import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../Utils/CheckInternetConnection.dart';
import '../../../Utils/Colors.dart';
import '../../../Utils/Shared_Prefrences.dart';
import '../../../Utils/ToastMessages.dart';
import '../../../Utils/globle_controller.dart';
import '../../../db_services/db_helper.dart';
import '../../../models/api_response_model.dart';
import '../../../models/assessment_hospital_model.dart';
import '../../../providers/assessment_provider.dart';
import '../../../providers/login_provider.dart';
import '../../../services/api_services.dart';
import '../assessment/offline_with_sub_child_new.dart';
import '../dashboard/navbar/nav_bar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    // TODO: implement initState
    WidgetsFlutterBinding.ensureInitialized(); // ✅ Required for secure storage
    _checkVersion();
    super.initState();
  }

  Future<void> _checkVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final versionData = await ApiService().checkAppVersion();

    print('DB ${versionData?.latestVersion.toString()}  CV ${currentVersion}');
    if (versionData != null) {
      bool needUpdate =
          isUpdateRequired(currentVersion, versionData.latestVersion);

      if (needUpdate && versionData.forceUpdate) {
        showForceUpdateDialog(context, versionData.apkUrl);
        return;
      }
    }

    dataSaved();
  }

  String name = '', userID = '';
  final CheckConnectivity _connectivityService = CheckConnectivity();
  APIResponse chartData = APIResponse();

  List<HospitalAssessmentModel>? list = [];

  dataSaved() async {
    final data = Provider.of<LoginProvider>(context, listen: false);
    final assessmentProvider =
        Provider.of<AssessmentProvider>(context, listen: false);
    await data.getUnSyncData();
    list = await data.assessmentsFuture;
    if (await _connectivityService.checkConnection() == true) {
      chartData = await data.getChartData(context);
      await Glob().checkToken(context);
      name = await SharedPreferencesHelper.getName();
      userID = await SharedPreferencesHelper.getUsername();
      print("name ${name} user ${userID}");
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
                                    dataSaved();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          list!.isNotEmpty
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: buildDialogButton(
                                        buttonText:
                                            'CONTINUE OFFLINE ASSESSMENT',
                                        textColor: Colors.black,
                                        onPressed: () {
                                          Navigator.pop(context);
                                          goToAssessmentOffline(
                                              assessmentProvider, list![0]);
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox()
                        ],
                      ),
                    ),
                  )),
            );
          });
    }
  }

  Toast toast = Toast();

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<LoginProvider>(context);
    final assessmentProvider = Provider.of<AssessmentProvider>(context);
    return data.isLoading == true
        ? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            drawer: NavBarScreen(name, userID),
            appBar: AppBar(
              title: Text(
                'Hospital Empanelment',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              centerTitle: true,
            ),
            body: FutureBuilder<List<HospitalAssessmentModel>>(
              future: data.assessmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final assessments = snapshot.data ?? [];
                return RefreshIndicator(
                  onRefresh: () => dataSaved(),
                  child: ListView(
                    children: [
                      if (assessments.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Your Un-Synchronized Assessment',
                            style: GoogleFonts.aBeeZee(color: Colors.blue),
                          ),
                        ),
                      // if (assessments.isEmpty)
                      //   Center(
                      //       child:
                      //           Text('No unsynchronized assessments found.')),
                      if (assessments.isNotEmpty)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                      onPressed: () {
                                        showBottomSheetNew(
                                            context, assessmentProvider);
                                      },
                                      icon: Icon(
                                        Icons.info,
                                        color: Colors.blue,
                                        size: 30,
                                      ))
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              // Important to make the ListView take only the needed space
                              physics: const NeverScrollableScrollPhysics(),
                              // Disable inner ListView scrolling
                              itemCount: 1,
                              itemBuilder: (context, index) {
                                final assessment = assessments[index];
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: buildTripCard(
                                      context, assessment, assessmentProvider),
                                );
                                // // final allSynced = assessment.unsyncedSections
                                // //     .every((section) => section.isSynced);
                                //
                                // return ExpansionTile(
                                //   title:
                                //       Text('Assessment ${assessment.assessment_id}'),
                                //   children: [
                                //     // ...assessment.unsyncedSections.map((section) {
                                //     //   return ListTile(
                                //     //     title: Text('Section ${section.sectionId}'),
                                //     //     trailing: section.isSynced
                                //     //         ? const Icon(Icons.check, color: Colors.green)
                                //     //         : ElevatedButton(
                                //     //             onPressed: () {
                                //     //               // _syncSection(
                                //     //               //     assessment.assessmentId,
                                //     //               //     assessment.criteriaId,
                                //     //               //     section.sectionId,
                                //     //               //     section,
                                //     //               //     assessmentProvider,
                                //     //               //     data);
                                //     //             },
                                //     //             child: const Text('Sync'),
                                //     //           ),
                                //     //   );
                                //     // }).toList(),
                                //     // if (allSynced)
                                //     //   Padding(
                                //     //     padding: const EdgeInsets.all(8.0),
                                //     //     child: ElevatedButton(
                                //     //       onPressed: () {
                                //     //         // Implement the complete assessment logic
                                //     //       },
                                //     //       child: const Text('Complete Assessment'),
                                //     //     ),
                                //     //   ),
                                //   ],
                                // );
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      // Add some space between the list and the charts
                      Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Dashboard',
                                  style: GoogleFonts.aBeeZee(
                                      color: Colors.blue, fontSize: 20),
                                ),
                              )
                            ],
                          ),
                          data.isLoading == true
                              ? const SizedBox()
                              : chartData != APIResponse()
                                  ? _buildCharts(chartData)
                                  : const SizedBox(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Assessments Chart',
                                  style: GoogleFonts.aBeeZee(
                                      color: Colors.blue, fontSize: 20),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
  }

  goToAssessmentOffline(AssessmentProvider assessmentProvider,
      HospitalAssessmentModel hospitalAssessmentModel) async {
    final result = await Get.to(() => AssessmentScreenOfflineWC(
        hospitalAssessmentModel: hospitalAssessmentModel));
    if (result != null) {
      if (result[0]["backValue"] == "completed") {
        //getData();
        await clearYourTable();
      }
    }
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  showBottomSheetNew(BuildContext context, AssessmentProvider provider) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text('Delete Offline DB'),
                onTap: () async {
                  Navigator.pop(context);
                  clearYourTable();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.download,
                  color: Colors.blue,
                ),
                title: const Text('Download/Share Offline DB'),
                onTap: () async {
                  Navigator.pop(context);
                  _showPasswordDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPasswordDialog() async {
    TextEditingController passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true, // Hides the password input
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                downloadDbWithPass(context, passwordController.text);
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> clearYourTable() async {
    await _dbHelper.clearAssessmentTable();
    dataSaved();
  }

  Future<void> downloadDb() async {
    //await _dbHelper.downloadAndShareDatabase();
    await _dbHelper.exportDatabase();
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

  Widget buildTripCard(
      BuildContext context,
      HospitalAssessmentModel hospitalAssessmentModel,
      AssessmentProvider providerAssessment) {
    return InkWell(
      onTap: () {
        goToAssessmentOffline(providerAssessment, hospitalAssessmentModel);
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Card(
          elevation: 8.0,
          child: SizedBox(
            child: Column(
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
                                  text: hospitalAssessmentModel.hospital ?? "",
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
                                  text: hospitalAssessmentModel.criteria ?? "",
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
                                      color: getColor(hospitalAssessmentModel
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
                hospitalAssessmentModel.completion_date!.trim().toString() == ""
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

  Widget _buildCharts(APIResponse chartData1) {
    // Replace with your chart data and configuration
    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 18,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: showingSections(chartData1),
                ),
              ),
            ),
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Indicator(
                color: Colors.blue,
                text: 'TOTAL',
                isSquare: true,
              ),
              SizedBox(
                height: 4,
              ),
              Indicator(
                color: Colors.green,
                text: 'COMPLETED',
                isSquare: true,
              ),
              SizedBox(
                height: 4,
              ),
              Indicator(
                color: Colors.yellow,
                text: 'PENDING',
                isSquare: true,
              ),
              SizedBox(
                height: 18,
              ),
            ],
          ),
          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );
  }

  int touchedIndex = -1;

  List<PieChartSectionData> showingSections(APIResponse chartData2) {
    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.blue,
            value: chartData2.total_assessments != null
                ? double.parse(chartData2.total_assessments.toString())
                : 0.0,
            title: chartData2.total_assessments != null
                ? 'Total ${chartData2.total_assessments}'
                : "Total 0",
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.green,
            value: chartData2.completed_assessments != null
                ? double.parse(chartData2.completed_assessments.toString())
                : 0.0,
            title: chartData2.completed_assessments != null
                ? "${((chartData2.completed_assessments! / chartData2.total_assessments!) * 100).toStringAsFixed(2)} %"
                : "0 %",
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Colors.yellow,
            value: chartData2.pending_assessments != null
                ? double.parse(chartData2.pending_assessments.toString())
                : 0.0,
            title: chartData2.pending_assessments != null
                ? "${((chartData2.pending_assessments! / chartData2.total_assessments!) * 100).toStringAsFixed(2)} %"
                : "0 %",
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: shadows,
            ),
          );
        default:
          throw Error();
      }
    });
  }

  void downloadDbWithPass(BuildContext context, String text) {
    if (text.toLowerCase().trim().isEmpty) {
      toast.showErrorToast('Please enter password');
    } else {
      if (text.toLowerCase().trim() == 'statelife.com.pk') {
        Navigator.of(context).pop();
        downloadDb();
      } else {
        toast.showErrorToast('Wrong Password');
      }
    }
  }
}

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  });

  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}
