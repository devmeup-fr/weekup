import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

final fallback = "assets/musics/default_alarm.mp3";

Future<String> resolveAudioOrDefault(String candidate) async {
  try {
    await rootBundle.load(candidate);
    return candidate;
  } catch (_) {
    debugPrint('Alarm audio introuvable: $candidate. Repli: $fallback');
    await rootBundle.load(fallback);
    return fallback;
  }
}
