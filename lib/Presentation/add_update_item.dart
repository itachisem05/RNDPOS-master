import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rndpo/Presentation/barcode.dart'; //barcode
import 'package:rndpo/screens/menu_screen.dart';
import 'package:rndpo/widgets/autocomplete.dart';
import '../API/api_service.dart';
import '../widgets/app_bar.dart';

class AddUpdateItem extends StatefulWidget {
  const AddUpdateItem({super.key});

  @override
  State<AddUpdateItem> createState() => _AddUpdateItemState();
}

class _AddUpdateItemState extends State<AddUpdateItem> {
  late final ApiService _apiService;
  late Future<Map<int, Map<String, dynamic>>> _departmentsFuture;
  late Future<Map<int, Map<String, dynamic>>> _packFuture;
  late Future<Map<int, Map<String, dynamic>>> _groupFuture;
  late Future<Map<int, Map<String, dynamic>>> _sizeFuture;
  late final BarcodeScannerService _barcodeScannerService; //barcode
  List<Map<String, dynamic>> autoCompleteItems = []; // To hold API result items

  int? _selectedDepartmentId;
  int? _selectedPackId;
  int? _selectedGroupId;
  int? _selectedSizeId;

  bool _isChecked = false;

  final TextEditingController _skuIdController = TextEditingController();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();

  final FocusNode _skuIdFocusNode = FocusNode();

  String id = "";
  String skuId = "";
  String name = "";
  String department = "";
  String pack = "";
  String size = "";
  String group = "";
  String purchaseprice = "";
  String sellingprice = "";
  String _barcode = '';

  Map<int, Map<String, dynamic>> _departments = {};
  Map<int, Map<String, dynamic>> _sizes = {};
  Map<int, Map<String, dynamic>> _packs = {};
  Map<int, Map<String, dynamic>> _groups = {};

