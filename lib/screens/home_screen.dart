import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/models/alarm_model.dart';
import 'package:my_alarms/services/alarm_service.dart';

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
    // updateSubscription ??= Alarm.updateStream.stream.listen((_) {
    //   unawaited(loadAlarms());
    // });
  }

  Future<void> loadAlarms() async {
    final loadedAlarms = await alarmService.getAlarms();
    print(
      "🚀 ~ _HomeScreenState ~ Future<void>loadAlarms ~ loadedAlarms:",
    );
    print(loadedAlarms);
    setState(() {
      alarms = loadedAlarms;
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AlarmRingScreen(alarmSettings: alarmSettings),
      ),
    );
    unawaited(loadAlarms());
  }

  Future<void> navigateToAlarmScreen(AlarmModel? alarm) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: AlarmEditScreen(alarm: alarm),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: alarms.isNotEmpty
              ? ListView.builder(
                  itemCount: alarms.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white.withOpacity(0.13),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: AlarmTile(
                          key: Key(alarms[index].id.toString()),
                          alarm: alarms[index],
                          onPressed: () => navigateToAlarmScreen(alarms[index]),
                          onDismissed: () {
                            alarmService
                                .deleteAlarm(index)
                                .then((_) => loadAlarms());
                          },
                          onToggleActive: (value) {}),
                    );
                  },
                )
              : Center(
                  child: Text(
                    context.translate('noAlarmSet'),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              onPressed: () => navigateToAlarmScreen(null),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.alarm_add_rounded, size: 33),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
