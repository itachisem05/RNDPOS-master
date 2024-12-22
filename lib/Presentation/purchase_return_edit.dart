import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rndpo/API/api_service.dart';
import 'package:rndpo/Presentation/barcode.dart';
import 'package:rndpo/Presentation/purchase_return.dart';
import 'package:rndpo/widgets/autocomplete.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class PurchaseReturnEdit extends StatefulWidget {
  final dynamic purchaseReturnId;

  const PurchaseReturnEdit({super.key, required this.purchaseReturnId});

  @override
  State<PurchaseReturnEdit> createState() => _PurchaseReturnEditState();
}

class _PurchaseReturnEditState extends State<PurchaseReturnEdit> {
  int? selectedSupplier;
  int? selectedPurchaseOrder;
  int? defaultSupplierId;
  int? defaultPurchaseOrder;
  int? purchaseReturnid;
  bool _isLoading = false;
  List<int> checking = [];
  String? highlightedId;

  late final BarcodeScannerService _barcodeScannerService;
  List<Map<String, dynamic>> autoCompleteItems = []; // To hold API result items

  late final ApiService _apiService;
  bool isLoading = true;
  String id = "";
  String _barcode = '';
  List<Map<String, String>> items = [];
  ScrollController _scrollController = ScrollController();

  late Future<Map<int, Map<String, dynamic>>> _suppliersFuture;
  Future<Map<int, Map<String, dynamic>>>? _purchaseOrdersFuture;
  Map<int, TextEditingController> costControllers = {};
  Map<int, TextEditingController> qtyControllers = {};
  TextEditingController notesController = TextEditingController();
  final TextEditingController _skuIdController = TextEditingController();
  final FocusNode _skuIdControllerFocusNode = FocusNode();
  double amount = 0.0;

  void _calculateAmountForProduct(int index) {
    double cost = double.tryParse(items[index]['cost'] ?? '0') ?? 0.0;
    int quantity = int.tryParse(items[index]['quantity'] ?? '0') ?? 0;
    double amount = cost * quantity;

    // Update the amount in the items list
    items[index]['amount'] = amount.toStringAsFixed(2);

    // Print for debugging
    print(
        'PurchaseReturnEdit: Amount for product ${items[index]['name']}: \$${amount.toStringAsFixed(2)}');

    // Trigger a rebuild if necessary
    setState(() {}); // Ensure the UI reflects the updated amount
  }

  void _fetchPurchaseOrders(int supplierId) {
    setState(() {
      _purchaseOrdersFuture = _apiService.getPurchaseReturn(supplierId);
    });
  }