  void _showAddProductDialog(String barcode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No product found'),
          content: Text('Do you want to add a new product #$barcode?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  // Assign barcode to skuId
                  skuId = barcode;
                  // Clear the SKU controller and other fields
                  _skuIdController.clear();
                  _itemNameController.clear();
                  _purchasePriceController.clear();
                  _sellingPriceController.clear();
                  _selectedDepartmentId = null;
                  _selectedPackId = null;
                  _selectedSizeId = null;
                  _selectedGroupId = null;
                  _isChecked = false;
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                // If user selects No, clear the SKU controller and show snackbar
                Navigator.of(context).pop(); // Close the dialog
                _clearFields();
                FocusScope.of(context).requestFocus(_skuIdFocusNode);
              },
              child: Text('No'),
            ),
          ],
        );
      },
    ).then((_) {
      // Handle any actions after the dialog closes if needed
    });
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _departmentsFuture = _apiService.getAllDepartment();
    _packFuture = _apiService.getAllPack();
    _groupFuture = _apiService.getAllGroup();
    _sizeFuture = _apiService.getAllSize();
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

  @override
  void dispose() {
    _skuIdController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _itemNameController.dispose();
    _skuIdFocusNode.dispose();
    super.dispose();
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
        // Show dialog to add a new product
        _showAddProductDialog(_skuIdController.text);
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }


  void _getProductMaster() async {
    try {
      var data = await _apiService.getProductMaster(id);
      if (data.isNotEmpty) {
        setState(() {
          skuId = data['productSKU'].toString();
          name = data['productName']?.toString() ?? '';
          department = data['departmentID']?.toString() ?? '';
          pack = data['packID']?.toString() ?? '';
          size = data['sizeID']?.toString() ?? '';
          group = data['productGroupID']?.toString() ?? '';
          purchaseprice = data['purchasePrice']?.toString() ?? '';
          sellingprice = data['sellingPrice']?.toString() ?? '';
          _isChecked = data['isNonTaxable'] ?? false;

          _itemNameController.text = name;
          _purchasePriceController.text = purchaseprice;
          _sellingPriceController.text = sellingprice;

          _selectedDepartmentId = int.tryParse(department);
          _selectedPackId = int.tryParse(pack);
          _selectedSizeId = int.tryParse(size);
          _selectedGroupId = int.tryParse(group);
        });
      }
    } catch (e) {
      print('An error occurred while fetching product master data: $e');
    }
  }

  Widget _buildDropdownField(
      String label,
      Map<int, Map<String, dynamic>>? data,
      int? selectedValue,
      ValueChanged<int?> onChanged, {
        bool isLoading = false,
        bool hasError = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
      child: DropdownButtonFormField<int>(
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
        dropdownColor: Colors.white,
        value: selectedValue,
        items: isLoading || hasError // Return empty list if loading or has error
            ? []
            : data?.entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value['name'] ?? ''),
          );
        }).toList(),
        onChanged: isLoading || hasError ? null : onChanged,
        hint: isLoading ? const Text('Loading...') : null,
        isExpanded: false,
        isDense: true,
      ),
    );
  }

  bool _validateInputs() {

    final productName = _itemNameController.text;
    final departmentID = _selectedDepartmentId;
    final sizeID = _selectedSizeId;
    final packID = _selectedPackId;


    if (productName.isEmpty) {
      _showError('Name cannot be empty');
      return false;
    }
    if (departmentID == null || departmentID <= 0) {
      _showError('Please select a department');
      return false;
    }
    if (sizeID == null || sizeID <= 0) {
      _showError('Please select a size');
      return false;
    }
    if (packID == null || packID <= 0) {
      _showError('Please select a pack');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red, // Set the background color to red
        duration: const Duration(
            seconds:
                3), // Optional: Set duration for how long the Snackbar is visible
      ),
    );
    print('Validation error: $message');
  }

  Future<void> _saveProduct() async {
    if (!_validateInputs()) {
      return; // Exit if validation fails
    }
    final productSKU = skuId;
    final productName = _itemNameController.text;
    final departmentID = _selectedDepartmentId ?? 0;
    final packID = _selectedPackId ?? 0;
    final sizeID = _selectedSizeId ?? 0;
    final categoryID = 0;
    final subCategoryID = 0;
    final packagingID = 11;
    final productTypeID = 0;
    final productGroupID = _selectedGroupId ?? 0;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
    final isTaxable = _isChecked;

    print('Product SKU: $productSKU');
    print('Product Name: $productName');
    print('Department ID: $departmentID');
    print('Pack ID: $packID');
    print('Size ID: $sizeID');
    print('Category ID: $categoryID');
    print('Sub-Category ID: $subCategoryID');
    print('Packaging ID: $packagingID');
    print('Product Type ID: $productTypeID');
    print('Product Group ID: $productGroupID');
    print('Purchase Price: $purchasePrice');
    print('Selling Price: $sellingPrice');
    print('Is Taxable: $isTaxable');

    try {
      await _apiService.postSaveProduct(
        id: id.isNotEmpty ? id : '0',
        productSKU: productSKU,
        productName: productName,
        departmentID: departmentID,
        packID: packID,
        sizeID: sizeID,
        categoryID: categoryID,
        subCategoryID: subCategoryID,
        packagingID: packagingID,
        productTypeID: productTypeID,
        productGroupID: productGroupID,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        isTaxable: isTaxable,
      );

      // Clear fields
      _clearFields();

      // Focus back to SKU ID field
      _skuIdFocusNode.requestFocus();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully')),
      );
      print('Product saved successfully');
    } catch (error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: $error')),
      );
      print('Error saving product: $error');
    }
  }

  void _clearFields() {
    setState(() {
      skuId = "";
      _skuIdController.clear();
      _itemNameController.clear();
      _purchasePriceController.clear();
      _sellingPriceController.clear();
      _selectedDepartmentId = null;
      _selectedPackId = null;
      _selectedSizeId = null;
      _selectedGroupId = null;
      _isChecked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const CustomAppBar(
        title: 'Add/Update Item',
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barcode Section
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
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      SvgPicture.asset('assets/images/cam.svg'),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    checkCameraPermission();
                                  }, // Implement camera functionality
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
                          _getProductMaster();  // Call your function
                          autoCompleteItems.clear();  // Clear the items
                          _skuIdController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // SKU Section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'SKU: $skuId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00255D),
                  ),
                ),
              ),
              // Item Name Section
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
                child: TextField(
                  controller: _itemNameController,
                  onTap: () => _itemNameController.selection = TextSelection(baseOffset: 0, extentOffset: _itemNameController.value.text.length),
                  decoration: InputDecoration(
                    labelText: 'Item Name',
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
                ),
              ),
              // Department Dropdown
              FutureBuilder<Map<int, Map<String, dynamic>>>(
                future: _departmentsFuture,
                builder: (context, snapshot) {
                  _departments = snapshot.data ?? {};
                  return _buildDropdownField(
                    'Department',
                    _departments,
                    _selectedDepartmentId,
                        (value) {
                      setState(() {
                        _selectedDepartmentId = value;
                      });
                    },
                    isLoading: snapshot.connectionState == ConnectionState.waiting,
                    hasError: snapshot.hasError,
                  );
                },
              ),
              // Pack Dropdown
              FutureBuilder<Map<int, Map<String, dynamic>>>(
                future: _packFuture,
                builder: (context, snapshot) {
                  // Extract the packs data
                  _packs = snapshot.data ?? {};

                  return _buildDropdownField(
                    'Pack',
                    _packs,
                    _selectedPackId,
                        (value) {
                      setState(() {
                        _selectedPackId = value;
                      });
                    },
                    isLoading: snapshot.connectionState == ConnectionState.waiting,
                    hasError: snapshot.hasError,
                  );
                },
              ),
              // Size Dropdown
              // Size Dropdown
              FutureBuilder<Map<int, Map<String, dynamic>>>(
                future: _sizeFuture,
                builder: (context, snapshot) {
                  _sizes = snapshot.data ?? {};
                  return _buildDropdownField(
                    'Size',
                    _sizes,
                    _selectedSizeId,
                        (value) {
                      setState(() {
                        _selectedSizeId = value;
                      });
                    },
                    isLoading: snapshot.connectionState == ConnectionState.waiting,
                    hasError: snapshot.hasError,
                  );
                },
              ),

