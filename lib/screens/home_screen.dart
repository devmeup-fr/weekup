import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/screens/alarm_logs_screen.dart';
import 'package:weekup/screens/settings_screen.dart';
import 'package:weekup/services/alarm_log_service.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/widgets/devmeup_widget.dart';
import 'package:weekup/widgets/next_alarm_set.dart';

import '../services/alarm_permissions_service.dart';
import '../widgets/alarm_tile.dart';
import 'alarm_edit_screen.dart';
import 'alarm_ring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlarmModel> alarms = [];
  bool getSnoozeAlarms = false;
  late AlarmService alarmService;

  static StreamSubscription<AlarmSettings>? ringSubscription;
  static StreamSubscription<int>? updateSubscription;

  @override
  void initState() {
    super.initState();
    AlarmPermissionsService.checkNotificationPermission(context);
    if (Alarm.android) {
      AlarmPermissionsService.checkAndroidScheduleExactAlarmPermission(context);
    }
    alarmService = AlarmService();
    unawaited(loadAlarms());
    ringSubscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
  }

  Future<void> loadAlarms() async {
    getSnoozeAlarms = await alarmService.isSnoozeAlarms();
    final loadedAlarms = await alarmService.getAlarms(withoutSnooze: true);
    setState(() {
      alarms = loadedAlarms.reversed.toList();
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    debugPrint(
      '[ALARM] 🚨 Alarm rang -> id=${alarmSettings.id}, '
      'title=${alarmSettings.notificationSettings.title}, '
      'dateTime=${alarmSettings.dateTime}',
    );

    await alarmService.saveAlarmLog(alarmSettings);

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AlarmRingScreen(
          alarmSettings: alarmSettings,
          loadAlarms: loadAlarms,
        ),
      ),
    );

    unawaited(loadAlarms());
  }

  Future<void> navigateToAlarmEditScreen(AlarmModel? alarm,
      {int? index}) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.65,
          child: AlarmEditScreen(
            alarm: alarm,
            index: index,
          ),
        );
      },
    );

    if (res != null && res == true) unawaited(loadAlarms());
  }

  @override
  void dispose() {
    ringSubscription?.cancel();
    updateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _navigateToLogs() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlarmLogsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarDividerColor: ThemeColors.primary,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.black87,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              context.translate('common.appTitle'),
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              // IconButton(
              //   tooltip: context.translate('settings.title'), // optionnel
              //   icon: const Icon(Icons.settings, color: Colors.white),
              //   onPressed: _navigateToSettings,
              // ),
              IconButton(
                tooltip: 'Logs', // ou context.translate('logs.title')
                icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
                onPressed: _navigateToLogs,
              ),
            ],
          ),
          body: SafeArea(
              child: Column(
            children: [
              if (getSnoozeAlarms && alarms.isEmpty)
                NextAlarmSet(reloadAlarms: loadAlarms),
              if (alarms.isNotEmpty) ...[
                NextAlarmSet(reloadAlarms: loadAlarms),
                Expanded(
                    child: ListView.builder(
                  itemCount: alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = alarms[index];
                    return Card(
                      color: Colors.white.withValues(alpha: 0.13),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: AlarmTile(
                          key: Key(alarm.id.toString()),
                          alarm: alarm,
                          onPressed: () =>
                              navigateToAlarmEditScreen(alarm, index: index),
                          onDismissed: () async {
                            final removedAlarm = alarms.removeAt(index);
                            setState(() {});
                            await alarmService
                                .deleteAlarmById(context, removedAlarm.id!,
                                    reschedule: true)
                                .then((_) => loadAlarms())
                                .catchError((error) {
                              // Réinsère l'élément si une erreur survient
                              setState(() {
                                alarms.insert(index, removedAlarm);
                              });
                            });
                          },
                          onToggleActive: (value) async {
                            setState(() {
                              alarm.isActive = value;
                              alarm.createdAt = DateTime.now();
                            });
                            await alarmService
                                .editAlarmById(context, alarm)
                                .then((_) => loadAlarms());
                          }),
                    );
                  },
                )),
              ] else
                Expanded(
                    child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        navigateToAlarmEditScreen(null, index: alarms.length),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            24), // ← change ici pour arrondir plus ou moins
                      ),
                      padding: EdgeInsets.all(16.0),
                    ),
                    icon: Icon(
                      Icons.alarm_add_rounded,
                      size: 33,
                      color: Colors.white,
                    ),
                    label: Text(
                      context.translate('alarms.new'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                )),
              DevMeUpWidget()
            ],
          )),
          floatingActionButton: alarms.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(10),
                  child: FloatingActionButton(
                    onPressed: () =>
                        navigateToAlarmEditScreen(null, index: alarms.length),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.alarm_add_rounded,
                        size: 33,
                        semanticLabel: context.translate('alarms.new')),
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ));
  }
}
