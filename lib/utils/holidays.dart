/// Jours fériés français (métropole), calculés hors ligne.
enum Holiday {
  newYear,
  easterMonday,
  labourDay,
  victoryDay,
  ascension,
  whitMonday,
  bastilleDay,
  assumption,
  allSaints,
  armistice,
  christmas,
}

final Map<int, Map<DateTime, Holiday>> _cache = {};

/// Dimanche de Pâques (algorithme de Meeus/Jones/Butcher).
DateTime easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

Map<DateTime, Holiday> frenchHolidays(int year) {
  return _cache.putIfAbsent(year, () {
    final easter = easterSunday(year);
    DateTime fromEaster(int days) =>
        DateTime(easter.year, easter.month, easter.day + days);
    return {
      DateTime(year, 1, 1): Holiday.newYear,
      fromEaster(1): Holiday.easterMonday,
      DateTime(year, 5, 1): Holiday.labourDay,
      DateTime(year, 5, 8): Holiday.victoryDay,
      fromEaster(39): Holiday.ascension,
      fromEaster(50): Holiday.whitMonday,
      DateTime(year, 7, 14): Holiday.bastilleDay,
      DateTime(year, 8, 15): Holiday.assumption,
      DateTime(year, 11, 1): Holiday.allSaints,
      DateTime(year, 11, 11): Holiday.armistice,
      DateTime(year, 12, 25): Holiday.christmas,
    };
  });
}

/// Le jour férié tombant à cette date (heure ignorée), sinon null.
Holiday? holidayOn(DateTime date) =>
    frenchHolidays(date.year)[DateTime(date.year, date.month, date.day)];
