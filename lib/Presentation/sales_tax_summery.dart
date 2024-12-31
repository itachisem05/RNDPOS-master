import 'package:flutter/material.dart';
import 'package:usa/API/api_service.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class SalesTaxSummery extends StatefulWidget {
  const SalesTaxSummery({super.key});

  @override
  State<SalesTaxSummery> createState() => _SalesTaxSummeryState();
}

class _SalesTaxSummeryState extends State<SalesTaxSummery> {
  DateTime? fromDate;
  DateTime? toDate;
  late final ApiService _apiService;

  Map<int, Map<String, dynamic>> salesTax = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now();
    toDate = DateTime.now();
    _apiService = ApiService();
    _loadSalesAndTaxSummary();


  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = isFromDate ? DateTime(2000) : (fromDate ?? DateTime(2000));
    DateTime lastDate = DateTime(2101);

    initialDate = isFromDate ? (fromDate ?? DateTime.now()) : (toDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
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
                content: Text('The end date cannot be earlier than the start date.'),
              ),
            );
            return;
          }
          toDate = picked;
        }
        _loadSalesAndTaxSummary(); // Load data after the date is selected
      });
    }
  }

  void _loadSalesAndTaxSummary() async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      var data = await _apiService.salesAndTaxSummary(fromDate, toDate);

      setState(() {
        salesTax = data; // Assuming data is already a Map<int, Map<String, dynamic>>
        isLoading = false;
      });
      print('Sales Tax Data: $salesTax');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
        ),
      );
    }
  }

  @override
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
              'Sales And Tax Summary',
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
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildSummaryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryList() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),
          const Divider(thickness: 1, color: Color(0xFF0070D0)),
          if (salesTax.isNotEmpty)
            ...salesTax.entries.map((entry) {
              final data = entry.value;
              final tenderType = data['tenderType'] ?? 'Unknown';
              var amountReceived = data['amountReceived']?.toString() ?? '--';
              var transactions = data['transactions']?.toString() ?? '--';
              if (transactions.endsWith('%')) {
                // If it's a percentage, you might want to format it or just display as is
                transactions = transactions; // Keep it as is
              } else {
                transactions = '--'; // Fallback for missing data
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(tenderType, textAlign: TextAlign.left)),
                    Expanded(flex: 1, child: Text(transactions, textAlign: TextAlign.center)), // Display transactions here
                    Expanded(flex: 1, child: Text(amountReceived, textAlign: TextAlign.right)),
                  ],
                ),
              );
            }).toList()
          else
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('No data available.'),
            ),
        ],
      ),
    );
  }

  // Format date as DD-MM-YYYY
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const String separator = '/';
    return '${date.month.toString().padLeft(2, '0')}$separator${date.day.toString().padLeft(2, '0')}$separator${date.year}';
  }
}
