import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rndpo/API/api_service.dart';
import 'package:rndpo/Presentation/purchase_order.dart';
import 'package:rndpo/widgets/app_bar.dart';
import '../screens/menu_screen.dart';

class PurchaseOrderItem {
  final String sku;
  final String supplierCode;
  final String name;
  final String size;
  final int onHand;
  final String pack;
  final double amount;

  PurchaseOrderItem({
    required this.sku,
    required this.supplierCode,
    required this.name,
    required this.size,
    required this.onHand,
    required this.pack,
    required this.amount,
  });

  @override
  String toString() {
    return 'SKU: $sku, Supplier Code: $supplierCode, Name: $name, Size: $size, On Hand: $onHand, Pack: $pack, Amount: \$${amount.toStringAsFixed(2)}';
  }
}

class ReceivePurchaseOrder extends StatefulWidget {
  final dynamic purchaseReturnId;

  const ReceivePurchaseOrder({super.key, required this.purchaseReturnId});

  @override
  State<ReceivePurchaseOrder> createState() => _ReceivePurchaseOrderState();
}

class _ReceivePurchaseOrderState extends State<ReceivePurchaseOrder> {
  int? selectedSupplier;
  late final ApiService _apiService;
  bool isLoading = true;
  String? orderNumber;
  dynamic? purchaseOrderIDs;
  dynamic? supplierName;
  dynamic? orderQty;
  dynamic? totalAmount;
  dynamic? purchaseOrderStatusID;
  dynamic? purchaseOrderStatusText;
  bool _isLoading = false;

  List<PurchaseOrderItem> items = []; // Dynamic list for API data
  List<TextEditingController> _quantityControllers = [];
  List<TextEditingController> _costControllers = [];
  List<double> amountList = [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    print('PurchaseReturn ID: ${widget.purchaseReturnId}');
    someMethod();
  }

  void someMethod() {
    print('someMethod: Purchase Order Edit: ${widget.purchaseReturnId}');
    handlePurchaseOrderResponse(widget.purchaseReturnId);
  }

  void handlePurchaseOrderResponse(Map<String, dynamic> purchaseOrder) {
    int purchaseOrderID = purchaseOrder['purchaseOrderID'];
    _getReceiveOrderIdDate(purchaseOrderID);
  }

