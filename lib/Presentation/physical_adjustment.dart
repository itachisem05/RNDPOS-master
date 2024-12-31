import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usa/API/api_service.dart';
import 'package:usa/Presentation/barcode.dart';
import 'package:usa/widgets/autocomplete.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:usa/Presentation/barcode.dart';

class PhysicalAdjustment extends StatefulWidget {
  const PhysicalAdjustment({super.key});

  @override
  State<PhysicalAdjustment> createState() => _PhysicalAdjustmentState();
}

class _PhysicalAdjustmentState extends State<PhysicalAdjustment> {
  late final ApiService _apiService;
  final TextEditingController _skuIdController = TextEditingController();
  final TextEditingController _onHandQuantityController =
      TextEditingController();
  final FocusNode _skuIdFocusNode = FocusNode();
  final FocusNode _onHandFocusNode = FocusNode();
  late final BarcodeScannerService _barcodeScannerService;
  List<Map<String, dynamic>> autoCompleteItems = []; // To hold API result items
  late Future<Map<int, Map<String, dynamic>>> _transactionCodesFuture;

  int? selectedTransactionCode;

  String _barcode = '';
  String id = "";
  String skuId = "";
  String name = "";
  String pack = "";
  String size = "";

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _barcodeScannerService = BarcodeScannerService();
    _transactionCodesFuture = _apiService.getAllTransactionCodeForAdjustment();
  }

  @override
  void dispose() {
    _skuIdController.dispose();
    _onHandQuantityController.dispose();
    _skuIdFocusNode.dispose();
    _onHandFocusNode.dispose();
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
      _getAutoComplete();
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
        FocusScope.of(context).requestFocus(_skuIdFocusNode);
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

  Future<void> _getProductMaster() async {
    try {
      var data = await _apiService.getProductMaster(id);
      if (data.isNotEmpty) {
        setState(() {
          skuId = data['productSKU'].toString();
          name = data['productName'].toString();
          pack = data['packName'].toString();
          size = data['sizeName'].toString();
        });
        FocusScope.of(context).requestFocus(_onHandFocusNode);
      } else {
        _showSnackbar('No product data found', Colors.red);
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }

  Future<void> _postUpdateInventory() async {
    try {
      print('Sending data to API:');
      print('Product ID: $id');
      print('On-hand Quantity: ${_onHandQuantityController.text}');
      print('selectedTransactionCode: $selectedTransactionCode');

      await _apiService.postUpdateInventory(
        int.parse(id),
        int.parse(_onHandQuantityController.text),
        selectedTransactionCode!,
      );

      setState(() {
        skuId = '';
        name = '';
        pack = '';
        size = '';
        selectedTransactionCode = null;
      });

      _onHandQuantityController.clear();
      _skuIdController.clear();

      _showSnackbar('Updated Inventory Successfully', Colors.green);
      FocusScope.of(context).requestFocus(_skuIdFocusNode);
    } catch (e) {
      print('An error occurred: $e');
    }
  }


  Widget _buildDropdown(
      String label, Future<Map<int, Map<String, dynamic>>> future,
      {ValueChanged<int?>? onChanged, int? value}) {
    return FutureBuilder<Map<int, Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a dropdown with loading state
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
            items: [],
            hint: const Text('Loading...'), // Placeholder while loading
            onChanged: null, // Disable interaction
          );
        } else if (snapshot.hasError) {
          // Show a dropdown with error state
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
            items: [],
            // Custom error message
            onChanged: null, // Disable interaction
          );
        } else {
          final data = snapshot.data ?? {};
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
            value: value,
            items: data.entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value['name'] ?? ''),
              );
            }).toList(),
            onChanged: onChanged, // Enable interaction
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const CustomAppBar(title: 'Physical Adjustment'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: 327,
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
                            'Scan product barcode',
                            style: TextStyle(
                              color: Color(0xFF00355E),
                              fontFamily: 'Inter-Regular',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Column(
                                children: [
                                  // SKU Input Box
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
                                                  controller: _skuIdController,
                                                  focusNode: _skuIdFocusNode,
                                                  onTap: () => _skuIdController.selection = TextSelection(baseOffset: 0, extentOffset: _skuIdController.value.text.length),
                                                  onSubmitted: (_) {
                                                    _getAutoComplete();
                                                  },
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
                                                  keyboardType:
                                                  TextInputType.number,
                                                  inputFormatters: <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
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
                                        this.id = id;  // Update the id
                                        _getProductMaster();  // Call your function
                                        autoCompleteItems.clear();  // Clear the items
                                      });
                                    },
                                  )
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductDetailRow('SKU: ', skuId),
                          _buildProductDetailRow('Name: ', name),
                          _buildProductDetailRow('Pack: ', pack),
                          _buildProductDetailRow('Size: ', size),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildDropdown('Reason', _transactionCodesFuture, onChanged: (value) {
                setState(() {
                  selectedTransactionCode = value;
                  print('selectedTransactionCode: $selectedTransactionCode');
                });
              }, value: selectedTransactionCode),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 50,
                    child: TextField(
                      controller: _onHandQuantityController,
                      focusNode: _onHandFocusNode,
                      onTap: () => _onHandQuantityController.selection = TextSelection(baseOffset: 0, extentOffset: _onHandQuantityController.value.text.length),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter Onhand Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF8FBBFF), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF8FBBFF), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF8FBBFF), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 110,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        final skuID = _skuIdController.text;
                        final onHandQuantity = _onHandQuantityController.text;

                        if (skuID.isEmpty) {
                          _showSnackbar('Please enter a SKU ID', Colors.red);
                        } else if (onHandQuantity.isEmpty ||
                            int.tryParse(onHandQuantity) == null ||
                            int.parse(onHandQuantity) <= 0) {
                          _showSnackbar('Please enter a proper on-hand quantity',
                              Colors.red);
                        } else if (selectedTransactionCode == null) {
                          _showSnackbar('Please select a Reason', Colors.red);
                        } else {
                          _postUpdateInventory();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00255D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Save & Next',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildProductDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF00255D),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF00255D)),
            overflow: TextOverflow.clip,
            softWrap: true,
          ),
        ),
      ],
    );
  }


}

//Original
