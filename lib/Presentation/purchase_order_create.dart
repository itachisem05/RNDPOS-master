import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:usa/API/api_service.dart';
import 'package:usa/Presentation/barcode.dart';
import 'package:usa/Presentation/home_screen.dart';
import 'package:usa/Presentation/purchase_order.dart';
import 'package:usa/widgets/autocomplete.dart';
import '../screens/menu_screen.dart';
import 'package:usa/widgets/app_bar.dart';

class PurchaseOrderCreate extends StatefulWidget {
  const PurchaseOrderCreate({super.key});

  @override
  State<PurchaseOrderCreate> createState() => _PurchaseOrderCreateState();
}

class _PurchaseOrderCreateState extends State<PurchaseOrderCreate> {
  int? selectedSupplier;
  late final ApiService _apiService;
  bool isLoading = true;
  bool _isLoading = false;
  ScrollController _scrollController = ScrollController();

  late Future<Map<int, Map<String, dynamic>>> _suppliersFuture;
  final TextEditingController _skuIdController = TextEditingController();
  final FocusNode _skuIdFocusNode = FocusNode();
  final FocusNode _onHandFocusNode = FocusNode();
  late final BarcodeScannerService _barcodeScannerService;
  List<Map<String, dynamic>> autoCompleteItems = []; // To hold API result items

  String id = "";
  String _barcode = '';
  List<Map<String, dynamic>> items = [];
  List<TextEditingController> _quantityControllers = [];
  String? highlightedId;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _suppliersFuture = _apiService.getAllSupplier();
    _barcodeScannerService = BarcodeScannerService();
  }

  @override
  void dispose() {
    _skuIdController.dispose();
    _skuIdFocusNode.dispose();
    _onHandFocusNode.dispose();
    _scrollController.dispose();
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
          autoCompleteItems =
              tempAutoCompleteItems; // Update the list for dropdown
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
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: color,
      ),
    );
  }



  void _getProductMaster() async {
    // Check if the id already exists in items
    if (items.any((item) => item['id'] == id)) {
      // Show Snackbar for product already exists
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
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          highlightedId = null;
          _skuIdController.clear();
          FocusScope.of(context).requestFocus(_skuIdFocusNode);
        });
      });

      return; // Exit the method if the product already exists
    }

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
          items.add(newItem);

          // Add a new controller for the new item
          _quantityControllers.add(TextEditingController(text: '1'));

          print("getproduct: add items $items"); // Print updated list
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
      print('Error fetching product master: $e');
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
      if (selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a supplier.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ensure items are not empty
      if (items.isEmpty) {
        throw Exception('Please add at least one item to generate a PO');
      }
      setState(() {
        _isLoading = true; // Start loading
      });
      // await Future.delayed(Duration(seconds: 2));
      // setState(() {
      //   _isLoading = false; // Stop loading
      // });

      final List<Map<String, dynamic>> purchaseItems = items.map((item) {
        return {
          'id': item['id'], // Product ID
          'quantity': item['quantity'], // Quantity to order
        };
      }).toList();

      // Call the API method with the populated list
      final result = await _apiService.postPurchaseOrderSave(
        supplierID: selectedSupplier!,
        purchaseOrderID: 0,
        items: purchaseItems,
      );

      // Check if result is valid
      if (result.isNotEmpty) {
        print('Purchase order saved successfully: $result');

        // Clear fields and lists
        setState(() {
          _skuIdController.clear();
          items.clear();
          _isLoading = false;
        });

        // Navigate to PurchaseOrder
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => PurchaseOrder()),
          (Route<dynamic> route) => false,
        );
      } else {
        // Handle the case where the response was empty or invalid
        throw Exception('No data returned from the server.');
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      print('An error occurred while saving the purchase order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateQuantity(int index, String value) {
    setState(() {
      items[index]['quantity'] = int.tryParse(value) ?? 1; // Update quantity
      print(items); // Print updated list
    });
  }

  void _showDeleteDialog(int index) {
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
            onPressed: () {
              setState(() {
                items.removeAt(index);
                print(items); // Print updated list
              });
              Navigator.of(ctx).pop();
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
                  const Text(
                    'Generate PO',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00255D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown('Supplier', _suppliersFuture),
                  const SizedBox(height: 20),
                  Opacity(
                    opacity: selectedSupplier == null ? 0.5 : 1.0,
                    child: AbsorbPointer(
                      absorbing: selectedSupplier == null,
                      child: Container(
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
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  decoration:
                                                      const InputDecoration(
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
                                      SvgPicture.asset(
                                          'assets/images/barcode.svg'),
                                    ],
                                  ),
                                  DropdownUtils.buildAutoCompleteDropdown(
                                    context,
                                    autoCompleteItems,
                                    (String id) {
                                      setState(() {
                                        this.id = id; // Update the id
                                        _getProductMaster(); // Call your function
                                        autoCompleteItems
                                            .clear(); // Clear the items
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                      Container(
                        height: 350,
                        child: Scrollbar(
                          thumbVisibility: true,
                          controller: _scrollController,
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final isHighlighted = highlightedId == items[index]['id'];
                              TextEditingController quantityController = TextEditingController(
                                text: items[index]['quantity'].toString(),
                              );

                              return Stack(
                                children: [
                                  // Container for highlighting effect
                                  Container(
                                    color: isHighlighted ? Colors.grey[200] : Colors.transparent, // Highlight color
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
                                                    contentPadding: EdgeInsets.symmetric(
                                                        vertical: 0.0, horizontal: 0.0),
                                                  ),
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14.0,
                                                    color: Color(0xFF00255D),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  keyboardType: TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                    LengthLimitingTextInputFormatter(6),
                                                  ],
                                                  controller: quantityController,
                                                  onTap: () => quantityController.selection = TextSelection(baseOffset: 0, extentOffset: quantityController.value.text.length),
                                                  onChanged: (value) {
                                                    _updateQuantity(index, value); // Update quantity state
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
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
              onPressed: _isLoading
                  ? null
                  : () {
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
          // Show the dropdown with a loading hint
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
            items: [], // Empty items during loading
            hint: const Text('Loading...'), // Hint while loading
            onChanged: null, // Disable interaction while loading
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No $label available');
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
                selectedSupplier = value; // Store the selected supplier ID as an int
              });
            },
          );
        }
      },
    );
  }

  double calculateTotal() {
    return items.fold(0.0, (sum, item) {
      final price = double.tryParse(item['costPrice'].toString()) ??
          0.0; // Ensure conversion
      final quantity = item['quantity'] as int? ?? 0;
      print('this is $price');
      print('$quantity');
      return sum + price * quantity;
    });
  }
}
