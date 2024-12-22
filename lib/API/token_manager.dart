import 'dart:convert';

class TokenManager {
  String? _token;

  Future<void> setToken(String token) async {
    _token = token;
    // Save token to shared preferences
  }

  String? getToken() {
    return _token; // Retrieve token from memory or shared preferences
  }

  bool isTokenExpired() {
    if (_token == null) return true;
    final payload = json.decode(utf8.decode(base64Url.decode(_token!.split('.')[1])));
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
    return DateTime.now().isAfter(expirationDate);
  }
}



// // old code

// import 'package:dio/dio.dart';

// class TokenManager {
//   String? _jwt;
//   final Dio _dio;
//
//   TokenManager(this._dio);
//
//   void setToken(String jwt) {
//     _jwt = jwt;
//   }
//
//   String? get token => _jwt;
//
//   bool isTokenExpired() {
//     if (_jwt == null) return true;
//     final payload = json.decode(utf8.decode(base64Url.decode(_jwt!.split('.')[1])));
//     final exp = payload['exp'] * 1000; // Convert to milliseconds
//     return DateTime.now().millisecondsSinceEpoch > exp;
//   }
//
//   Future<void> refreshToken() async {
//     try {
//       final response = await _dio.post(_refreshUrl, data: {
//         'token': _jwt,
//       });
//       _jwt = response.data['new_token'];
//     } catch (e) {
//       // Handle refresh token error (e.g., redirect to login)
//       print('Failed to refresh token: $e');
//     }
//   }
// }