import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/models/alarm_model.dart';
import 'package:my_alarms/services/alarm_service.dart';
import 'package:my_alarms/widgets/next_alarm_set.dart';
import 'package:url_launcher/url_launcher.dart';

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
  }

  Future<void> loadAlarms() async {
    final loadedAlarms = await alarmService.getAlarms();
    setState(() {
      alarms = loadedAlarms;
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) {
        return AlarmRingScreen(
            alarmSettings: alarmSettings, loadAlarms: loadAlarms);
      }),
    );

    unawaited(loadAlarms());
  }

  Future<void> navigateToAlarmScreen(AlarmModel? alarm, {int? index}) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
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

  // Function to open the URL
  void _launchURL() async {
    const url = 'devmeup.fr';
    if (await canLaunchUrl(Uri.https(url))) {
      await launchUrl(Uri.https(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: alarms.isNotEmpty
            ? Column(
                children: [
                  NextAlarmSet(),
                  Expanded(
                      child: ListView.builder(
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
                            onPressed: () => navigateToAlarmScreen(
                                alarms[index],
                                index: index),
                            onDismissed: () async {
                              await alarmService
                                  .deleteAlarm(context, index)
                                  .then((_) => loadAlarms());
                            },
                            onToggleActive: (value) async {
                              setState(() {
                                alarms[index].isActive = value;
                                alarms[index].createdAt = DateTime.now();
                              });
                              await alarmService
                                  .editAlarm(context, alarms[index], index)
                                  .then((_) => loadAlarms());
                            }),
                      );
                    },
                  )),
                  GestureDetector(
                    onTap: _launchURL, // Open the URL when tapped
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'DevMeUp',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  context.translate('noAlarmSet'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.grey),
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(10),
        child: FloatingActionButton(
          onPressed: () => navigateToAlarmScreen(null),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.alarm_add_rounded, size: 33),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
