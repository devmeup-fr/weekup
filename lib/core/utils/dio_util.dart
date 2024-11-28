import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioApp {
  static final DioApp _instance = DioApp._internal();

  late Dio _dio;

  factory DioApp() {
    return _instance;
  }

  DioApp._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 5000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'City-Light-Settings',
        },
      ),
    );
    _dio.interceptors.add(AuthenticationInterceptor());
  }

  Dio get dioInstance => _dio;
}

class AuthenticationInterceptor extends Interceptor {
  AuthenticationInterceptor();

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Get access token into the secureStorage
    FlutterSecureStorage secureStorage = const FlutterSecureStorage();

    final String? accessToken = await secureStorage.read(key: 'accessToken');

    // Add access token on header
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
      debugPrint("Bearer: $accessToken");
    }

    debugPrint("URI: ${options.uri}");

    return handler.next(options);
  }
}
