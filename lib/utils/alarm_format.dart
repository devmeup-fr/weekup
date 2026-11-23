import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:weekup/core/blocs/locale_cubit.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';

String localeCode(BuildContext context) =>
    context.read<LocaleCubit>().state.languageCode;

/// "7 h 32 min", "2 j 3 h", "moins d'une minute"
String formatCountdown(BuildContext context, Duration diff) {
  if (diff.inMinutes < 1) return context.translate('duration.lessThanMinute');

  // Arrondi à la minute supérieure : 7 h 31 min 20 s => 7 h 32 min
  final totalMinutes =
      diff.inSeconds % 60 == 0 ? diff.inMinutes : diff.inMinutes + 1;
  final days = totalMinutes ~/ (24 * 60);
  final hours = (totalMinutes ~/ 60) % 24;
  final minutes = totalMinutes % 60;

  String unit(String key, int n) =>
      context.translate('duration.$key', translationParams: {'n': '$n'});

  final parts = <String>[
    if (days > 0) unit('days', days),
    if (hours > 0) unit('hours', hours),
    if (minutes > 0 && days == 0) unit('minutes', minutes),
  ];
  return parts.join(' ');
}

/// "Aujourd'hui", "Demain", ou "mar. 24 nov."
/// Avec [inSentence], en minuscule pour s'insérer dans une phrase.
String formatRelativeDay(BuildContext context, DateTime date,
    {bool inSentence = false}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final delta = DateTime.utc(day.year, day.month, day.day)
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays;
  String word(String key) {
    final text = context.translate(key);
    return inSentence ? text.toLowerCase() : text;
  }

  if (delta == 0) return word('day.today');
  if (delta == 1) return word('day.tomorrow');
  return DateFormat('EEE d MMM', localeCode(context)).format(date);
}

/// Nom court localisé du jour (index 0 = lundi).
String shortDayName(BuildContext context, int index) {
  // 1er janvier 2024 = lundi
  final date = DateTime(2024, 1, 1 + index);
  final name = DateFormat('EEE', localeCode(context)).format(date);
  return name.replaceAll('.', '');
}

/// Résumé lisible de la répétition : "Une fois", "En semaine", "Lun, Mer"…
/// Avec [listDays] à false, les jours personnalisés ne sont pas énumérés
/// (la tuile les affiche déjà en pastilles).
String formatSchedule(BuildContext context, AlarmModel alarm,
    {bool listDays = true}) {
  if (alarm.isOneShot) return context.translate('repeat.once');

  String days;
  final d = alarm.selectedDays;
  if (alarm.isDaily) {
    days = context.translate('repeat.everyday');
  } else if (d.sublist(0, 5).every((x) => x) && !d[5] && !d[6]) {
    days = context.translate('repeat.weekdays');
  } else if (d.sublist(0, 5).every((x) => !x) && d[5] && d[6]) {
    days = context.translate('repeat.weekend');
  } else if (!listDays) {
    days = '';
  } else {
    days = [
      for (var i = 0; i < 7; i++)
        if (d[i]) shortDayName(context, i),
    ].join(', ');
  }

  if (alarm.recurrenceWeeks > 1) {
    final weeks = context.translate('x_weeks',
        translationParams: {'weeks': '${alarm.recurrenceWeeks}'});
    days = days.isEmpty ? weeks : '$days · $weeks';
  }
  return days;
}

String formatHourMinute(DateTime date) => DateFormat('HH:mm').format(date);
