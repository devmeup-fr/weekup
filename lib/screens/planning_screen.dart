import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/screens/alarm_edit_screen.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/services/settings_service.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/utils/alarm_format.dart';
import 'package:weekup/utils/holidays.dart';

/// Ce qui sonne (ou non) d'aujourd'hui à la fin de la semaine prochaine.
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningEntry {
  final AlarmModel alarm;
  final Occurrence occurrence;

  const _PlanningEntry(this.alarm, this.occurrence);
}

class _PlanningScreenState extends State<PlanningScreen> {
  final alarmService = AlarmService();
  List<AlarmModel>? alarms;
  DateTime? resumeAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await alarmService.cleanup();
    final vacation = await AppSettings.vacationResumeAt();
    if (!mounted) return;
    setState(() {
      alarms = loaded;
      resumeAt = vacation;
    });
  }

  Future<void> _edit(AlarmModel alarm) async {
    if (alarm.isSnooze) return;
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.94,
        child: AlarmEditScreen(alarm: alarm),
      ),
    );
    if (res == true) await _load();
  }

  /// Jours d'aujourd'hui au dimanche de la semaine prochaine.
  List<DateTime> _days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final count = 7 - (today.weekday - 1) + 7;
    return [
      for (var i = 0; i < count; i++)
        DateTime(today.year, today.month, today.day + i),
    ];
  }

  Map<DateTime, List<_PlanningEntry>> _entries(List<DateTime> days) {
    final from = days.first;
    final to = days.last.add(const Duration(days: 1));
    final byDay = {for (final d in days) d: <_PlanningEntry>[]};
    for (final alarm in alarms!) {
      for (final o in alarm.occurrencesBetween(from, to, resumeAt: resumeAt)) {
        final day = DateTime(o.date.year, o.date.month, o.date.day);
        byDay[day]?.add(_PlanningEntry(alarm, o));
      }
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.occurrence.date.compareTo(b.occurrence.date));
    }
    return byDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.translate('planning.title'))),
      body: alarms == null ? const SizedBox.shrink() : _buildList(),
    );
  }

  Widget _buildList() {
    final days = _days();
    final entries = _entries(days);
    final items = <Widget>[];

    for (final day in days) {
      if (day == days.first || day.weekday == DateTime.monday) {
        items.add(_WeekHeader(
          label: context.translate(
              day == days.first ? 'planning.this_week' : 'planning.next_week'),
        ));
      }
      items.add(_DayRow(
        day: day,
        entries: entries[day]!,
        onVacation: resumeAt != null && day.isBefore(resumeAt!),
        onTap: _edit,
      ));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Text(
              context.translate('planning.hint'),
              style: const TextStyle(color: ThemeColors.textMuted),
            ),
          ),
          ...items,
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: ThemeColors.textMuted,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.entries,
    required this.onVacation,
    required this.onTap,
  });

  final DateTime day;
  final List<_PlanningEntry> entries;
  final bool onVacation;
  final void Function(AlarmModel) onTap;

  @override
  Widget build(BuildContext context) {
    final locale = localeCode(context);
    final now = DateTime.now();
    final isToday = day == DateTime(now.year, now.month, now.day);
    final holiday = holidayOn(day);
    final weekend = day.weekday >= DateTime.saturday;

    final tags = <Widget>[
      if (holiday != null)
        _Tag(
          icon: Icons.celebration_outlined,
          text: context.translate('holidays.names.${holiday.name}'),
        ),
      if (onVacation)
        _Tag(
          icon: Icons.beach_access_rounded,
          text: context.translate('vacation.title'),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color:
              isToday ? ThemeColors.nightSurfaceHigh : ThemeColors.nightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isToday
                ? ThemeColors.secondary.withValues(alpha: 0.5)
                : ThemeColors.nightOutline,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE', locale)
                        .format(day)
                        .replaceAll('.', '')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? ThemeColors.secondary
                          : weekend
                              ? ThemeColors.textFaint
                              : ThemeColors.textMuted,
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: isToday ? ThemeColors.secondary : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(spacing: 6, runSpacing: 6, children: tags),
                    ),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        context.translate('planning.no_alarm'),
                        style: const TextStyle(color: ThemeColors.textFaint),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in entries)
                          _EntryChip(
                            entry: e,
                            past: e.occurrence.date.isBefore(now),
                            onTap: () => onTap(e.alarm),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ThemeColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ThemeColors.secondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: ThemeColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _EntryChip extends StatelessWidget {
  const _EntryChip({
    required this.entry,
    required this.past,
    required this.onTap,
  });

  final _PlanningEntry entry;
  final bool past;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rings = entry.occurrence.rings;
    final dimmed = !rings || past;
    final alarm = entry.alarm;
    final reasonIcon = switch (entry.occurrence.excludedBy) {
      OccurrenceExclusion.holiday => Icons.celebration_outlined,
      OccurrenceExclusion.paused => Icons.beach_access_rounded,
      OccurrenceExclusion.skipped => Icons.redo_rounded,
      null => alarm.isSnooze ? Icons.snooze_rounded : null,
    };
    final label = alarm.isSnooze
        ? context.translate('logs_isSnooze')
        : alarm.hasTitle
            ? alarm.title!
            : null;

    return Material(
      color: rings && !past
          ? ThemeColors.secondary.withValues(alpha: 0.14)
          : ThemeColors.night,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: rings && !past
              ? ThemeColors.secondary.withValues(alpha: 0.35)
              : ThemeColors.nightOutline,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reasonIcon != null) ...[
                Icon(reasonIcon,
                    size: 14,
                    color: dimmed ? ThemeColors.textFaint : Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                formatHourMinute(entry.occurrence.date),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: dimmed ? ThemeColors.textFaint : Colors.white,
                  decoration: rings ? null : TextDecoration.lineThrough,
                  decorationColor: ThemeColors.textFaint,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: dimmed
                          ? ThemeColors.textFaint
                          : ThemeColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
