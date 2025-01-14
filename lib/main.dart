import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/blocs/locale_cubit.dart';
import 'core/utils/localization_util.dart';
import 'screens/home_screen.dart';
import 'theme/themes.dart';

// ignore: constant_identifier_names
const bool MODE_MOCK = false;
// ignore: constant_identifier_names
const bool WITH_CLEAN_PREF = false;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Alarm.init();
  FlutterNativeSplash.remove();

  // CLEAN PREF USE
  if (WITH_CLEAN_PREF) {
    await handlerCleanPref();
  }
  runApp(
    MultiBlocProvider(providers: [
      BlocProvider(create: (_) => LocaleCubit()),
    ], child: const MyApp()),
  );
}

Future<void> handlerCleanPref() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  prefs.clear();
  secureStorage.deleteAll();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
        builder: (context, state) => MaterialApp(
              debugShowCheckedModeBanner: false,
              localizationsDelegates: [
                LocalizationApp.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              localeResolutionCallback: (locale, supportedLocales) {
                if (!supportedLocales.contains(locale)) {
                  return LocalizationApp.forcedLocale;
                }
                return locale;
              },
              locale: state,
              supportedLocales: LocalizationApp.supportedLocales,
              onGenerateTitle: (BuildContext context) =>
                  context.translate("common.appTitle"),
              theme: Themes.light(),
              home: HomeScreen(),
            ));
  }
}
