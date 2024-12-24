import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/models/alarm_model.dart';
import 'package:my_alarms/services/alarm_service.dart';
import 'package:my_alarms/theme/colors.dart';
import 'package:volume_controller/volume_controller.dart';

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
  late TextEditingController _titleController;
  late AlarmService alarmService;
  final AudioPlayer audioPlayer = AudioPlayer();
  bool loading = false;
  bool playing = false;
  double? originalVolume;

  late bool creating;
  late DateTime selectedDateTime;
  late bool loopAudio;
  late bool vibrate;
  late double volume;
  late double fadeDuration;
  late String assetAudio;

  late List<bool> selectedDays;
  late int recurrenceWeeks;

  final audioOptions = [
    'ciucciarella.mp3',
    'marimba.mp3',
    'mozart.mp3',
    'nokia.mp3',
    'aurora-ambient.mp3',
    'daybreak.mp3',
    'der-tag.mp3',
    'early-morning-rise.mp3',
    'emotional-piano.mp3',
    'good-morning.mp3',
    'jingle-bells.mp3',
    'kirby.mp3',
    'morning.mp3',
    'soft-corporate.mp3',
    'tropical.mp3',
    'dofus_nowel.mp3',
    'one_piece.mp3',
    'star_wars.mp3',
  ];

  @override
  void initState() {
    super.initState();
    alarmService = AlarmService();
    VolumeController()
        .getVolume()
        .then((vol) => originalVolume = vol.toDouble());

    creating = widget.alarm == null;
    if (creating) {
      _titleController = TextEditingController(text: '');
      selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
      selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);
      loopAudio = true;
      vibrate = true;
      volume = 50;
      fadeDuration = 0;
      assetAudio = 'marimba.mp3';
      selectedDays = List.filled(7, false);
      recurrenceWeeks = 1;
    } else {
      _titleController = TextEditingController(text: widget.alarm!.title ?? '');
      selectedDateTime = widget.alarm!.time;
      loopAudio = widget.alarm!.loopAudio;
      vibrate = widget.alarm!.vibrate;
      volume = widget.alarm!.volume != null ? widget.alarm!.volume! * 100 : 50;
      assetAudio = widget.alarm!.assetAudio;
      selectedDays = widget.alarm!.selectedDays;
      recurrenceWeeks = widget.alarm!.recurrenceWeeks;
    }
    _scrollHourController =
        FixedExtentScrollController(initialItem: selectedDateTime.hour);
    _scrollMinController =
        FixedExtentScrollController(initialItem: selectedDateTime.minute);
  }

  @override
  void dispose() async {
    super.dispose();
    // Restore the original volume
    double volume = await VolumeController().getVolume();
    if (originalVolume != null && originalVolume != volume) {
      VolumeController().setVolume(originalVolume!);
    }
    _scrollHourController.dispose();
    _scrollMinController.dispose();
    audioPlayer.dispose(); // Dispose of audio player
  }

  Future<void> playAudio() async {
    if (playing) {
      await audioPlayer.stop();
      setState(() => playing = false);

      if (originalVolume != null) {
        VolumeController().setVolume(originalVolume!);
      }
    } else {
      VolumeController().setVolume((volume / 100));

      await audioPlayer.setVolume(volume / 100); // Set internal player volume
      await audioPlayer.play(AssetSource('musics/$assetAudio'));
      setState(() => playing = true);

      // Stop playing after the audio ends
      audioPlayer.onPlayerComplete.listen((event) {
        setState(() => playing = false);

        if (originalVolume != null) {
          VolumeController().setVolume(originalVolume!);
        }
      });
    }
  }

  Future<void> saveAlarm() async {
    if (loading) return;

    AlarmModel alarmModel = AlarmModel(
        id: widget.index ?? 0,
        title: _titleController.text != '' ? _titleController.text : null,
        time: selectedDateTime,
        vibrate: vibrate,
        volume: volume / 100,
        assetAudio: assetAudio,
        selectedDays: selectedDays,
        recurrenceWeeks: recurrenceWeeks);

    if (creating) {
      setState(() => loading = true);
      await alarmService.saveAlarm(context, alarmModel).then((res) {
        if (mounted) {
          Navigator.pop(context, true);
        }
        setState(() => loading = false);
      });
    } else {
      await alarmService
          .editAlarm(context, alarmModel, widget.index ?? 0)
          .then((res) {
        if (mounted) {
          Navigator.pop(context, true);
        }
        setState(() => loading = false);
      });
    }
  }

  void deleteAlarm() async {
    await alarmService.deleteAlarm(context, widget.index ?? 0).then((res) {
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
                                color: isSelected
                                    ? ThemeColors.secondary
                                    : Colors.grey,
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
                color: ThemeColors.secondary,
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
                                color: isSelected
                                    ? ThemeColors.secondary
                                    : Colors.grey),
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
          actions: [
            // Bouton Annuler avec icône
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: TextStyle(fontSize: 16),
              ),
              child: Row(
                children: [
                  Icon(Icons.close,
                      size: 18, color: Colors.white), // Icône "Fermer"
                  SizedBox(width: 8),
                  Text(context.translate('cancel')),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 90),
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: context.translate('alarm_title'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    controller: _titleController,
                  ),
                  const SizedBox(height: 20),
                  // Heure sélectionnée
                  buildTimeSelector(),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 4, // Ajuste l'espace horizontal
                    children: List.generate(7, (index) {
                      final day = context.translate('day_${index + 1}');
                      return SizedBox(
                        width: MediaQuery.of(context).size.width / 7 -
                            10, // Ajuste la largeur
                        child: ChoiceChip(
                          label: FittedBox(child: Text(day)),
                          selected: selectedDays[index],
                          onSelected: (selected) {
                            setState(() {
                              selectedDays[index] = selected;
                            });
                          },
                          showCheckmark: false,
                          selectedColor: ThemeColors.primary,
                          backgroundColor: Colors.white,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Récurrence toutes les X semaines
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.translate(
                          recurrenceWeeks == 1
                              ? 'repeat_every_week'
                              : 'x_weeks',
                          translationParams: {
                            "weeks": recurrenceWeeks.toString()
                          })),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: 4,
                          divisions: 3,
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: assetAudio,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              playing = false;
                              assetAudio = newValue!;
                            });
                          },
                          dropdownColor: Colors.white,
                          focusColor: Colors.white,
                          items: audioOptions
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value
                                      .split('/')
                                      .last // Récupère le nom du fichier
                                      .replaceAll('.mp3',
                                          '') // Supprime l'extension .mp3
                                      .replaceAll('_', ' ')
                                      .replaceFirstMapped(
                                          RegExp(r'^[a-zA-Z]'),
                                          (match) =>
                                              match.group(0)!.toUpperCase()),
                                  style: const TextStyle(fontSize: 16),
                                ));
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: playAudio,
                        icon: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: playing
                              ? ThemeColors.secondary
                              : ThemeColors.primary,
                          size: 30,
                        ),
                      ),
                    ],
                  ),

                  // Volume Slider
                  const SizedBox(height: 20),
                  Text(
                    "${context.translate('volume')} ( ${volume.toInt()} )",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: volume,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) async {
                      setState(() {
                        volume = value;
                      });
                      if (playing) {
                        VolumeController().setVolume(value / 100);
                        audioPlayer.setVolume(value / 100);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    value: loopAudio,
                    onChanged: (value) => setState(() => loopAudio = value),
                    title: Text(context.translate('loop_audio')),
                    activeColor: ThemeColors.primary,
                  ),
                  SwitchListTile(
                    value: vibrate,
                    onChanged: (value) => setState(() => vibrate = value),
                    title: Text(context.translate('vibrate')),
                    activeColor: ThemeColors.primary,
                  ),
                ],
              ),
            ),
            if (!creating)
              Positioned(
                left: 16,
                bottom: 16,
                child: TextButton(
                  onPressed: deleteAlarm,
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeColors.primaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete,
                          size: 18,
                          color: ThemeColors.primaryLight), // Icône "Supprimer"
                      SizedBox(width: 8),
                      Text(context.translate('delete_alarm')),
                    ],
                  ),
                ),
              ),

            // Bouton Sauvegarder en bas à droite
            Positioned(
              right: 16,
              bottom: 16,
              child: OutlinedButton(
                onPressed: loading ? null : saveAlarm,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ThemeColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              ThemeColors.primary),
                        ),
                      )
                    : Row(
                        children: [
                          Icon(Icons.save,
                              size: 18,
                              color:
                                  ThemeColors.primary), // Icône "Enregistrer"
                          SizedBox(width: 8),
                          Text(
                            context.translate('save'),
                            style: const TextStyle(
                              color: ThemeColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ));
  }
}
