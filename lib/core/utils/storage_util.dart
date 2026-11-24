import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Options spécifiques pour Android :
/// EncryptedSharedPreferences (Jetpack Security) est abandonné depuis la v10 :
/// au premier lancement, les données qui y sont encore sont migrées vers le
/// chiffrement propre au plugin (AES-GCM), avec une copie de sauvegarde le
/// temps de la migration. Cette version doit être publiée avant de passer à
/// flutter_secure_storage 11, qui ne sait plus lire l'ancien format.
AndroidOptions _getAndroidOptions() => const AndroidOptions(
      migrateOnAlgorithmChange: true,
      migrateWithBackup: true,
    );

/// Singleton sécurisé à utiliser partout dans l'app
final FlutterSecureStorage secureStorage = FlutterSecureStorage(
  aOptions: _getAndroidOptions(),
);

Future<String?> safeReadSecure(String key) async {
  try {
    return await secureStorage.read(key: key);
  } catch (e) {
    if (e.toString().contains("BAD_DECRYPT")) {
      await secureStorage.delete(key: key);
      // Log event or report to analytics/crashlytics
    }
    return null;
  }
}

