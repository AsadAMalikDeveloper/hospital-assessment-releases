import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hospital_assessment_slic/Utils/Shared_Prefrences.dart';

import 'package:lottie/lottie.dart';
import '../../../widgets/Text.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized(); // ✅ Required for secure storage

    _initApp();
  }

  Future<void> _initApp() async {
    // Optional: simulate loading / version check
    await Future.delayed(const Duration(seconds: 2));

    // Retrieve login status safely
    bool isLogin = false;
    try {
      isLogin = await SharedPreferencesHelper.getIsLogin();
    } catch (e) {
      debugPrint("Error reading login status: $e");
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    // Navigate based on login
    if (isLogin) {
      Get.off(() => HomeScreen());
    } else {
      Get.off(() => LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: text(
                  labelText: 'Hospital Assessment',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  textColor: Colors.blue,
                  fontStyle: 'Poppins',
                ),
              ),
              Center(
                child: SizedBox(
                  height: 200,
                  width: 250,
                  child: Lottie.asset('assets/lottie/assessment_lottie.json'),
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  Image.asset(
                    'assets/images/state_life_logo.png',
                    height: 50,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: text(
                      labelText: 'Powered by StateLife',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      textColor: Colors.black54,
                      fontStyle: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ─── Loader overlay ───
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
