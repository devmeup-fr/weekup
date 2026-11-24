import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un son importé depuis le téléphone, copié dans le stockage de l'app
/// (`<documents>/sounds/<file>`) pour rester disponible même si l'original
/// est supprimé.
class CustomSound {
  final String file;
  final String name;

  const CustomSound(this.file, this.name);

  /// Valeur stockée dans `AlarmModel.assetAudio`.
  String get assetAudio => '${CustomSoundService.prefix}$file';

  Map<String, dynamic> toMap() => {'file': file, 'name': name};

  factory CustomSound.fromMap(Map<String, dynamic> m) =>
      CustomSound(m['file'] as String, m['name'] as String);
}

class CustomSoundService {
  /// Les sons intégrés sont de simples noms de fichier ("marimba.mp3") ;
  /// les sons importés sont préfixés.
  static const String prefix = 'custom:';
  static const String _prefsKey = 'custom_sounds';
  static const String _dirName = 'sounds';

  static bool isCustom(String assetAudio) => assetAudio.startsWith(prefix);

  static String _file(String assetAudio) => assetAudio.substring(prefix.length);

  /// Chemin relatif au dossier documents, format accepté par le plugin
  /// d'alarme sur Android comme sur iOS (le chemin absolu change sur iOS).
  static String relativePath(String assetAudio) =>
      '$_dirName/${_file(assetAudio)}';

  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, _dirName)).create(recursive: true);
  }

  static Future<File> fileFor(String assetAudio) async =>
      File(p.join((await _dir()).path, _file(assetAudio)));

  static Future<List<CustomSound>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    return [
      for (final s in raw)
        CustomSound.fromMap(jsonDecode(s) as Map<String, dynamic>),
    ];
  }

  static Future<void> _save(List<CustomSound> sounds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      sounds.map((s) => jsonEncode(s.toMap())).toList(),
    );
  }

  /// Ouvre le sélecteur de fichiers audio et importe le son choisi.
  static Future<CustomSound?> pick() async {
    final picked = await FilePicker.pickFile(type: FileType.audio);
    if (picked == null) return null;

    final ext = p.extension(picked.name);
    final file = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final target = p.join((await _dir()).path, file);
    // Pas de chemin local quand le sélecteur renvoie une URI content:// (Android).
    final path = picked.path;
    if (path != null) {
      await File(path).copy(target);
    } else {
      await File(target).writeAsBytes(await picked.readAsBytes());
    }

    final sound = CustomSound(file, p.basenameWithoutExtension(picked.name));
    await _save([...await list(), sound]);
    return sound;
  }

  static Future<void> remove(CustomSound sound) async {
    final f = await fileFor(sound.assetAudio);
    if (await f.exists()) await f.delete();
    await _save((await list()).where((s) => s.file != sound.file).toList());
  }

  /// Nom affichable d'un son importé, ou null s'il a été supprimé.
  static String? nameOf(String assetAudio, List<CustomSound> sounds) {
    for (final s in sounds) {
      if (s.assetAudio == assetAudio) return s.name;
    }
    return null;
  }
}
