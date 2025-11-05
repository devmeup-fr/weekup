import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/theme/colors.dart';

class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({
    required this.alarmSettings,
    required this.loadAlarms,
    super.key,
  });

  final AlarmSettings alarmSettings;
  final Function loadAlarms;

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  late final AppLifecycleListener _listener;
  late AlarmService alarmService;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    alarmService = AlarmService();
    _listener = AppLifecycleListener(onInactive: () => snoozeAlarm());
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final isRinging = await Alarm.isRinging(widget.alarmSettings.id);
      if (isRinging) {
        return;
      }

      timer.cancel();
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        await alarmService.setNextAlarm(context, removeSnooze: true);
        await widget.loadAlarms();
      }
    });
  }

  @override
  void dispose() {
    _listener.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> snoozeAlarm() async {
    final snoozeDate = DateTime.now().add(Duration(minutes: 10));

    await Alarm.stop(widget.alarmSettings.id);

    final shadow = AlarmModel(
      id: null,
      title: widget.alarmSettings.notificationSettings.title,
      time: snoozeDate,
      isActive: true,
      loopAudio: widget.alarmSettings.loopAudio,
      vibrate: widget.alarmSettings.vibrate,
      volume: widget.alarmSettings.volume,
      assetAudio: widget.alarmSettings.assetAudioPath.split('/').last,
      isSnooze: true,
    );

    await alarmService.saveAlarm(context, shadow, showToast: false);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
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
              ThemeColors.primary,
              ThemeColors.secondary,
              ThemeColors.secondary,
              ThemeColors.primary,
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
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 30),
            // Titre principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '⏰',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 38,
                          color: Colors.white70,
                        ),
                  ),
                  Text(
                    widget.alarmSettings.notificationSettings.title,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ],
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
                  color: ThemeColors.primaryLight,
                  onPressed: snoozeAlarm,
                ),
                _buildActionButton(
                  context,
                  title: context.translate('alarmStop'),
                  color: ThemeColors.primary,
                  onPressed: () async {
                    await Alarm.stop(widget.alarmSettings.id);
                    await alarmService.setNextAlarm(context);

                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
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
