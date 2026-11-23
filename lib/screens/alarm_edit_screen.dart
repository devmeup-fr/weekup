import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/services/settings_service.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/utils/alarm_format.dart';

const audioOptions = [
  'marimba.mp3',
  'ciucciarella.mp3',
  'mozart.mp3',
  'nokia.mp3',
  'aurora-ambient.mp3',
  'daybreak.mp3',
  'der-tag.mp3',
  'early-morning-rise.mp3',
  'emotional-piano.mp3',
  'emotional-piano-2.mp3',
  'good-morning.mp3',
  'wake-up-call.mp3',
  'jingle-bells.mp3',
  'kirby.mp3',
  'morning.mp3',
  'soft-corporate.mp3',
  'tropical.mp3',
  'dofus_nowel.mp3',
  'one_piece.mp3',
  'star_wars.mp3',
];

String audioLabel(String file) => file
    .split('/')
    .last
    .replaceAll('.mp3', '')
    .replaceAll('_', ' ')
    .replaceAll('-', ' ')
    .replaceFirstMapped(RegExp(r'^[a-zA-Z]'), (m) => m.group(0)!.toUpperCase());

enum _RepeatPreset { once, weekdays, weekend, everyday, custom }

class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({super.key, this.alarm});

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
  StreamSubscription<void>? _playerCompleteSub;
  bool loading = false;
  String? playing;
  double? originalVolume;

  late bool creating;
  late DateTime createdFor;
  late int hour;
  late int minute;
  late bool loopAudio;
  late bool vibrate;
  late double volume;
  late String assetAudio;

  late List<bool> selectedDays;
  late int recurrenceWeeks;
  late bool skipHolidays;
  DateTime? resumeAt;

  @override
  void initState() {
    super.initState();
    alarmService = AlarmService();
    VolumeController().getVolume().then((vol) => originalVolume = vol);
    _playerCompleteSub = audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playing = null);
      _restoreVolume();
    });

    AppSettings.vacationResumeAt().then((r) {
      if (mounted && r != null) setState(() => resumeAt = r);
    });

    final alarm = widget.alarm;
    creating = alarm == null;
    skipHolidays = alarm?.skipHolidays ?? false;
    final now = DateTime.now();

    if (alarm == null) {
      final start = now.add(const Duration(minutes: 1));
      _titleController = TextEditingController();
      hour = start.hour;
      minute = start.minute;
      loopAudio = true;
      vibrate = true;
      volume = 40;
      assetAudio = audioOptions.first;
      selectedDays = List.filled(7, false);
      recurrenceWeeks = 1;
      createdFor = DateTime(now.year, now.month, now.day);
    } else {
      final t = alarm.time.toLocal();
      _titleController = TextEditingController(text: alarm.title ?? '');
      hour = t.hour;
      minute = t.minute;
      loopAudio = alarm.loopAudio;
      vibrate = alarm.vibrate;
      volume = alarm.volume != null ? alarm.volume! * 100 : 50;
      assetAudio = audioOptions.contains(alarm.assetAudio)
          ? alarm.assetAudio
          : audioOptions.first;
      // Copie : ne jamais muter la liste du modèle (annulation possible)
      selectedDays = alarm.selectedDays.length == 7
          ? List<bool>.from(alarm.selectedDays)
          : List.filled(7, true);
      recurrenceWeeks = alarm.recurrenceWeeks;
      final ref = (alarm.createdFor ?? now).toLocal();
      createdFor = DateTime(ref.year, ref.month, ref.day);
      if (alarm.isOneShot) {
        // Une alarme ponctuelle expirée reprend au prochain hh:mm
        final date = alarm.oneShotDate();
        if (date != null && date.isAfter(now)) {
          createdFor = DateTime(date.year, date.month, date.day);
        } else {
          createdFor = DateTime(now.year, now.month, now.day);
        }
      }
    }

    _scrollHourController = FixedExtentScrollController(initialItem: hour);
    _scrollMinController = FixedExtentScrollController(initialItem: minute);
  }

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    audioPlayer.dispose();
    _restoreVolume();
    _scrollHourController.dispose();
    _scrollMinController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _restoreVolume() {
    if (originalVolume != null) VolumeController().setVolume(originalVolume!);
  }

  // ---------------------------------------------------
  // Modèle
  // ---------------------------------------------------
  AlarmModel _buildModel() {
    final now = DateTime.now();
    return AlarmModel(
      id: widget.alarm?.id,
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null,
      time: DateTime(now.year, now.month, now.day, hour, minute),
      isActive: true,
      loopAudio: loopAudio,
      vibrate: vibrate,
      volume: volume / 100,
      assetAudio: assetAudio,
      selectedDays: List<bool>.from(selectedDays),
      recurrenceWeeks: recurrenceWeeks,
      skipHolidays: skipHolidays,
      createdAt: now,
      createdFor: createdFor,
    );
  }

  _RepeatPreset get _preset {
    final d = selectedDays;
    if (d.every((x) => !x)) return _RepeatPreset.once;
    if (d.every((x) => x)) return _RepeatPreset.everyday;
    if (d.sublist(0, 5).every((x) => x) && !d[5] && !d[6]) {
      return _RepeatPreset.weekdays;
    }
    if (d.sublist(0, 5).every((x) => !x) && d[5] && d[6]) {
      return _RepeatPreset.weekend;
    }
    return _RepeatPreset.custom;
  }

  void _applyPreset(_RepeatPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (preset) {
        case _RepeatPreset.once:
          selectedDays = List.filled(7, false);
        case _RepeatPreset.weekdays:
          selectedDays = [true, true, true, true, true, false, false];
        case _RepeatPreset.weekend:
          selectedDays = [false, false, false, false, false, true, true];
        case _RepeatPreset.everyday:
          selectedDays = List.filled(7, true);
        case _RepeatPreset.custom:
          break;
      }
    });
  }

  // ---------------------------------------------------
  // Audio
  // ---------------------------------------------------
  Future<void> _togglePreview(String file) async {
    if (playing == file) {
      await audioPlayer.stop();
      setState(() => playing = null);
      _restoreVolume();
      return;
    }
    VolumeController().setVolume(volume / 100);
    await audioPlayer.stop();
    await audioPlayer.setVolume(1);
    await audioPlayer.play(AssetSource('musics/$file'));
    if (mounted) setState(() => playing = file);
  }

  Future<void> _stopPreview() async {
    if (playing == null) return;
    await audioPlayer.stop();
    if (mounted) setState(() => playing = null);
    _restoreVolume();
  }

  Future<void> _pickSound() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (ctx, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  ctx.translate('select_audio'),
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    for (final file in audioOptions)
                      ListTile(
                        leading: IconButton(
                          icon: Icon(
                            playing == file
                                ? Icons.stop_circle_rounded
                                : Icons.play_circle_outline_rounded,
                            color: playing == file
                                ? ThemeColors.secondary
                                : ThemeColors.textMuted,
                          ),
                          onPressed: () async {
                            await _togglePreview(file);
                            setSheetState(() {});
                          },
                        ),
                        title: Text(audioLabel(file)),
                        trailing: file == assetAudio
                            ? const Icon(Icons.check_rounded,
                                color: ThemeColors.secondary)
                            : null,
                        onTap: () => Navigator.pop(ctx, file),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _stopPreview();
    if (picked != null) setState(() => assetAudio = picked);
  }

  // ---------------------------------------------------
  // Date
  // ---------------------------------------------------
  Future<void> _selectCreatedFor() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: createdFor.isBefore(today) ? today : createdFor,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(
          () => createdFor = DateTime(picked.year, picked.month, picked.day));
    }
  }

  // ---------------------------------------------------
  // Save / Delete
  // ---------------------------------------------------
  Future<void> saveAlarm() async {
    if (loading) return;
    setState(() => loading = true);
    await _stopPreview();
    if (!mounted) return;

    final alarmModel = _buildModel();
    try {
      if (creating) {
        await alarmService.saveAlarm(context, alarmModel);
      } else {
        await alarmService.editAlarmById(context, alarmModel);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteAlarm() async {
    final id = widget.alarm?.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.translate('delete_alarm')),
        content: Text(ctx.translate('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.errorSoft),
            child: Text(ctx.translate('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await alarmService.deleteAlarmById(context, id);
    if (mounted) Navigator.pop(context, true);
  }

  // ---------------------------------------------------
  // UI
  // ---------------------------------------------------
  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 96,
      height: 180,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 60,
        perspective: 0.004,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          HapticFeedback.selectionClick();
          onChanged(index % count);
        },
        childDelegate: ListWheelChildLoopingListDelegate(
          children: List.generate(count, (i) {
            final isSelected = i == selected;
            return Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: isSelected ? 52 : 40,
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                  color: isSelected ? Colors.white : ThemeColors.textFaint,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget buildTimeSelector() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: ThemeColors.nightSurfaceHigh,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _wheel(
              controller: _scrollHourController,
              count: 24,
              selected: hour,
              onChanged: (v) => setState(() => hour = v),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: ThemeColors.secondary,
                ),
              ),
            ),
            _wheel(
              controller: _scrollMinController,
              count: 60,
              selected: minute,
              onChanged: (v) => setState(() => minute = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: ThemeColors.textMuted,
                    letterSpacing: 1.1,
                  ),
            ),
          ),
          Material(
            color: ThemeColors.night,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: ThemeColors.nightOutline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _presetChips() {
    final labels = {
      _RepeatPreset.once: 'repeat.once',
      _RepeatPreset.weekdays: 'repeat.weekdays',
      _RepeatPreset.weekend: 'repeat.weekend',
      _RepeatPreset.everyday: 'repeat.everyday',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Row(
        children: [
          for (final e in labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(context.translate(e.value)),
                selected: _preset == e.key,
                showCheckmark: false,
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color:
                          _preset == e.key ? ThemeColors.night : Colors.white,
                    ),
                onSelected: (_) => _applyPreset(e.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayToggles() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final on = selectedDays[i];
          return Semantics(
            button: true,
            selected: on,
            label: shortDayName(context, i),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => selectedDays[i] = !on);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      on ? ThemeColors.secondary : ThemeColors.nightSurfaceHigh,
                ),
                child: Text(
                  context.translate('day_${i + 1}'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: on ? ThemeColors.night : ThemeColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _frequencySelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.translate('repeat_every'),
              style: const TextStyle(color: ThemeColors.textMuted)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final w in [1, 2, 3, 4])
                  ButtonSegment(
                    value: w,
                    label: Text(
                      w == 1
                          ? context.translate('repeat.weekly_short')
                          : context.translate('repeat.n_weeks_short',
                              translationParams: {'weeks': '$w'}),
                    ),
                  ),
              ],
              selected: {recurrenceWeeks},
              onSelectionChanged: (s) =>
                  setState(() => recurrenceWeeks = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: ThemeColors.secondary,
                selectedForegroundColor: ThemeColors.night,
                side: const BorderSide(color: ThemeColors.nightOutline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(label),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildModel();
    final nextDate = preview.getNextOccurrence(resumeAt: resumeAt);
    final isOnce = preview.isOneShot;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: ThemeColors.nightSurface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // --- En-tête ---
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 4),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                        foregroundColor: ThemeColors.textMuted),
                    child: Text(context.translate('cancel')),
                  ),
                  Expanded(
                    child: Text(
                      context
                          .translate(creating ? 'create_alarm' : 'edit_alarm'),
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  FilledButton(
                    onPressed: loading ? null : saveAlarm,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ThemeColors.night,
                            ),
                          )
                        : Text(context.translate('save')),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  buildTimeSelector(),
                  const SizedBox(height: 8),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        nextDate == null
                            ? context.translate('noAlarmEnabled')
                            : '${formatRelativeDay(context, nextDate)} · ${context.translate('ringsIn', translationParams: {
                                    'duration': formatCountdown(context,
                                        nextDate.difference(DateTime.now())),
                                  })}',
                        key: ValueKey(
                            '$hour:$minute:$selectedDays:$createdFor:$skipHolidays'),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: ThemeColors.secondary),
                      ),
                    ),
                  ),

                  // --- Répétition ---
                  _section(context.translate('repeat_on'), [
                    _presetChips(),
                    _dayToggles(),
                    if (!isOnce) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      _frequencySelector(),
                      const Divider(),
                      SwitchListTile(
                        secondary: const Icon(Icons.celebration_outlined),
                        title: Text(context.translate('holidays.skip')),
                        subtitle: Text(
                          context.translate('holidays.skip_hint'),
                          style: const TextStyle(color: ThemeColors.textMuted),
                        ),
                        value: skipHolidays,
                        onChanged: (v) => setState(() => skipHolidays = v),
                      ),
                    ],
                    const Divider(),
                    _row(
                      icon: Icons.event_rounded,
                      label: context.translate(
                          isOnce ? 'alarm_date' : 'alarm_createdFor'),
                      trailing: Text(
                        isOnce && nextDate != null
                            ? formatRelativeDay(context, nextDate)
                            : formatRelativeDay(context, createdFor),
                        style: const TextStyle(
                            fontSize: 15, color: ThemeColors.secondary),
                      ),
                      onTap: _selectCreatedFor,
                    ),
                  ]),

                  // --- Options ---
                  _section(context.translate('options'), [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TextField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 40,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.label_outline_rounded),
                          hintText:
                              context.translate('alarm_title_placeholder'),
                          counterText: '',
                        ),
                      ),
                    ),
                    _row(
                      icon: Icons.music_note_rounded,
                      label: context.translate('select_audio'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(audioLabel(assetAudio),
                              style: const TextStyle(
                                  fontSize: 15, color: ThemeColors.textMuted)),
                          const Icon(Icons.chevron_right_rounded,
                              color: ThemeColors.textMuted),
                        ],
                      ),
                      onTap: _pickSound,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                      child: Row(
                        children: [
                          Icon(
                            volume == 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            size: 22,
                            color: ThemeColors.textMuted,
                          ),
                          Expanded(
                            child: Slider(
                              value: volume,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              label: '${volume.round()} %',
                              onChanged: (v) => setState(() => volume = v),
                              onChangeEnd: (v) {
                                if (playing != null) {
                                  VolumeController().setVolume(v / 100);
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text('${volume.round()}%',
                                style: const TextStyle(
                                    color: ThemeColors.textMuted)),
                          ),
                          IconButton(
                            tooltip: context.translate('preview'),
                            onPressed: () => _togglePreview(assetAudio),
                            icon: Icon(
                              playing != null
                                  ? Icons.stop_circle_rounded
                                  : Icons.play_circle_outline_rounded,
                              color: ThemeColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration_rounded),
                      title: Text(context.translate('vibrate')),
                      value: vibrate,
                      onChanged: (v) => setState(() => vibrate = v),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.repeat_rounded),
                      title: Text(context.translate('loop_audio')),
                      value: loopAudio,
                      onChanged: (v) => setState(() => loopAudio = v),
                    ),
                  ]),

                  if (!creating) ...[
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: deleteAlarm,
                      style: TextButton.styleFrom(
                        foregroundColor: ThemeColors.errorSoft,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(context.translate('delete_alarm')),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
