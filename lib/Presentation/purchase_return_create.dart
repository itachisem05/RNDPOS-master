import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rndpo/API/api_service.dart';
import 'package:rndpo/Presentation/barcode.dart';
import 'package:rndpo/Presentation/purchase_return.dart';
import 'package:rndpo/widgets/app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rndpo/widgets/autocomplete.dart';
import '../screens/menu_screen.dart';

class PurchaseReturnCreate extends StatefulWidget {
  const PurchaseReturnCreate({super.key});

  @override
  State<PurchaseReturnCreate> createState() => _PurchaseReturnCreateState();
}

class _PurchaseReturnCreateState extends State<PurchaseReturnCreate> {
  int? selectedSupplier;
  int? selectedPurchaseOrder;
  late final BarcodeScannerService _barcodeScannerService;
  List<Map<String, dynamic>> autoCompleteItems = []; // To hold API result items

  late final ApiService _apiService;
  bool isLoading = true;
  String id = "";
  String _barcode = '';
  ScrollController _scrollController = ScrollController();
  late Future<Map<int, Map<String, dynamic>>> _suppliersFuture;
  Future<Map<int, Map<String, dynamic>>>? _purchaseOrdersFuture;
  Map<int, TextEditingController> costControllers = {};
  Map<int, TextEditingController> qtyControllers = {};
  TextEditingController costController = TextEditingController();
  TextEditingController qtyController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  final TextEditingController _skuIdController = TextEditingController();
  final FocusNode _skuIdControllerFocusNode = FocusNode();
  double amount = 0.0;
  bool _isLoading = false;
  String? highlightedId;

  void _calculateAmountForProduct(int index) {
    double cost = double.tryParse(items[index]['cost'] ?? '0') ?? 0.0;
    int quantity = int.tryParse(items[index]['quantity'] ?? '0') ?? 0;
    double amount = cost * quantity;

    // Update the amount in the items list
    items[index]['amount'] = amount.toStringAsFixed(2);

    // Print for debugging
    print('Amount for product ${items[index]['name']}: \$${amount.toStringAsFixed(2)}');

    // Trigger a rebuild if necessary
    setState(() {}); // Ensure the UI reflects the updated amount
  }

  void _fetchPurchaseOrders(int supplierId) {
    setState(() {
      _purchaseOrdersFuture = _apiService.getPurchaseReturn(supplierId);
    });
  }

  List<Map<String, String>> items = [];

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

