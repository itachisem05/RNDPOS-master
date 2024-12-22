import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rndpo/API/api_service.dart';
import 'package:rndpo/Presentation/purchase_order_create.dart';
import 'package:rndpo/Presentation/purchase_order_edit.dart';
import 'package:rndpo/Presentation/receive_purchase_order.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class PurchaseOrder extends StatefulWidget {
  const PurchaseOrder({super.key});

  @override
  State createState() => _PurchaseOrderState();
}

class _PurchaseOrderState extends State<PurchaseOrder> {
  late final ApiService _apiService;
  bool isLoading = false;
  bool hasMoreData = false;
  Map<int, Map<String, dynamic>> _purchaseOrders = {};
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchPurchaseOrders();
  }

  void _fetchPurchaseOrders({int page = 1}) async {
    if (page < 1 || page > _totalPages) return; // Out of bounds

    setState(() => isLoading = true);

    try {
      final data = await _apiService.getPurchaseOrdersForPage(page);

      setState(() {
        if (page == 1) {
          _purchaseOrders = data['purchaseOrders'];
        } else {
          _purchaseOrders.addAll(data['purchaseOrders']);
        }

        _currentPage = data['currentPage'];
        _totalPages = data['totalPages'];
        hasMoreData = _currentPage < _totalPages;
        isLoading = false;
      });
    } catch (e) {
      print('An error occurred: $e');
      setState(() {
        isLoading = false;
        hasMoreData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load purchase orders')),
      );
    }
  }

  void _loadMoreOrders() {
    if (hasMoreData) {
      _fetchPurchaseOrders(page: _currentPage + 1);
      print('order : $_purchaseOrders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const CustomAppBar(
        title: 'Purchase Order',
      ),
      body: Column(
        children: [
          _buildHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              thickness: 1,
              color: Color(0xFF00355E),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _purchaseOrders.length,
              itemBuilder: (ctx, index) {
                final purchaseOrder = _purchaseOrders.values.elementAt(index);
                return _buildPurchaseOrderCard(purchaseOrder);
              },
            ),
          ),
          if (hasMoreData) _buildLoadMoreButton(), // Always show the Load More button
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text(
            'List of Purchase Order',
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
                  builder: (context) => const PurchaseOrderCreate(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              '+ Create PO',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF00255D),
                fontSize: 15.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseOrderCard(Map<String, dynamic> purchaseOrder) {
    // Check the purchaseOrderStatusID
    bool shouldHideIcons = purchaseOrder['purchaseOrderStatusID'] == 6;

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
                    Text('Order No:', style: _labelStyle),
                    SizedBox(height: 8),
                    Text('Supplier:', style: _labelStyle),
                    SizedBox(height: 8),
                    Text('Order Qty:', style: _labelStyle),
                    SizedBox(height: 8),
                    Text('Total Amount:', style: _labelStyle),
                    SizedBox(height: 8),
                    Text('Status:', style: _labelStyle),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(purchaseOrder['purchaseOrderNumber'] ?? '', style: _textStyle),
                    const SizedBox(height: 8),
                    Text(purchaseOrder['supplierName'] ?? '', style: _textStyle),
                    const SizedBox(height: 8),
                    Text(purchaseOrder['orderQty']?.toString() ?? '', style: _textStyle),
                    const SizedBox(height: 8),
                    Text('\$${purchaseOrder['totalAmount']?.toString() ?? ''}', style: _textStyle),
                    const SizedBox(height: 8),
                    Text(purchaseOrder['purchaseOrderStatusText']?.toString() ?? '', style: _textStyle),
                  ],
                ),
              ],
            ),
            // Only show icons if shouldHideIcons is false
            if (!shouldHideIcons) ...[
              Positioned(
                bottom: -3,
                right: 0,
                child: IconButton(
                  icon: SvgPicture.asset('assets/images/edit.svg'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PurchaseOrderEdit(purchaseOrder: purchaseOrder),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -3,
                right: 40,
                child: IconButton(
                  icon: SvgPicture.asset('assets/images/receive.svg'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  ReceivePurchaseOrder(purchaseReturnId: purchaseOrder,),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
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

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.bold,
    color: Color(0xFF00355E),
  );

  static const TextStyle _textStyle = TextStyle(
    fontFamily: 'Inter',
    color: Color(0xFF00255D),
  );
}