  void _getAutoComplete() async {
    try {
      // Get the autocomplete data from the API
      Map<int, Map<String, dynamic>> data =
      await _apiService.getAutoComplete(_skuIdController.text);

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
          autoCompleteItems =
              tempAutoCompleteItems; // Update the list for dropdown
        });
      } else {
        _showSnackbar('No product data found', Colors.red);
        _skuIdController.clear();
      }
    } catch (e) {
      print('An error occurred: $e');
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

  @override
  void dispose() {
    _skuIdControllerFocusNode.dispose();
    super.dispose();
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
        });
      });
    } else {
      // Call the method to get the product master
      _getProductMaster();
    }
  }


  Future<void> _getProductMaster() async {
    try {
      print('PurchaseReturnEdit: Fetching product master for ID: $id');
      var data = await _apiService.getProductMaster(id);
      print('PurchaseReturnEdit: Product master data received: $data');

      if (data.isNotEmpty) {
        // Check if onHand value is greater than 0
        if (int.parse(data['onHand'].toString()) > 0) {
          setState(() {
            final newItem = {
              'productId': id,
              'sku': data['productSKU'].toString(),
              'name': data['productName'].toString(),
              'onHand': data['onHand'].toString(),
              'purchasePrice': data['purchasePrice'].toString(),
              'cost': '', // New field for cost
              'quantity': '', // New field for quantity
            };
            items.add(newItem); // Add new item to the list

            if (!checking.contains(int.parse(id))) {
              checking.add(int.parse(id));
            }

            print('PurchaseReturnEdit: New item added: $newItem');
            print('PurchaseReturnEdit: item: $items');
            costControllers[items.length - 1] = TextEditingController();
            qtyControllers[items.length - 1] = TextEditingController();
          });
          _skuIdController.clear(); // Clear SKU ID controller after fetching product
          FocusScope.of(context).requestFocus();
        } else {
          // Clear fields and show Snackbar for OnHand value 0
          _skuIdController.clear(); // Clear SKU ID controller
          // Clear other fields if necessary
          costControllers.clear();
          qtyControllers.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Onhand is less than 0; returns not allowed.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
          print('PurchaseReturnEdit: OnHand value is 0 for ID: $id');
        }
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
        print('PurchaseReturnEdit: No product data found for ID: $id');
        _skuIdController.clear(); // Clear SKU ID controller
      }
    } catch (e) {
      // Handle error appropriately
      print('PurchaseReturnEdit: Error fetching product master: $e');
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

  Future<void> _getPurchaseReturnIdData(int purchaseReturnId) async {
    try {
      var data = await _apiService.purchaseReturnEdit(purchaseReturnId); // Call your API method

      if (data.isNotEmpty) {
        setState(() {
          var commonData = data.removeAt(0);
          defaultSupplierId = commonData['supplierID'];
          selectedSupplier = defaultSupplierId;
          defaultPurchaseOrder = commonData['purchaseOrderID'];
          purchaseReturnid = commonData["purchaseReturnID"];
          notesController.text = commonData['notes'];
          _purchaseOrdersFuture = _apiService.getPurchaseReturn(defaultSupplierId!);

          var idx = 0;
          data.forEach((orderDetails) {
            final newItem = {
              'productId': orderDetails['productId']?.toString() ?? '',
              'sku': orderDetails['sku']?.toString() ?? '',
              'name': orderDetails['productName']?.toString() ?? '',
              'onHand': orderDetails['onHand']?.toString() ?? '',
              'purchasePrice': orderDetails['purchasePrice']?.toString() ?? '',
              'cost': orderDetails['cost']?.toString() ?? '',
              'quantity': orderDetails['quantity']?.toString() ?? '',
              'purchaseReturnTxnID': orderDetails['purchaseReturnTxnID']?.toString() ?? '',
              'purchaseOrderID': selectedPurchaseOrder?.toString() ?? '',
              'supplierID': selectedSupplier?.toString() ?? '',
              'notes': notesController.text,
            };

            items.add(newItem); // Add the new item to the list

            // Store productId in checking if not already present
            if (!checking.contains(orderDetails['productId'])) {
              checking.add((orderDetails['productId']));
            }

            print('costControllers: $costControllers');
            print('checking: $checking');
            costControllers[idx] = TextEditingController();
            costControllers[idx]?.text = newItem['cost']!;

            qtyControllers[idx] = TextEditingController();
            qtyControllers[idx]?.text = newItem['quantity']!;

            _calculateAmountForProduct(idx);
            idx++;
          });
          print("_getPurchaseReturnIdDate: $items"); // Print updated list
        });

        _skuIdController.clear();

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
      print('_getPurchaseReturnIdDate: $e');
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
  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _suppliersFuture = _apiService.getAllSupplier();
    print('PurchaseReturn ID: ${widget.purchaseReturnId}');
    print(
        'PurchaseReturn ID runtimeType: ${widget.purchaseReturnId.runtimeType}');
    // int purchaseReturnId = int.tryParse(widget.purchaseReturnId) ?? 0; // Fallback to 0 if parsing fails
    _getPurchaseReturnIdData(widget.purchaseReturnId);
    _barcodeScannerService = BarcodeScannerService();
  }

  void checkCameraPermission() {
    _barcodeScannerService.checkCameraPermission(context, (barcode) {
      setState(() {
        print('Raw barcode: $barcode');
        _barcode = barcode;
        _skuIdController.text = _barcode;
      });
      print('Cleaned barcode: $_barcode');
      _getAutoComplete();
    });
  }

  void _postPurchaseReturn() async {
    try {
      print('selectedSupplier: $selectedSupplier');
      print('defaultSupplierId: $defaultSupplierId');
      print('purchaseReturnid: $purchaseReturnid');

      // Ensure items are not empty
      if (items.isEmpty) {
        throw Exception('Items list is empty.');
      }
      if (selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a supplier.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (selectedPurchaseOrder == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a purchase order.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _isLoading = true; // Start loading
      });
      print('Items before processing: $items');

      for (var item in items) {
        if (item['id'] == null ||
            item['quantity'] == null ||
            item['cost'] == null ||
            item['name'] == null) {
          print('Null properties found in item: $item');
        }
      }

      // Prepare the purchase items to match the desired format
      final List<Map<String, dynamic>> purchaseItems = items.map((item) {
        return {
          'productId': int.tryParse(item['productId'] ?? '') ?? 0,
          'quantity': int.tryParse(item['quantity'] ?? '') ?? 0,
          'cost': double.tryParse(item['cost'] ?? '') ?? 0.0,
          'productName': item['name'] ?? '',
          // Ensure productName has a default value
        };
      }).toList();

      print("final data $items");

      // Create the body to send to the API
      final Map<String, dynamic> body = {
        'purchaseOrderID': selectedPurchaseOrder!,
        'supplierID': selectedSupplier!,
        'purchaseReturnID': purchaseReturnid ?? 0,
        'notes': notesController.text,
        'products': purchaseItems,
      };

      String jsonString = jsonEncode(body);
      print('PurchaseReturnEdit: Json validated data.');
      print(jsonString);

      // Call the API method with the populated body
      print('PurchaseReturnEdit: Sending to API...');
      await _apiService.postPurchaseReturnSave(body);

      print('PurchaseReturnEdit: Purchase order saved successfully.');

      // Clear fields and lists
      setState(() {
        _skuIdController.clear();
        notesController.clear(); // Clear notes controller
        items.clear();
        _isLoading = false;
      });

      // Navigate to HomeScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PurchaseReturn()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print(
          'PurchaseReturnEdit: An error occurred while saving the purchase order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(
      BuildContext context, int index, int purchaseReturnId) {
    // Extract the productID from the item to be deleted
    final productID = items[index]['productId'];
    print("this delete productID $productID");

    // Use the passed purchaseReturnId
    final int purchaseReturnID = purchaseReturnId;
    print("this delete purchaseOrderID $purchaseReturnID");

    // Check if productID is an int or can be converted to an int
    int? intProductID;

    if (productID is int) {
      intProductID = productID as int?; // It's already an int
    } else if (productID is String) {
      intProductID = int.tryParse(productID); // Try to parse it to int
    }

    // Handle cases where intProductID could not be assigned
    if (intProductID == null) {
      print(
          'Invalid product ID: $productID'); // Log or handle the error appropriately
      return;
    }

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
              Navigator.of(ctx).pop(); // Close the dialog
              await _deleteOrderProduct(
                  purchaseReturnID, intProductID!); // Call the delete method
            },
            child: const Text('Yes', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrderProduct(int purchaseReturnID, int productID) async {
    try {
      await _apiService.deleteReturnProduct(purchaseReturnID, productID);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      print('Items before deletion: $items');
      print('Attempting to delete productId: $productID');

      final originalLength = items.length;

      setState(() {
        items = items.where((item) {
          // Ensure type consistency
          final itemProductId = int.tryParse(item['productId'].toString());
          return itemProductId != productID;
        }).toList();
      });

      print('Items after deletion: $items');
      if (items.length == originalLength) {
        print('No items were deleted. Please check the productID.');
      }
    } catch (e) {
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
        title: 'Purchase Return',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdown('Supplier', _suppliersFuture),
                  const SizedBox(height: 15),
                  if (_purchaseOrdersFuture != null) ...[
                    _buildPurchaseOrderDropdown(_purchaseOrdersFuture!),
                    const SizedBox(height: 15),
                  ],
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Write note',
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
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal:
                          12.0), // Adjust vertical padding to control height
                    ),
                    onChanged: (String? value) {},
                  ),
                  const SizedBox(height: 15),
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
                                              controller: _skuIdController,
                                              focusNode:
                                              _skuIdControllerFocusNode,
                                              onSubmitted: (String sku) {
                                                _getAutoComplete();
                                              },
                                              decoration: const InputDecoration(
                                                hintText:
                                                'Scan or Enter Barcode',
                                                border: InputBorder.none,
                                                contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 10.0,
                                                    vertical: 9),
                                              ),
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
                                    this.id = id; // Update the id
                                    _checkProductAndHandle(id);
                                    autoCompleteItems.clear(); // Clear the items
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
        Container(
          height: 310, // Fixed height for the ListView
          child: Scrollbar(
            thumbVisibility: true,
            controller: _scrollController,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final isHighlighted = highlightedId == items[index]['productId'];
                String? purchaseReturnTxnIDS = items[index]['purchaseReturnTxnID'];
                int purchaseReturnTxnID = purchaseReturnTxnIDS != null ? int.tryParse(purchaseReturnTxnIDS) ?? 0 : 0;

                return Column(
                  children: [
                    Container(
                      color: isHighlighted ? Colors.grey[200] : Colors.transparent,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('SKU:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                      const SizedBox(height: 4),
                                      const Text('Name:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                      const SizedBox(height: 4),
                                      const Text('onHand:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                      const SizedBox(height: 4),
                                      const Text('Actual Cost:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                      const SizedBox(height: 4),
                                      if (purchaseReturnTxnID > 0) ...[
                                        const Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Cost:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                            SizedBox(height: 4),
                                            Text('QTY:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                            SizedBox(height: 4),
                                            Text('Amount:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(items[index]['sku'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00255D))),
                                      const SizedBox(height: 4),
                                      Text(items[index]['name'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00255D)), overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(items[index]['onHand'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00255D))),
                                      const SizedBox(height: 4),
                                      Text(items[index]['purchasePrice'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00255D))),
                                      const SizedBox(height: 4),
                                      if (purchaseReturnTxnID > 0) ...[
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(items[index]['cost'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00255D))),
                                            SizedBox(height: 4),
                                            Text(items[index]['quantity'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00255D))),
                                            SizedBox(height: 4),
                                            Text(
                                              '\$${items[index]['amount'] ?? '0.00'}',
                                              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: Color(0xFF00255D)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                _showDeleteDialog(context, index, widget.purchaseReturnId);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                  'assets/images/delete2.svg',
                                  color: const Color(0xFF00255D),
                                  width: 20.0,
                                  height: 20.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (purchaseReturnTxnID > 0) ...[] else ...[
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: costControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'Cost',
                                  labelStyle: TextStyle(color: Color(0xFF00255D), fontFamily: 'Inter', fontWeight: FontWeight.w400),
                                  border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8FBBFF))),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8FBBFF), width: 1.5)),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8FBBFF), width: 2.0)),
                                ),
                                style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: Color(0xFF00255D)),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                onChanged: (value) {
                                  items[index]['cost'] = value;
                                  _calculateAmountForProduct(index);
                                  print('PurchaseReturnEdit: Updated Cost for ${items[index]['name']}: $value');
                                  print('PurchaseReturnEdit: this is item $items');
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: qtyControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'Qty',
                                  labelStyle: TextStyle(color: Color(0xFF00255D), fontFamily: 'Inter', fontWeight: FontWeight.w400),
                                  border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8FBBFF))),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8FBBFF), width: 1.5)),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8FBBFF), width: 2.0)),
                                ),
                                style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: Color(0xFF00255D)),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                onChanged: (value) {
                                  // Parse onHand quantity from String to int
                                  final int onHand = int.tryParse(items[index]['onHand'].toString()) ?? 0;
                                  final int enteredQty = int.tryParse(value) ?? 0;

                                  if (enteredQty > onHand) {
                                    // Show snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Cannot enter more than Onhand Qty")),
                                    );

                                    // Clear the field safely
                                    qtyControllers[index]?.clear();
                                    items[index]['quantity'] = '0'; // Reset quantity in your items list as String
                                  } else {
                                    // Update quantity in your items list and calculate amount
                                    items[index]['quantity'] = enteredQty.toString(); // Store as String
                                    _calculateAmountForProduct(index);
                                  }

                                  print('PurchaseReturnEdit: Updated Quantity for ${items[index]['name']}: $value');
                                  print('PurchaseReturnEdit: this is item $items');
                                },
                              ),
                            )
