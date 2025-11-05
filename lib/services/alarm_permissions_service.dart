import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:weekup/core/utils/localization_util.dart';

class AlarmPermissionsService {
  static Future<void> checkNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      if (context.mounted) {
        alarmPrint(context.translate('requesting_notification_permission'));
      }
      final res = await Permission.notification.request();
      if (context.mounted) {
        alarmPrint(
          context.translate(
            res.isGranted
                ? 'notification_permission_granted'
                : 'notification_permission_denied',
          ),
        );
      }
    }
  }

  static Future<void> checkAndroidExternalStoragePermission(
    BuildContext context,
  ) async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      if (context.mounted) {
        alarmPrint(context.translate('requesting_external_storage_permission'));
      }
      final res = await Permission.storage.request();
      if (context.mounted) {
        alarmPrint(
          context.translate(
            res.isGranted
                ? 'external_storage_permission_granted'
                : 'external_storage_permission_denied',
          ),
        );
      }
    }
  }

  static Future<void> checkAndroidScheduleExactAlarmPermission(
    BuildContext context,
  ) async {
    final status = await Permission.scheduleExactAlarm.status;
    if (context.mounted) {
      alarmPrint(
        context.translate(
          'schedule_exact_alarm_permission_status',
          translationParams: {'status': status.toString()},
        ),
      );
    }
    if (status.isDenied) {
      if (context.mounted) {
        alarmPrint(
          context.translate('requesting_schedule_exact_alarm_permission'),
        );
      }
      final res = await Permission.scheduleExactAlarm.request();
      if (context.mounted) {
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
}
