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
  late FixedExtentScrollController _scrollMinController;
  late FixedExtentScrollController _scrollHourController;
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

  final audioOptions = [
    'assets/musics/marimba.mp3',
    'assets/musics/mozart.mp3',
    'assets/musics/nokia.mp3',
    'assets/musics/one_piece.mp3',
    'assets/musics/star_wars.mp3',
  ];

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
      volume = 0.5;
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
      assetAudio = widget.alarm!.assetAudio;
      selectedDays =
          widget.alarm!.selectedDays; // Charger les jours ici si disponible
      recurrenceWeeks = widget
          .alarm!.recurrenceWeeks; // Charger les semaines ici si disponible
    }
    _scrollHourController =
        FixedExtentScrollController(initialItem: selectedDateTime.hour);
    _scrollMinController =
        FixedExtentScrollController(initialItem: selectedDateTime.minute);
  }

  @override
  void dispose() {
    _scrollHourController.dispose();
    _scrollMinController.dispose();
    super.dispose();
  }

  void saveAlarm() {
    if (loading) return;

    if (creating) {
      setState(() => loading = true);
      alarmService
          .saveAlarm(
              context,
              AlarmModel(
                  id: widget.index ?? 1,
                  title: '',
                  time: selectedDateTime,
                  vibrate: vibrate,
                  volume: volume,
                  assetAudio: assetAudio,
                  selectedDays: selectedDays,
                  recurrenceWeeks: recurrenceWeeks))
          .then((res) {
        if (mounted) {
          Navigator.pop(context, true);
        }
        setState(() => loading = false);
      });
    } else {
      alarmService
          .editAlarm(
              context,
              AlarmModel(
                  id: widget.index ?? 0,
                  title: '',
                  time: selectedDateTime,
                  vibrate: vibrate,
                  volume: volume,
                  assetAudio: assetAudio,
                  selectedDays: selectedDays,
                  recurrenceWeeks: recurrenceWeeks),
              widget.index ?? 0)
          .then((res) {
        if (mounted) {
          Navigator.pop(context, true);
        }
        setState(() => loading = false);
      });
    }
  }

  void deleteAlarm() {
    alarmService.deleteAlarm(context, widget.index ?? 0).then((res) {
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
                      controller: _scrollHourController,
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
                                fontSize: 36,
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
                      controller: _scrollMinController,
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
                              fontSize: 36,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.translate(
                    recurrenceWeeks == 1 ? 'repeat_every_week' : 'x_weeks',
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
            Text(
              context.translate('select_audio'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: assetAudio,
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  assetAudio = newValue!;
                });
              },
              dropdownColor: Colors.white,
              focusColor: Colors.white,
              items: audioOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value
                        .split('/')
                        .last // Récupère le nom du fichier
                        .replaceAll('.mp3', '') // Supprime l'extension .mp3
                        .replaceAll('_', ' ')
                        .replaceFirstMapped(
                            RegExp(r'^[a-zA-Z]'),
                            (match) => match
                                .group(0)!
                                .toUpperCase()), // Met une majuscule à la première lettre
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
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
