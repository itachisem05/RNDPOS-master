import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:usa/API/api_service.dart';
import 'package:usa/Presentation/barcode.dart';
import 'package:usa/Presentation/home_screen.dart';
import 'package:usa/Presentation/printable_label.dart';
import 'package:usa/widgets/autocomplete.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class PrintableCreate extends StatefulWidget {
  const PrintableCreate({super.key});

  @override
  State createState() => _PrintableCreateState();
}

class _PrintableCreateState extends State<PrintableCreate> {

  late final ApiService _apiService;
  final TextEditingController _skuIdController = TextEditingController();
  final TextEditingController _labelTitleController = TextEditingController();
  final TextEditingController _noOfCopiesController = TextEditingController();
  final FocusNode _skuFocusNode = FocusNode();
  final FocusNode _labelTitleFocusNode = FocusNode();
  final FocusNode _noOfCopiesFocusNode = FocusNode();
  late final BarcodeScannerService _barcodeScannerService;
  List<Map<String, dynamic>> autoCompleteItems = [];

  // Initialize items list to store card data
  List<Map<String, String>> items = [];
  List<Map<String, dynamic>> products = [];
  String _barcode = '';
  bool isLoading = false;
  String id = "";

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _barcodeScannerService = BarcodeScannerService();
  }


  @override
  void dispose() {
    _skuIdController.dispose();
    _labelTitleController.dispose();
    _noOfCopiesController.dispose();
    _skuFocusNode.dispose();
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

  void _getProductMaster(String id) async {
    try {
      var data = await _apiService.getProductMaster(id);
      if (data.isNotEmpty) {
        setState(() {
          // Add product to the items list for UI display
          items.add({
            'sku': data['productSKU'].toString(),
            'name': data['productName'].toString(),
          });

          // Create a new product entry and add it to the products list
          products.add({
            'labelProductTxnID': 0, // Default value
            'productID': id,
          });
          print('this is your products $products');
        });
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }


  void _postLabelSave() async {
    final labelTitle = _labelTitleController.text.trim();
    final numberOfCopies = _noOfCopiesController.text.trim();

    try {
      // Ensure the products list is populated
      if (products.isEmpty) {
        throw Exception('Products list is empty.');
      }

      // Call the API method with the populated list
      await _apiService.postLabelSave(
        labelTitle: labelTitle,
        numberOfCopies: numberOfCopies,
        products: products,
      );

      print('Label saved successfully.');

      // Clear fields and lists
      setState(() {
        _labelTitleController.clear();
        _noOfCopiesController.clear();
        _skuIdController.clear();
        items.clear();
        products.clear();
      });

      // Navigate to HomeScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Printable()),
            (Route<dynamic> route) => false,
      );

    } catch (e) {
      print('An error occurred while saving the label: $e');
    }
  }

  void _showDeleteDialog(int index) {
    final productIdToDelete = products[index]['productID']; // Get the productID of the item to be deleted

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?', style: TextStyle(fontFamily: 'Inter')),
        content: const Text('Are you sure you want to delete this label?'),
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
                // Remove the item from the UI list
                items.removeAt(index);

                // Remove the corresponding product from the products list
                products.removeWhere((product) => product['productID'] == productIdToDelete);

                // Print the updated lists to the console
                print('Updated items list: $items');
                print('Updated products list: $products');
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Yes', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  void _validateAndSave() {
    final labelTitle = _labelTitleController.text.trim();
    final noOfCopies = _noOfCopiesController.text.trim();
    if (labelTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a label title.'),
        ),
      );
      return;
    }
    if (noOfCopies.isEmpty || int.tryParse(noOfCopies) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of copies.'),
        ),
      );
      return;
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The list of items is empty.'),
        ),
      );
      return;
    }

    // Proceed with Save & Next functionality
    _postLabelSave();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const CustomAppBar(title: 'Printable Label'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                              onTap: () => _skuIdController.selection = TextSelection(baseOffset: 0, extentOffset: _skuIdController.value.text.length),
                                              focusNode: _skuFocusNode,
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
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: SvgPicture.asset('assets/images/cam.svg'),
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
                                    _getProductMaster(id);  // Call your function
                                    autoCompleteItems.clear();  // Clear the items
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 360,
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 4.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      child: const Text(
                                                        'SKU:  ',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF00255D),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        constraints: const BoxConstraints(
                                                          maxWidth: double.infinity,
                                                        ),
                                                        child: Text(
                                                          items[index]['sku']!,
                                                          style: const TextStyle(color: Color(0xFF00255D)),
                                                          overflow: TextOverflow.clip,
                                                          softWrap: true,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 50,
                                                    child: const Text(
                                                      'Name: ',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF00255D),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      constraints: const BoxConstraints(
                                                        maxWidth: double.infinity,
                                                      ),
                                                      child: Text(
                                                        items[index]['name']!,
                                                        style: const TextStyle(color: Color(0xFF00255D)),
                                                        overflow: TextOverflow.clip,
                                                        softWrap: true,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 5.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              _showDeleteDialog(index);
                                            },
                                            child: SvgPicture.asset(
                                              'assets/images/delete2.svg',
                                              color: const Color(0xFF00255D),
                                              width: 20.0, // Set your desired width
                                              height: 20.0, // Set your desired height
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: Divider(
                                      thickness: 1,
                                      color: Color(0xFF8CB7DC),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          // Section to stay at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      flex: 2, // 75% of the space
                      child: TextField(
                        controller: _labelTitleController,
                        onTap: () => _labelTitleController.selection = TextSelection(baseOffset: 0, extentOffset: _labelTitleController.value.text.length),
                        focusNode: _labelTitleFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Title',
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
                        onEditingComplete: () {
                          // Move focus to the No of Copies field when Enter is pressed
                          FocusScope.of(context).requestFocus(_noOfCopiesFocusNode);
                        },
                      ),
                    ),
                    const SizedBox(width: 10), // Space between the two TextFields
                    Flexible(
                      flex: 1, // 25% of the space
                      child: TextField(
                        controller: _noOfCopiesController,
                        onTap: () => _noOfCopiesController.selection = TextSelection(baseOffset: 0, extentOffset: _noOfCopiesController.value.text.length),
                        focusNode: _noOfCopiesFocusNode,
                        decoration: InputDecoration(
                          labelText: '#copies',
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
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            _validateAndSave();
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
