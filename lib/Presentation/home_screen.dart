import 'package:flutter/material.dart';
import 'package:rndpo/Presentation/notification_screen.dart';
import 'package:rndpo/screens/menu_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rndpo/API/api_service.dart';
import 'package:rndpo/widgets/app_bar.dart' as custom_app_bar;
import 'package:rndpo/Presentation/notification_screen.dart' as notification_screen;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /* DateTime? fromDate;
  DateTime? toDate;*/
  DateTime? fromDate;
  DateTime? toDate;
  late final ApiService _apiService;


  List<String> departmentKeys = [];


  Map<int, Map<String, dynamic>>? transactionCountData = {};
  Map<String, Map<String, dynamic>>? departmentWiseData = {};

  bool isLoading = false; //here

  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now();
    print("initsate: $fromDate");
    toDate = DateTime.now();
    print("initsate: $toDate");
    _apiService = ApiService();
    _loadTransactionCountData(); // Load data on initialization
    _loadDepartmentWise();
  }
  @override
  void dispose() {
    super.dispose();
  }


  void _loadTransactionCountData() async {
    try {
      var data = await _apiService.getTransactionCount(fromDate, toDate);

      if (mounted) { // Check if the widget is still in the widget tree
        setState(() {
          transactionCountData = {}; // Initialize the map
          // Assuming data is a Map<int, Map<String, dynamic>>
          data.forEach((key, value) {
            transactionCountData?[key] = {
              'count': value['trnasactionCount'],
              'label': value['reasonText'],
            };
          });
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still in the widget tree
        setState(() {
          isLoading = false;
        });
      }
      throw Exception('Error loading transaction count data: $e');
    }
  }

  void _loadDepartmentWise() async {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    try {
      var data = await _apiService.departmentWise(fromDate, toDate);

      if (mounted) { // Check if the widget is still in the widget tree
        setState(() {
          departmentWiseData = {}; // Initialize the map
          departmentKeys.clear(); // Clear existing keys if any
          // Assuming data is a Map<int, Map<String, dynamic>>
          data.forEach((key, value) {
            departmentKeys.add(key.toString());
            departmentWiseData?[key.toString()] = {
              'netSales': value['netSales']?.toString() ?? '0.0',
              'totalTax': value['totalTax']?.toString() ?? '0.0',
              'grossSales': value['grossSales']?.toString() ?? '0.0',
            };
          });
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still in the widget tree
        setState(() {
          isLoading = false;
          departmentWiseData = {
            //empty
          };
          departmentKeys = ['default'];
        });
      }
      // Optionally, log or display the error message
      // print('Error loading Department Wise data: $e');
    }
  }

  // Function to select date
  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime initialDate = DateTime.now();
    DateTime? firstDate;
    DateTime lastDate = DateTime(2101);

    if (isFromDate) {
      firstDate = DateTime(2000);
      initialDate = fromDate ?? DateTime.now();
    } else {
      firstDate = fromDate ?? DateTime(2000);
      initialDate = toDate ?? DateTime.now();
    }

    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate!,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          if (toDate != null && toDate!.isBefore(fromDate!)) {
            toDate = fromDate;
          }
        } else {
          if (picked.isBefore(fromDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                Text('The end date cannot be earlier than the start date.'),
              ),
            );
            return;
          }
          toDate = picked;
        }
        // print('Selected fromDate: $fromDate, toDate: $toDate');
        _loadTransactionCountData();// Load data after the date is selected
        _loadDepartmentWise();
      });
    }
  }

  // Format date as DD-MM-YYYY
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const String separator = '/';
    return '${date.month.toString().padLeft(2, '0')}$separator${date.day.toString().padLeft(2, '0')}$separator${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const custom_app_bar.CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container for date pickers and stats
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // From Date Picker
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            height: 30, // Reduced height for date picker
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                              Border.all(color: const Color(0xFF0070D0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                // Smaller icon
                                const SizedBox(width: 8),
                                Text(
                                  fromDate != null
                                      ? _formatDate(fromDate)
                                      : 'From Date',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // To Date Picker
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            height: 30, // Reduced height for date picker
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                              Border.all(color: const Color(0xFF0070D0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                // Smaller icon
                                const SizedBox(width: 8),
                                Text(
                                  toDate != null
                                      ? _formatDate(toDate)
                                      : 'To Date',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Row for stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox(1, 0), // Delete tab
                      _buildStatBox(5, 1), // Void tab
                      _buildStatBox(6, 2), // No Sale tab
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Department Sales Section
            const Text('Department wise sales',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(color: Color(0xFF00255D)),
            const SizedBox(height: 8),
            // Sales Boxes
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: departmentWiseData!.entries.expand((entry) {
                  return [
                    Container(

                      child: _buildSalesBox(
                          entry.key),
                    ),
                    const SizedBox(height: 8), // Adjust height as needed
                  ];
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for stat boxes
  Widget _buildStatBox(int ID, int tabIndex) {
    const defaultLabels = {
      0: 'Delete Item',
      1: 'Void Invoice',
      2: 'No Sale',
    };

    var data = transactionCountData?[ID];
    var number = data?['count']?.toString() ?? '0';
    var label = data?['label'] ?? defaultLabels[ID] ?? 'No Data';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationScreen(
              selectedTabIndex: tabIndex,
              id: ID, // Pass the ID here
              fromDate: fromDate!, // Pass the fromDate
              toDate: toDate!, // Pass the toDate
            ),
          ),
        );
      },
      child: Container(
        width: 90,
        height: 90,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for sales boxes
  Widget _buildSalesBox(String category) {
    // Provide default values if data is not available
    final data = departmentWiseData?[category];
    final netSales = data?['netSales']?.toString() ?? '0.0';
    final totalTax = data?['totalTax']?.toString() ?? '0.0';
    final grossSales = data?['grossSales']?.toString() ?? '0.0';

    return Container(
      width: double.infinity, // Stretch to fill the width
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), // Added gap between items
          Text('Net sales: \$${netSales}'),
          const SizedBox(height: 8), // Added gap between items
          Text('Total Tax: \$${totalTax}'),
          const SizedBox(height: 8), // Added gap between items
          Text('Gross Sales: \$${grossSales}'),
        ],
      ),
    );
  }
}
