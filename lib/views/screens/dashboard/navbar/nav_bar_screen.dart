import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../Utils/CheckInternetConnection.dart';
import '../../../../Utils/Shared_Prefrences.dart';
import '../../../../Utils/ToastMessages.dart';
import '../../../../Utils/globle_controller.dart';
import '../../../../db_services/db_helper.dart';
import '../../../../models/districts_model.dart';
import '../../../../models/hospital_model.dart';
import '../../../../models/state_model.dart';
import '../../../../providers/login_provider.dart';
import '../../../../providers/state_district_provider.dart';
import '../../splash/splash_screen.dart'; // Add this package to retrieve version info

class NavBarScreen extends StatefulWidget {
  final String name, userID;

  const NavBarScreen(this.name, this.userID, {super.key});

  @override
  _NavBarScreenState createState() => _NavBarScreenState();
}

class _NavBarScreenState extends State<NavBarScreen> {
  String version = '';

  @override
  void initState() {
    super.initState();
    _getVersion();
  }

  Future<void> _getVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      version = '${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginProvider>(context, listen: false);
    final stateDistrictProvider =
    Provider.of<StateDistrictProvider>(context, listen: false);
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    widget.name,
                    style: GoogleFonts.poppins(
                        color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(
                    widget.userID,
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                  currentAccountPicture: ClipOval(
                    child: Icon(
                      Icons.person,
                      size: 60,
                    ),
                  ),
                  decoration: BoxDecoration(color: Colors.white),
                ),
                ListTile(
                  leading: Icon(Icons.home_outlined),
                  title: Text('Home'),
                  selected: provider.selectedIndex == 0,
                  selectedTileColor: Colors.grey[200],
                  onTap: () => provider.onItemTap(0, context),
                ),
                ListTile(
                  leading: Icon(Icons.local_hospital_outlined),
                  title: Text('Hospitals'),
                  selected: provider.selectedIndex == 1,
                  selectedTileColor: Colors.grey[200],
                  onTap: () => provider.onItemTap(1, context),
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.building_2_fill),
                  title: Text('Corporate Hospitals'),
                  selected: provider.selectedIndex == 2,
                  selectedTileColor: Colors.grey[200],
                  onTap: () => provider.onItemTap(2, context),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout_outlined),
                  title: Text('Logout'),
                  onTap: () {
                    logout(context);
                  },
                ),
              ],
            ),
          ),
          // Add version text at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Version $version',
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await SharedPreferencesHelper.saveName('');
    await SharedPreferencesHelper.saveUsername('');
    await SharedPreferencesHelper.saveZoneCode('');
    await SharedPreferencesHelper.saveToken('');
    await SharedPreferencesHelper.setIsLogin(false);
    Get.offAll(Splash());
  }

  final CheckConnectivity _connectivityService = CheckConnectivity();
  Toast toast = Toast();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  checkData(BuildContext context1, LoginProvider provider,
      StateDistrictProvider stateDistrictProvider, bool value) async {
    if (value == false) {
      if (await _connectivityService.checkConnection() == true) {
        await _dbHelper.clearTables();
        provider.changeIsOfflineStatus(false);
      } else {
        toast.showErrorToast('You need to internet connection to go online');
      }
    } else if (value == true) {
      provider.changeIsOfflineStatus(true);
      showLoaderDialog(context1, 'Downloading data from server');
      _dbHelper.clearTables();
      await stateDistrictProvider.getStateList(context1, false);
      await stateDistrictProvider.getDistrictsList(context1, "", "All", false);
      await stateDistrictProvider.getHospitalList(context1, "", "All", false);
      if (stateDistrictProvider.stateList != []) {
        for (StateModel state in stateDistrictProvider.stateList!) {
          await _dbHelper.insertStates(state.state!, state.state_ID!);
        }
      }
      if (stateDistrictProvider.districtsList != []) {
        for (DistrictModel district in stateDistrictProvider.districtsList!) {
          await _dbHelper.insertDistricts(
              district.district!, district.district_id!, district.state_id!);
        }
      }
      if (stateDistrictProvider.hospitalList != []) {
        for (HospitalModel hospital in stateDistrictProvider.hospitalList!) {
          await _dbHelper.insertHospitals(
              hospital.hospital!, hospital.sp_id!, hospital.dist_id!);
        }
      }
      Navigator.of(context1, rootNavigator: true).pop();
    }
  }
}
