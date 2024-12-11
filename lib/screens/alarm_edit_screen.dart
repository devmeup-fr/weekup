import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/models/alarm_model.dart';
import 'package:my_alarms/services/alarm_service.dart';

class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({super.key, this.alarm, this.index});

  final int? index;
  final AlarmModel? alarm;

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late AlarmService alarmService;
  bool loading = false;

  late bool creating;
  late DateTime selectedDateTime;
  late bool loopAudio;
  late bool vibrate;
  late double? volume;
  late double fadeDuration;
  late String assetAudio;

  // Nouveaux paramètres
  late List<bool> selectedDays;
  late int recurrenceWeeks;

  @override
  void initState() {
    super.initState();
    alarmService = AlarmService();

    creating = widget.alarm == null;
    if (creating) {
      selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
      selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);
      loopAudio = true;
      vibrate = true;
      volume = null;
      fadeDuration = 0;
      assetAudio = 'assets/musics/marimba.mp3';
      selectedDays =
          List.filled(7, false); // Par défaut, aucun jour sélectionné
      recurrenceWeeks = 1; // Par défaut, répétition chaque semaine
    } else {
      selectedDateTime = widget.alarm!.time;
      loopAudio = widget.alarm!.loopAudio;
      vibrate = widget.alarm!.vibrate;
      volume = widget.alarm!.volume;
      selectedDays =
          List.filled(7, false); // Charger les jours ici si disponible
      recurrenceWeeks = 1; // Charger les semaines ici si disponible
    }
  }

  // AlarmSettings buildAlarmSettings() {
  //   final id = creating
  //       ? DateTime.now().millisecondsSinceEpoch % 10000 + 1
  //       : widget.alarm!.id;

  //   final alarmSettings = AlarmSettings(
  //     id: id,
  //     dateTime: selectedDateTime,
  //     loopAudio: loopAudio,
  //     vibrate: vibrate,
  //     volume: volume,
  //     fadeDuration: fadeDuration,
  //     assetAudioPath: assetAudio,
  //     notificationSettings: NotificationSettings(
  //       title: context.translate('alarm_notification_title'),
  //       body: context.translate('alarm_notification_body',
  //           translationParams: {"id": id.toString()}),
  //       stopButton: context.translate('stop_alarm_button'),
  //       icon: 'notification_icon',
  //     ),
  //   );

  //   return alarmSettings;
  // }

  void saveAlarm() {
    if (loading) return;
    setState(() => loading = true);
    alarmService
        .saveAlarm(AlarmModel(
            id: widget.index ?? 0,
            title: '',
            time: selectedDateTime,
            vibrate: vibrate,
            volume: volume,
            selectedDays: selectedDays,
            recurrenceWeeks: recurrenceWeeks))
        .then((res) {
      if (mounted) Navigator.pop(context, true);
      setState(() => loading = false);
    });
  }

  void deleteAlarm() {
    alarmService.deleteAlarm(widget.index ?? 0).then((res) {
      if (mounted) Navigator.pop(context, true);
    });
  }

  Widget buildTimeSelector() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hour selector
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120, // Adjust height as needed
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.003,
                      diameterRatio: 1.2,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedDateTime =
                              selectedDateTime.copyWith(hour: index);
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final isSelected = index == selectedDateTime.hour;
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                            ),
                          );
                        },
                        childCount: 24, // 24 hours
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Separator
            const Text(
              ':',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            // Minute selector
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120, // Adjust height as needed
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.001,
                      diameterRatio: 1.2,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedDateTime = selectedDateTime.copyWith(
                            minute: index,
                          );
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final isSelected = index == selectedDateTime.minute;
                          return Center(
                              child: Text(
                            index.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                          ));
                        },
                        childCount: 60, // 60 minutes
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(creating
            ? context.translate('create_alarm')
            : context.translate('edit_alarm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.translate('cancel'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // Heure sélectionnée
            buildTimeSelector(),
            const SizedBox(height: 20),

            Wrap(
              spacing: 4,
              children: List.generate(7, (index) {
                final day = context.translate('day_${index + 1}');
                return ChoiceChip(
                  label: Text(day),
                  selected: selectedDays[index],
                  onSelected: (selected) {
                    setState(() {
                      selectedDays[index] = selected;
                    });
                  },
                  showCheckmark: false,
                  selectedColor: Colors.blue.shade200,
                  backgroundColor: Colors.white,
                );
              }),
            ),
            const SizedBox(height: 20),

            // Récurrence toutes les X semaines
            Text(
              context.translate('repeat_every'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.translate('x_weeks',
                    translationParams: {"weeks": recurrenceWeeks.toString()})),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    value: recurrenceWeeks.toDouble(),
                    onChanged: (value) {
                      setState(() {
                        recurrenceWeeks = value.toInt();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Autres options
            SwitchListTile(
              value: loopAudio,
              onChanged: (value) => setState(() => loopAudio = value),
              title: Text(context.translate('loop_audio')),
              activeColor: Colors.blue,
            ),
            SwitchListTile(
              value: vibrate,
              onChanged: (value) => setState(() => vibrate = value),
              title: Text(context.translate('vibrate')),
              activeColor: Colors.blue,
            ),

            // Sauvegarder ou supprimer
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                !creating
                    ? TextButton(
                        onPressed: deleteAlarm,
                        child: Text(
                          context.translate('delete_alarm'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : Container(),
                OutlinedButton(
                  onPressed: loading ? null : saveAlarm,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Colors.blue, width: 2), // Border styling
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Text(
                          context.translate('save'),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
