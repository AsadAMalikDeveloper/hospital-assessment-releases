import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../Utils/CheckInternetConnection.dart';
import '../../../Utils/globle_controller.dart';
import '../../../models/hospital_model.dart';
import '../../../providers/login_provider.dart';
import '../../../providers/state_district_provider.dart';
import 'hospital_assessment_detail_screen.dart';

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  String state_id = '', dist_id = '';
  String searchQuery = '';
  List<HospitalModel> filteredHospitals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  final CheckConnectivity _connectivityService = CheckConnectivity();
  _loadData() async {
    if (!mounted) return;
    if (await _connectivityService.checkConnection() == true) {
      final provider = Provider.of<StateDistrictProvider>(context, listen: false);
      LoginProvider loginProvider =
      Provider.of<LoginProvider>(context, listen: false);
      await provider.getStateList(context, loginProvider.isOffline);
      await Glob().checkToken(context);
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
                                    _loadData();
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
  void dispose() {
    super.dispose();
  }

  goBack(BuildContext context) {
    final provider = Provider.of<LoginProvider>(context, listen: false);
    provider.changeIndex(0);
    Future.microtask(() => Get.back());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateDistrictProvider>(context);
    bool isOffline = Provider.of<LoginProvider>(context).isOffline;
    return SafeArea(
      child: PopScope(
        canPop: true,
        onPopInvoked: (bool canPop) {
          goBack(context);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Hospitals',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
            leading: IconButton(
                onPressed: () {
                  goBack(context);
                },
                icon: const Icon(Icons.arrow_back)),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Consumer<StateDistrictProvider>(
                      builder: (context, data, child) {
                    if (data.isLoading ?? false) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.lightBlue,
                        ),
                      );
                    } else if (data.stateList == []) {
                      return const Center(child: Text("No States Found"));
                    } else {
                      return DropdownButtonFormField(
                        decoration: InputDecoration(
                          labelText: "State",
                          hintText: "Select State",
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
                        items: data.stateList!
                            .map((e) => DropdownMenuItem(
                                  value: e.state_ID.toString(),
                                  child: Text(
                                    e.state!,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.0.sp,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (selectedCategory) {
                          state_id = selectedCategory!.toString();
                          data.setLoaderDistricts(true);
                          data.getDistrictsList(
                              context, state_id, "ID", isOffline);
                        },
                      );
                    }
                  }),
                ),
                provider.isLoadingDistricts == true
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(15),
                        child: Consumer<StateDistrictProvider>(
                            builder: (context, data, child) {
                          if (data.isLoadingDistricts == true) {
                            return const SizedBox();
                          } else if (data.districtsList == []) {
                            return const Center(
                                child:
                                    Text("No District Found against this state"));
                          } else {
                            return DropdownButtonFormField(
                              decoration: InputDecoration(
                                labelText: "District",
                                hintText: (provider.districtsList!.isEmpty &&
                                        state_id == '')
                                    ? 'Select District'
                                    : provider.districtsList!.isEmpty
                                        ? 'No district against this state'
                                        : "Select District",
                                hintStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w300,
                                  color: Colors.grey,
                                  fontSize: 14.0.sp,
                                ),
                                labelStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.0.sp,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                              ),
                              items: data.districtsList!
                                  .map((e) => DropdownMenuItem(
                                        value: e.district_id.toString(),
                                        child: Text(
                                          e.district!,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.0.sp,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (selectedCategory) {
                                dist_id = selectedCategory!.toString();
                                data.getHospitalList(
                                    context, dist_id, "ID", isOffline);
                              },
                            );
                          }
                        }),
                      ),
                provider.isLoadingHospitals == true
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(15),
                        child: provider.hospitalList!.isEmpty
                            ? const SizedBox()
                            : Column(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8.0),
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: "Search Hospitals",
                                        hintText: "Enter hospital name",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onChanged: (query) {
                                        setState(() {
                                          searchQuery = query.toLowerCase();
                                          filteredHospitals = provider
                                              .hospitalList!
                                              .where((hospital) => searchQuery
                                                  .split(' ')
                                                  .every((word) => hospital
                                                      .hospital!
                                                      .toLowerCase()
                                                      .contains(word)))
                                              .toList();
                                        });
                                      },
                                    ),
                                  ),
                                  Consumer<StateDistrictProvider>(
                                      builder: (context, data, child) {
                                    final hospitalsToShow = searchQuery.isEmpty
                                        ? provider.hospitalList!
                                        : filteredHospitals;
                                    if (hospitalsToShow.isEmpty) {
                                      return const Center(
                                          child: Text(
                                              "No hospital Found against this state and district"));
                                    } else {
                                      return Padding(
                                        padding: EdgeInsets.only(top: 20.h),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                "Hospitals",
                                                style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16.sp),
                                              ),
                                            ),
                                            Column(
                                              children: hospitalsToShow
                                                  .map((result) => Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                8.0),
                                                        child: InkWell(
                                                            onTap: () {
                                                              getNGo(context,
                                                                  result);
                                                            },
                                                            child: member(result
                                                                .hospital!)),
                                                      ))
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }),
                                ],
                              ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget member(String name) {
    return Container(
      margin: const EdgeInsets.only(left: 0, right: 0),
      width: 1.sw,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: Colors.blue,
          border: Border.all(width: 1, color: Colors.white)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Container(
            child: Padding(
              padding: const EdgeInsets.all(4.0).w,
              child: Icon(Icons.local_hospital_outlined),
            ),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(20)).r,
                border: Border.all(
                    width: 1, color: const Color.fromARGB(255, 255, 255, 255))),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                name,
                style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  getNGo(BuildContext context, HospitalModel result) {
    Get.to(HospitalAssessmentDetailScreen(hospitalModel: result));
  }
}
