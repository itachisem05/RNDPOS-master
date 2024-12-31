import 'package:http/http.dart' as http;
import 'package:usa/Presentation/purchase_order_edit.dart';
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final USER_OBJECT_STRING = 'user';
  final USER_TOKEN_STRING = 'token';

  Future<Map<String, dynamic>> fetchData(String endpoint) async {
    final response = await http.get(Uri.parse('${Config.apiUrl}/$endpoint'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

/*  // TODO: Function to handle login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/auth/token'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      // Store user data and token locally
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(USER_OBJECT_STRING, json.encode(data));
      await prefs.setString(USER_TOKEN_STRING, data['token']);

      return data;
    } else {
      // Log the response body for more details
      print('Login failed: ${response.body}');
      throw Exception('Failed to login: ${response.reasonPhrase}');
    }
  }

  // TODO: Function to fetch user data from local storage
  Future<Map<String, dynamic>?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(USER_OBJECT_STRING);
    if (userJson != null) {
      return json.decode(userJson);
    }
    return null;
  }

  // TODO: Function to fetch token from local storage
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(USER_TOKEN_STRING);
  }*/

  Future<void> refreshToken() async {
    print('Entered refreshToken...');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');

    if (username != null && password != null) {
      final data = await login(username, password);
    }
    print('Exited refreshToken.');
  }

  bool isTokenExpired(String? token) {
    print('Entered isTokenExpired...');
    if (token == null) return true;
    final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))));
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
    print('Exited isTokenExpired with: ${DateTime.now().isAfter(expirationDate)}');
    return DateTime.now().isAfter(expirationDate);
  }

  //todo ==============================================================================================================
  // TODO: Function to handle login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/auth/token'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      // Store user data and token locally
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(USER_OBJECT_STRING, json.encode(data));
      await prefs.setString(USER_TOKEN_STRING, data['token']);
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      print('$username');
      print('$password');


      // Set logout status to false upon successful login
      await setLogoutStatus(false);

      return data;
    } else {
      print('Login failed: ${response.body}');
      throw Exception('Failed to login: ${response.reasonPhrase}');
    }
  }

  // Function to set logout status
  Future<void> setLogoutStatus(bool isLoggedOut) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logout_status', isLoggedOut);
    print('$isLoggedOut');
  }

  // Function to fetch user data from local storage
  Future<Map<String, dynamic>?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(USER_OBJECT_STRING);
    if (userJson != null) {
      return json.decode(userJson);
    }
    return null;
  }

  // Function to fetch token from local storage
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(USER_TOKEN_STRING);

    if (isTokenExpired(token)) {
      await refreshToken(); // Handle token refresh
    }

    final SharedPreferences prefs2 = await SharedPreferences.getInstance();
    return prefs2.getString(USER_TOKEN_STRING);
  }

  // Function to fetch username from local storage
  Future<String?> getUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Function to fetch password from local storage
  Future<String?> getPassword() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('password');
  }

  // Function to handle logout
  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(USER_OBJECT_STRING);
    await prefs.remove(USER_TOKEN_STRING);
    await prefs.remove('username');
    await prefs.remove('password');

    // Set logout status to true
    await setLogoutStatus(true);
  }

  //todo ==============================================================================================================

  // TODO: Function to formate Date
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  // TODO: Function to Get Transaction count
  Future<Map<int, Map<String, dynamic>>> getTransactionCount(
      DateTime? fromDate, DateTime? toDate) async {
    // Format the dates to 'MM/DD/YYYY' format
    String formattedFromDate = _formatDate(fromDate);
    String formattedToDate = _formatDate(toDate);
    String? token = await getToken();

    // Print formatted dates to console for debugging
    // print('Formatted fromDate: $formattedFromDate, toDate: $formattedToDate');

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/Dashboard/GetTransactionCount?fromDate=$formattedFromDate&endDate=$formattedToDate'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    // print('Response status code: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // print('Decoded JSON data: $data');

      final Map<int, Map<String, dynamic>> processedData = {};

      for (var item in data) {
        final reasonID = item['reasonID'];
        final transactionCount = item['trnasactionCount'];
        final reasonText = item['reasonText'];

        processedData[reasonID] = {
          'trnasactionCount': transactionCount,
          'reasonText': reasonText,
        };
      }

      // print('Processed transaction data: $processedData');
      return processedData;
    } else {
      // print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  // TODO: Function to Get Department wise Sales
  Future<Map<String, Map<String, dynamic>>> departmentWise(
      DateTime? fromDate, DateTime? toDate) async {
    // Format the dates to 'MM/DD/YYYY' format
    String formattedFromDate = _formatDate(fromDate);
    String formattedToDate = _formatDate(toDate);
    String? token = await getToken();

    // Print formatted dates to console for debugging
    // print('Formatted fromDate: $formattedFromDate, toDate: $formattedToDate');

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/Report/DepartmentWise?fromDate=$formattedFromDate&endDate=$formattedToDate'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    // print('Response status code: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // print('Decoded JSON data: $data');

      final Map<String, Map<String, dynamic>> processedData = {};

      for (var item in data) {
        final departmentName = item['departmentName'];
        final netSales = item['netSales'];
        final totalTax = item['totalTax'];
        final grossSales = item['grossSales'];

        processedData[departmentName] = {
          'netSales': netSales,
          'totalTax': totalTax,
          'grossSales': grossSales,
        };
      }

      // print('Processed transaction data: $processedData');
      return processedData;
    } else {
      // print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO sales: Report

  //TODO Sales: Summary
  Future<Map<int, Map<String, dynamic>>> salesSummary(
      DateTime? fromDate, DateTime? toDate) async {
    // Format the dates to 'MM/DD/YYYY' format
    String formattedFromDate = _formatDate(fromDate);
    String formattedToDate = _formatDate(toDate);
    String? token = await getToken();

    // Print formatted dates to console for debugging
    // print('Formatted fromDate: $formattedFromDate, toDate: $formattedToDate');

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/Report/SalesSummary?fromDate=$formattedFromDate&endDate=$formattedToDate'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    // print('Response status code: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // print('Decoded JSON data: $data');

      final Map<int, Map<String, dynamic>> processedData = {};

      int idx = 0;

      for (var item in data) {
        final tenderType = item['tenderType'];
        final amountReceived = item['amountReceived'];

        processedData[idx++] = {
          'tenderType': tenderType,
          'amountReceived': amountReceived,
        };
      }

      // print('Processed transaction data: $processedData');
      return processedData;
    } else {
      // print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO Sales: Sales by Tender
  Future<Map<int, Map<String, dynamic>>> salesByTender(
      DateTime? fromDate, DateTime? toDate) async {
    // Format the dates to 'MM/DD/YYYY' format
    String formattedFromDate = _formatDate(fromDate);
    String formattedToDate = _formatDate(toDate);
    String? token = await getToken();

    // Print formatted dates to console for debugging
    // print('Formatted fromDate: $formattedFromDate, toDate: $formattedToDate');
    // print('Hello - Sales By Tender here...!');

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/Report/SalesByTender?fromDate=$formattedFromDate&endDate=$formattedToDate'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    // print('Response status code: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // print('Decoded JSON data: $data');

      final Map<int, Map<String, dynamic>> processedData = {};

      int idx = 0;

      for (var item in data) {
        final tenderType = item['tenderType'];
        final amountReceived = item['amountReceived'];
        final transactions = item['transactions'];
        final tenderPercentage = item['tenderPercentage'];

        processedData[idx++] = {
          'tenderType': tenderType,
          'amountReceived': amountReceived,
          'transactions': transactions,
          'tenderPercentage': tenderPercentage,
        };
      }

      // print('Processed transaction data: $processedData');
      return processedData;
    } else {
      // print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO Sales: Sales and Tax Summary
  Future<Map<int, Map<String, dynamic>>> salesAndTaxSummary(
      DateTime? fromDate, DateTime? toDate) async {
    // Check if dates are null
    if (fromDate == null || toDate == null) {
      throw ArgumentError('Both fromDate and toDate must be provided');
    }

    // Format the dates to 'MM/DD/YYYY' format
    String formattedFromDate = _formatDate(fromDate);
    String formattedToDate = _formatDate(toDate);
    String? token = await getToken();

    // Print formatted dates to console for debugging
    print('Formatted fromDate: $formattedFromDate, toDate: $formattedToDate');
    print('Hello - Sales By Tender here...!');

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/Report/SalesAndTaxSummary?fromDate=$formattedFromDate&endDate=$formattedToDate'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        final Map<int, Map<String, dynamic>> processedData = {};

        int idx = 0;

        for (var item in data) {
          final tenderType = item['tenderType'];
          final amountReceived = item['amountReceived'];
          final transactions = item['transactions'];

          processedData[idx++] = {
            'tenderType': tenderType,
            'amountReceived': amountReceived,
            'transactions': transactions,
          };
        }

        // print('Processed transaction data: $processedData');
        return processedData;
      } catch (e) {
        // print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : Autocomplete API -> getAutoComplete
  Future<Map<int, Map<String, dynamic>>> getAutoComplete(String skuId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/Product/GetAutoCompeleteProduct?sku=$skuId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    // print('Response status code: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        // print('Decoded JSON data: $data');

        final Map<int, Map<String, dynamic>> processedData = {};

        int idx = 0;

        for (var item in data) {
          final productID = item['productID'];
          final productSKU = item['productSKU'];
          final productName = item['productName'];

          processedData[idx++] = {
            'productID': productID,
            'productSKU': productSKU,
            'productName': productName,
          };
        }

        // print('Processed transaction data: $processedData');
        return processedData;
      } catch (e) {
        // print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      // print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : Autocomplete API -> getAutoCompleteBySupplier
  Future<Map<int, Map<String, dynamic>>> getAutoCompleteBySupplier(int supplierId, String skuId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/PurchaseOrder/AutoCompleteProductBySupplier?supplierID=$supplierId&query=$skuId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      try {
        final dynamic jsonResponse = json.decode(response.body);

        // Check if the response is a list or a map
        if (jsonResponse is List) {
          // If it's a list, handle it directly
          final Map<int, Map<String, dynamic>> processedData = {};

          int idx = 0;

          for (var item in jsonResponse) {
            final productID = item['id'];
            final productName = item['name'];

            processedData[idx++] = {
              'productID': productID,
              'productName': productName,
            };
          }

          return processedData;
        } else if (jsonResponse is Map && jsonResponse['message'] == 'No record round.') {
          throw Exception('No products found.');
        } else {
          throw Exception('Unexpected response format');
        }
      } catch (e) {
        throw Exception('Error decoding JSON data: $e');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  //TODO : Product Details  API -> getProductMaster
  Future<Map<String, dynamic>> getProductMaster(String productId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/Product/GetProductMaster?productID=$productId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract the required fields from the API response
        final Map<String, dynamic> processedData = {
          'sizeID': data['sizeID'] ?? '',
          'productSKU': data['productSKU'] ?? '',
          'productName': data['productName'] ?? '',
          'packID': data['packID'] ?? '',
          'departmentID': data['departmentID'] ?? '',
          'productGroupID': data['productGroupID'] ?? '',
          'purchasePrice': data['purchasePrice']?.toString() ?? '',
          'sellingPrice': data['sellingPrice']?.toString() ?? '',
          'onHand': data['onHand']?.toString() ?? '',
          'labelProductTxnID': data['labelProductTxnID']?.toString() ?? '',
          'packName': data['packName']?.toString() ?? '',
          'sizeName': data['sizeName']?.toString() ?? '',
          'isNonTaxable': data['isNonTaxble'] ?? false,
        };
        print('Data from getProductMaster: $processedData');
        return processedData;
      } catch (e) {
        throw Exception('Error decoding JSON data: $e');
      }
    } else {
      throw Exception(
          'Failed to load data, status code: ${response.statusCode}');
    }
  }

  //TODO : Product Details  API -> purchaseOrder getProduct master
  Future<Map<String, dynamic>> getPurchaseOrderProductMaster(String productId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/purchaseorder/GetProductMaster?productID=$productId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract the required fields from the API response
        final Map<String, dynamic> processedData = {
          'sizeID': data['sizeID'] ?? '',
          'productSKU': data['productSKU'] ?? '',
          'productName': data['productName'] ?? '',
          'packID': data['packID'] ?? '',
          'departmentID': data['departmentID'] ?? '',
          'productGroupID': data['productGroupID'] ?? '',
          'purchasePrice': data['purchasePrice']?.toString() ?? '',
          'sellingPrice': data['sellingPrice']?.toString() ?? '',
          'onHand': data['onHand']?.toString() ?? '',
          'labelProductTxnID': data['labelProductTxnID']?.toString() ?? '',
          'packName': data['packName']?.toString() ?? '',
          'sizeName': data['sizeName']?.toString() ?? '',
          'salesWeekAvg': data['salesWeekAvg']?.toString() ?? '',
          'isNonTaxable': data['isNonTaxble'] ?? false,
        };
        print('Data from getProductMaster: $processedData');
        return processedData;
      } catch (e) {
        throw Exception('Error decoding JSON data: $e');
      }
    } else {
      throw Exception(
          'Failed to load data, status code: ${response.statusCode}');
    }
  }

  //TODO : UpdateInventory API -> postUpdateInventory
  Future<void> postUpdateInventory(int productId, int onHand, int transactionCodeID) async {
    try {
      String? token = await getToken();
      if (token == null) {
        throw Exception('Token retrieval failed');
      }

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/Product/InventoryCount'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productID': productId,
          'onHand': onHand,
          'transactionCodeID': transactionCodeID
        }),
      );

      // Print the response for debugging purposes
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Inventory Count Updated');
      } else {
        throw Exception(
            'Failed to update inventory count with status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any other exceptions that may occur
      print('An error occurred: $e');
      throw e; // Re-throw the exception after logging
    }
  }

  //TODO : InventoryCount API -> postInventoryCount
  Future<void> postInventoryCount(int productId, int onHand) async {
    try {
      String? token = await getToken();
      if (token == null) {
        throw Exception('Token retrieval failed');
      }

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/Product/InventoryCount'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productID': productId,
          'onHand': onHand,
        }),
      );

      // Print the response for debugging purposes
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Inventory Count Updated');
      } else {
        throw Exception(
            'Failed to update inventory count with status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any other exceptions that may occur
      print('An error occurred: $e');
      throw e; // Re-throw the exception after logging
    }
  }

  //TODO : StartInventoryCount API -> getStartInventoryCount
  Future<String> getStartInventoryCount() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/Product/StartInventoryCount'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        // Extract and return the 'message' field
        final String message = data['message'] ?? 'No message available';
        return message;
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : EndInventoryCount API -> getEndInventoryCount
  Future<String> getEndInventoryCount() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/Product/EndInventoryCount'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        // Extract and return the 'message' field
        final String message = data['message'] ?? 'No message available';
        return message;
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO: GetInventoryCountStatus API -> Menu Drawer -> Physical Inventory Count
  Future<String> getInventoryCountStatus() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/Product/GetInventoryCountStatus'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        // Extract 'isActive' field and convert it to a string representation
        final bool isActive =
            data['isActive'] ?? false; // Default to false if 'isActive' is null
        return isActive
            ? 'true'
            : 'false'; // Return 'true' or 'false' as strings
      } catch (e) {
        print('Status error: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Status Error: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : GetAllDepartment API -> getAllDepartment -> AddUpate page - Department
  Future<Map<int, Map<String, dynamic>>> getAllDepartment() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/storemaster/GetAllDepartment'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> departments = {};
      for (var item in jsonData) {
        departments[item['id']] = {
          'name': item['name'],
        };
      }
      return departments;
    } else {
      throw Exception('Failed to load departments');
    }
  }

  //TODO : GetAllPack API -> getAllPack -> AddUpate page -Pack
  Future<Map<int, Map<String, dynamic>>> getAllPack() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/storemaster/GetAllPack'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    // print('Response status code: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> pack = {};
      for (var item in jsonData) {
        pack[item['id']] = {
          'name': item['name'],
        };
      }
      return pack;
    } else {
      throw Exception('Failed to load pack');
    }
  }

  //TODO : GetAllGroup API -> getAllGroup -> AddUpate page - Item Type
  Future<Map<int, Map<String, dynamic>>> getAllGroup() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/storemaster/GetAllGroup'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    // print('Response status code: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> itemType = {};
      for (var item in jsonData) {
        itemType[item['id']] = {
          'name': item['name'],
        };
      }
      return itemType;
    } else {
      throw Exception('Failed to load itemType');
    }
  }

  //TODO : GetAllSize API -> getAllSize -> AddUpate page - size
  Future<Map<int, Map<String, dynamic>>> getAllSize() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/storemaster/GetAllSize'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    // print('Response status code: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> size = {};
      for (var item in jsonData) {
        size[item['id']] = {
          'name': item['name'],
        };
      }
      return size;
    } else {
      throw Exception('Failed to load size');
    }
  }

  //TODO : /Product/SaveProduct API -> postSaveProduct -> addupdate
  Future<void> postSaveProduct({
    required String id,
    required String productSKU,
    required String productName,
    required int departmentID,
    required int packID,
    required int sizeID,
    int categoryID = 0, // default value
    int subCategoryID = 0, // default value
    int packagingID = 11, // default value
    int productTypeID = 0, // default value
    int productGroupID = 0, // default value
    double purchasePrice = 0.0,
    double sellingPrice = 0.0,
    bool isTaxable = false,
  }) async {
    String? token = await getToken();

    final response = await http.post(
      Uri.parse('${Config.apiUrl}/Product/SaveProduct'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "productID": id,
        "productSKU": productSKU,
        "productName": productName,
        "productDesc": "Startup's Friend",
        "departmentID": departmentID,
        "packID": packID,
        "sizeID": sizeID,
        "categoryID": categoryID,
        "subCategoryID": subCategoryID,
        "packagingID": packagingID,
        "productTypeID": productTypeID,
        "productGroupID": productGroupID,
        "onHand": 0, // assuming default value for 'onHand'
        "purchasePrice": purchasePrice,
        "sellingPrice": sellingPrice,
        "isTaxable": isTaxable,
      }),
    );

    if (response.statusCode == 200) {
      // Parse the response body if needed
      // Return data or a success indication here
      return;
    } else {
      // Handle error cases based on response
      throw Exception('Failed to save product: ${response.statusCode}');
    }
  }

  //TODO : StoreMaster/GetAllSupplier API -> GetAllSupplier -> Inventory Item Report
  Future<Map<int, Map<String, dynamic>>> getAllSupplier() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/storemaster/GetAllSupplier'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('getAllSupplier: Response status code: ${response.statusCode}');
    print('getAllSupplier: Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> allSupplier = {};
      for (var item in jsonData) {
        allSupplier[item['id']] = {
          'name': item['name'],
        };
      }
      return allSupplier;
    } else {
      throw Exception('getAllSupplier: Failed to load allSupplier');
    }
  }

  //TODO : StoreMaster/getAllTransactionCodeForAdjustment API -> GetAllTransactionCodeForAdjustment -> Physical Adjustment
  Future<Map<int, Map<String, dynamic>>> getAllTransactionCodeForAdjustment() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/storemaster/GetAllTransactionCodeForAdjustment'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('getAllTransactionCodeForAdjustment: Response status code: ${response.statusCode}');
    print('getAllTransactionCodeForAdjustment: Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> allTransactionCodes = {};
      for (var item in jsonData) {
        allTransactionCodes[item['id']] = {
          'name': item['name'],
        };
      }
      return allTransactionCodes;
    } else {
      throw Exception('getAllTransactionCodeForAdjustment: Failed to load allTransactionCodes');
    }
  }

  //TODO : StoreMaster/GetAllCategory API -> getAllCategory  -> Inventory Item Report
  Future<Map<int, Map<String, dynamic>>> getAllCategory(
      int departmentId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/storemaster/GetAllCategory?departmentID=$departmentId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> allCategory = {};

      for (var item in jsonData) {
        if (item['id'] != null && item['name'] != null) {
          allCategory[item['id']] = {
            'name': item['name'],
          };
        } else {
          print('Warning: Item missing id or name: $item');
        }
      }
      return allCategory;
    } else {
      final Map<String, dynamic> errorResponse = json.decode(response.body);
      throw Exception(
          'Failed to load categories: ${errorResponse['message'] ?? response.reasonPhrase}');
    }
  }

  //TODO : StoreMaster/GetAllSubCategory API -> getAllSubCategory -> Inventory Item Report
  Future<Map<int, Map<String, dynamic>>> getAllSubCategory(
      int subDepartmentId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/storemaster/GetAllSubCategory?categoryID=$subDepartmentId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> allSubCategory = {};
      for (var item in jsonData) {
        allSubCategory[item['id']] = {
          'name': item['name'],
        };
      }
      return allSubCategory;
    } else {
      throw Exception('Failed to load allSupplier');
    }
  }

  //TODO : StoreMaster/GetAllStatus API -> getAllStatus  -> Inventory Item Report
  Future<Map<int, Map<String, dynamic>>> getAllStatus() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/storemaster/GetAllStatus'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> allStatus = {};
      for (var item in jsonData) {
        allStatus[item['id']] = {
          'name': item['name'],
        };
      }
      return allStatus;
    } else {
      throw Exception('Failed to load allSupplier');
    }
  }

  //TODO: /storemaster/OnHandStock API -> getOnHandStock -> Inventory Item Report

  Future<Map<int, Map<String, dynamic>>> getOnHandStock() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/storemaster/OnHandStock'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final Map<int, Map<String, dynamic>> onHandStock = {};
      for (var item in jsonData) {
        onHandStock[item['id']] = {
          'name': item['name'],
        };
      }
      return onHandStock;
    } else {
      throw Exception('Failed to load onHandStock');
    }
  }

  //TODO : Report/InventoryValue API -> InventoryValue  -> Inventory Item Report
  Future<Map<String, dynamic>> getInventoryValue({
    int productGroupID = 0,
    int categoryID = 0,
    int subCategoryID = 0,
    int departmentID = 0,
    int packID = 0,
    int sizeID = 0,
    int statusID = 1,
    int supplierID = 0,
    int onHandFilter = 0,
    int itemGroupID = 0,
    int pageNo = 1,
    String searchString = "",
    String orderBy = "ProductID",
    String sortBy = "desc",
  }) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token is null, cannot make request');
    }

    // Create the request body
    final requestBody = jsonEncode({
      'productGroupID': productGroupID,
      'categoryID': categoryID,
      'subCategoryID': subCategoryID,
      'departmentID': departmentID,
      'packID': packID,
      'sizeID': sizeID,
      'statusID': statusID,
      'supplierID': supplierID,
      'onHandFilter': onHandFilter,
      'itemGroupID': itemGroupID,
      'pageNo': pageNo,
      'searchString': searchString,
      'orderBy': orderBy,
      'sortBy': sortBy,
    });

    final uri = Uri.parse('${Config.apiUrl}/Report/InventoryValue');
    print('Request URL: $uri');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: requestBody,
    );

    print('Response status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);

        // Check for "No Record Found" message
        if (decodedResponse['message'] == "No Record Found.") {
          return {
            'currentPage': 0,
            'totalPages': 0,
            'data': [],
            'message': decodedResponse['message'],
          };
        }

        // Validate 'data' key exists
        if (!decodedResponse.containsKey('data')) {
          throw Exception('Response does not contain "data" key');
        }

        final List<dynamic> dataList = decodedResponse['data'];
        if (dataList is! List) {
          throw Exception('Data is not a list');
        }

        // Process data and ensure correct typing
        List<Map<String, dynamic>> processedData = dataList
            .where((item) => item is Map<String, dynamic> && item.containsKey('productID'))
            .map((item) => {
          'productID': item['productID'],
          'productSKU': item['productSKU'],
          'productName': item['productName'],
          'onHand': item['onHand'],
          'currentValue': item['currentValue'],
          'purchasePrice': item['purchasePrice'],
          'sellingPrice': item['sellingPrice'],
          'departmentName': item['departmentName'],
        })
            .toList();

        return {
          'currentPage': decodedResponse['currentPage'],
          'totalPages': decodedResponse['totalPages'],
          'data': processedData,
        };
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data: $e');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data. Status code: ${response.statusCode}');
    }
  }


  //TODO : Label/GetAll API -> getAll -> Printable Label
  Future<Map<String, dynamic>> getAllLabel(int pageNumber) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/Label/GetAll?pageNumber=$pageNumber'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('Decoded JSON data: $jsonResponse');

        final List<dynamic> data = jsonResponse['data'] ?? [];
        final Map<int, Map<String, dynamic>> processedData = {};

        int currentPage = jsonResponse['currentPage'] ?? pageNumber;
        int totalPages = jsonResponse['totalPages'] ?? 0;

        print('Current Page: $currentPage');
        print('Total Pages: $totalPages');

        for (var item in data) {
          if (item is Map<String, dynamic>) {
            final int id = item['labelTxnID'] is int
                ? item['labelTxnID']
                : int.tryParse(item['labelTxnID'].toString()) ?? -1;

            if (id != -1) {
              processedData[id] = {
                'title': item['labelTitle'] ?? 'Unknown',
                'copies': item['numberOfCopy'] ?? 0,
                'labelTxnID': id,
              };
            } else {
              print('Invalid labelTxnID: ${item['labelTxnID']}');
            }
          } else {
            print('Unexpected item format: $item');
          }
        }

        return {
          'labels': processedData,
          'currentPage': currentPage,
          'totalPages': totalPages,
        };
      } catch (e) {
        throw Exception('Error decoding JSON data: $e');
      }
    } else {
      throw Exception(
          'Failed to load data with status code: ${response.statusCode}');
    }
  }

  //TODO : Label/Get API -> Get -> Printable Label
  Future<String> getLabelEdit(int tnxid, int pagenumber) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/Label/Get?labelID=$tnxid&pageNumber=$pagenumber'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('API: Response status code: ${response.statusCode}');
    print('API: Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Return the raw response body directly
      return response.body;
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : Label/Delete API -> Delete -> Printable Label
  Future<void> delLabelDelete(int labelID) async {
    String? token = await getToken();

    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/Label/Delete?labelID=$labelID'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Process response if needed. For now, we'll assume success if status code is 200.
      print('Label deleted successfully');
    } else if (response.statusCode == 404) {
      print('Label not found');
      throw Exception('Label not found');
    } else {
      print('Failed to delete label with status code: ${response.statusCode}');
      throw Exception('Failed to delete label');
    }
  }

  //TODO : Label/Get API -> Label/Get -> Printable Label Create
  Future<Map<int, Map<String, dynamic>>> getLabel() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}Label/Get?labelID=46'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        final Map<int, Map<String, dynamic>> processedData = {};

        int idx = 0;

        print('Processed transaction data: $processedData');
        return processedData;
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : Label/DeleteProductFromLabelTxn API -> DeleteProductFromLabelTxn -> Printable Label Create
  Future<void> deleteProductFromLabelTxn(int labelProductTxnID) async {
    String? token = await getToken();

    final response = await http.delete(
      Uri.parse(
          '${Config.apiUrl}/Label/DeleteProductFromLabelTxn?labelProductTxnID=$labelProductTxnID'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Product deleted successfully');
    } else {
      print(
          'Failed to delete product with status code: ${response.statusCode}');
      throw Exception('Failed to delete product');
    }
  }

  //TODO : PurchaseOrder/DeleteReturnProduct API -> deleteReturnProduct -> Purchase Order
  Future<void> deleteReturnProduct(int purchaseReturnID, int productID) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token is null. Cannot perform delete operation.');
    }

    final response = await http.delete(
      Uri.parse(
        '${Config.apiUrl}/PurchaseOrder/DeleteReturnProduct?PurchaseReturnID=$purchaseReturnID&productID=$productID',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Product deleted successfully');
    } else {
      print('Failed to delete product with status code: ${response.statusCode}');
      throw Exception('Failed to delete product: ${response.body}');
    }
  }

  //TODO : PurchaseOrder/DeleteOrderItem API -> deleteReturnProduct -> Purchase Order
  Future<void> deleteOrderProduct(int purchaseOrderTxnID) async {
    String? token = await getToken();

    final response = await http.delete(
      Uri.parse(
          '${Config.apiUrl}/PurchaseOrder/DeleteOrderItem?purchaseOrderTxnID=$purchaseOrderTxnID'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Product deleted successfully');
    } else {
      print(
          'Failed to delete product with status code: ${response.statusCode}');
      throw Exception('Failed to delete product');
    }
  }


  //TODO : Label/Save API -> Label/Save -> Printable Label Create
  Future<void> postLabelSave({
    required String labelTitle,
    required String numberOfCopies,
    required List<Map<String, dynamic>> products,
    int? LabelTxnID,
  }) async {
    String? token = await getToken();

    final url = Uri.parse('${Config.apiUrl}/Label/Save');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({
      "labelTxnID": LabelTxnID ?? 0,
      "labelTitle": labelTitle,
      "numberOfCopy": numberOfCopies,
      "products": products,
    });

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');
        // Handle the response as needed
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : PurchaseOrder/GetAll API ->   -> Purchase Order
  Future<Map<String, dynamic>> getPurchaseOrdersForPage(int pageNo) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/PurchaseOrder/GetAll?pageNumber=$pageNo'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print(
        'getPurchaseOrdersForPage: Response status code for page $pageNo: ${response.statusCode}');
    print('getPurchaseOrdersForPage: Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print(
            'getPurchaseOrdersForPage: Decoded JSON data for page $pageNo: $jsonData');

        // Extract pagination info from the response
        int currentPage = jsonData['currentPage'] ?? pageNo;
        int totalPages = jsonData['totalPages'] ?? 0;

        print('Current Page: $currentPage');
        print('Total Pages: $totalPages');

        // Extract and process purchase orders
        final List<dynamic> purchaseOrders = jsonData['data'] ?? [];
        final Map<int, Map<String, dynamic>> processedData = {};

        for (var order in purchaseOrders) {
          final int purchaseOrderID = order['purchaseOrderID'] ?? 0;
          processedData[purchaseOrderID] = {
            'purchaseOrderNumber': order['purchaseOrderNumber'] ?? '',
            'supplierName': order['supplierName'] ?? '',
            'orderQty': order['orderQty'] ?? 0,
            'totalAmount': order['totalAmount'] ?? 0,
            'purchaseOrderID': order['purchaseOrderID'] ?? 0,
            'purchaseOrderStatusID': order['purchaseOrderStatusID'] ?? 0,
            'purchaseOrderStatusText': order['purchaseOrderStatusText'] ?? 0,
          };
        }

        // return processedData;
        return {
          'purchaseOrders': processedData,
          'currentPage': pageNo,
          'totalPages': totalPages,
        };
      } catch (e) {
        print('getPurchaseOrdersForPage: Error decoding JSON data: $e');
        throw Exception('getPurchaseOrdersForPage: Error decoding JSON data');
      }
    } else {
      print(
          'getPurchaseOrdersForPage: Failed to load data with status code: ${response.statusCode}');
      throw Exception('getPurchaseOrdersForPage: Failed to load data');
    }
  }

  //--------------------------- one API pending of Purchase Order page

  //TODO : PurchaseOrder/DeleteOrderItem API ->   -> Purchase Order Edit page - delete icon
  Future<Map<int, Map<String, dynamic>>> delDeleteOrderItem() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/PurchaseOrder/DeleteOrderItem?purchaseOrderTxnID=5239'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        final Map<int, Map<String, dynamic>> processedData = {};

        int idx = 0;

        print('Processed transaction data: $processedData');
        return processedData;
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : /PurchaseOrder/Save API ->   -> Purchase Order create page
  Future<Map<int, Map<String, dynamic>>> postPurchaseOrderSave({
    required int supplierID,
    required int purchaseOrderID,
    required List<Map<String, dynamic>> items,
  }) async {
    // Fetch the token
    String? token = await getToken();
    print('Token retrieved: $token');

    // Map items to the required format for the API
    final List<Map<String, dynamic>> products = items.map((item) {
      print('Mapping item: $item');
      return {
        "productId": item['id'], // Ensure this ID is not null
        "quantity": item['quantity'],
      };
    }).toList();

    // Print the products being sent
    print('Products to be sent: $products');

    final Map<String, dynamic> body = {
      "purchaseOrderID": purchaseOrderID,
      "supplierID": supplierID,
      "companyID": 0,
      "userID": 0,
      "products": products,
    };

    // Log the complete request body
    print('Request body: $body');

    final response = await http.post(
      Uri.parse('${Config.apiUrl}/PurchaseOrder/Save'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    // Log response status and body for debugging
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        // Check if identity exists in the response
        if (data.containsKey('identity')) {
          final Map<int, Map<String, dynamic>> processedData = {};
          processedData[data['identity']] = data; // Example of storing the identity
          print('Processed transaction data: $processedData');
          return processedData;
        } else {
          print('Identity key not found in response data.');
          throw Exception('Identity key not found in response data.');
        }
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      // Handle different status codes
      print('Failed to load data with status code: ${response.statusCode}');
      print('Reason: ${response.reasonPhrase}');

      // Log the error response for further investigation
      print('Error response body: ${response.body}');

      throw Exception('Failed to load data: ${response.reasonPhrase}');
    }
  }

  //TODO : /PurchaseOrder/Save API ->   -> Purchase Return create page
  Future<Map<int, Map<String, dynamic>>> postPurchaseReturnSave(
      Map<String, dynamic> body) async {
    String? token = await getToken();

    print("API body $body");
    // Create a new body map without adding extra quotes
    final formattedBody = {
      'purchaseOrderID': body['purchaseOrderID'],
      'supplierID': body['supplierID'],
      'purchaseReturnID': body['purchaseReturnID'],
      'notes': body['notes'], // Keep this as is
      'products': (body['products'] as List).map((product) {
        return {
          'productId': product['productId'],
          'quantity': product['quantity'],
          'cost': product['cost'],
          'productName': product['productName'], // Keep this as is
        };
      }).toList(),
    };
    String jsonBody = json.encode(formattedBody);
    print('Formatted body: $jsonBody');

    try {
      json.decode(
          jsonBody); // This will throw an error if jsonBody is not valid JSON
    } catch (e) {
      print('Invalid JSON: $e');
      throw Exception('Invalid JSON format');
    }

    final response = await http.post(
      Uri.parse('${Config.apiUrl}/PurchaseOrder/PurchaseReturn'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonBody,
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        final Map<int, Map<String, dynamic>> processedData = {};
        processedData[data['identity']] =
            data; // Adjust if identity is stored differently

        print('Processed transaction data: $processedData');
        return processedData;
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : PurchaseOrder/GetAllOrderBySupplier API ->   -> Purchase Return
  Future<Map<int, Map<String, dynamic>>> getPurchaseReturn(int supplierId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/PurchaseOrder/GetAllOrderBySupplier?supplierID=$supplierId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        final Map<int, Map<String, dynamic>> processedData = {};
        int idx = 0;

        for (var item in data) {
          int id = item['id'];
          String name = item['name'];

          processedData[idx++] = {
            'Id': id,
            'name': name,
            // Add any other fields you need here
          };
        }

        print('Processed transaction data: $processedData');

        // Return an empty map if no data is found
        return processedData.isNotEmpty ? processedData : {};
      } catch (e) {
        // Return an empty map in case of a JSON decoding error
        return {};
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      return {};
    }
  }


  //TODO : PurchaseOrder/PurchaseReturn API ->   -> Purchase Return
  Future<Map<int, Map<String, dynamic>>> postPurchaseReturn() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/PurchaseOrder/PurchaseReturn'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        final Map<int, Map<String, dynamic>> processedData = {};

        int idx = 0;

        print('Processed transaction data: $processedData');
        return processedData;
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : PurchaseOrder/GetAll API ->   -> Purchase Order
  Future<Map<String, dynamic>> getPurchaseReturnForPage(int pageNo) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/PurchaseOrder/GetAllPurchaseReturn?pageNumber=$pageNo'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print(
        'getPurchaseReturnForPage: Response status code for page $pageNo: ${response.statusCode}');
    print('getPurchaseReturnForPage: Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print(
            'getPurchaseReturnForPage :Decoded JSON data for page $pageNo: $jsonData');

        // Extract pagination info from the response
        int currentPage = jsonData['currentPage'] ?? pageNo;
        int totalPages = jsonData['totalPages'] ?? 0;

        print('Current Page: $currentPage');
        print('Total Pages: $totalPages');

        // Extract and process purchase orders
        final List<dynamic> purchaseOrders =
            jsonData['data'] ?? []; // Use an empty list if null
        final Map<int, Map<String, dynamic>> processedData = {};
        final List<int> purchaseReturnIDList = [];

        if (purchaseOrders.isNotEmpty) {
          // Check if purchaseOrders is not empty
          for (var order in purchaseOrders) {
            final int purchaseReturnID = order['purchaseReturnID'] ??
                0; // Ensure this ID is fetched correctly

            purchaseReturnIDList.add(purchaseReturnID);

            processedData[purchaseReturnID] = {
              'purchaseOrderID': order['purchaseOrderID'] ?? 0,
              // Ensure this is an int
              'referenceNumber': order['referenceNumber'] ?? '',
              // This should be a String
              'purchaseOrderNumber': order['purchaseOrderNumber'] ?? '',
              // This should be a String (not int)
              'returnDate': order['returnDate'] ?? '',
              // This should be a String (not int)
              "purchaseReturnID": purchaseReturnID,
            };
          }
        } else {
          print(
              'getPurchaseReturnForPage: No purchase orders found for this page.');
        }

        print(
            'getPurchaseReturnForPage: purchaseReturnIDList: $purchaseReturnIDList');

        return {
          'purchaseReturn': processedData,
          'purchaseReturnIDList': purchaseReturnIDList,
          'currentPage': currentPage,
          'totalPages': totalPages,
        };
      } catch (e) {
        print('getPurchaseReturnForPage: Error decoding JSON data: $e');
        throw Exception('getPurchaseReturnForPage: Error decoding JSON data');
      }
    } else {
      print(
          'getPurchaseReturnForPage: Failed to load data with status code: ${response.statusCode}');
      throw Exception('getPurchaseReturnForPage: Failed to load data');
    }
  }

  //TODO : Purchase Order Edit  API -> Edit -> Purchase Order Edit
  Future<Map<int, Map<String, dynamic>>> purchaseOrderEdit(
      dynamic purchaseOrderId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/PurchaseOrder/Get?orderID=$purchaseOrderId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('PurchaseOrderEdit: Response status code: ${response.statusCode}');
    print('PurchaseOrderEdit: Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);

        print('decodedResponse: $decodedResponse');

        final Map<String, dynamic> data = decodedResponse;

        print('PurchaseOrderEdit: Decoded JSON data: $data');

        final Map<int, Map<String, dynamic>> processedData = {};

        if (data['purchaseOrderID'] != null) {
          print('check0');
          final String purchaseOrderNumber = data['purchaseOrderNumber'] ?? '';
          print('check0.5');
          final int supplierID = data['supplierID'] ?? 0;

          print('check1');
          final int purchaseOrderID = data['purchaseOrderID'] ?? 0;
          processedData[0] = {
            'purchaseOrderNumber': purchaseOrderNumber,
            'supplierID': supplierID,
            'purchaseOrderID': purchaseOrderID,
          };

          List<dynamic> productTxns = data['purchaseOrderProductTxns'] ?? [];

          int idx = 1;

          for (var product in productTxns) {
            if (product is Map<String, dynamic>) {
              final int productId = product['productID'] ?? 0;
              final String productSKU = product['productSKU'] ?? '';
              final String productName = product['productName'] ?? '';
              final String sizeName = product['sizeName'] ?? '';
              final String packName = product['packName'] ?? '';
              final String salesWeekAvg = product['salesWeekAvg'] ?? '';
              print('check2');
              final int onHand = product['onHand'] ?? 0;
              print('check3');
              final int orderQty = product['orderQty'] ?? 0;
              print('check4');
              final double purchasePrice = product['purchasePrice'] ?? 0;
              final int purchaseOrderTxnID = product['purchaseOrderTxnID'] ?? 0;
              processedData[idx] = {
                'productID': productId,
                'productSKU': productSKU,
                'productName': productName,
                'onHand': onHand,
                'orderQty': orderQty,
                'costPrice': purchasePrice,
                'purchaseOrderTxnID': purchaseOrderTxnID,
                'sizeName': sizeName,
                'packName': packName,
                'salesWeekAvg': salesWeekAvg,
              };

              idx++;
            }
          }
        }

        print('PurchaseOrderEdit: Processed transaction data: $processedData');
        return processedData;
      } catch (e) {
        print('PurchaseOrderEdit: Error decoding JSON data: $e');
        throw Exception('PurchaseOrderEdit: Error decoding JSON data');
      }
    } else {
      print(
          'PurchaseOrderEdit: Failed to load data with status code: ${response.statusCode}');
      throw Exception('PurchaseOrderEdit: Failed to load data');
    }
  }

  //TODO : Purchase Order Edit  API -> Edit -> Receive Purchase Order
  Future<List<Map<String, dynamic>>> ReceivePurchaseOrder(dynamic purchaseOrderId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/PurchaseOrder/Get?orderID=$purchaseOrderId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('PurchaseOrderEdit: Response status code: ${response.statusCode}');
    print('PurchaseOrderEdit: Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);
        print('decodedResponse: $decodedResponse');

        // Create a list to store the entire response as is
        List<Map<String, dynamic>> processedData = [];

        // Add the whole response directly to the list
        processedData.add(decodedResponse);

        print('PurchaseOrderEdit: Processed data: $processedData');
        return processedData;
      } catch (e) {
        print('PurchaseOrderEdit: Error decoding JSON data: $e');
        throw Exception('PurchaseOrderEdit: Error decoding JSON data');
      }
    } else {
      print('PurchaseOrderEdit: Failed to load data with status code: ${response.statusCode}');
      throw Exception('PurchaseOrderEdit: Failed to load data');
    }
  }


  //TODO : Purchase Return Edit  API -> Edit -> Purchase Return Edit
  Future<List<Map<String, dynamic>>> purchaseReturnEdit(
      dynamic purchaseReturnId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/PurchaseOrder/GetPurchaseReturn?purchaseReturnID=$purchaseReturnId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);
        final List<Map<String, dynamic>> processedData = [];

        if (decodedResponse['purchaseOrderID'] != null) {
          // Add purchase order details to the list
          processedData.add({
            'purchaseOrderID': decodedResponse['purchaseOrderID'],
            'supplierID': decodedResponse['supplierID'],
            'supplierName': decodedResponse['supplierName'],
            'purchaseOrderNumber': decodedResponse['purchaseOrderNumber'],
            'purchaseReturnID': decodedResponse['purchaseReturnID'],
            'notes': decodedResponse['notes'] ?? '',
          });

          List<dynamic> products = decodedResponse['products'] ?? [];
          for (var product in products) {
            if (product is Map<String, dynamic>) {
              final int productId = product['productId'];
              print('Processing product with ID: $productId');
              processedData.add({
                'productId': productId,
                'quantity': product['quantity'],
                'sku': product['sku'],
                'cost': product['cost'],
                'onHand': product['onHand'],
                'productName': product['productName'],
                'purchasePrice': product['purchasePrice'],
                'supplierCode': product['supplierCode'],
                'packName': product['packName'],
                'sizeName': product['sizeName'],
                'purchaseReturnTxnID': product['purchaseReturnTxnID'],
                // ...productMasterData, // Include product master data
              });
            }
          }
        }

        print('processedData before return: $processedData');
        return processedData;
      } catch (e) {
        throw Exception('Error decoding JSON data: $e');
      }
    } else {
      throw Exception(
          'Failed to load data with status code: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getProductMasterEdit(String productId) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/Product/GetProductMaster?productID=$productId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract the required fields from the API response
        final Map<String, dynamic> processedData = {
          'productSKU': data['productSKU'] ?? '',
          'sellingPrice': data['sellingPrice']?.toString() ?? '',
          'onHand': data['onHand']?.toString() ?? '',
        };
        print('This is data $processedData');
        return processedData;
      } catch (e) {
        throw Exception('Error decoding JSON data: $e');
      }
    } else {
      throw Exception(
          'Failed to load data, status code: ${response.statusCode}');
    }
  }

  //TODO : Dashboard/GetAllReasonDetail API ->   -> Notification
  Future<Map<String, dynamic>> getAllReasonDetail({
    required int reasonID,
    required String fromDate,
    required String endDate,
    required int pageNumber,
  }) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse(
        '${Config.apiUrl}/Dashboard/GetAllReasonDetail'
        '?reasonID=$reasonID&fromDate=$fromDate&endDate=$endDate&pageNumber=$pageNumber',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('Decoded JSON data: $jsonData');

        // Check for error code
        if (jsonData['code'] != null && jsonData['code'] != 200) {
          throw Exception('Error from API: ${jsonData['message']}');
        }

        // Handle successful response
        final int currentPage =
            jsonData['currentPage'] ?? 0; // Default to 0 if null
        final int totalPages =
            jsonData['totalPages'] ?? 0; // Default to 0 if null
        final List<dynamic> data =
            jsonData['data'] ?? []; // Default to empty list if null

        final List<String> sentences = [];

        for (var item in data) {
          String userName = item['userName'];
          String createDate =
              item['createdDate'] ?? '01/01/1999'; // Handle empty create date

          // Check for specific reasonID
          String sentence;
          if (reasonID == 6) {
            sentence = "$userName opened the cash drawer on $createDate.";
          } else {
            int batchID = item['batchID'];
            int quantity = item['quantity'];
            String productSKU = item['productSKU'] ?? 'N/A'; // Handle empty SKU
            String productName =
                item['productName'] ?? 'N/A'; // Handle empty product name
            String amount = item['amount'] ?? '0.00'; // Handle empty amount

            // Default sentence structure
            sentence =
                "User: $userName\nBatch ID: $batchID\nName: $productName\nSKU: $productSKU\nUnits: $quantity\nTotal: \$$amount\nDate: $createDate";
          }

          sentences.add(sentence);
        }

        print('Current Page: $currentPage, Total Pages: $totalPages');
        return {
          'currentPage': currentPage,
          'totalPages': totalPages,
          'sentences': sentences,
        };
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //TODO : /StoreMaster/GetContactUs API ->   -> Support
  Future<Map<String, dynamic>> getContactUs() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/StoreMaster/GetContactUs'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        // Decode JSON response
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        // Directly return the data as contact information
        return {
          'fullAddress': data['fullAddress'],
          'city': data['city'],
          'state': data['state'],
          'zipCode': data['zipCode'],
          'phone': data['phone'],
          'email': data['email'],
          'webSite': data['webSite'],
        };
      } catch (e) {
        print('Error decoding JSON data: $e');
        throw Exception('Error decoding JSON data');
      }
    } else {
      print('Failed to load data with status code: ${response.statusCode}');
      throw Exception('Failed to load data');
    }
  }

  //todo : Receive Purchase Order ->
  Future<void> postReceivePurchaseOrder(int purchaseOrderID, List<Map<String, dynamic>> products) async {
    try {
      String? token = await getToken();
      if (token == null) {
        throw Exception('Token retrieval failed');
      }

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/PurchaseOrder/ReceiveOrder'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'purchaseOrderID': purchaseOrderID,
          'products': products,
        }),
      );

      // Print the response for debugging purposes
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Purchase order updated successfully');
      } else {
        throw Exception('Failed to update purchase order with status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any other exceptions that may occur
      print('An error occurred: $e');
      throw e; // Re-throw the exception after logging
    }
  }

  //todo :- save device info
  Future<Map<String, dynamic>> sendDeviceInfo({
    required String identifier,
    // required String fireBaseToken,
    // required String languages,
    // required int timezone,
    required String deviceModel,
    required String deviceOS,
  }) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token is null, cannot make request');
    }

    // Create the request body
    final requestBody = jsonEncode({
      'appID': "com.randdpos.usa",
      'deviceType': 1,
      'emailAuthHash': "emailAuthHash",
      'identifier': identifier,
      'fireBaseToken': "fireBaseToken",
      'testType': 2,
      'languages': "languages",
      'timezone': 0,
      'deviceModel': deviceModel,
      'deviceOS': deviceOS,
      'adid': "adid",
      'sdk': "sdk",
      'sessionCount': 0,
      'createdAt': 0,
      'lastActive': 0,
      'notificationTypes': 1,
      'longitude': "longitude",
      'latitude': "latitude",
      'country': "country",
    });

    final uri = Uri.parse('${Config.apiUrl}/Device/Save'); // Replace with your actual endpoint
    print('Request URL: $uri');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: requestBody,
    );

    print('Response status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('Device info sent successfully.');
      return jsonDecode(response.body); // Return the response body as a Map
    } else {
      print('Failed to send device info with status code: ${response.statusCode}');
      throw Exception('Failed to send device info. Status code: ${response.statusCode}');
    }
  }


}
