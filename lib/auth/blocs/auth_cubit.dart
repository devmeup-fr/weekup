import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/auth_user_model.dart';
import '../repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(AuthState.loading()) {
    _initializeAuthState();
  }

  Future<void> _initializeAuthState() async {
    final AuthState initialAuthState = await AuthState.getInitialAuthState();
    emit(initialAuthState);
  }

  Future<void> authUser(String user, String password) async {
    if (user.isEmpty || password.isEmpty) return;

    AuthUserModel userAuthenticated = await repository.authUser(user, password);

    emit(AuthState.success(userAuthenticated: userAuthenticated, state: state));
  }

  Future<void> logout() async {
    await repository.logout();
    emit(AuthState.logout());
  }

  Future<void> autoLog() async {
    emit(AuthState.success());
  }
}
