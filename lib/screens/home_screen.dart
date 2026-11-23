import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/screens/planning_screen.dart';
import 'package:weekup/screens/settings_screen.dart';
import 'package:weekup/services/alarm_log_service.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/services/settings_service.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/widgets/devmeup_widget.dart';
import 'package:weekup/widgets/next_alarm_set.dart';

import '../services/alarm_permissions_service.dart';
import '../widgets/alarm_tile.dart';
import 'alarm_edit_screen.dart';
import 'alarm_ring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<AlarmModel> alarms = [];
  AlarmModel? snooze;
  ({AlarmModel alarm, DateTime date})? next;
  DateTime? resumeAt;
  bool loaded = false;
  late AlarmService alarmService;

  static StreamSubscription<AlarmSettings>? ringSubscription;
  bool _ringScreenOpen = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    alarmService = AlarmService();
    ringSubscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AlarmPermissionsService.checkNotificationPermission(context);
      if (Alarm.android && mounted) {
        await AlarmPermissionsService.checkAndroidScheduleExactAlarmPermission(
          context,
        );
      }
      if (mounted) await _resync();
    });
    unawaited(loadAlarms());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_resync());
  }

  /// Replanifie toutes les alarmes (au démarrage et au retour dans l'app).
  Future<void> _resync() async {
    await alarmService.syncAlarms(AlarmNotificationTexts.of(context));
    await loadAlarms();
  }

  Future<void> loadAlarms() async {
    final all = await alarmService.cleanup();
    final found = await alarmService.findNextAlarm();
    final vacation = await AppSettings.vacationResumeAt();
    if (!mounted) return;

    final regular = all.where((a) => !a.isSnooze).toList()
      ..sort((a, b) {
        final ta = a.time.toLocal(), tb = b.time.toLocal();
        final byTime =
            (ta.hour * 60 + ta.minute).compareTo(tb.hour * 60 + tb.minute);
        return byTime != 0 ? byTime : (a.id ?? 0).compareTo(b.id ?? 0);
      });

    setState(() {
      alarms = regular;
      snooze = all.where((a) => a.isSnooze).firstOrNull;
      next = found;
      resumeAt = vacation;
      loaded = true;
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    debugPrint(
      '[ALARM] 🚨 Alarm rang -> id=${alarmSettings.id}, '
      'title=${alarmSettings.notificationSettings.title}, '
      'dateTime=${alarmSettings.dateTime}',
    );
    if (_ringScreenOpen) return;
    _ringScreenOpen = true;

    await alarmService.saveAlarmLog(alarmSettings);
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AlarmRingScreen(
          alarmSettings: alarmSettings,
          loadAlarms: loadAlarms,
        ),
      ),
    );

    _ringScreenOpen = false;
    unawaited(loadAlarms());
  }

  Future<void> navigateToAlarmEditScreen(AlarmModel? alarm) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.94,
        child: AlarmEditScreen(alarm: alarm),
      ),
    );

    if (res == true) unawaited(loadAlarms());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    unawaited(loadAlarms());
  }

  // ---------------------------------------------------
  // Actions sur une alarme
  // ---------------------------------------------------
  Future<void> _toggle(AlarmModel alarm, bool value) async {
    setState(() {
      alarm.isActive = value;
      alarm.skippedUntil = null;
      if (value) alarm.createdAt = DateTime.now().toUtc();
    });
    await alarmService.editAlarmById(context, alarm, showToast: value);
    await loadAlarms();
  }

  Future<void> _delete(AlarmModel alarm) async {
    final backup = alarm.copy();
    setState(() => alarms.removeWhere((a) => a.id == alarm.id));
    await alarmService.deleteAlarmById(context, alarm.id!);
    await loadAlarms();
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.translate('alarm_deleted')),
          action: SnackBarAction(
            label: context.translate('undo'),
            onPressed: () async {
              await alarmService.saveAlarm(context, backup, showToast: false);
              await loadAlarms();
            },
          ),
        ),
      );
  }

  Future<void> _onAction(AlarmModel alarm, AlarmTileAction action) async {
    switch (action) {
      case AlarmTileAction.skip:
        alarm.skippedUntil = alarm.getNextOccurrence()?.toUtc();
        await alarmService.editAlarmById(context, alarm);
      case AlarmTileAction.unskip:
        alarm.skippedUntil = null;
        await alarmService.editAlarmById(context, alarm);
      case AlarmTileAction.duplicate:
        final copy = alarm.copy()
          ..id = null
          ..createdAt = DateTime.now().toUtc();
        await alarmService.saveAlarm(context, copy);
      case AlarmTileAction.delete:
        await _delete(alarm);
        return;
    }
    await loadAlarms();
  }

  // ---------------------------------------------------
  // Mode vacances
  // ---------------------------------------------------
  Future<void> _vacation() async {
    if (resumeAt != null) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_calendar_rounded),
                title: Text(ctx.translate('vacation.change')),
                onTap: () => Navigator.pop(ctx, 'change'),
              ),
              ListTile(
                leading: const Icon(Icons.alarm_on_rounded),
                title: Text(ctx.translate('vacation.resume')),
                onTap: () => Navigator.pop(ctx, 'resume'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (action == 'resume') return _setVacation(null);
      if (action != 'change') return;
    }
    if (!mounted) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = resumeAt?.subtract(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      helpText: context.translate('vacation.pick'),
      initialDate: current ?? today.add(const Duration(days: 6)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) await _setVacation(picked);
  }

  Future<void> _setVacation(DateTime? lastDayOff) async {
    await AppSettings.setVacation(lastDayOff);
    if (!mounted) return;
    await alarmService.syncAlarms(AlarmNotificationTexts.of(context));
    await loadAlarms();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.translate(
            lastDayOff == null ? 'vacation.resumed' : 'vacation.started')),
      ));
  }

  Future<void> _cancelSnooze() async {
    await alarmService.clearSnoozes(context);
    if (!mounted) return;
    // Remplace le message « Alarme supprimée · Rétablir » éventuel
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.translate('snooze_canceled'))),
      );
    await loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: ThemeColors.night,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.translate('common.appTitle'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              tooltip: context.translate('planning.title'),
              icon: const Icon(Icons.calendar_view_week_rounded),
              onPressed: () => _navigateTo(const PlanningScreen()),
            ),
            IconButton(
              tooltip: context.translate('vacation.title'),
              icon: Icon(
                resumeAt != null
                    ? Icons.beach_access_rounded
                    : Icons.beach_access_outlined,
                color: resumeAt != null ? ThemeColors.secondary : null,
              ),
              onPressed: _vacation,
            ),
            IconButton(
              tooltip: context.translate('settings.title'),
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _navigateTo(const SettingsScreen()),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: !loaded
            ? const SizedBox.shrink()
            : RefreshIndicator(
                onRefresh: _resync,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  children: [
                    NextAlarmSet(
                      next: next,
                      snooze: snooze,
                      onCancelSnooze: _cancelSnooze,
                      resumeAt: resumeAt,
                      onEndVacation: () => _setVacation(null),
                    ),
                    const SizedBox(height: 24),
                    if (alarms.isEmpty)
                      _EmptyState(
                        onCreate: () => navigateToAlarmEditScreen(null),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          context.translate('alarms.title'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: ThemeColors.textMuted),
                        ),
                      ),
                      for (final alarm in alarms)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AlarmTile(
                            key: ValueKey('alarm-${alarm.id}'),
                            alarm: alarm,
                            resumeAt: resumeAt,
                            onPressed: () => navigateToAlarmEditScreen(alarm),
                            onDismissed: () => _delete(alarm),
                            onToggleActive: (v) => _toggle(alarm, v),
                            onAction: (a) => _onAction(alarm, a),
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    const Center(child: DevMeUpWidget()),
                  ],
                ),
              ),
        floatingActionButton: alarms.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => navigateToAlarmEditScreen(null),
                icon: const Icon(Icons.add_alarm_rounded),
                label: Text(context.translate('alarms.new')),
              )
            : null,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: ThemeColors.nightSurfaceHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_add_rounded,
                size: 44, color: ThemeColors.secondary),
          ),
          const SizedBox(height: 20),
          Text(context.translate('empty.title'), style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            context.translate('empty.subtitle'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: ThemeColors.textMuted),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.translate('alarms.new')),
          ),
        ],
      ),
    );
  }
}
