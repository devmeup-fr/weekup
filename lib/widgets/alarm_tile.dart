import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_alarms/core/blocs/locale_cubit.dart';
import 'package:my_alarms/core/utils/extension_util.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/models/alarm_model.dart';
import 'package:my_alarms/theme/colors.dart';

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
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        color: ThemeColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        child: const Icon(
          Icons.delete,
          size: 30,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDismissed?.call(),
      child: GestureDetector(
        onTap: onPressed,
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                          : Colors.white.withOpacity(0.3),
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
                                    : Colors.grey.shade600.withOpacity(0.3),
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
                                  : Colors.white.withOpacity(0.3),
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
                      activeColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
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
                                : Container(),
                            if (!alarm.isAllDaysFalse())
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
                                          context.translate('day_${index + 1}'),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                      );
                                    }),
                                  ))
                          ]),
                      if (!alarm.isAllDaysFalse()) const SizedBox(height: 4),
                      if (!alarm.isAllDaysFalse())
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
                                      'weeks': alarm.recurrenceWeeks.toString(),
                                    },
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            ])
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
