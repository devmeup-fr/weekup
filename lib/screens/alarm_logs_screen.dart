import 'package:flutter/material.dart';
import 'package:weekup/core/utils/extension_util.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_log_model.dart';
import 'package:weekup/services/alarm_log_service.dart';
import 'package:weekup/services/alarm_service.dart';

class AlarmLogsScreen extends StatelessWidget {
  const AlarmLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarmService = AlarmService();

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(context.translate('logs_title'),
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: context.translate('logs_remove'),
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            onPressed: () async {
              await alarmService.clearAlarmLogs();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<AlarmLogModel>>(
        future: alarmService.getAlarmLogs(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? const <AlarmLogModel>[];
          if (data.isEmpty) {
            return Center(
              child: Text(context.translate('logs_none'),
                  style: TextStyle(color: Colors.white70)),
            );
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Colors.white24),
            itemBuilder: (context, i) {
              final e = data[i];
              return ListTile(
                tileColor: Colors.white.withValues(alpha: 0.08),
                title: Text(
                  e.title.isNotEmpty
                      ? e.title
                      : '${context.translate('alarm_title_placeholder')} #${e.id}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${context.translate('logs_firedAt')}: ${e.firedAt.formatDate()}\n'
                  '${context.translate('logs_scheduledFor')}: ${e.scheduledFor.formatDate()}\n'
                  '${e.isSnooze ? context.translate('logs_isSnooze') : ''}',
                  style: const TextStyle(color: Colors.white70),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              );
            },
          );
        },
      ),
    );
  }
}
