import 'package:flutter/material.dart';
import 'package:rndpo/screens/menu_screen.dart';

import '../API/api_service.dart';
import '../widgets/app_bar.dart';

class SalesSummery extends StatefulWidget {
  const SalesSummery({super.key});

  @override
  State<SalesSummery> createState() => _SalesSummeryState();
}

class _SalesSummeryState extends State<SalesSummery> {
  DateTime? fromDate;
  DateTime? toDate;
  late final ApiService _apiService;

  Map<int, Map<String, dynamic>>? summary = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now();
    toDate = DateTime.now();
    _apiService = ApiService();
    _loadSalesSummary();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
        print('Selected fromDate: $fromDate, toDate: $toDate');
        _loadSalesSummary(); // Load data after the date is selected
      });
    }
  }

  // Format date as DD-MM-YYYY
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const String separator = '/';
    return '${date.month.toString().padLeft(2, '0')}$separator${date.day.toString().padLeft(2, '0')}$separator${date.year}';
  }

  void _loadSalesSummary() async {
    try {
      var data = await _apiService.salesSummary(fromDate, toDate);

      setState(() {
        summary = {}; // Initialize the map
        // Assuming data is a Map<int, Map<String, dynamic>>
        data.forEach((key, value) {
          summary?[key] = {
            'tenderType': value['tenderType'],
            'amountReceived': value['amountReceived'],
          };
        });
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      throw Exception('Error loading transaction count data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const CustomAppBar(
        title: 'Reports',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Summery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00255D),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: const Color(0xFF0070D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            fromDate != null
                                ? _formatDate(fromDate)
                                : 'From date',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: const Color(0xFF0070D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            toDate != null ? _formatDate(toDate) : 'To date',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Amount',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      // Horizontal padding
                      child: Divider(
                        thickness: 1, // Thickness of the divider
                        color: Color(0xFF0070D0), // Color of the divider
                      ),
                    ),
                    if (summary != null) ...[
                      ...?summary?.entries.map((entry) {
                        final data = entry.value;
                        final tenderType = data['tenderType'] ??
                            'Unknown'; // Default to 'Unknown' if not found
                        var amountReceived =
                            data['amountReceived']?.toString() ??
                                '--'; // Default to '--' if not found
                        if (amountReceived == '') {
                          amountReceived = '--';
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tenderType),
                              Text(amountReceived),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
