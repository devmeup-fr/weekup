import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmPermissionsService {
  static Future<void> checkNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      alarmPrint(context.translate('requesting_notification_permission'));
      final res = await Permission.notification.request();
      alarmPrint(
        context.translate(
          res.isGranted
              ? 'notification_permission_granted'
              : 'notification_permission_denied',
        ),
      );
    }
  }

  static Future<void> checkAndroidExternalStoragePermission(
      BuildContext context) async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      alarmPrint(context.translate('requesting_external_storage_permission'));
      final res = await Permission.storage.request();
      alarmPrint(
        context.translate(
          res.isGranted
              ? 'external_storage_permission_granted'
              : 'external_storage_permission_denied',
        ),
      );
    }
  }

  static Future<void> checkAndroidScheduleExactAlarmPermission(
      BuildContext context) async {
    final status = await Permission.scheduleExactAlarm.status;
    alarmPrint(
      context.translate(
        'schedule_exact_alarm_permission_status',
        translationParams: {'status': status.toString()},
      ),
    );
    if (status.isDenied) {
      alarmPrint(
          context.translate('requesting_schedule_exact_alarm_permission'));
      final res = await Permission.scheduleExactAlarm.request();
      alarmPrint(
        context.translate(
          res.isGranted
              ? 'schedule_exact_alarm_permission_granted'
              : 'schedule_exact_alarm_permission_denied',
        ),
      );
    }
  }
}
