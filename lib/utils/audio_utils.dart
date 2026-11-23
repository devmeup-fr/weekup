import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:weekup/services/custom_sound_service.dart';

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

/// Chemin à donner au plugin d'alarme pour `AlarmModel.assetAudio` :
/// son intégré, ou son importé (repli sur le son par défaut s'il a disparu).
Future<String> resolveAlarmAudio(String assetAudio) async {
  if (CustomSoundService.isCustom(assetAudio)) {
    try {
      if (await (await CustomSoundService.fileFor(assetAudio)).exists()) {
        return CustomSoundService.relativePath(assetAudio);
      }
    } catch (e) {
      debugPrint('Son importé inaccessible: $assetAudio ($e)');
    }
    return fallback;
  }
  return resolveAudioOrDefault('assets/musics/$assetAudio');
}
