import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/localization_util.dart';

class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({required this.alarmSettings, super.key});

  final AlarmSettings alarmSettings;

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final isRinging = await Alarm.isRinging(widget.alarmSettings.id);
      if (isRinging) {
        alarmPrint('Alarm ${widget.alarmSettings.id} is still ringing...');
        return;
      }

      alarmPrint('Alarm ${widget.alarmSettings.id} stopped ringing.');
      timer.cancel();
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          // Titre principal
          Text(
            '⏰ ${context.translate('alarmTitle')} ⏰',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 15),
          Text(
            context.translate('alarmDescription'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 20,
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 30),
          Text(
            formattedTime,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                context,
                title: context.translate('alarmSnooze'),
                color: Color.fromARGB(96, 199, 15, 231),
                onPressed: () {
                  final now = DateTime.now();
                  Alarm.stop(widget.alarmSettings.id);
                  Alarm.set(
                    alarmSettings: widget.alarmSettings.copyWith(
                      dateTime: DateTime(
                        now.year,
                        now.month,
                        now.day,
                        now.hour,
                        now.minute,
                      ).add(const Duration(minutes: 5)),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                title: context.translate('alarmStop'),
                color: Colors.redAccent,
                onPressed: () {
                  Alarm.stop(widget.alarmSettings.id);
                },
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildActionButton(BuildContext context,
      {required String title,
      required Color color,
      required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          backgroundColor: color,
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
