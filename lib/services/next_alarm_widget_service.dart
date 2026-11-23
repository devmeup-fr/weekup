import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:weekup/models/alarm_model.dart';

/// Textes du widget, résolus avec un BuildContext.
class NextAlarmWidgetTexts {
  final String header;
  final String empty;
  final String today;
  final String tomorrow;
  final String snooze;
  final String locale;

  const NextAlarmWidgetTexts({
    required this.header,
    required this.empty,
    required this.today,
    required this.tomorrow,
    required this.snooze,
    required this.locale,
  });

  Map<String, dynamic> toMap() => {
        'header': header,
        'empty': empty,
        'today': today,
        'tomorrow': tomorrow,
        'snooze': snooze,
        'locale': locale,
      };

  factory NextAlarmWidgetTexts.fromMap(Map<String, dynamic> m) =>
      NextAlarmWidgetTexts(
        header: m['header'] as String,
        empty: m['empty'] as String,
        today: m['today'] as String,
        tomorrow: m['tomorrow'] as String,
        snooze: m['snooze'] as String,
        locale: m['locale'] as String,
      );
}

/// Widget Android « Prochaine alarme » (voir NextAlarmWidget.kt).
class NextAlarmWidgetService {
  static const String qualifiedAndroidName =
      'com.devmeup.my_alarms.NextAlarmWidget';
  static const int maxEntries = 20;

  /// [occurrences] : sonneries à venir, toutes alarmes confondues.
  static Future<void> update(
    List<({DateTime date, AlarmModel alarm})> occurrences,
    NextAlarmWidgetTexts texts,
  ) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final sorted = [...occurrences]..sort((a, b) => a.date.compareTo(b.date));
    final next = sorted.take(maxEntries).toList();
    final dayFormat = DateFormat('EEE d MMM', texts.locale);
    final timeFormat = DateFormat('HH:mm');

    final entries = [
      for (final o in next)
        {
          't': o.date.millisecondsSinceEpoch,
          'time': timeFormat.format(o.date),
          'day': dayFormat.format(o.date),
          'label': o.alarm.isSnooze
              ? texts.snooze
              : (o.alarm.hasTitle ? o.alarm.title! : ''),
        },
    ];

    await HomeWidget.saveWidgetData<String>('entries', jsonEncode(entries));
    await HomeWidget.saveWidgetData<String>('header', texts.header);
    await HomeWidget.saveWidgetData<String>('empty', texts.empty);
    await HomeWidget.saveWidgetData<String>('today', texts.today);
    await HomeWidget.saveWidgetData<String>('tomorrow', texts.tomorrow);
    await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedAndroidName);

    // Rafraîchir juste après chaque sonnerie et à minuit (« Demain » devient
    // « Aujourd'hui »), même si l'app n'est pas rouverte.
    final now = DateTime.now();
    final times = <DateTime>{
      for (final o in next) o.date.add(const Duration(minutes: 1)),
      for (var d = 1; d <= 2; d++) DateTime(now.year, now.month, now.day + d),
    }.where((t) => t.isAfter(now)).toList()
      ..sort();
    await HomeWidget.scheduleWidgetUpdates(
      times,
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }
}
