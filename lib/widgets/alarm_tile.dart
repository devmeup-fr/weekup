import 'package:flutter/material.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/utils/alarm_format.dart';

enum AlarmTileAction { skip, unskip, duplicate, delete }

class AlarmTile extends StatelessWidget {
  const AlarmTile({
    required this.alarm,
    required this.onPressed,
    super.key,
    this.onDismissed,
    required this.onToggleActive,
    required this.onAction,
    this.resumeAt,
  });

  final AlarmModel alarm;
  final void Function() onPressed;
  final void Function()? onDismissed;
  final void Function(bool) onToggleActive;
  final void Function(AlarmTileAction) onAction;
  final DateTime? resumeAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = alarm.isActive;
    final skipping = alarm.isSkipping();
    final next = alarm.getNextOccurrence(resumeAt: resumeAt);
    final paused = resumeAt != null && !alarm.isOneShot && active;
    final mainColor = active ? Colors.white : ThemeColors.textFaint;
    final subColor = active ? ThemeColors.textMuted : ThemeColors.textFaint;

    final schedule = formatSchedule(context, alarm, listDays: false);
    final subtitle = [
      if (schedule.isNotEmpty) schedule,
      if (next != null)
        skipping || paused
            ? context.translate('skip.until', translationParams: {
                'day': formatRelativeDay(context, next, inSentence: true),
              })
            : formatRelativeDay(context, next),
    ].join(' · ');

    final background = Container(
      decoration: BoxDecoration(
        color: ThemeColors.error,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white),
          Icon(Icons.delete_outline_rounded, color: Colors.white),
        ],
      ),
    );

    return Dismissible(
      key: key!,
      direction: onDismissed != null
          ? DismissDirection.horizontal
          : DismissDirection.none,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      background: background,
      onDismissed: (_) => onDismissed?.call(),
      child: Card(
        color: active ? ThemeColors.nightSurface : ThemeColors.night,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          onLongPress: () => _showMenu(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 4, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (alarm.hasTitle)
                        Text(
                          alarm.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: subColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        formatHourMinute(alarm.time.toLocal()),
                        style: textTheme.displayMedium?.copyWith(
                          color: mainColor,
                          fontWeight: FontWeight.w300,
                          height: 1.1,
                          decoration:
                              skipping ? TextDecoration.lineThrough : null,
                          decorationColor: ThemeColors.textMuted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (skipping || paused) ...[
                            Icon(
                                paused
                                    ? Icons.beach_access_rounded
                                    : Icons.redo_rounded,
                                size: 14,
                                color: ThemeColors.secondary),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: skipping || paused
                                    ? ThemeColors.secondary
                                    : subColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (alarm.skipHolidays && !alarm.isOneShot) ...[
                        const SizedBox(height: 2),
                        Text(
                          context.translate('holidays.off_short'),
                          style: textTheme.bodySmall
                              ?.copyWith(color: ThemeColors.textFaint),
                        ),
                      ],
                      if (!alarm.isOneShot && !alarm.isDaily) ...[
                        const SizedBox(height: 8),
                        _DayDots(days: alarm.selectedDays, active: active),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: active,
                  onChanged: onToggleActive,
                ),
                IconButton(
                  tooltip: context.translate('more_actions'),
                  icon: const Icon(Icons.more_vert_rounded,
                      color: ThemeColors.textMuted),
                  onPressed: () => _showMenu(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    final canSkip = alarm.isActive && !alarm.isOneShot;
    final skipping = alarm.isSkipping();

    final action = await showModalBottomSheet<AlarmTileAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canSkip && !skipping)
              ListTile(
                leading: const Icon(Icons.redo_rounded),
                title: Text(ctx.translate('skip.next')),
                subtitle: Text(ctx.translate('skip.next_hint')),
                onTap: () => Navigator.pop(ctx, AlarmTileAction.skip),
              ),
            if (skipping)
              ListTile(
                leading: const Icon(Icons.undo_rounded),
                title: Text(ctx.translate('skip.cancel')),
                onTap: () => Navigator.pop(ctx, AlarmTileAction.unskip),
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(ctx.translate('duplicate_alarm')),
              onTap: () => Navigator.pop(ctx, AlarmTileAction.duplicate),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: ThemeColors.errorSoft),
              title: Text(
                ctx.translate('delete_alarm'),
                style: const TextStyle(color: ThemeColors.errorSoft),
              ),
              onTap: () => Navigator.pop(ctx, AlarmTileAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action != null) onAction(action);
  }
}

class _DayDots extends StatelessWidget {
  const _DayDots({required this.days, required this.active});

  final List<bool> days;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final on = days.length > i && days[i];
        final color = !on
            ? ThemeColors.textFaint.withValues(alpha: 0.5)
            : active
                ? ThemeColors.secondary
                : ThemeColors.textMuted;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            context.translate('day_${i + 1}'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: on ? FontWeight.w700 : FontWeight.w400,
              color: color,
            ),
          ),
        );
      }),
    );
  }
}
