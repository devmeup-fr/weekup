import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  setSystemUIMode();
  requestPermissions();

  await Alarm.init();

  // CLEAN PREF USE
  if (WITH_CLEAN_PREF) {
    await handlerCleanPref();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final Locale initialLocale = await getStoredLocale();

  runApp(
    MultiBlocProvider(providers: [
      BlocProvider(create: (_) => LocaleCubit(initialLocale)),
    ], child: const MyApp()),
  );
}

void setSystemUIMode() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
}

Future<void> requestPermissions() async {
  await [
    Permission.storage,
    Permission.notification,
    Permission.scheduleExactAlarm,
  ].request();
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
