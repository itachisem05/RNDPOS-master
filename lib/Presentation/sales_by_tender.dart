import 'package:flutter/material.dart';
import '../API/api_service.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class SalesByTender extends StatefulWidget {
  const SalesByTender({super.key});

  @override
  State<SalesByTender> createState() => _SalesByTenderState();
}

class _SalesByTenderState extends State<SalesByTender> {
  DateTime? fromDate;
  DateTime? toDate;
  late final ApiService _apiService;

  Map<int, Map<String, dynamic>>? tender = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now();
    toDate = DateTime.now();
    _apiService = ApiService();
    _loadSalesByTender();
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
        _loadSalesByTender(); // Load data after the date is selected
      });
    }
  }

  // Format date as DD-MM-YYYY
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const String separator = '/';
    return '${date.month.toString().padLeft(2, '0')}$separator${date.day.toString().padLeft(2, '0')}$separator${date.year}';
  }

  void _loadSalesByTender() async {
    try {
      var data = await _apiService.salesByTender(fromDate, toDate);

      setState(() {
        tender = {}; // Initialize the map
        // Assuming data is a Map<int, Map<String, dynamic>>
        data.forEach((key, value) {
          tender?[key] = {
            'tenderType': value['tenderType'],
            'amountReceived': value['amountReceived'],
            'transactions': value['transactions'],
            'tenderPercentage': value['tenderPercentage'],
          };
        });
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      throw Exception('Error Sales by tender data: $e');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const CustomAppBar(title: 'Reports'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales By Tender',
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
                            fromDate != null ? _formatDate(fromDate) : 'From date',
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
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tender != null) ...[
                        ...?tender?.entries.map((entry) {
                          final data = entry.value;
                          final tenderType = data['tenderType'] ?? 'Unknown';
                          var amountReceived = data['amountReceived']?.toString() ?? '--';
                          var transactions = data['transactions']?.toString() ?? '--';
                          var tenderPercentage = data['tenderPercentage']?.toString() ?? '--';

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Name:',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF00355E),
                                          ),
                                        ),
                                        Text(
                                          'Amount:',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF00355E),
                                          ),
                                        ),
                                        Text(
                                          'Sales (%):',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF00355E),
                                          ),
                                        ),
                                        Text(
                                          'Transactions:',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF00355E),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 20), // Manually set space between columns
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tenderType,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF00355E),
                                          ),
                                        ),
                                        Text(
                                          amountReceived,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF00355E),
                                          ),
                                        ),
                                        Text(
                                          tenderPercentage,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF00355E),
                                          ),
                                        ),
                                        Text(
                                          transactions,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF00355E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                thickness: 1,
                                color: Color(0xFF0070D0),
                              ),
                            ],
                          );
                        }).toList(),
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
  }
}