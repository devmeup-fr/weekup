import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/services/next_alarm_widget_service.dart';
import 'package:weekup/services/upcoming_notification_service.dart';

void main() {
  const texts = AlarmNotificationTexts(
    defaultTitle: 'Votre alarme',
    body: 'Votre alarme sonne.',
    stopButton: "Arrêter l'alarme",
    upcoming: UpcomingTexts(
      title: 'Alarme à {time}',
      titleNamed: '{title} · {time}',
      body: 'Bientôt.',
      ignore: 'Ignorer',
      channelName: 'Alarmes imminentes',
      ringBody: 'Il est {time}',
      ringStop: 'Arrêter',
      ringSnooze: 'Reporter',
      ringChannel: 'Alarme en cours',
    ),
    widget: NextAlarmWidgetTexts(
      header: 'Prochaine alarme',
      empty: 'Aucune alarme active',
      today: "Aujourd'hui",
      tomorrow: 'Demain',
      snooze: 'Rappel différé',
      locale: 'fr',
    ),
  );

  test('les textes mis en cache sont relus à l\'identique (moteur '
      'd\'arrière-plan)', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await AlarmNotificationTexts.cached(), isNull);
    await texts.cache();
    final back = await AlarmNotificationTexts.cached();
    expect(back!.toMap(), texts.toMap());
  });
}
