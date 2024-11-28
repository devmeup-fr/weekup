import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/dio_util.dart';
import '../../main.dart';
import '../mocks/auth_maintainer_mock.dart';
import '../models/auth_user_model.dart';

class AuthRepository {
  Future<AuthUserModel> authUser(String user, String password) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (MODE_MOCK) {
      AuthUserModel? authUser;
      authUser = AuthUserModel.fromJson(getAuthMaintainerMock());

      prefs.setString('authUser', json.encode(authUser.toJson()));

      return authUser;
    }

    String urlApiPlatform = const String.fromEnvironment('URL_API_PLATFORM');

    final Response response = await DioApp().dioInstance.post(
        '$urlApiPlatform/api/app-mobile/login',
        data: {"user": user, "password": password});

    AuthUserModel authUser = AuthUserModel.fromJson(response.data);

    authUser.printAttributes();

    prefs.setString('authUser', json.encode(authUser.toJson()));
    prefs.setString('lastUserConnected', user);

    return authUser;
  }

  Future<void> logout() async {
    FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    await secureStorage.write(key: 'lastUserConnected', value: null);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authUser');
    await prefs.remove('serialsAvailable');
  }
}