// Group Dropdown
              FutureBuilder<Map<int, Map<String, dynamic>>>(
                future: _groupFuture,
                builder: (context, snapshot) {
                  _groups = snapshot.data ?? {};
                  return _buildDropdownField(
                    'Group',
                    _groups,
                    _selectedGroupId,
                        (value) {
                      setState(() {
                        _selectedGroupId = value;
                      });
                    },
                    isLoading: snapshot.connectionState == ConnectionState.waiting,
                    hasError: snapshot.hasError,
                  );
                },
              ),

              // Purchase Price Field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _purchasePriceController,
                  onTap: () => _purchasePriceController.selection = TextSelection(baseOffset: 0, extentOffset: _purchasePriceController.value.text.length),
                  decoration: InputDecoration(
                    labelText: 'Purchase Price',
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
                    LengthLimitingTextInputFormatter(6),
                    // Restrict input to 6 characters
                  ],
                ),
              ),
              // Selling Price Field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _sellingPriceController,
                  onTap: () => _sellingPriceController.selection = TextSelection(baseOffset: 0, extentOffset: _sellingPriceController.value.text.length),
                  decoration: InputDecoration(
                    labelText: 'Selling Price',
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
                    LengthLimitingTextInputFormatter(6),
                    // Restrict input to 6 characters
                  ],
                ),
              ),
              // Taxable Checkbox
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _isChecked = value ?? false;
                        });
                      },
                    ),
                    const Text('Is Taxable'),
                  ],
                ),
              ),
              // Save Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00255D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save & Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