  Future<void> _getProductMaster() async {
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

      // Start a timer to remove highlight after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          highlightedId = null;
          _skuIdController.clear();
        });
      });

      return; // Exit the method if the product already exists
    }

    try {
      print('Fetching product master for ID: $id');
      var data = await _apiService.getProductMaster(id);
      print('Product master data received: $data');

      if (data.isNotEmpty) {
        // Check if onHand value is greater than 0
        if (int.parse(data['onHand'].toString()) > 0) {
          setState(() {
            final newItem = {
              'id': id,
              'sku': data['productSKU'].toString(),
              'name': data['productName'].toString(),
              'onHand': data['onHand'].toString(),
              'actualCost': data['purchasePrice'].toString(),
              'cost': '', // New field for cost
              'quantity': '', // New field for quantity
            };
            items.add(newItem); // Add new item to the list
            print('New item added: $newItem');
            costControllers[items.length - 1] = TextEditingController();
            qtyControllers[items.length - 1] = TextEditingController();
          });
          _skuIdController.clear(); // Clear SKU ID controller after fetching product
          FocusScope.of(context).requestFocus();
        } else {
          // Clear fields and show Snackbar for OnHand value 0
          _skuIdController.clear(); // Clear SKU ID controller
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
          print('OnHand value is 0 for ID: $id');
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
        print('No product data found for ID: $id');
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

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _suppliersFuture = _apiService.getAllSupplier();
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

      // Prepare the purchase items to match the desired format
      final List<Map<String, dynamic>> purchaseItems = items.map((item) {
        return {
          'productId': int.tryParse(item['id']!) ?? 0,
          'quantity': int.tryParse(item['quantity']!) ?? 0,
          'cost': double.tryParse(item['cost']!) ?? 0.0,
          'productName': item['name'],
        };
      }).toList();

      // Create the body to send to the API
      final Map<String, dynamic> body = {
        'purchaseOrderID': selectedPurchaseOrder!,
        'supplierID': selectedSupplier!,
        'purchaseReturnID': 0, // Assuming this is static for now
        'notes': notesController.text,
        'products': purchaseItems,
      };
      String jsonString = jsonEncode(body);
      print('Json validated data.');
      print(jsonString);

      // Call the API method with the populated body
      print('Sending to API...');
      await _apiService.postPurchaseReturnSave(body);

      print('Purchase order saved successfully.');

      // Clear fields and lists
      setState(() {
        _skuIdController.clear();
        notesController.clear(); // Clear notes controller
        items.clear();
        _isLoading = false;
      });

      // Navigate to HomeScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => PurchaseReturn()),
        (Route<dynamic> route) => false,
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

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // Log the item to be deleted before removing it
                print('Deleted item: ${items[index]['name']}');
                items.removeAt(index); // This removes the item from the list
                print('Updated items: $items'); // Log the updated list
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Yes'),
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
          height: 200,
          child: Scrollbar(
            thumbVisibility: true,
            controller: _scrollController, // Ensure this is defined
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final isHighlighted = highlightedId == items[index]['id'];
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
                                const Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('SKU:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                      SizedBox(height: 4),
                                      Text('Name:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                      SizedBox(height: 4),
                                      Text('Onhand:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
                                      SizedBox(height: 4),
                                      Text('Actual Cost:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00255D))),
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
                                      Text(
                                        items[index]['name'] ?? 'N/A',
                                        style: const TextStyle(color: Color(0xFF00255D)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(items[index]['onHand'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00255D))),
                                      const SizedBox(height: 4),
                                      Text(items[index]['actualCost'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00255D))),
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
                                _showDeleteDialog(index);
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
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: costControllers[index], // Make sure this is defined
                              decoration: const InputDecoration(
                                labelText: 'Cost',
                                labelStyle: TextStyle(color: Color(0xFF00255D), fontFamily: 'Inter', fontWeight: FontWeight.w400),
                                border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8FBBFF))),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8FBBFF), width: 1.5)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8FBBFF), width: 2.0)),
                              ),
                              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: Color(0xFF00255D)),
                              keyboardType: TextInputType.number,
                              inputFormatters: [LengthLimitingTextInputFormatter(6)],
                              onChanged: (value) {
                                items[index]['cost'] = value; // Save the cost in the item
                                _calculateAmountForProduct(index); // Calculate amount
                                print('Updated Cost for ${items[index]['name']}: $value'); // Log cost update
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
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Amount: \$${items[index]['amount'] ?? '00.00'}',
                                style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: Color(0xFF00255D)),
                              ),
                            ),
                          ),
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
                  onPressed:_isLoading ? null :  () async {
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
            onChanged: (int? value) {
              setState(() {
                selectedSupplier = value; // Directly assign int? value
                if (value != null) {
                  _fetchPurchaseOrders(value);
                  print(
                      'selected" $selectedSupplier'); // Pass the selected supplier ID here
                }
              });
            },
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
          return DropdownButtonFormField<int>(
            decoration: InputDecoration(
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
          return const Text('No Purchase Orders available');
        } else {
          final data = snapshot.data!;

          // Create a set to keep track of unique Ids
          final Set<int> uniqueIds =
              data.values.map((entry) => entry['Id'] as int).toSet();

          // Check for duplicates in the IDs
          if (uniqueIds.length < data.length) {
            return const Text('Duplicate IDs found in Purchase Orders');
          }

          return DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Purchase Order',
              isDense: true,
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
                value: entry.value['Id'], // Set the Id as the value
                child: Text(entry.value['name']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                // Check if newValue is not null
                if (newValue != null) {
                  selectedPurchaseOrder = newValue; // Set to selected Id
                  print('selected: $selectedPurchaseOrder');
                }
              });
            },
            value: selectedPurchaseOrder, // Ensure this is int?
          );
        }
      },
    );
  }
}
