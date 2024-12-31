import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:usa/Presentation/add_update_item.dart';
import 'package:usa/Presentation/home_screen.dart';
import 'package:usa/Presentation/inventory_item_report.dart';
import 'package:usa/Presentation/login_screen.dart';
import 'package:usa/Presentation/physical_inventory_count.dart';
import 'package:usa/Presentation/physical_inventory_count_finish.dart';
import 'package:usa/Presentation/printable_label.dart';
import 'package:usa/Presentation/purchase_order.dart';
import 'package:usa/Presentation/purchase_return.dart';
import 'package:usa/Presentation/receive_purchase_order.dart';
import 'package:usa/Presentation/sales_by_tender.dart';
import 'package:usa/Presentation/sales_tax_summery.dart';
import 'package:usa/Presentation/physical_adjustment.dart';
import 'package:usa/Presentation/sales_summery.dart';
import '../API/api_service.dart'; // Import the API service

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ApiService _apiService = ApiService(); // Initialize the API service
  Future<bool>? _inventoryStatusFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the inventory status future
    // _inventoryStatusFuture = _checkInventoryStatus();
  }

  void _onInventoryCountTap() {
    setState(() {
      _inventoryStatusFuture =
          _checkInventoryStatus(); // Initialize the future on tap
    });

    // Use then to handle navigation after the future completes
    _inventoryStatusFuture?.then((status) {
      _navigateTo(status
          ? const PhysicalInventoryCountFinish()
          : const PhysicalInventoryCount());
    }).catchError((e) {
      print('Error fetching inventory count status: $e');
      // You might want to show an error dialog or similar here
    });
  }

  Future<bool> _checkInventoryStatus() async {
    try {
      final status = await _apiService.getInventoryCountStatus();
      return status == 'true';
    } catch (e) {
      print('Error fetching inventory count status: $e');
      return false; // Return false in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          const Divider(color: Color(0xFF004DC8), thickness: 2),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem('homepage.svg', 'Home Page', () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (Route<dynamic> route) => false,
                  );
                }),
                _buildDrawerItem('physical_adjustment.svg', 'Physical Adjustment', () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const PhysicalAdjustment()),
                        (Route<dynamic> route) => route is HomeScreen,
                  );
                }),
                FutureBuilder<bool>(
                  future: _inventoryStatusFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildDrawerItem(
                        'physical_count.svg',
                        'Physical Inventory Count',
                            () {}, // No action during loading
                      );
                    } else {
                      return _buildDrawerItem(
                        'physical_count.svg',
                        'Physical Inventory Count',
                            () {
                          if (snapshot.hasError || !snapshot.hasData) {
                            _onInventoryCountTap(); // Call when there's an error or no data
                          } else {
                            // Navigate based on the inventory status
                            _navigateTo(snapshot.data!
                                ? const PhysicalInventoryCountFinish()
                                : const PhysicalInventoryCount());
                          }
                        },
                      );
                    }
                  },
                ),
                _buildDrawerItem('addupdate_item.svg', 'Add/Update Items', () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AddUpdateItem()),
                        (Route<dynamic> route) => true,
                  );
                }),
                _buildDrawerItem('print_labels.svg', 'Print Labels', () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const Printable()),
                        (Route<dynamic> route) => true,
                  );
                }),
                _buildReportsSection(),
                _buildDrawerItem('purchase_order.svg', 'Purchase Order', () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const PurchaseOrder()),
                        (Route<dynamic> route) => true,
                  );
                }),
                _buildDrawerItem('purchase_return.svg', 'Purchase Return', () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const PurchaseReturn()),
                        (Route<dynamic> route) => true,
                  );
                }),
                const SizedBox(height: 16), // Optional spacing
              ],
            ),
          ),
          // Spacer to push the Logout button to the bottom
          // const Spacer(),
          const Divider(color: Color(0xFFB6B8BB), thickness: 1),
      _buildDrawerItem('logout.svg', 'Log Out', () async {
        // Call the logout function to clear user data and set logout status
        await ApiService().logout(); // Make sure to call the logout method from an instance of ApiService


        // Navigate to the LoginScreen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false, // Ensure all previous routes are removed
        );
      }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16.0,
        right: 0.0,
        top: MediaQuery.of(context).padding.top + 16.0,
      ),
      child: Row(
        children: [
          SvgPicture.asset("assets/images/appbar_icon.svg",
              height: 40.0, width: 80.0),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String iconPath, String title, VoidCallback onTap) {
    return ListTile(
      leading: SvgPicture.asset("assets/images/$iconPath", color: Colors.black),
      title: Text(title,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Color(0xFF00355E))),
      onTap: onTap,
    );
  }

  Widget _buildReportItem(String iconPath, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 32.0),
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF004DC8), width: 1.0)),
      ),
      child: ListTile(
        leading:
            SvgPicture.asset("assets/images/$iconPath", color: Colors.black),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: Color(0xFF00355E))),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReportsSection() {
    return ExpansionTile(
      leading:
          SvgPicture.asset("assets/images/reports.svg", color: Colors.black),
      title: const Text("Reports",
          style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Color(0xFF00355E))),
      children: [
        _buildReportItem('sales_summery.svg', 'Sales Summary', () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SalesSummery()),
            (Route<dynamic> route) => route is HomeScreen,
          );
        }),
        _buildReportItem('sales_tender.svg', 'Sales by Tender', () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SalesByTender()),
            (Route<dynamic> route) => route is HomeScreen,
          );
        }),
        _buildReportItem('sales_tax.svg', 'Sales & Tax Summary', () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SalesTaxSummery()),
            (Route<dynamic> route) => route is HomeScreen,
          );
        }),
        _buildReportItem('inventory_item.svg', 'Inventory Item Report', () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const InventoryItemReport()),
            (Route<dynamic> route) => true,
          );
        }),
      ],
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}
