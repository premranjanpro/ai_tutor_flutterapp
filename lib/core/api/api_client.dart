import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  static const String baseUrl = 'http://localhost:5000'; // Target local API

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshToken = await SecureStorage.getRefreshToken();
            final accessToken = await SecureStorage.getAccessToken();
            
            if (refreshToken != null && accessToken != null) {
              try {
                // Request token refresh using a separate Dio instance to avoid circular calls
                final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
                final response = await refreshDio.post('/api/auth/refresh-token', data: {
                  'accessToken': accessToken,
                  'refreshToken': refreshToken,
                });

                if (response.statusCode == 200 && response.data['success'] == true) {
                  final data = response.data['data'];
                  await SecureStorage.saveTokens(
                    accessToken: data['accessToken'],
                    refreshToken: data['refreshToken'],
                    userId: data['user']['userId'],
                    userName: data['user']['name'],
                  );

                  // Update request header and retry original request
                  final newAccessToken = data['accessToken'];
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  final options = Options(
                    method: error.requestOptions.method,
                    headers: error.requestOptions.headers,
                  );
                  
                  final cloneReq = await dio.request(
                    error.requestOptions.path,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                    options: options,
                  );
                  
                  return handler.resolve(cloneReq);
                }
              } catch (e) {
                // If refresh fails, clear tokens and let user login again
                await SecureStorage.clearAll();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
