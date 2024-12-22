import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rndpo/API/api_service.dart';
import 'package:rndpo/Presentation/purchase_return_create.dart';
import 'package:rndpo/Presentation/purchase_return_edit.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class PurchaseReturn extends StatefulWidget {
  const PurchaseReturn({super.key});

  @override
  State<PurchaseReturn> createState() => _PurchaseReturnState();
}

class _PurchaseReturnState extends State<PurchaseReturn> {
  late final ApiService _apiService;
  bool isLoading = false;
  Map<int, Map<String, dynamic>> _purchaseReturn = {};
  int _currentPage = 1;
  int _totalPages = 1;
  bool hasMoreData = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchPurchaseOrders();
  }

  void _loadMoreOrders() {
    if (hasMoreData && !isLoading) {
      _fetchPurchaseOrders(page: _currentPage + 1);
    }
  }

  void _fetchPurchaseOrders({int page = 1}) async {
    if (page < 1 || page > _totalPages) {
      return; // Out of bounds
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await _apiService.getPurchaseReturnForPage(page);
      // _purchaseReturn = response['purchaseReturn'] as Map<int, Map<String, dynamic>>;

      if (page == 1) {
        _purchaseReturn = response['purchaseReturn'] as Map<int, Map<String, dynamic>>;
      } else {
        _purchaseReturn.addAll(response['purchaseReturn'] as Map<int, Map<String, dynamic>>);
      }

      _currentPage = response['currentPage'] ?? page;
      _totalPages = response['totalPages'] ?? 0;
      hasMoreData = _currentPage < _totalPages;
    } catch (e) {
      print('An error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const CustomAppBar(
        title: 'Purchase Return',
      ),
      body:
      // isLoading
      //     ? const Center(child: CircularProgressIndicator())
      //     :
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text(
                  'List of Purchase Return',
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
                        builder: (context) => const PurchaseReturnCreate(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    '+ Create PR',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF00255D),
                      fontSize: 15.0,
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
            child: ListView.builder(
              itemCount: _purchaseReturn.length,
              itemBuilder: (ctx, index) {
                final purchaseReturn = _purchaseReturn.values.elementAt(index);
                return Card(
                  color: const Color(0xFFF0F8FF),
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  elevation: 0.0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reference No.:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'PO No.: ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Return Date:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  purchaseReturn['referenceNumber'] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF00255D),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  purchaseReturn['purchaseOrderNumber'] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF00255D),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  purchaseReturn['returnDate']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF00255D),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: -3,
                          right: 0,
                          child: IconButton(
                            icon: SvgPicture.asset('assets/images/edit.svg'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PurchaseReturnEdit(
                                    purchaseReturnId: purchaseReturn['purchaseReturnID'],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (hasMoreData)
            Padding(
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
                      ? const CircularProgressIndicator() // Show loading indicator if loading
                      : const Text('Load More'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
