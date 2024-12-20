import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/services/alarm_service.dart';

class AlarmRingScreen extends StatelessWidget {
  const AlarmRingScreen({required this.alarmSettings, super.key});

  final AlarmSettings alarmSettings;

  @override
  Widget build(BuildContext context) {
    // Récupérer l'heure actuelle
    final currentTime = DateTime.now();
    final formattedTime =
        '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(96, 199, 15, 231),
              Colors.black,
              Colors.black,
              Colors.black,
              Color.fromARGB(96, 199, 15, 231)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône centrale avec animation
            AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: AlwaysStoppedAnimation(0.5),
              size: 120,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 30),
            // Titre principal avec effet d'ombre
            Text(
              '⏰ ${context.translate('alarmTitle')} ⏰',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 5.0,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            // Sous-titre ou description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                context.translate('alarmDescription'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
              ),
            ),
            const SizedBox(height: 30),
            // Affichage de l'heure actuelle
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 5.0,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            // Boutons d'actions avec un design moderne
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bouton Snooze
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      Alarm.set(
                        alarmSettings: alarmSettings.copyWith(
                          dateTime: DateTime(
                            now.year,
                            now.month,
                            now.day,
                            now.hour,
                            now.minute,
                          ).add(
                              const Duration(minutes: 5)), // Ajout de 5 minutes
                        ),
                      ).then((_) async {
                        if (context.mounted) {
                          Navigator.pop(context);
                          await AlarmService().setNextAlarm(context);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Color.fromARGB(96, 199, 15, 231),
                      elevation: 5,
                    ),
                    child: Text(
                      context.translate('alarmSnooze'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white),
                    ),
                  ),
                ),
                // Bouton Stop
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      Alarm.stop(alarmSettings.id).then((_) async {
                        if (context.mounted) {
                          Navigator.pop(context);
                          await AlarmService().setNextAlarm(context);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 5,
                    ),
                    child: Text(
                      context.translate('alarmStop'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
