import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../enums/storage_keys_enum.dart';
import 'storage_util.dart';

class DioApp {
  static final DioApp _instance = DioApp._internal();

  late Dio _dio;

  factory DioApp() {
    return _instance;
  }

  DioApp._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: 10000),
        receiveTimeout: const Duration(milliseconds: 10000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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
    final String? accessToken =
        await safeReadSecure(SecureStorageKeys.accessToken.name);

    // Add access token on header
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
      debugPrint("Bearer: $accessToken");
    }

    debugPrint("URI: ${options.uri}");

    return handler.next(options);
  }
}