,
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Amount: ',
                                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Color(0xFF00255D)),
                                      ),
                                      TextSpan(
                                        text: '\$${items[index]['amount'] ?? '0.00'}',
                                        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: Color(0xFF00255D)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Divider(thickness: 1, color: Color(0xFFA4D5FF)),
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
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              // Evenly space the buttons
              children: [
                ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context)
                        .requestFocus(_skuIdControllerFocusNode);
                    print('PurchaseReturnEdit: final : $items');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Color(0xFF00255D), // Border color
                        width: 1.0, // Border width
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(150, 50), // Fixed width
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(color: Color(0xFF00255D)),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null :  () async {
                    _postPurchaseReturn();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00255D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(150, 50), // Fixed width
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
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
        } else {
          final data = snapshot.data!;

          // Get the name corresponding to the defaultSupplierId
          final selectedValue =
              data[defaultSupplierId]?['name'] ?? 'Not selected';

          print('inside _buildReadOnlyDropdown');

          return Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Supplier: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00255D),
                  ),
                ),
                TextSpan(
                  text: selectedValue,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500, // Medium weight
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildPurchaseOrderDropdown(
      Future<Map<int, Map<String, dynamic>>> future) {
    return FutureBuilder<Map<int, Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No Purchase Orders available');
        } else {
          final data = snapshot.data!;

          print('inside _buildPurchaseOrderDropdown');
          print('data: $data');

          // Retrieve the name corresponding to the defaultPurchaseOrder
          final selectedValue = data.values.firstWhere(
                (item) => item['Id'] == defaultPurchaseOrder,
            orElse: () => {'name': 'Not selected'},
          )['name'];

          print('defaultPurchaseOrder: $defaultPurchaseOrder');
          selectedPurchaseOrder = defaultPurchaseOrder;
          print(
              'assigned value to selectedPurchaseOrder which is  : $selectedPurchaseOrder');

          return Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Purchase Order: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00255D),
                  ),
                ),
                TextSpan(
                  text: selectedValue,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500, // Medium weight
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}