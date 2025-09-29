import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Options spécifiques pour Android :
/// Utilisation de EncryptedSharedPreferences (chiffrement natif)
AndroidOptions _getAndroidOptions() => const AndroidOptions(
      encryptedSharedPreferences: true,
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

