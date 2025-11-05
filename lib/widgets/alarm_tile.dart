import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weekup/core/blocs/locale_cubit.dart';
import 'package:weekup/core/utils/extension_util.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/theme/colors.dart';

class AlarmTile extends StatelessWidget {
  const AlarmTile({
    required this.alarm,
    required this.onPressed,
    super.key,
    this.onDismissed,
    required this.onToggleActive,
  });

  final AlarmModel alarm;
  final void Function() onPressed;
  final void Function()? onDismissed;
  final void Function(bool) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: onDismissed != null
          ? DismissDirection.horizontal
          : DismissDirection.none,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.25,
        DismissDirection.endToStart: 0.25,
      },
      background: Container(
        decoration: BoxDecoration(
          color: ThemeColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete, size: 30, color: Colors.white),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: ThemeColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, size: 30, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed?.call(),
      child: GestureDetector(
        onTap: onPressed,
        child: Card(
            color:
                alarm.isActive ? ThemeColors.primaryLight : Colors.transparent,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.alarm_rounded,
                        size: 30,
                        color: alarm.isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (alarm.title != null && alarm.title != "")
                              Text(
                                alarm.title!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: alarm.isActive
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade600
                                          .withValues(alpha: 0.3),
                                ),
                              ),
                            if (alarm.title != null && alarm.title != "")
                              const SizedBox(height: 4),
                            Text(
                              alarm.time.formatTime(),
                              style: TextStyle(
                                fontSize: 48,
                                color: alarm.isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: alarm.isActive,
                        onChanged: (value) {
                          onToggleActive(value);
                        },
                      ),
                      const Icon(
                        Icons.keyboard_arrow_right_rounded,
                        size: 35,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<LocaleCubit, Locale>(
                    builder: (context, state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              (alarm.getNextOccurrence() != null)
                                  ? Text(
                                      alarm.getNextOccurrence()?.formatDateMin(
                                              state.languageCode) ??
                                          '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const SizedBox(height: 14),
                              if (!alarm.isOneShot)
                                Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: List.generate(7, (index) {
                                        final isSelected =
                                            alarm.selectedDays.length > index
                                                ? alarm.selectedDays[index]
                                                : false;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Text(
                                            context
                                                .translate('day_${index + 1}'),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withValues(alpha: 0.3),
                                            ),
                                          ),
                                        );
                                      }),
                                    ))
                            ]),
                        const SizedBox(height: 4),
                        if (!alarm.isOneShot)
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Text(
                                    context.translate(
                                      alarm.recurrenceWeeks == 1
                                          ? 'repeat_every_week'
                                          : 'x_weeks',
                                      translationParams: {
                                        'weeks':
                                            alarm.recurrenceWeeks.toString(),
                                      },
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              ])
                        else
                          const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
