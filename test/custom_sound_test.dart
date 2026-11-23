import 'package:flutter_test/flutter_test.dart';
import 'package:weekup/services/custom_sound_service.dart';

void main() {
  const sound = CustomSound('1700000000000.mp3', 'Ma chanson');

  test('un son importé est reconnu et pointe vers le dossier sounds', () {
    expect(sound.assetAudio, 'custom:1700000000000.mp3');
    expect(CustomSoundService.isCustom(sound.assetAudio), isTrue);
    expect(CustomSoundService.isCustom('marimba.mp3'), isFalse);
    expect(
      CustomSoundService.relativePath(sound.assetAudio),
      'sounds/1700000000000.mp3',
    );
  });

  test('nom affiché, ou null si le son a été supprimé', () {
    expect(CustomSoundService.nameOf(sound.assetAudio, [sound]), 'Ma chanson');
    expect(CustomSoundService.nameOf(sound.assetAudio, const []), isNull);
  });
}
