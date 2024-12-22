import 'package:flutter/material.dart';
import 'package:rndpo/routes/app_routes.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../API/api_service.dart';

class SplashScreen extends StatelessWidget {
  final String versionNumber;

  const SplashScreen({Key? key, required this.versionNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // Create an instance of ApiService
    final ApiService apiService = ApiService();

    // Check login status and navigate accordingly
    Future.microtask(() async {
      try {
        final user = await apiService.getUser();
        if (user != null) {
          // Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
          Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
        }
      } catch (e) {
        // Handle any errors that occur during user check
        print('Error fetching user data: ${e.toString()}');
        Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
      }
    });

    // // Navigate to login screen after 10 seconds
    // Future.delayed(const Duration(seconds: 3), () {
    //   Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
    // });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 150, // Maximum width
                  maxHeight: 150, // Maximum height
                ),
                child: SvgPicture.asset(
                  'assets/images/logo.svg', // Ensure this path is correct
                  fit: BoxFit.contain, // Adjust the fit as needed
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xFFE0E0E0), // Light-colored background
                padding: const EdgeInsets.all(16.0), // Padding
                child: Center(
                  child: Text(
                    'Ver $versionNumber',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
