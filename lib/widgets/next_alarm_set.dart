import 'package:flutter/material.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/utils/alarm_format.dart';

/// Carte d'en-tête : prochaine alarme + compte à rebours + rappel différé.
class NextAlarmSet extends StatelessWidget {
  const NextAlarmSet({
    super.key,
    required this.next,
    this.snooze,
    required this.onCancelSnooze,
    this.resumeAt,
    this.onEndVacation,
  });

  final ({AlarmModel alarm, DateTime date})? next;
  final AlarmModel? snooze;
  final VoidCallback onCancelSnooze;
  final DateTime? resumeAt;
  final VoidCallback? onEndVacation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final next = this.next;

    final vacation = resumeAt == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _Banner(
              icon: Icons.beach_access_rounded,
              text: context.translate('vacation.banner', translationParams: {
                'day': formatRelativeDay(
                  context,
                  resumeAt!.subtract(const Duration(days: 1)),
                  inSentence: true,
                ),
              }),
              action: context.translate('vacation.resume_short'),
              onAction: onEndVacation,
            ),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [ThemeColors.dusk, ThemeColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.dusk.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: next == null
          ? Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.bedtime_rounded,
                        color: ThemeColors.secondary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        context.translate('noAlarmEnabled'),
                        style: textTheme.titleMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (vacation != null) vacation,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      next.alarm.isSnooze
                          ? Icons.snooze_rounded
                          : Icons.alarm_on_rounded,
                      size: 18,
                      color: ThemeColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.translate('nextDateTitle').toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: ThemeColors.secondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatHourMinute(next.date),
                      style: textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          formatRelativeDay(context, next.date),
                          style: textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  context.translate('ringsIn', translationParams: {
                    'duration': formatCountdown(
                        context, next.date.difference(DateTime.now())),
                  }),
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
                if (next.alarm.hasTitle && !next.alarm.isSnooze)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      next.alarm.title!,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: ThemeColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (snooze != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _Banner(
                      icon: Icons.snooze_rounded,
                      text: context
                          .translate('snooze_banner', translationParams: {
                        'time': formatHourMinute(
                            snooze!.getNextOccurrence() ?? next.date),
                      }),
                      action: context.translate('cancel'),
                      onAction: onCancelSnooze,
                    ),
                  ),
                if (vacation != null) vacation,
              ],
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}