  Future<void> _getReceiveOrderIdDate(int purchaseOrderID) async {
    try {
      setState(() {
        isLoading = true;
      });

      var data = await _apiService.ReceivePurchaseOrder(purchaseOrderID);
      List<Map<String, dynamic>> productList = data;

      if (productList.isNotEmpty) {
        orderNumber = productList[0]['purchaseOrderNumber'] ?? 'Unknown Order';
        selectedSupplier = productList[0]['supplierID'];
        supplierName = productList[0]['supplierName'] ?? 'Unknown Supplier';
        orderQty = productList[0]['orderQty'] ?? 0;
        totalAmount = productList[0]['totalAmount'] ?? 0.0;
        purchaseOrderIDs = productList[0]['purchaseOrderID'] ?? 0.0;


        // Clear previous items and controllers if necessary
        items.clear();
        _quantityControllers.clear();
        _costControllers.clear();
        amountList.clear();

        items = (productList[0]['purchaseOrderProductTxns'] as List)
            .map((item) {
          print('Item: $item'); // Log each item

          // Create a new PurchaseOrderItem
          final newItem = PurchaseOrderItem(
            sku: item['productID'].toString() ?? 'N/A',
            supplierCode: item['productCode'] ?? 'N/A',
            name: item['productName'] ?? 'N/A',
            size: item['sizeName'] ?? 'N/A',
            onHand: item['onHand'] ?? 0, // Ensure 'onHand' is handled
            pack: item['packName'] ?? 'N/A',
            amount: (item['purchasePrice'] as num?)?.toDouble() ?? 0.0, // Handle amount
          );

          // Add quantity and cost controllers for the current item
          _quantityControllers.add(TextEditingController(text: item['orderQty'].toString()));
          _costControllers.add(TextEditingController(text: item['purchasePrice'].toString()));
          amountList.add(0.0); // Initialize amountList for each item

          return newItem;
        }).toList();

        print('Parsed Products: $items');
      } else {
        print('No data available');
      }
    } catch (e) {
      print('Error fetching product master: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching product data',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _postReceivePurchaseOrder() async {
    try {
      // Ensure purchaseOrderID is valid
      if (purchaseOrderIDs == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Purchase Order ID.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _isLoading = true; // Start loading
      });

      int purchaseOrderID = purchaseOrderIDs; // Adjust accordingly
      print('/n $purchaseOrderIDs');

      // Create the products list
      List<Map<String, dynamic>> products = [];

      for (int index = 0; index < items.length; index++) {
        int quantity = int.tryParse(_quantityControllers[index].text) ?? 0;
        double cost = double.tryParse(_costControllers[index].text) ?? 0.0;

        // Assuming SKU is not guaranteed to be an integer
        String sku = items[index].sku;
        print('items[index]:\n $items[index]');
        if (quantity > 0 ) {
          products.add({
            'productId': sku, // Ensure this matches your API's expected type
            'quantity': quantity,
            'cost': cost,
          });
        }
      }

      // Check if there are products to send
      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter quantities for products.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Prepare the body for the API request
      final requestBody = {
        'purchaseOrderID': purchaseOrderID,
        'products': products,
      };

      print('Sending data to API:');
      print('Request Body: $requestBody');

      // Call the API service method to post the data
      await _apiService.postReceivePurchaseOrder(purchaseOrderID, products);

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isLoading = false;
      });

      // Optionally, navigate back
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PurchaseOrder()),
            (Route<dynamic> route) => false, // Changed to false to clear the stack properly
      );
    } catch (e) {
      print('An error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while sending data.',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmountValue = 0;
    int totalQuantity = 0;

    for (int index = 0; index < items.length; index++) {
      double cost = double.tryParse(_costControllers[index].text) ?? 0.0;
      int quantity = int.tryParse(_quantityControllers[index].text) ?? 0;

      // Calculate amount for this item
      double amount = cost * quantity;
      amountList[index] = amount; // Update amountList

      // Add to total values
      totalAmountValue += amount;
      totalQuantity += quantity;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const CustomAppBar(title: 'Receive Purchase Order'),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: const Color(0xFFF0F8FF),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order No: $orderNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Supplier: $supplierName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Color(0xFF006FC5)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF0F8FF),
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${index + 1}.',
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF00255D))),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('SKU:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00255D))),
                                                  Text('Sup. code:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00255D))),
                                                  Text('Name:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00255D))),
                                                  Text('Size:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00255D))),
                                                  Text('On Hand:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00255D))),
                                                  Text('Pack:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00255D))),
                                                ],
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('${item.sku}', style: const TextStyle(fontWeight: FontWeight.w400)),
                                                    Text('${item.supplierCode}', style: const TextStyle(fontWeight: FontWeight.w400)),
                                                    Text('${item.name}', style: const TextStyle(fontWeight: FontWeight.w400)),
                                                    Text('${item.size}', style: const TextStyle(fontWeight: FontWeight.w400)),
                                                    Text('${item.onHand}', style: const TextStyle(fontWeight: FontWeight.w400)),
                                                    Text('${item.pack}', style: const TextStyle(fontWeight: FontWeight.w400)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          controller: _costControllers[index],
                                          decoration: const InputDecoration(
                                            labelText: 'Cost',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [LengthLimitingTextInputFormatter(6)],
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          controller: _quantityControllers[index],
                                          decoration: const InputDecoration(
                                            labelText: 'Qty',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'Amount: \$${amountList[index].toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF00255D),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: const Divider(color: Color(0xFF006FC5)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF00255D)),
                        children: [
                          const TextSpan(text: 'Total: ', style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: '\$${totalAmountValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF00255D)),
                        children: [
                          const TextSpan(text: 'Qty: ', style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: '$totalQuantity', style: const TextStyle(fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const PurchaseOrder()),
                                (Route<dynamic> route) => true,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00255D),
                          side: const BorderSide(color: Color(0xFF00255D)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 7,
                      child: ElevatedButton(
                        onPressed:_isLoading ? null :   () {
                          _postReceivePurchaseOrder();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00255D),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Receive',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
