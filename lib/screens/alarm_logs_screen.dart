import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_log_model.dart';
import 'package:weekup/services/alarm_log_service.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/utils/alarm_format.dart';

class AlarmLogsScreen extends StatefulWidget {
  const AlarmLogsScreen({super.key});

  @override
  State<AlarmLogsScreen> createState() => _AlarmLogsScreenState();
}

class _AlarmLogsScreenState extends State<AlarmLogsScreen> {
  final alarmService = AlarmService();
  late Future<List<AlarmLogModel>> _logs = alarmService.getAlarmLogs();

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.translate('logs_remove')),
        content: Text(ctx.translate('logs_remove_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.errorSoft),
            child: Text(ctx.translate('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await alarmService.clearAlarmLogs();
    setState(() => _logs = alarmService.getAlarmLogs());
  }

  ({IconData icon, Color color, String label}) _style(AlarmLogModel e) {
    switch (e.action) {
      case AlarmLogAction.snooze:
        return (
          icon: Icons.snooze_rounded,
          color: ThemeColors.secondary,
          label: context.translate('logs_action.snooze', translationParams: {
            'time': formatHourMinute(e.scheduledFor.toLocal()),
          }),
        );
      case AlarmLogAction.stop:
        return (
          icon: Icons.alarm_off_rounded,
          color: ThemeColors.success,
          label: context.translate('logs_action.stop'),
        );
      case AlarmLogAction.ring:
        return (
          icon: Icons.notifications_active_rounded,
          color: Colors.white,
          label: context.translate(
              e.isSnooze ? 'logs_action.ring_snooze' : 'logs_action.ring'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('logs_title')),
        actions: [
          IconButton(
            tooltip: context.translate('logs_remove'),
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clear,
          ),
        ],
      ),
      body: FutureBuilder<List<AlarmLogModel>>(
        future: _logs,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? const <AlarmLogModel>[];
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded,
                      size: 56, color: ThemeColors.textFaint),
                  const SizedBox(height: 12),
                  Text(context.translate('logs_none'),
                      style: const TextStyle(color: ThemeColors.textMuted)),
                ],
              ),
            );
          }

          // Regroupement par jour
          final items = <Widget>[];
          DateTime? currentDay;
          for (final e in data) {
            final fired = e.firedAt.toLocal();
            final day = DateTime(fired.year, fired.month, fired.day);
            if (currentDay != day) {
              currentDay = day;
              items.add(Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  DateFormat('EEEE d MMMM', localeCode(context)).format(day),
                  style: textTheme.labelLarge
                      ?.copyWith(color: ThemeColors.textMuted),
                ),
              ));
            }
            final style = _style(e);
            items.add(ListTile(
              leading: CircleAvatar(
                backgroundColor: ThemeColors.nightSurfaceHigh,
                child: Icon(style.icon, color: style.color, size: 20),
              ),
              title: Text(
                e.title.isNotEmpty
                    ? e.title
                    : context.translate('alarm_title_placeholder'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(style.label,
                  style: const TextStyle(color: ThemeColors.textMuted)),
              trailing: Text(
                DateFormat('HH:mm').format(fired),
                style: textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: items,
          );
        },
      ),
    );
  }
}
