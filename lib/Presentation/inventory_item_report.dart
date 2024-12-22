import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:rndpo/API/api_service.dart';
import '../screens/menu_screen.dart';
import '../widgets/app_bar.dart';

class InventoryItemReport extends StatefulWidget {
  const InventoryItemReport({super.key});

  @override
  State<InventoryItemReport> createState() => _InventoryItemReportState();
}

class _InventoryItemReportState extends State<InventoryItemReport> {
  bool _isFilterVisible = true;
  late final ApiService _apiService;
  final TextEditingController _searchTextController = TextEditingController();
  List<Map<String, dynamic>> products = [];
  int currentPage = 1; // Declare to store the current page
  int totalPages = 1; // Declare to store the total pages

  late Future<Map<int, Map<String, dynamic>>> _departmentsFuture;
  late Future<Map<int, Map<String, dynamic>>> _suppliersFuture;
  late Future<Map<int, Map<String, dynamic>>> _sizesFuture;
  late Future<Map<int, Map<String, dynamic>>> _packsFuture;
  late Future<Map<int, Map<String, dynamic>>> _categoriesFuture;
  late Future<Map<int, Map<String, dynamic>>> _subCategoriesFuture;
  late Future<Map<int, Map<String, dynamic>>> _groupsFuture;
  late Future<Map<int, Map<String, dynamic>>> _statusesFuture;
  late Future<Map<int, Map<String, dynamic>>> _onHandStockFuture;

