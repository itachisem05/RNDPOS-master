import 'package:flutter/material.dart';
import 'package:usa/Presentation/add_update_item.dart';
import 'package:usa/Presentation/home_screen.dart';
import 'package:usa/Presentation/info_screen.dart';
import 'package:usa/Presentation/login_screen.dart';
import 'package:usa/Presentation/null.dart';
import 'package:usa/Presentation/printable_create.dart';
import 'package:usa/Presentation/printable_label_edit.dart';
import 'package:usa/Presentation/purchase_order_create.dart';
import 'package:usa/Presentation/purchase_order_edit.dart';
import 'package:usa/Presentation/purchase_return_create.dart';
import 'package:usa/Presentation/purchase_return_edit.dart';
import 'package:usa/Presentation/splash_screen.dart';
import 'package:usa/screens/menu_screen.dart';
import 'package:usa/Presentation/physical_adjustment.dart';
import 'package:usa/Presentation/inventory_item_report.dart';
import 'package:usa/Presentation/physical_inventory_count.dart';
import 'package:usa/Presentation/physical_inventory_count_finish.dart';
import 'package:usa/Presentation/purchase_order.dart';
import 'package:usa/Presentation/receive_purchase_order.dart';
import 'package:usa/Presentation/sales_by_tender.dart';
import 'package:usa/Presentation/sales_summery.dart';
import 'package:usa/Presentation/sales_tax_summery.dart';
import 'package:usa/Presentation/purchase_return.dart';
import 'package:usa/Presentation/notification_screen.dart';
import 'package:usa/Presentation/printable_label.dart';

class AppRoutes {
  static const String splashScreen = '/splash';
  static const String underDevelopment = '/under_development';
  static const String loginScreen = '/login';
  static const String homeScreen = '/home';
  static const String menuScreen = '/menu';
  static const String physicalAdjustment = '/physical_adjustment';
  static const String addUpdate = '/add_update';
  static const String infoScreen = '/info';
  static const String inventoryItemReport = '/inventory_item_report';
  static const String physicalInventoryCount = '/physical_inventory_count';
  static const String purchaseOrder = '/purchase_order';
  static const String receivePurchaseOrder = '/receive_purchase_order';
  static const String salesByTender = '/sales_by_tender';
  static const String salesSummery = '/sales_summery';
  static const String salesTaxSummery = '/sales_tax_summery';
  static const String purchaseReturn = '/purchase_return';
  static const String physicalInventoryCountFinish = '/physical_inventory_count_finish';
  static const String notificationScreen = '/notification_screen';
  static const String printable = '/printable_label';
  static const String printableCreate = '/printable_create';
  static const String printableEdit = '/printable_label_edit';
  static const String purchaseOrderCreate = '/purchase_order_create';
  static const String purchaseOrderEdit = '/purchase_order_edit';
  static const String purchaseReturnCreate = '/purchase_return_create';
  static const String purchaseReturnEdit = '/purchase_return_edit';

  static Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    splashScreen: (context) => const SplashScreen(versionNumber: '1.0.0'),
    underDevelopment: (context) => UnderDevelopmentScreen(),
    loginScreen: (context) => LoginScreen(),
    homeScreen: (context) => const HomeScreen(),
    menuScreen: (context) => MenuScreen(),
    physicalAdjustment: (context) => const PhysicalAdjustment(),
    addUpdate: (context) => const AddUpdateItem(),
    infoScreen: (context) => const InfoScreen(),
    inventoryItemReport: (context) => const InventoryItemReport(),
    physicalInventoryCount: (context) => const PhysicalInventoryCount(),
    purchaseOrder: (context) => const PurchaseOrder(),
    purchaseReturn: (context) => const PurchaseReturn(),
    receivePurchaseOrder: (context) => const ReceivePurchaseOrder(purchaseReturnId: 0,),
    salesByTender: (context) => const SalesByTender(),
    salesSummery: (context) => const SalesSummery(),
    salesTaxSummery: (context) => const SalesTaxSummery(),
    physicalInventoryCountFinish: (context) => const PhysicalInventoryCountFinish(),
    notificationScreen: (context) => NotificationScreen(id: 0,  fromDate: DateTime.now(), toDate: DateTime.now(),),
    printable: (context) => const Printable(),
    printableCreate: (context) => const PrintableCreate(),
    printableEdit: (context) => const PrintableLabelEdit(labelTxnID: 0,),
    purchaseOrderCreate: (context) => const PurchaseOrderCreate(),
    purchaseOrderEdit: (context) => const PurchaseOrderEdit(purchaseOrder: 0,),
    purchaseReturnCreate: (context) => const PurchaseReturnCreate(),
    purchaseReturnEdit: (context) => const PurchaseReturnEdit(purchaseReturnId: 0,),
  };
}
