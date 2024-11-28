import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

// Network settings
// static get delegate =>  FlutterI18nDelegate(
//   translationLoader: CustomNetworkFileTranslationLoader(
//     baseUri: Uri.https("postman-echo.com", "get",
//         {"title": "Basic network example", "content": "Translated content"}),
//   ),
// );

extension ContextExtension on BuildContext {
  String translate(String description,
          {Map<String, String>? translationParams}) =>
      FlutterI18n.translate(this, description,
          translationParams: translationParams);

  bool containsKey(String key) => FlutterI18n.translate(this, key) != key;
}

// Local settings
class LocalizationApp {
  static List<Locale> get supportedLocales => const [
        Locale('fr', 'FR'),
        Locale('en', 'EN'),
        Locale('es', 'ES'),
      ];

  static Locale get forcedLocale => supportedLocales[0];

  static get delegate => FlutterI18nDelegate(
        translationLoader: FileTranslationLoader(
          useCountryCode: false,
          basePath: 'assets/i18n',
          fallbackFile: 'fr', // Langue par défaut
        ),
        missingTranslationHandler: (key, locale) {
          debugPrint(
              "--- Missing Key: $key, languageCode: ${locale?.languageCode}");
        },
      );
}

// class CustomNetworkFileTranslationLoader extends NetworkFileTranslationLoader {
//   CustomNetworkFileTranslationLoader({required baseUri})
//       : super(baseUri: baseUri, decodeStrategies: [JsonDecodeStrategy()]);

//   @override
//   Uri resolveUri(final String fileName, final String extension) {
//     return baseUri;
//   }
// }
