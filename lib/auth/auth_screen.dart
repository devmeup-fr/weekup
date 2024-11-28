import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/core/widgets/nav_bar_widget.dart';
import '/core/widgets/version_app_widget.dart';
import '../core/utils/localization_util.dart';
import '../core/widgets/container_view_widget.dart';
import '../core/widgets/modal_widget.dart';
import '../core/widgets/password_widget.dart';
import '../core/widgets/policy_widget.dart';
// import '../main.dart';
import 'blocs/auth_cubit.dart';
import 'blocs/auth_state.dart';
// import 'mocks/auth_maintainer_mock.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool initialized;
  late TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  late FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  late bool _isBiometricsAvailable = false;
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _handleLastUserConnected() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _usernameController = TextEditingController();
    _secureStorage = const FlutterSecureStorage();
    bool isStoredKey = await _secureStorage.containsKey(key: 'useBiometrics');
    if (Platform.isAndroid || Platform.isIOS) {
      bool checkBiometrics = await _localAuthentication.canCheckBiometrics;
      _isBiometricsAvailable = isStoredKey && checkBiometrics;
    } else {
      _isBiometricsAvailable = false;
    }

    if (mounted) {
      setState(() {
        _usernameController.text = prefs.getString('lastUserConnected') ?? '';
        initialized = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initialized = false;
    _handleLastUserConnected();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> authUserHandle(String username, String password) async {
    try {
      await context.read<AuthCubit>().authUser(username, password);
    } catch (e) {
      debugPrint(e.toString());
      if (e is DioException) {
        debugPrint("Error code : ${e.response?.statusCode.toString()}");
        debugPrint(e.response?.data.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Center(
                child: Text(context.translate(
                    'auth.errors.${e.response?.statusCode ?? 500}')))));
      }

      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<void> authBiometricUserHandle() async {
    String? username = await _secureStorage.read(key: 'username');
    String? password = await _secureStorage.read(key: 'password');
    if (password != null && username != null) {
      await authUserHandle(username, password);
    }
  }

  Future<void> showSavePasswordConfirmationDialog(
      String username, String password) async {
    final isAvailable = await _localAuthentication.canCheckBiometrics;
    if (!isAvailable) {
      await authUserHandle(username, password);
      return;
    }

    return showDialog<void>(
      context: _scaffoldKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ModalWidget(
          title: context.translate('auth.biometrics.title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(context.translate('auth.biometrics.askBiometrics')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _secureStorage.delete(key: 'useBiometrics');
                await authUserHandle(username, password);
              },
              child: Text(
                context.translate('common.cancel'),
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final isAuthenticated = await _localAuthentication.authenticate(
                    localizedReason:
                        context.translate('auth.biometrics.localizedReason'),
                    options: const AuthenticationOptions(biometricOnly: true));
                if (isAuthenticated) {
                  await _secureStorage.write(
                      key: 'useBiometrics', value: 'true');
                  await _secureStorage.write(key: 'username', value: username);
                  await _secureStorage.write(key: 'password', value: password);
                  await authUserHandle(username, password);
                } else {
                  setState(() {
                    _isLoggingIn = false;
                  });
                }
              },
              child: Text(context.translate('common.validate')),
            ),
          ],
        );
      },
    );
  }

  void submitForm(BuildContext context) async {
    return await context
        .read<AuthCubit>()
        .autoLog(); // REMOVE this after development

    // setState(() {
    //   _isLoggingIn = true;
    // });

    // final username = _usernameController.text;
    // final password = _passwordController.text;

    // if (MODE_MOCK) {
    //   context.read<AuthCubit>().authUser(
    //       getAuthUsernameMaintainerMock(), getAuthPassMaintainerMock());

    //   return;
    // }

    // if (username.isNotEmpty && password.isNotEmpty) {
    //   if (!_isBiometricsAvailable) {
    //     await authUserHandle(username, password);
    //   } else {
    //     // Show confirmation dialog to save the password securely
    //     await showSavePasswordConfirmationDialog(username, password);
    //   }
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //         content: Center(
    //             child: Text(context.translate('auth.errors.fillFields')))),
    //   );
    //   setState(() {
    //     _isLoggingIn = false;
    //   });
    // }
  }

  void authenticateWithBiometrics(BuildContext context) async {
    setState(() {
      _isLoggingIn = true;
    });
    try {
      final isAuthenticated = await _localAuthentication.authenticate(
          localizedReason: context.translate('auth.biometrics.localizedReason'),
          options: const AuthenticationOptions(biometricOnly: true));
      if (isAuthenticated) {
        // Authentication successful, proceed with login
        await authBiometricUserHandle();
        setState(() {
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Center(
              child: Text(context.translate(
                  'auth.errors.${e is DioException ? (e.response?.statusCode ?? '500') : '500'}')))));
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        appBar: NavBar(
          context: context,
          titleNavBar: context.translate('common.appTitle'),
        ),
        body: BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
          return ContainerViewWidget(
              child: Column(children: [
            Expanded(child: Container()),
            Image.asset(
              'assets/images/EPnrj.png',
              width: 200,
              height: 100,
            ),
            const SizedBox(height: 40),
            SizedBox(
              child: Center(child: buildLoginForm(context)),
            ),
            Expanded(child: Container()),
            const Column(children: [
              PolicyWidget(),
              VersionAppWidget(),
            ])
          ]));
        }));
  }

  Widget buildLoginForm(BuildContext context) {
    if (!initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
        key: _formKey,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: context.translate('auth.username'),
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                  ),
                  onFieldSubmitted: (value) {
                    submitForm(context);
                  },
                ),
                const SizedBox(height: 20),
                PasswordWidget(
                    controller: _passwordController, submitForm: submitForm),
                const SizedBox(height: 30),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _isLoggingIn ? null : () => submitForm(context),
                    child: _isLoggingIn
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.tertiary),
                            ))
                        : Text(context.translate('auth.buttonLabel'),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary)),
                  ),
                ),
                const SizedBox(height: 10),
                if (!_isBiometricsAvailable)
                  TextButton(
                    onPressed: _isLoggingIn
                        ? null
                        : () => authenticateWithBiometrics(context),
                    child: Text(context.translate('auth.biometrics.title')),
                  ),
                Divider(
                  color: Theme.of(context).colorScheme.primary,
                  height: 60,
                  thickness: 1,
                ),
                Text(context.translate('auth.support.askID')),
                const SizedBox(height: 10),
              ],
            )));
  }
}
