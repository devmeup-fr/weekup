import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

enum ABC {
  a,
  b,
  c,
}

class Snackbar {
  static final snackBarKeyA = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyB = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyC = GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> getSnackbar(ABC abc) {
    switch (abc) {
      case ABC.a:
        return snackBarKeyA;
      case ABC.b:
        return snackBarKeyB;
      case ABC.c:
        return snackBarKeyC;
    }
  }

  static show(ABC abc, String msg, {required bool success}) {
    final snackBar = success
        ? SnackBar(
            content: Text(msg), backgroundColor: ThemeColors.successLight)
        : SnackBar(content: Text(msg), backgroundColor: ThemeColors.errorLight);
    getSnackbar(abc).currentState?.removeCurrentSnackBar();
    getSnackbar(abc).currentState?.showSnackBar(snackBar);
  }
}

String prettyException(String prefix, dynamic e) {
  if (e is PlatformException) {
    return "$prefix ${e.message}";
  }
  return prefix + e.toString();
}
