import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:usa/API/api_service.dart';
import 'package:usa/Presentation/printable_create.dart';
import 'package:usa/Presentation/printable_label_edit.dart';

import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class Printable extends StatefulWidget {
  const Printable({super.key});

  @override
  State<Printable> createState() => _PrintableState();
}

class _PrintableState extends State<Printable> {
  late final ApiService _apiService;
  bool isLoading = true;
  List<Map<String, dynamic>> labels =
      []; // Changed type to Map<String, dynamic>
  int? pageNumber = 1;
  int _currentPage = 1; // Current page number
  int _totalPages = 1; // Total number of pages from the API
  bool hasMoreData = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _getAllLabel();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadMoreOrders() {
    if (hasMoreData) {
      _getAllLabel(page: _currentPage + 1); // Fetch the next page of labels
      print('Current Page: $_currentPage, Total Pages: $_totalPages');
    }
  }


  Future<void> _getAllLabel({int page = 1}) async {
    try {
      final response = await _apiService.getAllLabel(page);

      // Extract the labels, currentPage, and totalPages from the response
      final data = response['labels'];

      // Verify that the data is of the expected type
      if (data is Map<int, Map<String, dynamic>>) {
        _currentPage = response['currentPage'];
        _totalPages = response['totalPages'];

        setState(() {
          if (page == 1) {
            labels = data.values.map((label) {
              return {
                "title": label['title'] ?? 'No Title',
                "copies": int.tryParse(label['copies']?.toString() ?? '0') ?? 0,
                "labelTxnID": int.parse(label['labelTxnID']?.toString() ?? '0'),
              };
            }).toList();
          } else {
            labels.addAll(data.values.map((label) {
              return {
                "title": label['title'] ?? 'No Title',
                "copies": int.tryParse(label['copies']?.toString() ?? '0') ?? 0,
                "labelTxnID": int.parse(label['labelTxnID']?.toString() ?? '0'),
              };
            }).toList());
          }

          hasMoreData = _currentPage < _totalPages;
          isLoading = false;
          print('Labels: $labels');
        });
      } else {
        print('Unexpected format for labels: $data');
      }
    } catch (e) {
      print('An error occurred: $e');
      setState(() {
        isLoading = false;
        hasMoreData = false;
      });
    }
  }


  //todo --- delete
  void _delLabelDelete(int labelID) async {
    try {
      await _apiService.delLabelDelete(labelID);
      // Update the state or perform any action required after successful deletion
      _getAllLabel(); // Refresh the list after deletion
    } catch (e) {
      // Handle the exception here
      print('An error occurred: $e');
    }
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?', style: TextStyle(fontFamily: 'Inter')),
        content: const Text('Are you sure you want to delete this label?',
            style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close the dialog
            },
            child: const Text('No', style: TextStyle(fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close the dialog

              try {
                // Determine if labelTxnID is a String or an int
                final labelTxnID = labels[index]["labelTxnID"];
                final labelID = labelTxnID is int
                    ? labelTxnID
                    : int.tryParse(labelTxnID.toString()) ?? -1;

                if (labelID == -1) {
                  print('Invalid label ID');
                  return;
                }

                await _apiService.delLabelDelete(labelID);
                setState(() {
                  labels.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Label deleted successfully',
                        style: TextStyle(fontFamily: 'Inter')),
                    backgroundColor: Colors.green, // Change color as needed
                  ),
                );
                print('Label deleted and list updated');
              } catch (e) {
                print('An error occurred during deletion: $e');
              }
            },
            child: const Text('Yes', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: CustomAppBar(title: 'Printable Label'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text(
                  'List of Printable Labels',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00255D),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrintableCreate(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    '+ Create Label',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF00255D),
                      fontSize: 15.0, // Set the font size to 15 pixels
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              thickness: 1,
              color: Color(0xFF00355E),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: labels.length,
                  itemBuilder: (ctx, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FF),
                        borderRadius: BorderRadius.circular(10.0), // Curved borders
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded( // Use Expanded to allow text to take available space
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Label Title: ',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00355E),
                                        ),
                                      ),
                                      const WidgetSpan(
                                        child: SizedBox(width: 10),
                                      ),
                                      TextSpan(
                                        text: '${labels[index]["title"]}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.normal,
                                          color: Color(0xFF00255D),
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2, // Allow for a maximum of 2 lines
                                  overflow: TextOverflow.ellipsis, // Show ellipsis if text overflows
                                ),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'No. of Copy: ',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00355E),
                                        ),
                                      ),
                                      const WidgetSpan(
                                        child: SizedBox(width: 3),
                                      ),
                                      TextSpan(
                                        text: '${labels[index]["copies"]}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.normal,
                                          color: Color(0xFF00255D),
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2, // Allow for a maximum of 2 lines
                                  overflow: TextOverflow.ellipsis, // Show ellipsis if text overflows
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: SvgPicture.asset('assets/images/edit.svg'),
                                onPressed: () {
                                  final labelTxnID = labels[index]["labelTxnID"];
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => PrintableLabelEdit(labelTxnID: labelTxnID),
                                    ),
                                        (Route<dynamic> route) => true,
                                  );
                                },
                              ),
                              IconButton(
                                icon: SvgPicture.asset('assets/images/delete.svg'),
                                onPressed: () => _showDeleteDialog(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withOpacity(0.8),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasMoreData) _buildLoadMoreButton(), // Always show the Load More button
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _loadMoreOrders,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF00355E),
            side: const BorderSide(color: Color(0xFFA4D5FF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const CircularProgressIndicator() // Show loading indicator
              : const Text('Load More'),
        ),
      ),
    );
  }
}
