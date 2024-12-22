
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerService {
  Future<String> scanBarcode(BuildContext context) async {
    try {
      await Future.delayed(Duration(milliseconds: 1000));

      String barcode;
      int attempts = 0;

      do {
        barcode = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666',
          'Cancel',
          true,
          ScanMode.BARCODE,
        );

        attempts++;
      } while (barcode == '-1' && attempts < 2); // Retry up to 2 times

      if (barcode != '-1') {
        return barcode.replaceAll(RegExp(r'[^0-9]'), '');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to scan barcode')),
      );
    }
    return '';
  }

  Future<void> checkCameraPermission(BuildContext context, Function(String) onSuccess) async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      final barcode = await scanBarcode(context);
      if (barcode.isNotEmpty) onSuccess(barcode);
    } else if (status.isDenied) {
      // Request permission
      final result = await Permission.camera.request();
      if (result.isGranted) {
        final barcode = await scanBarcode(context);
        if (barcode.isNotEmpty) onSuccess(barcode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
    } else {
      // Handle the case where permission is permanently denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is permanently denied. Please enable it in app settings.')),
      );
    }
  }
}
