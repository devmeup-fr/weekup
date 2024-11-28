import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/localization_util.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(LocalizationApp.forcedLocale);

  void changeLocale(Locale locale) {
    emit(locale);
  }
}
