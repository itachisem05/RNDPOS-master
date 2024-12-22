import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rndpo/API/api_service.dart';
import 'package:rndpo/Presentation/barcode.dart';
import 'package:rndpo/Presentation/purchase_order.dart';
import 'package:rndpo/widgets/autocomplete.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class PurchaseOrderEdit extends StatefulWidget {
  final dynamic purchaseOrder;

  const PurchaseOrderEdit({Key? key, required this.purchaseOrder})
      : super(key: key);

  @override
  State<PurchaseOrderEdit> createState() => _PurchaseOrderEditState();
}

class _PurchaseOrderEditState extends State<PurchaseOrderEdit> {
  int? selectedSupplier;
  dynamic purchaseOrderIdNumber;
  late final ApiService _apiService;
  bool isLoading = true;
  bool _isLoading = false;
  String? orderNumber;
  ScrollController _scrollController = ScrollController();

  late Future<Map<int, Map<String, dynamic>>> _suppliersFuture;
  final TextEditingController _skuIdController = TextEditingController();
  final FocusNode _skuIdFocusNode = FocusNode();
  final FocusNode _onHandFocusNode = FocusNode();
  late final BarcodeScannerService _barcodeScannerService;
  List<Map<String, dynamic>> autoCompleteItems = []; // To hold API result items
  List<TextEditingController> _quantityControllers = [];
  List<TextEditingController> _costControllers = [];

  String _barcode = '';
  String id = "";
  List<Map<String, dynamic>> items = [];
  List<int> checking = [];
  String? highlightedId;

  void someMethod() {
    print('someMethod: Purchase Order Edit: ${widget.purchaseOrder}');
    handlePurchaseOrderResponse(widget.purchaseOrder);
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _suppliersFuture = _apiService.getAllSupplier();
    print('initState: Purchase Order Edit: ${widget.purchaseOrder}');
    someMethod();
    _barcodeScannerService = BarcodeScannerService();
  }

  @override
  void dispose() {
    _skuIdController.dispose();
    _skuIdFocusNode.dispose();
    _onHandFocusNode.dispose();
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void checkCameraPermission() {
    _barcodeScannerService.checkCameraPermission(context, (barcode) {
      setState(() {
        print('Raw barcode: $barcode');
        _barcode = barcode;
        _skuIdController.text = _barcode;
      });
      print('Cleaned barcode: $_barcode');
      _getAutoCompleteBySupplier();
    });
  }

  void _getAutoCompleteBySupplier() async {
    try {
      // Get the autocomplete data from the API
      Map<int, Map<String, dynamic>> data = await _apiService
          .getAutoCompleteBySupplier(selectedSupplier!, _skuIdController.text);

      if (data.isNotEmpty) {
        List<Map<String, String>> tempAutoCompleteItems = [];

        // Iterate over the map entries
        data.forEach((key, value) {
          tempAutoCompleteItems.add({
            'id': value['productID'].toString(),
            'name': value['productName'].toString(),
          });
        });

        setState(() {
          autoCompleteItems = tempAutoCompleteItems; // Update the list for dropdown
        });
      } else {
        _showSnackbar('No product data found', Colors.red);
        _skuIdController.clear();
        FocusScope.of(context).requestFocus(_skuIdFocusNode);
      }
    } catch (e) {
      // Check for specific error messages
      if (e.toString().contains('No products found')) {
        _showSnackbar('No products found.', Colors.red);
        _showSnackbar('No product data found', Colors.red);
        _skuIdController.clear();
        FocusScope.of(context).requestFocus(_skuIdFocusNode);
      } else {
        print('An error occurred: $e');
        _showSnackbar('An error occurred. Please try again.', Colors.red);
      }
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: color,
      ),
    );
  }

  void handlePurchaseOrderResponse(Map<String, dynamic> purchaseOrder) {
    int purchaseOrderID = purchaseOrder['purchaseOrderID'];
    _getPurchaseOrderIdDate(purchaseOrderID);
  }

