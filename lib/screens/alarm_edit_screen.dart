import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/extension_util.dart';
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
  late ScrollController _scrollController;

  late FixedExtentScrollController _scrollMinController;
  late FixedExtentScrollController _scrollHourController;
  late TextEditingController _titleController;
  late AlarmService alarmService;
  final AudioPlayer audioPlayer = AudioPlayer();
  bool loading = false;
  bool playing = false;
  double? originalVolume;

  late bool creating;
  late DateTime createdFor;
  late DateTime selectedDateTime;
  late bool loopAudio;
  late bool vibrate;
  late double volume;
  late double fadeDuration;
  late String assetAudio;

  late List<bool> selectedDays;
  late int recurrenceWeeks;
  bool showMoreOptions = false;

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
    _scrollController = ScrollController();

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
      createdFor = widget.alarm?.createdFor ?? DateTime.now();
    } else {
      _titleController = TextEditingController(text: widget.alarm!.title ?? '');
      selectedDateTime = widget.alarm!.time;
      loopAudio = widget.alarm!.loopAudio;
      vibrate = widget.alarm!.vibrate;
      volume = widget.alarm!.volume != null ? widget.alarm!.volume! * 100 : 50;
      assetAudio = widget.alarm!.assetAudio;
      selectedDays = widget.alarm!.selectedDays;
      recurrenceWeeks = widget.alarm!.recurrenceWeeks;
      createdFor = widget.alarm?.createdFor ?? DateTime.now();
    }
    _scrollHourController =
        FixedExtentScrollController(initialItem: selectedDateTime.hour);
    _scrollMinController =
        FixedExtentScrollController(initialItem: selectedDateTime.minute);
  }

  @override
  void dispose() async {
    super.dispose();
    _scrollController.dispose();

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

  Future<void> _selectCreatedFor() async {
    DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: createdFor,
      firstDate: now,
      lastDate: now.add(Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        createdFor = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          now.hour,
          now.minute,
        ).toUtc();
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
        recurrenceWeeks: recurrenceWeeks,
        createdFor: createdFor);

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
    return SafeArea(
        child: Scaffold(
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
                  padding: EdgeInsets.fromLTRB(16, 8, 16, creating ? 16 : 90),
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      // Heure sélectionnée
                      buildTimeSelector(),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 3.0;
                          final itemWidth =
                              (constraints.maxWidth - spacing * 6) / 7;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: 0,
                            children: List.generate(7, (index) {
                              final day = context.translate('day_${index + 1}');

                              return SizedBox(
                                width: itemWidth,
                                child: ChoiceChip(
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(day, maxLines: 1),
                                  ),
                                  showCheckmark: false,
                                  selected: selectedDays[index],
                                  onSelected: (selected) {
                                    setState(
                                        () => selectedDays[index] = selected);
                                  },
                                  selectedColor: ThemeColors.primary,
                                  backgroundColor: Colors.white,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  labelPadding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  visualDensity: const VisualDensity(
                                      horizontal: -2, vertical: -2),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // Récurrence toutes les X semaines
                      Container(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
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
                          )),
                      Container(
                        padding: const EdgeInsets.only(left: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.translate('alarm_createdFor'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: _selectCreatedFor,
                              child: Text(
                                createdFor.formatDateDay(),
                                style: const TextStyle(
                                  color: ThemeColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showMoreOptions = !showMoreOptions;
                          });
                          if (!showMoreOptions) return;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                            );
                          });
                        },
                        child: Text(showMoreOptions
                            ? context.translate('show_less')
                            : context.translate('show_more')),
                      ),

                      if (showMoreOptions) ...[
                        const SizedBox(height: 16),
                        // --- Alarm Title ---
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.only(
                              top: 4, bottom: 4, left: 16, right: 18),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.label, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                context.translate('alarm_title'),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _titleController,
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 0),
                                    hintText: context
                                        .translate('alarm_title_placeholder'),
                                    hintStyle: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

// --- Select Audio ---
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.only(
                              top: 4, bottom: 4, left: 16, right: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_note, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                context.translate('select_audio'),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: assetAudio,
                                    isExpanded: true,
                                    alignment: Alignment.centerRight,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    dropdownColor: Colors.white,
                                    focusColor: Colors.white,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        playing = false;
                                        assetAudio = newValue!;
                                      });
                                    },
                                    items: audioOptions
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      final label = value
                                          .split('/')
                                          .last
                                          .replaceAll('.mp3', '')
                                          .replaceAll('_', ' ')
                                          .replaceFirstMapped(
                                            RegExp(r'^[a-zA-Z]'),
                                            (m) => m.group(0)!.toUpperCase(),
                                          );
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          label,
                                          style: const TextStyle(fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: playAudio,
                                icon: Icon(
                                    playing ? Icons.pause : Icons.play_arrow),
                                color: playing
                                    ? ThemeColors.secondary
                                    : ThemeColors.primary,
                                iconSize: 24,
                                splashRadius: 22,
                              ),
                            ],
                          ),
                        ),

// --- Volume ---
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.volume_up, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.translate('volume'),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8),
                                  ),
                                  child: Slider(
                                    value: volume,
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    onChanged: (v) =>
                                        setState(() => volume = v),
                                    onChangeEnd: (v) {
                                      if (playing) {
                                        final scalar = v / 100;
                                        VolumeController().setVolume(scalar);
                                        audioPlayer.setVolume(scalar);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 48,
                                child: TextField(
                                  controller: TextEditingController(
                                      text: volume.toInt().toString())
                                    ..selection = TextSelection.collapsed(
                                      offset: volume.toInt().toString().length,
                                    ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 0),
                                  ),
                                  onSubmitted: (value) {
                                    final parsed = int.tryParse(value);
                                    if (parsed != null) {
                                      setState(() {
                                        volume =
                                            parsed.clamp(0, 100).toDouble();
                                      });
                                      if (playing) {
                                        final scalar = volume / 100;
                                        VolumeController().setVolume(scalar);
                                        audioPlayer.setVolume(scalar);
                                      }
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        ),

// --- Loop Audio ---
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.repeat, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.translate('loop_audio'),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Switch(
                                value: loopAudio,
                                onChanged: (value) =>
                                    setState(() => loopAudio = value),
                                activeThumbColor: ThemeColors.primary,
                              ),
                            ],
                          ),
                        ),

// --- Vibrate ---
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.vibration, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.translate('vibrate'),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Switch(
                                value: vibrate,
                                onChanged: (value) =>
                                    setState(() => vibrate = value),
                                activeThumbColor: ThemeColors.primary,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ]
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
                        foregroundColor: ThemeColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              size: 18,
                              color: ThemeColors.error), // Icône "Supprimer"
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
                      side: const BorderSide(
                          color: ThemeColors.primary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                    ),
                    child: loading
                        ? SizedBox(
                            height: 16,
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
                                  color: ThemeColors
                                      .primary), // Icône "Enregistrer"
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
            )));
  }
}
