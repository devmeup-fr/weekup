import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/localization_util.dart';

class NextAlarmSet extends StatelessWidget {
  const NextAlarmSet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AlarmSettings>?>(
      future: Alarm.getAlarms(),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          final nextAlarm = snapshot.data!.first;
          final now = DateTime.now();
          final remainingTime = nextAlarm.dateTime.difference(now);
          final formattedDate =
              "${nextAlarm.dateTime.day}/${nextAlarm.dateTime.month}/${nextAlarm.dateTime.year}";
          final formattedHours =
              remainingTime.inHours.toString().padLeft(2, '0');
          final formattedMinutes =
              (remainingTime.inMinutes % 60).toString().padLeft(2, '0');

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
                Text(
                  "${formattedHours}h ${formattedMinutes}m",
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  "${context.translate('common.date')} : $formattedDate",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
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
