import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/storage_util.dart';
import '../enums/storage_keys_enum.dart';
import '../utils/localization_util.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(super.initialLocale);

  void changeLocale(Locale locale) async {
    await secureStorage.write(
        key: SecureStorageKeys.localeLanguageCode.name,
        value: locale.languageCode);
    await secureStorage.write(
        key: SecureStorageKeys.localeCountryCode.name,
        value: locale.countryCode);
    emit(locale);
  }
}

Future<Locale> getStoredLocale() async {
  final String? languageCode =
      await secureStorage.read(key: SecureStorageKeys.localeLanguageCode.name);
  final String? countryCode =
      await secureStorage.read(key: SecureStorageKeys.localeCountryCode.name);
  if (languageCode != null && languageCode.isNotEmpty) {
    return Locale(languageCode, countryCode);
  }
  return LocalizationApp.forcedLocale;
}