  int? selectedSupplier;
  int? selectedSize;
  int? selectedPack;
  int? selectedDepartment;
  int? selectedCategory;
  int? selectedSubCategory;
  int? selectedGroup;
  int? selectedStatus;
  int? selectedOnHandStock;
  bool _isLoading = false;
  bool isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool hasMoreData = false;
  bool _isResetLoading = false;
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _departmentsFuture = _apiService.getAllDepartment();
    _suppliersFuture = _apiService.getAllSupplier();
    _sizesFuture = _apiService.getAllSize();
    _packsFuture = _apiService.getAllPack();
    _categoriesFuture = Future.value({});
    _subCategoriesFuture = Future.value({});
    _groupsFuture = _apiService.getAllGroup();
    _statusesFuture = _apiService.getAllStatus();
    _onHandStockFuture = _apiService.getOnHandStock();
    _getInventorySearch();
  }

  Future<void> _getInventorySearch({
    int supplierID = 0,
    int sizeID = 0,
    int packID = 0,
    int departmentID = 0,
    int categoryID = 0,
    int subCategoryID = 0,
    int productGroupID = 0,
    int statusID = 1,
    int onHandFilter = 0,
    int itemGroupID = 0,
    int pageNo = 1,
    String searchString = "",
    String orderBy = "ProductID",
    String sortBy = "desc",
  }) async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      var response = await _apiService.getInventoryValue(
        productGroupID: productGroupID,
        categoryID: categoryID,
        subCategoryID: subCategoryID,
        departmentID: departmentID,
        packID: packID,
        sizeID: sizeID,
        statusID: statusID,
        supplierID: supplierID,
        onHandFilter: onHandFilter,
        itemGroupID: itemGroupID,
        pageNo: pageNo,
        searchString: searchString,
        orderBy: orderBy,
        sortBy: sortBy,
      );

      // Safely extract the product data from the response
      List<dynamic> productsData = response['data'];

      // Ensure productsData is a list of maps
      if (productsData is List) {
        products = productsData
            .where((item) => item is Map<String, dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      } else {
        products = [];
      }

      // Extract current page and total pages
      currentPage = response['currentPage'];
      totalPages = response['totalPages'];

      hasMoreData = currentPage < totalPages;

      print('Current page: $currentPage, Total pages: $totalPages');
      print('Total products loaded: ${products.length}');

      for (var product in products) {
        print(product); // Print each product separately
      }

      // Optionally, trigger a UI update
      setState(() {}); // Only if this is within a StatefulWidget
    } catch (e) {
      // Handle error appropriately
      print('Error loading inventory data: $e');
      // Optionally, show a message to the user
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }


  Future<void> _fetchInventoryData({int page = 1}) async {
    if (page < 1 || page > totalPages) return; // Out of bounds

    setState(() => isLoading = true);

    try {
      var response = await _apiService.getInventoryValue(
        productGroupID: selectedGroup ?? 0,
        categoryID: selectedCategory ?? 0,
        subCategoryID: selectedSubCategory ?? 0,
        departmentID: selectedDepartment ?? 0,
        packID: selectedPack ?? 0,
        sizeID: selectedSize ?? 0,
        statusID: selectedStatus ?? 1,
        supplierID: selectedSupplier ?? 0,
        onHandFilter: selectedOnHandStock ?? 0,
        pageNo: page,
        searchString: _searchTextController.text,
        orderBy: "ProductID",
        sortBy: "desc",
      );

      setState(() {
        if (page == 1) {
          products = response['data']; // Reset the product list
        } else {
          products.addAll(response['data']); // Append new data
        }

        currentPage = response['currentPage'];
        totalPages = response['totalPages'];
        hasMoreData = currentPage < totalPages;
        isLoading = false;
      });
    } catch (e) {
      print('An error occurred: $e');
      setState(() {
        isLoading = false;
        hasMoreData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load inventory data')),
      );
    }
  }

  void _loadMoreData() {
    if (hasMoreData) {
      _fetchInventoryData(page: currentPage + 1);
      print('Loaded more products: ${products.length}');
    }
  }

  void _onDepartmentSelected(int? value) {
    setState(() {
      selectedDepartment = value;
      selectedCategory = null; // Reset category when department changes
      _categoriesFuture =
          value != null ? _apiService.getAllCategory(value) : Future.value({});
      _subCategoriesFuture = Future.value({}); // Reset subcategories
    });
  }

  void _onCategorySelected(int? value) {
    setState(() {
      selectedCategory = value;
      _subCategoriesFuture = value != null
          ? _apiService.getAllSubCategory(value)
          : Future.value({});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MenuScreen(),
      appBar: const CustomAppBar(title: 'Reports'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inventory Item Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00255D),
                    ),
                  ),
                  IconButton(
                    icon: SvgPicture.asset('assets/images/filter.svg'),
                    onPressed: () {
                      setState(() {
                        _isFilterVisible = !_isFilterVisible;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isFilterVisible) _buildFilterPanel(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.isEmpty ? 1 : products.length, // Check if products list is empty
                itemBuilder: (context, index) {
                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        'No data found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  final product = products[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F8FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProductDetailRow('SKU: ', product['productSKU'] ?? 'N/A'),
                            const SizedBox(height: 5), // Vertical space
                            _buildProductDetailRow('Name: ', product['productName'] ?? 'N/A'),
                            const SizedBox(height: 5), // Vertical space
                            _buildProductDetailRow('Dept.: ', product['departmentName'] ?? 'N/A'),
                          ],
                        ),
                        const SizedBox(height: 5), // Vertical space
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'On Hand:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${product['onHand'] ?? 0}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Current:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$${(product['currentValue'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5), // Vertical space
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Purchase:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$${(product['purchasePrice'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Selling:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$${(product['sellingPrice'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xFF00355E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              Center(
                child: SizedBox(
                  width: 320,
                  height: 45, 
                  child: OutlinedButton(
                    onPressed: () {
                      _loadMoreData();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00355E),
                      side: const BorderSide(color: Color(0xFFA4D5FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Load More'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchTextController,
            onTap: () => _searchTextController.selection = TextSelection(baseOffset: 0, extentOffset: _searchTextController.value.text.length),
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(15.0),
                child: SvgPicture.asset(
                  'assets/images/search.svg',
                ),
              ),
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
          const SizedBox(height: 15),
          _buildDropdown('Supplier', _suppliersFuture, onChanged: (value) {
            setState(() {
              selectedSupplier = value;
              print('Supplier: $selectedSupplier');
            });
          }, value: selectedSupplier),
          const SizedBox(height: 15),
          _buildDropdown('Size', _sizesFuture, onChanged: (value) {
            setState(() {
              selectedSize = value;
              print('Size: $selectedSize');
            });
          }, value: selectedSize),
          const SizedBox(height: 15),
          _buildDropdown('Pack', _packsFuture, onChanged: (value) {
            setState(() {
              selectedPack = value;
              print('Pack: $selectedPack');
            });
          }, value: selectedPack),
          const SizedBox(height: 15),
          _buildDropdown(
            'Department',
            _departmentsFuture,
            onChanged: (newValue) {
              print('Selected Department: $newValue'); // Print statement
              _onDepartmentSelected(newValue);
            },
            value: selectedDepartment,
          ),
          const SizedBox(height: 15),
          _buildDropdown(
            'Category',
            _categoriesFuture,
            onChanged: (newValue) {
              print('Selected Category: $newValue'); // Print statement
              _onCategorySelected(newValue);
            },
            value: selectedCategory,
          ),
          const SizedBox(height: 15),
          _buildDropdown('Sub Category', _subCategoriesFuture,
              onChanged: (value) {
            setState(() {
              selectedSubCategory = value; // Store selected subcategory ID
              print('Sub Category: $selectedSubCategory');
            });
          }, value: selectedSubCategory),
          const SizedBox(height: 15),
          _buildDropdown('Group', _groupsFuture, onChanged: (value) {
            setState(() {
              selectedGroup = value;
              print('Group: $selectedGroup');
            });
          }, value: selectedGroup),
          const SizedBox(height: 15),
          _buildDropdown('Status', _statusesFuture, onChanged: (value) {
            setState(() {
              selectedStatus = value;
              print('Status: $selectedStatus');
            });
          }, value: selectedStatus),
          const SizedBox(height: 15),
          _buildDropdown('On Hand Stock', _onHandStockFuture,
              onChanged: (value) {
            setState(() {
              selectedOnHandStock = value;
              print('On Hand Stock: $selectedOnHandStock');
            });
          }, value: selectedOnHandStock),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isResetLoading = true;
                    });

                    // Reset all filter variables to null
                    selectedSupplier = null;
                    selectedSize = null;
                    selectedPack = null;
                    selectedDepartment = null;
                    selectedCategory = null;
                    selectedSubCategory = null;
                    selectedGroup = null;
                    selectedStatus = null;
                    selectedOnHandStock = null;

                    // Clear the search text controller
                    _searchTextController.clear();
                    performInventorySearch();

                    // Simulate a delay
                    Future.delayed(const Duration(seconds: 2), () {
                      setState(() {
                        _isResetLoading = false;
                      });
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00255D),
                    side: const BorderSide(color: Color(0xFF00255D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: _isResetLoading
                      ? const SizedBox(
                          width: 15, // Adjust width as needed
                          height: 15, // Adjust height as needed
                          child: CircularProgressIndicator(
                              strokeWidth: 2), // Adjust stroke width if desired
                        )
                      : const Text('Reset'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isSearchLoading = true;
                    });

                    performInventorySearch();

                    // Simulate a delay
                    Future.delayed(const Duration(seconds: 2), () {
                      setState(() {
                        _isSearchLoading = false;
                      });
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00255D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: _isSearchLoading
                      ? const SizedBox(
                          width: 15, // Adjust width as needed
                          height: 15, // Adjust height as needed
                          child: CircularProgressIndicator(
                              strokeWidth: 2), // Adjust stroke width if desired
                        )
                      : const Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white, // Set the text color to white
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void performInventorySearch() {
    _getInventorySearch(
      supplierID: selectedSupplier ?? 0,
      sizeID: selectedSize ?? 0,
      packID: selectedPack ?? 0,
      departmentID: selectedDepartment ?? 0,
      categoryID: selectedCategory ?? 0,
      subCategoryID: selectedSubCategory ?? 0,
      productGroupID: selectedGroup ?? 0,
      statusID: selectedStatus ?? 1,
      onHandFilter: selectedOnHandStock ?? 0,
      pageNo: 1,
      // Set to 1 for a fresh search
      searchString: _searchTextController.text,
      // Pass the search string
      orderBy: "ProductID",
      // Modify as needed
      sortBy: "desc", // Modify as needed
    );
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
