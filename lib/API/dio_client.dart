import 'package:dio/dio.dart';
import 'package:rndpo/API/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Import your ApiService

class DioClient {
  late Dio _dio;
  late TokenManager _tokenManager;

  DioClient(this._tokenManager) {
    _dio = Dio();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add authorization header if token is available
        final token = _tokenManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Handle response if needed
        return handler.next(response);
      },
      onError: (DioError err, ErrorInterceptorHandler handler) async {
        if (err.response?.statusCode == 401) {
          // Log out or show an error message to the user
        }
        return handler.next(err); // Forward other errors
      },
    ));
  }

  Dio get dio => _dio; // Provide access to Dio instance
}
