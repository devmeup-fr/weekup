import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../models/auth_user_model.dart';

enum AuthStatus { initial, loading, failure, success }

class AuthState extends Equatable {
  final AuthStatus cubitStatus;
  final AuthUserModel? userAuthenticated;
  final String? msgError;

  const AuthState({
    this.cubitStatus = AuthStatus.initial,
    this.userAuthenticated,
    this.msgError,
  });

  static Future<AuthState> getInitialAuthState() async {
    if (MODE_MOCK) {
      return const AuthState();
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authUserModelString = prefs.getString('authUser');

    AuthUserModel? userAuthenticated;
    if (authUserModelString != null) {
      final Map<String, dynamic> authUserModelMap =
          json.decode(authUserModelString);
      userAuthenticated = AuthUserModel.fromJson(authUserModelMap);
    }

    return AuthState(
      cubitStatus: AuthStatus.success,
      // cubitStatus:
      //     authUserModelString != null ? AuthStatus.success : AuthStatus.initial,
      userAuthenticated: userAuthenticated,
      msgError: null,
    );
  }

  factory AuthState.success(
      {AuthUserModel? userAuthenticated, AuthState? state}) {
    return AuthState(
      cubitStatus: AuthStatus.success,
      userAuthenticated: userAuthenticated ?? state?.userAuthenticated,
      msgError: state?.msgError,
    );
  }

  factory AuthState.failure(String? msgError, {AuthState? state}) {
    return AuthState(
      cubitStatus: AuthStatus.failure,
      msgError: msgError,
      userAuthenticated: state?.userAuthenticated,
    );
  }

  factory AuthState.loading({AuthState? state}) {
    return AuthState(
      cubitStatus: AuthStatus.loading,
      userAuthenticated: state?.userAuthenticated,
      msgError: state?.msgError,
    );
  }

  factory AuthState.logout() {
    return const AuthState();
  }

  @override
  List<Object?> get props => [
        cubitStatus,
        userAuthenticated,
        msgError,
      ];
}

class AuthInitial extends AuthState {}
