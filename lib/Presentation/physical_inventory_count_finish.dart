import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rndpo/API/api_service.dart';
import 'package:rndpo/Presentation/physical_inventory_count.dart';
import 'package:rndpo/widgets/autocomplete.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';
import 'home_screen.dart';
import 'package:rndpo/Presentation/barcode.dart';

class PhysicalInventoryCountFinish extends StatefulWidget {
  const PhysicalInventoryCountFinish({super.key});

  @override
  State<PhysicalInventoryCountFinish> createState() =>
      _PhysicalInventoryCountFinishState();
}

class _PhysicalInventoryCountFinishState
    extends State<PhysicalInventoryCountFinish> {
  late final ApiService _apiService;
  final TextEditingController _skuIdController = TextEditingController();
  final TextEditingController _onHandQuantityController =
      TextEditingController();
  final FocusNode _skuIdFocusNode = FocusNode();
  final FocusNode _onHandFocusNode = FocusNode();
  late final BarcodeScannerService _barcodeScannerService;
  List<Map<String, dynamic>> autoCompleteItems = [];
  String id = "";
  String skuId = "";
  String name = "";
  String pack = "";
  String size = "";
  String _barcode = '';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _barcodeScannerService = BarcodeScannerService();
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
        // Automatically request focus on the on-hand quantity field
        FocusScope.of(context).requestFocus(_onHandFocusNode);
      } else {
        // Show a snackbar if no data is fetched
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No product data found',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
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

      await _apiService.postInventoryCount(
        int.parse(id),
        int.parse(_onHandQuantityController.text),
      );

      setState(() {
        skuId = '';
        name = '';
        pack = '';
        size = '';
      });

      _onHandQuantityController.clear();
      _skuIdController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inventory Count Update',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      FocusScope.of(context).requestFocus(_skuIdFocusNode);
    } catch (e) {
      print('An error occurred: $e');
    }
  }

  _getEndInventoryCount() async {
    try {
      var message = await _apiService.getEndInventoryCount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3), // Duration of the Snackbar
        ),
      );
    } catch (e) {
      // Handle the exception here
      print('An error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while fetching data'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish count?', style: TextStyle(fontFamily: 'Inter')),
        content: const Text('Are you sure you want to finish counting?',
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
              await _getEndInventoryCount();
              {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const HomeScreen()),
                      (Route<dynamic> route) => false, // Adjust as needed
                );
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
      appBar: const CustomAppBar(title: 'Physical Inventory Count'),
      body: SingleChildScrollView(  // Wrap the Padding with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 0),
                child: TextButton(
                  onPressed: () => _showFinishDialog(),
                  style: TextButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00255D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Finish Count',
                    style: TextStyle(
                      color: Color(0xFF00255D),
                      fontFamily: 'Inter', // Ensure the Inter font is available
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                                          onTap: () => _skuIdController.selection = TextSelection(baseOffset: 0, extentOffset: _skuIdController.value.text.length),
                                          focusNode: _skuIdFocusNode,
                                          onSubmitted: (String sku) {
                                            _getAutoComplete();
                                          },
                                          decoration: const InputDecoration(
                                            hintText: 'Scan or Enter Barcode',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                                horizontal: 10.0, vertical: 9),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter.digitsOnly,
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

                          // Autocomplete Options Below Input Box
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
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SKU:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00255D),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Name:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00255D),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pack:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00255D),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Size:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00255D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(skuId),
                                const SizedBox(height: 4),
                                Text(name),
                                const SizedBox(height: 4),
                                Text(pack),
                                const SizedBox(height: 4),
                                Text(size),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 50,
                    child: TextField(
                      controller: _onHandQuantityController,
                      onTap: () => _onHandQuantityController.selection = TextSelection(baseOffset: 0, extentOffset: _onHandQuantityController.value.text.length),
                      focusNode: _onHandFocusNode,
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
                            color: Color(0xFF8FBBFF),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF8FBBFF),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF8FBBFF),
                            width: 1.5,
                          ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter a SKU ID',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (onHandQuantity.isEmpty ||
                            int.tryParse(onHandQuantity) == null ||
                            int.parse(onHandQuantity) <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter a proper on-hand quantity',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          // Call API to update inventory
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

}