  void _checkProductAndHandle(String id) {

    print('Entered _checkProductAndHandle');
    print('String id: $id');
    print('checking: $checking');

    // Check if the id exists in the checking list
    if (checking.contains(int.parse(id))) {
      print('inside if means item with id exists');
      // Show the snack bar for existing product
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product already exists',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      // Highlight the existing product
      setState(() {
        highlightedId = id; // Set the highlighted id
      });

      // Start a timer to remove highlight after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          highlightedId = null;
          _skuIdController.clear();
          FocusScope.of(context).requestFocus(_skuIdFocusNode);
        });
      });
    } else {
      // Call the method to get the product master
      _getProductMaster();
    }
  }



  void _getProductMaster() async {
    // Check if the product already exists in the checking list
   /* if (items.any((item) => item['id'] == id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product already exists',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      // Highlight the existing product
      setState(() {
        highlightedId = id; // Set the highlighted id
      });

      // Start a timer to remove highlight after 1 second
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          highlightedId = null;
          _skuIdController.clear();
          FocusScope.of(context).requestFocus(_skuIdFocusNode);
        });
      });

      return; // Exit the method if the product already exists
    }
*/
    try {
      var data = await _apiService.getPurchaseOrderProductMaster(id);
      if (data.isNotEmpty) {
        setState(() {
          final newItem = {
            'id': id,
            'skuId': data['productSKU'].toString(),
            'name': data['productName'].toString(),
            'size': data['sizeName'].toString(),
            'pack': data['packName'].toString(),
            'salesAvg': data['salesWeekAvg'].toString(),
            'onHand': data['onHand'].toString(),
            'costPrice': data['purchasePrice'].toString(),
            'quantity': 1, // Default quantity
          };


          if (!checking.contains(int.parse(id))) {
            checking.add(int.parse(id));
          }

          // Add the new item to the items list
          items.add(newItem);


          // Add a new controller for the new item
          _quantityControllers.add(TextEditingController(text: '1'));
          _costControllers.add(TextEditingController(text: data['purchasePrice'].toString()));

          print("getProduct: added items $items"); // Print updated list
        });
        _skuIdController.clear(); // Clear SKU ID controller
        FocusScope.of(context).requestFocus(_onHandFocusNode);
      } else {
        _showSnackBar('No product data found');
        _skuIdController.clear(); // Clear SKU ID controller
      }
    } catch (e) {
      print('Error fetching product master: $e');
      _showSnackBar('Error fetching product data');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _getPurchaseOrderIdDate(int purchaseOrderID) async {
    try {
      var data = await _apiService.purchaseOrderEdit(purchaseOrderID);
      if (data.isNotEmpty) {
        setState(() {
          // Iterate through the fetched data and create new items

          Map<String, dynamic>? commonDetails = data.remove(0);

          orderNumber = commonDetails?['purchaseOrderNumber'];
          selectedSupplier = commonDetails?['supplierID'];
          purchaseOrderIdNumber = commonDetails?['purchaseOrderID'];

          print('api called: $orderNumber');
          print('api called: $selectedSupplier');
          print('api called: $purchaseOrderIdNumber');

          data.forEach((orderId, details) {
            // Check for duplicates in the items list
            if (!items.any((item) => item['id'] == details['productID'] && item['skuId'] == details['productSKU'])) {
              final newItem = {
                'id': details['productID'],
                'skuId': details['productSKU'],
                'name': details['productName'],
                'onHand': details['onHand'],
                'quantity': details['orderQty'],
                'costPrice': details['costPrice'],
                'purchaseOrderTxnID': details['purchaseOrderTxnID'],
                'size': details['sizeName'],
                'pack': details['packName'],
                'salesAvg': details['salesWeekAvg'],
              };
              items.add(newItem);

              // Add the ID and SKU to the checking list
              if (!checking.contains(details['productID'])) {
                checking.add(details['productID'],);
              }

              // Add controllers
              _quantityControllers.add(TextEditingController(text: details['orderQty'].toString()));
              _costControllers.add(TextEditingController(text: details['costPrice'].toString()));
            }
          });

          print("this are in items $items"); // Print updated list
          print("this are in checking $checking"); // Print updated list
        });
        _skuIdController
            .clear(); // Clear SKU ID controller after fetching product
        FocusScope.of(context).requestFocus(_onHandFocusNode);
      } else {
        // Show Snackbar for not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No product data found',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        _skuIdController.clear(); // Clear SKU ID controller
      }
    } catch (e) {
      // Handle error appropriately
      print('Error fetching _getPurchaseOrderIdDate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error fetching product data',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _postPurchaseOrder() async {
    try {
      // Ensure items are not empty
      if (items.isEmpty) {
        throw Exception('Items list is empty.');
      }
      print('Items to be sent: $items'); // Debugging print to check contents

      if (selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a supplier.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _isLoading = true; // Start loading
      });

      final List<Map<String, dynamic>> purchaseItems = items.map((item) {
        return {
          'id': item['id'], // Product ID
          'quantity': item['quantity'], // Quantity to order
        };
      }).toList();

      print('Purchase items being sent: $purchaseItems'); // Debugging print
      print(
          'Purchase items being sent: ${purchaseItems.runtimeType}'); // Debugging print

      // Call the API method with the populated list
      await _apiService.postPurchaseOrderSave(
        supplierID: selectedSupplier!,
        purchaseOrderID: purchaseOrderIdNumber,
        items: purchaseItems,
      );

      print('Purchase order saved successfully.');

      // Clear fields and lists
      setState(() {
        _skuIdController.clear();
        items.clear();
        _isLoading = false;
      });

      // Navigate to HomeScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PurchaseOrder()),
        (Route<dynamic> route) => true,
      );
    } catch (e) {
      print('An error occurred while saving the purchase order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateQuantity(int index, String value) {
    setState(() {
      // Update the quantity, ensuring it defaults to 1 if the input is invalid
      items[index]['quantity'] = int.tryParse(value) ?? 1;
    });
  }

  void _showDeleteDialog(int index) {
    // Check if the purchaseOrderTxnID key exists in the item
    final item = items[index];
    final purchaseOrderTxnID = item.containsKey('purchaseOrderTxnID')
        ? item['purchaseOrderTxnID']
        : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?', style: TextStyle(fontFamily: 'Inter')),
        content: const Text('Are you sure you want to delete this item?',
            style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('No', style: TextStyle(fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () async {
              if (items.length == 1) {
                // Show Snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("List can't be empty."),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } else {
                if (purchaseOrderTxnID != null) {
                  // Call the method to delete the order product
                  _deleteOrderProduct(purchaseOrderTxnID);
                }
                setState(() {
                  items.removeAt(index);
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Yes', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  void _deleteOrderProduct(int purchaseOrderTxnID) async {
    try {
      // Call the API service to delete the product
      await _apiService.deleteOrderProduct(purchaseOrderTxnID);

      // Optionally, show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      // Remove the item from the UI list
      setState(() {
        items.removeWhere((item) => item['purchaseOrderTxnID'] == purchaseOrderTxnID);
      });
    } catch (e) {
      // Handle the exception here, e.g., show an error message
      print('An error occurred while deleting the product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete product: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Order NO: ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00255D),
                        ),
                      ),
                      Text(
                        orderNumber ?? 'Loading...',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal, // Use regular weight
                          color: Color(
                              0xFF00255D), // Keep the same color if desired
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown('Supplier', _suppliersFuture),
                  const SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width - 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF0F8FF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Scan product barcode and make a list',
                                style: TextStyle(
                                  color: Color(0xFF00355E),
                                  fontFamily: 'Inter-Regular',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFF00255D),
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              decoration: const InputDecoration(
                                                hintText:
                                                    'Scan or Enter Barcode',
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 9),
                                              ),
                                              controller: _skuIdController,
                                              onTap: () => _skuIdController.selection = TextSelection(baseOffset: 0, extentOffset: _skuIdController.value.text.length),
                                              onSubmitted: (String sku) {
                                                _getAutoCompleteBySupplier();
                                              },
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: SvgPicture.asset(
                                                'assets/images/cam.svg'),
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              checkCameraPermission();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SvgPicture.asset('assets/images/barcode.svg'),
                                ],
                              ),
                              DropdownUtils.buildAutoCompleteDropdown(
                                context,
                                autoCompleteItems,
                                    (String id) {
                                  setState(() {
                                    this.id = id;  // Update the id
                                    _checkProductAndHandle(id);
                                    // _getProductMaster();  // Call your function
                                    autoCompleteItems.clear();  // Clear the items
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 350, // Fixed height for the ListView
                          child: Scrollbar(
                            thumbVisibility: true, // Always show the scrollbar
                            controller: _scrollController,
                            child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final isHighlighted = highlightedId == items[index]['id'];
                                return Stack(
                                  children: [
                                    Container(
                                      color: isHighlighted ? Colors.grey[200] : Colors.transparent,
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 60,
                                                  height: 40,
                                                  child: TextField(
                                                    decoration: const InputDecoration(
                                                      hintText: 'Qty',
                                                      hintStyle: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.w400,
                                                        color: Color(0xFF00255D),
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: Color(0xFF00255D),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: Color(0xFF00255D),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: Color(0xFF00255D),
                                                          width: 2.0,
                                                        ),
                                                      ),
                                                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                                                    ),
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight: FontWeight.w400,
                                                      fontSize: 16.0,
                                                      color: Color(0xFF00255D),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    keyboardType: TextInputType.number,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.digitsOnly,
                                                      LengthLimitingTextInputFormatter(6),
                                                    ],
                                                    controller: _quantityControllers[index],
                                                    onTap: () => _quantityControllers[index].selection = TextSelection(baseOffset: 0, extentOffset: _quantityControllers[index].value.text.length),
                                                    onChanged: (value) {
                                                      _updateQuantity(index, value);
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text(
                                                            'SKU:',
                                                            style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14,
                                                                color: Color(0xFF00255D)),
                                                          ),
                                                          const SizedBox(height: 5.0),
                                                          const Text(
                                                            'Name:',
                                                            style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14,
                                                                color: Color(0xFF00255D)),
                                                          ),
                                                          const SizedBox(height: 5.0),

                                                          Row(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    'Size:',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 14,
                                                                        color: Color(0xFF00255D)),
                                                                  ),
                                                                  SizedBox(height: 5.0),
                                                                  Text(
                                                                    'On hand:',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 14,
                                                                        color: Color(0xFF00255D)),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(width: 5.0,),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              '${items[index]['skuId'] ?? 'N/A'}',
                                                              style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Color(0xFF00255D)),
                                                              overflow: TextOverflow.clip,
                                                              softWrap: true,
                                                            ),
                                                            const SizedBox(height: 5.0),
                                                            Text(
                                                              items[index]['name'] ?? 'Unnamed',
                                                              style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Color(0xFF00255D)),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 5.0),
                                                            Row(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      '${items[index]['size']?.toString() ?? '0.00'}',
                                                                      style: const TextStyle(
                                                                          fontSize: 14,
                                                                          color: Color(0xFF00255D)),
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                    const SizedBox(height: 5.0),
                                                                    Text(
                                                                      '${items[index]['onHand']?.toString() ?? '0.00'}',
                                                                      style: const TextStyle(
                                                                          fontSize: 14,
                                                                          color: Color(0xFF00255D)),
                                                                      overflow: TextOverflow.clip,
                                                                      softWrap: true,
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(width: 10.0,),
                                                                Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Row(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          'Pack:',
                                                                          style: TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 14,
                                                                              color: Color(0xFF00255D)),
                                                                        ),
                                                                        SizedBox(width: 5.0),
                                                                        Text(
                                                                          '${items[index]['pack']?.toString() ?? '0.00'}',
                                                                          style: const TextStyle(
                                                                              fontSize: 14,
                                                                              color: Color(0xFF00255D)),
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    SizedBox(height: 5.0),
                                                                    Row(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          'Sales Avg.:',
                                                                          style: TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 14,
                                                                              color: Color(0xFF00255D)),
                                                                        ),
                                                                        SizedBox(width: 5.0),
                                                                        Text(
                                                                          '${items[index]['salesAvg']?.toString() ?? '0.00'}',
                                                                          style: const TextStyle(
                                                                              fontSize: 14,
                                                                              color: Color(0xFF00255D)),
                                                                          overflow: TextOverflow.clip,
                                                                          softWrap: true,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                            child: Divider(
                                              thickness: 1,
                                              color: Color(0xFFA4D5FF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: -10,
                                      right: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: IconButton(
                                          icon: SvgPicture.asset(
                                            'assets/images/delete2.svg',
                                            color: const Color(0xFF00255D),
                                            width: 20.0,
                                            height: 20.0,
                                          ),
                                          onPressed: () {
                                            _showDeleteDialog(index);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Total: \$${calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null :  () {
                _postPurchaseOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00255D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Generate PO',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String label, Future<Map<int, Map<String, dynamic>>> future) {
    return FutureBuilder<Map<int, Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No $label available');
        } else if (selectedSupplier != null) {
          final data = snapshot.data!;
          final String supplierName = data[selectedSupplier]?['name'];

          return Row(
            children: [
              const Text(
                'Supplier: ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00255D),
                ),
              ),
              Text(
                supplierName ?? "Loading..",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal, // Use regular weight
                  color: Color(0xFF00255D), // Keep the same color if desired
                ),
              ),
            ],
          );
        } else {
          final data = snapshot.data!;
          return DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF8FBBFF)),
                borderRadius: BorderRadius.circular(12.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF8FBBFF)),
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            items: data.entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value['name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSupplier =
                    value; // Store the selected supplier ID as an int
              });
            },
          );
        }
      },
    );
  }

  double calculateTotal() {
    double total = items.fold(0.0, (sum, item) {
      final price = double.tryParse(item['costPrice'].toString()) ?? 0.0;
      final quantity = item['quantity'] as int? ?? 0;
      print('Calculating: $price * $quantity'); // Debugging line
      return sum + (price * quantity);
    });
    print('Total: $total'); // Debugging line
    return total;
  }
}
