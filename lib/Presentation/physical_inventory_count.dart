import 'package:flutter/material.dart';
import 'package:usa/API/api_service.dart';
import 'package:usa/Presentation/home_screen.dart';
import 'package:usa/Presentation/physical_inventory_count_finish.dart';

import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class PhysicalInventoryCount extends StatefulWidget {
  const PhysicalInventoryCount({super.key});

  @override
  State<PhysicalInventoryCount> createState() => _PhysicalInventoryCountState();
}

class _PhysicalInventoryCountState extends State<PhysicalInventoryCount> {
  late final ApiService _apiService;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _getStartInventoryCount() async {
    try {
      var message = await _apiService.getStartInventoryCount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3), // Duration of the Snackbar
        ),
      );
    } catch (e) {
      // Handle the exception here
      print('An error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching data'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: CustomAppBar(title: 'Physical Inventory count'),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0), // Add padding around the text
            alignment: Alignment.topLeft, // Align text to the top left
            child: const Text(
              'Once you start the inventory count, you can scan and count the inventory. Once done, finish the inventory count.',
              style: TextStyle(
                fontSize: 12.0, // Change this value to adjust the text size
                fontWeight: FontWeight.w600, // Set the font weight to semi-bold
                fontFamily: 'Inter', // Specify the Inter font
                color: Color(0xFF03255D), // Set the color
              ),
              textAlign: TextAlign.start, // Start align the text
            )
            ,
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.only(top: .0, left: 24.0),
              child: SizedBox(
                width: 150.0,
                height: 40.0,
                child: ElevatedButton(
                  onPressed: () async {
                    await _getStartInventoryCount();
                    {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const PhysicalInventoryCountFinish()),
                            (Route<dynamic> route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00255D),
                    // Button background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: EdgeInsets.zero, // Remove padding to fit exactly
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(color: Colors.white), // Text color
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
