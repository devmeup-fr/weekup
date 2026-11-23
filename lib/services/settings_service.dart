import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekup/core/enums/storage_keys_enum.dart';

/// Réglages globaux de l'application (persistés dans SharedPreferences).
class AppSettings {
  static const snoozeChoices = [5, 10, 15, 20, 30];
  static const maxSnoozeChoices = [1, 2, 3, 5, 10];
  static const fadeChoices = [0, 10, 30, 60];
  static const upcomingChoices = [0, 15, 30, 60, 120];
  static const silenceChoices = [0, 5, 10, 15, 30];

  final int snoozeMinutes;
  final int maxSnoozes;
  final int fadeSeconds;

  /// Délai de la notification « alarme imminente » (0 = désactivée).
  final int upcomingMinutes;

  /// Arrêt automatique d'une sonnerie sans réponse (0 = jamais).
  final int silenceAfterMinutes;

  const AppSettings({
    this.snoozeMinutes = 10,
    this.maxSnoozes = 3,
    this.fadeSeconds = 10,
    this.upcomingMinutes = 30,
    this.silenceAfterMinutes = 10,
  });

  /// Mode vacances : date (locale, minuit) à laquelle les alarmes
  /// récurrentes reprennent, ou null si aucune pause en cours.
  static Future<DateTime?> vacationResumeAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(PrefStorageKeys.vacationResumeAt.name);
    if (ms == null) return null;
    final resumeAt = DateTime.fromMillisecondsSinceEpoch(ms);
    if (!resumeAt.isAfter(DateTime.now())) {
      await prefs.remove(PrefStorageKeys.vacationResumeAt.name);
      return null;
    }
    return resumeAt;
  }

  /// [lastDayOff] : dernier jour de vacances inclus ; null pour reprendre.
  static Future<void> setVacation(DateTime? lastDayOff) async {
    final prefs = await SharedPreferences.getInstance();
    if (lastDayOff == null) {
      await prefs.remove(PrefStorageKeys.vacationResumeAt.name);
      return;
    }
    final resumeAt =
        DateTime(lastDayOff.year, lastDayOff.month, lastDayOff.day + 1);
    await prefs.setInt(
      PrefStorageKeys.vacationResumeAt.name,
      resumeAt.millisecondsSinceEpoch,
    );
  }

  AppSettings copyWith({
    int? snoozeMinutes,
    int? maxSnoozes,
    int? fadeSeconds,
    int? upcomingMinutes,
    int? silenceAfterMinutes,
  }) {
    return AppSettings(
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      maxSnoozes: maxSnoozes ?? this.maxSnoozes,
      fadeSeconds: fadeSeconds ?? this.fadeSeconds,
      upcomingMinutes: upcomingMinutes ?? this.upcomingMinutes,
      silenceAfterMinutes: silenceAfterMinutes ?? this.silenceAfterMinutes,
    );
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = AppSettings();
    return AppSettings(
      snoozeMinutes: prefs.getInt(PrefStorageKeys.snoozeMinutes.name) ??
          defaults.snoozeMinutes,
      maxSnoozes:
          prefs.getInt(PrefStorageKeys.maxSnoozes.name) ?? defaults.maxSnoozes,
      fadeSeconds: prefs.getInt(PrefStorageKeys.fadeSeconds.name) ??
          defaults.fadeSeconds,
      upcomingMinutes: prefs.getInt(PrefStorageKeys.upcomingMinutes.name) ??
          defaults.upcomingMinutes,
      silenceAfterMinutes:
          prefs.getInt(PrefStorageKeys.silenceAfterMinutes.name) ??
              defaults.silenceAfterMinutes,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefStorageKeys.snoozeMinutes.name, snoozeMinutes);
    await prefs.setInt(PrefStorageKeys.maxSnoozes.name, maxSnoozes);
    await prefs.setInt(PrefStorageKeys.fadeSeconds.name, fadeSeconds);
    await prefs.setInt(PrefStorageKeys.upcomingMinutes.name, upcomingMinutes);
    await prefs.setInt(
      PrefStorageKeys.silenceAfterMinutes.name,
      silenceAfterMinutes,
    );
  }
}
