import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:alarm/service/alarm_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekup/core/blocs/locale_cubit.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/screens/alarm_edit_screen.dart';
import 'package:weekup/screens/alarm_ring_screen.dart';
import 'package:weekup/screens/home_screen.dart';
import 'package:weekup/screens/planning_screen.dart';
import 'package:weekup/screens/settings_screen.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/theme/themes.dart';

/// Rendu des écrans principaux sur un téléphone (390×844) en FR et EN :
/// échoue sur tout débordement de mise en page ou clé de traduction manquante.
/// `flutter test --dart-define=GOLDENS=true` écrit aussi des captures PNG.
const _goldens = bool.fromEnvironment('GOLDENS');

Future<void> _loadFonts() async {
  final loader = FontLoader('Roboto_regular');
  for (final w in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/google_fonts/Roboto-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void _mockPlugins() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in [
    'com.kurenai7968.volume_controller.method',
    'com.kurenai7968.volume_controller.volume_listener_event',
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => call.method == 'getVolume' ? 0.5 : null,
    );
  }
  messenger.setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/permissions/methods'),
    (call) async => call.method == 'requestPermissions' ? <int, int>{} : 1,
  );
  const codec = StandardMessageCodec();
  for (final api in ['setAlarm', 'stopAlarm', 'isRinging']) {
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.alarm.AlarmApi.$api',
      (_) async =>
          codec.encodeMessage(<Object?>[api == 'isRinging' ? false : null]),
    );
  }
}

Map<String, Object> _prefsWithAlarms() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  AlarmModel make(int id, int h, int m, List<bool> days,
          {String? title, bool active = true, int weeks = 1}) =>
      AlarmModel(
        id: id,
        title: title,
        time: DateTime(today.year, today.month, today.day, h, m),
        assetAudio: 'marimba.mp3',
        selectedDays: days,
        isActive: active,
        recurrenceWeeks: weeks,
        createdAt: today,
        createdFor: today,
      );
  final alarms = [
    make(1, 6, 45, [true, true, true, true, true, false, false],
        title: 'Boulot')
      ..skipHolidays = true,
    make(2, 9, 30, [false, false, false, false, false, true, true],
        title: 'Grasse mat\''),
    make(3, 7, 15, [true, false, true, false, false, false, false],
        weeks: 2, title: 'Piscine'),
    make(4, 5, 0, List.filled(7, false), active: false),
  ];
  return {
    // Vacances jusqu'à demain inclus
    'vacationResumeAt':
        today.add(const Duration(days: 2)).millisecondsSinceEpoch,
    AlarmService.alarmKey: alarms.map((a) => jsonEncode(a.toMap())).toList(),
  };
}

Widget _app(Locale locale, Widget home) => BlocProvider(
      create: (_) => LocaleCubit(locale),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Themes.night(),
        locale: locale,
        supportedLocales: LocalizationApp.supportedLocales,
        localizationsDelegates: [
          LocalizationApp.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    await _loadFonts();
    _mockPlugins();
  });

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'edit': () => AlarmEditScreen(alarm: null),
    'edit_recurring': () => AlarmEditScreen(
          alarm: AlarmModel.fromMap(jsonDecode(
              (_prefsWithAlarms()[AlarmService.alarmKey]
                  as List<String>)[0]) as Map<String, dynamic>),
        ),
    'settings': () => const SettingsScreen(),
    'planning': () => const PlanningScreen(),
    'ring': () => AlarmRingScreen(
          alarmSettings: AlarmSettings(
            id: 10,
            dateTime: DateTime.now(),
            assetAudioPath: 'assets/musics/marimba.mp3',
            volume: 0.4,
            notificationSettings: const NotificationSettings(
              title: 'Boulot',
              body: 'Votre alarme sonne.',
            ),
          ),
          loadAlarms: () async {},
        ),
  };

  for (final locale in const [Locale('fr', 'FR'), Locale('en', 'EN')]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} (${locale.languageCode})', (tester) async {
        // Flux natifs sans implémentation en test (fgbg, events audioplayers)
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exception is MissingPluginException) return;
          originalOnError?.call(details);
        };
        final originalPrint = debugPrint;
        final missingKeys = <String>[];
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null && message.contains('Missing Key')) {
            missingKeys.add(message);
          }
        };

        SharedPreferences.setMockInitialValues(_prefsWithAlarms());
        await AlarmStorage.init();
        // En mode captures, l'édition est rendue en entier (pas de défilement)
        tester.view.physicalSize =
            Size(390, _goldens && entry.key.startsWith('edit') ? 1500 : 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.runAsync(() async {
          // L'édition s'ouvre dans une feuille à 94 % de la hauteur
          final screen = entry.key.startsWith('edit')
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                      heightFactor: 0.94, child: entry.value()),
                )
              : entry.value();
          await tester.pumpWidget(_app(locale, screen));
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pump(const Duration(milliseconds: 500));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)));
        await tester.pump(const Duration(milliseconds: 500));

        debugPrint = originalPrint;
        if (_goldens) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
                'goldens/${entry.key}_${locale.languageCode}.png'),
          );
        }
        expect(missingKeys, isEmpty);

        // Libère les timers périodiques des écrans
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
        FlutterError.onError = originalOnError;
      });
    }
  }
}
