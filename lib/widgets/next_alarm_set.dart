import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_alarms/core/utils/extension_util.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/models/alarm_model.dart';
import 'package:my_alarms/services/alarm_service.dart';

import '../core/blocs/locale_cubit.dart';

class NextAlarmSet extends StatefulWidget {
  const NextAlarmSet({
    super.key,
  });

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AlarmModel?>(
      future: alarmService.findNextAlarm(context),
      builder: (context, snapshot) {
        final nextAlarm = snapshot.data;

        if (nextAlarm?.getNextOccurrence() != null) {
          return Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                )
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.25,
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            context.translate('noAlarmEnabled'),
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      },
    );
  }
}
