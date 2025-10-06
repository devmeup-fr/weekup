import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_alarms/core/utils/extension_util.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/models/alarm_model.dart';
import 'package:my_alarms/services/alarm_service.dart';

import '../core/blocs/locale_cubit.dart';

class NextAlarmSet extends StatefulWidget {
  final Function reloadAlarms;

  const NextAlarmSet({super.key, required this.reloadAlarms});

  @override
  State<NextAlarmSet> createState() => _NextAlarmSetState();
}

class _NextAlarmSetState extends State<NextAlarmSet> {
  late AlarmService alarmService;

  @override
  void initState() {
    super.initState();
    alarmService = AlarmService();
  }

  Future<void> _cancelSnooze(AlarmModel snooze) async {
    final id = snooze.id;
    if (id == null) return;

    await alarmService.deleteAlarmById(context, id, reschedule: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.translate('snooze_canceled'))),
    );

    setState(() {});
    widget.reloadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AlarmModel?>(
      future: alarmService.findNextAlarm(context),
      builder: (context, snapshot) {
        final nextAlarm = snapshot.data;

        if (nextAlarm?.getNextOccurrence() != null) {
          final isSnooze = nextAlarm?.isSnooze == true;

          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 160),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.translate('nextDateTitle'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 5),
                BlocBuilder<LocaleCubit, Locale>(
                  builder: (context, state) => Text(
                    nextAlarm!
                        .getNextOccurrence()!
                        .formatDateWS(state.languageCode),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
                // --- Ruban Snooze + action Annuler ---
                if (isSnooze) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.snooze,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.translate('snooze_explainer'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelSnooze(nextAlarm!),
                            icon: const Icon(Icons.cancel),
                            label: Text(context.translate('cancel_snooze')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.25,
          decoration: const BoxDecoration(color: Colors.transparent),
          alignment: Alignment.center,
          child: Text(
            context.translate('noAlarmEnabled'),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      },
    );
  }
}
