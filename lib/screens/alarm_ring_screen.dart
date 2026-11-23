import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_log_model.dart';
import 'package:weekup/services/alarm_log_service.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/services/settings_service.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/utils/alarm_format.dart';

class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({
    required this.alarmSettings,
    required this.loadAlarms,
    super.key,
  });

  final AlarmSettings alarmSettings;
  final Function loadAlarms;

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late final VolumeController _volumeController;
  late final AnimationController _pulse;
  StreamSubscription<double>? _subscription;
  late AlarmService alarmService;

  bool _stopped = false;
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();

  int _remainingSnoozes = 1;
  int _snoozeMinutes = 10;

  /// Volume de référence lu après la mise en route de l'alarme : le plugin
  /// règle lui-même le volume système, ce qui déclenche aussi l'écouteur.
  double? _baselineVolume;
  final DateTime _openedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    alarmService = AlarmService();
    _volumeController = VolumeController()..showSystemUI = false;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _startRefreshLoop();
    unawaited(_loadSnoozeInfo());

    _subscription = _volumeController.listener(_onVolumeChanged);
  }

  Future<void> _loadSnoozeInfo() async {
    final settings = await AppSettings.load();
    final remaining = await alarmService.remainingSnoozes();
    if (!mounted) return;
    setState(() {
      _snoozeMinutes = settings.snoozeMinutes;
      _remainingSnoozes = remaining;
    });
  }

  /// Un appui sur un bouton de volume reporte l'alarme.
  Future<void> _onVolumeChanged(double v) async {
    if (_stopped) return;

    // Période de grâce : ignorer les réglages faits par le plugin au démarrage
    if (DateTime.now().difference(_openedAt) < const Duration(seconds: 2)) {
      _baselineVolume = v;
      return;
    }
    final baseline = _baselineVolume ??= v;
    if ((v - baseline).abs() < 0.01) return;

    if (_remainingSnoozes <= 0) return;
    final isRinging = await Alarm.isRinging(widget.alarmSettings.id);
    if (!isRinging) return;
    await _stopAlarm(snooze: true);
  }

  void _startRefreshLoop() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onRefreshTick();
    });
  }

  Future<void> _onRefreshTick() async {
    if (!mounted || _stopped) return;

    setState(() => _now = DateTime.now());

    // Arrêtée depuis la notification
    final isRinging = await Alarm.isRinging(widget.alarmSettings.id);
    if (!isRinging && !_stopped && mounted) {
      await _stopAlarm();
    }
  }

  Future<void> _stopAlarm({bool snooze = false}) async {
    if (_stopped) return;
    _stopped = true;
    HapticFeedback.mediumImpact();

    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _subscription?.cancel();
    _subscription = null;

    try {
      await Alarm.stop(widget.alarmSettings.id);
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final snoozedText = context.translate('snooze_alarm',
          translationParams: {'minutes': '$_snoozeMinutes'});

      if (snooze) {
        final shadow = await alarmService.snooze(context, widget.alarmSettings);
        if (shadow != null) {
          await alarmService.saveAlarmLog(
            widget.alarmSettings,
            action: AlarmLogAction.snooze,
            scheduledFor: shadow.getNextOccurrence(),
          );
          messenger.showSnackBar(SnackBar(content: Text(snoozedText)));
        } else if (mounted) {
          await alarmService.clearSnoozes(context);
        }
      } else if (mounted) {
        await alarmService.saveAlarmLog(
          widget.alarmSettings,
          action: AlarmLogAction.stop,
        );
        if (mounted) await alarmService.clearSnoozes(context);
      }
    } catch (e, s) {
      debugPrint('Erreur arrêt alarme: $e\n$s');
    }

    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    await widget.loadAlarms();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _subscription?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canSnooze = _remainingSnoozes > 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ThemeColors.dusk,
                ThemeColors.primary,
                ThemeColors.night
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Text(
                    formatRelativeDay(context, _now),
                    style:
                        textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatHourMinute(_now),
                    style: textTheme.displayLarge?.copyWith(
                      fontSize: 88,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _PulsingBell(animation: _pulse),
                  const SizedBox(height: 32),
                  Text(
                    widget.alarmSettings.notificationSettings.title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.translate('alarmDescription'),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: OutlinedButton.icon(
                      onPressed:
                          canSnooze ? () => _stopAlarm(snooze: true) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white
                              .withValues(alpha: canSnooze ? 0.5 : 0.15),
                        ),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      icon: const Icon(Icons.snooze_rounded),
                      label: Text(
                        canSnooze
                            ? context.translate('alarmSnoozeFor',
                                translationParams: {
                                    'minutes': '$_snoozeMinutes'
                                  })
                            : context.translate('snooze_limit_reached'),
                      ),
                    ),
                  ),
                  if (canSnooze)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        context.translate('snooze_remaining',
                            translationParams: {'n': '$_remainingSnoozes'}),
                        style: textTheme.bodySmall
                            ?.copyWith(color: Colors.white54),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton.icon(
                      onPressed: () => _stopAlarm(),
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.alarm_off_rounded),
                      label: Text(context.translate('alarmStop')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (canSnooze)
                    Text(
                      context.translate('volume_snooze_hint'),
                      textAlign: TextAlign.center,
                      style:
                          textTheme.bodySmall?.copyWith(color: Colors.white38),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingBell extends StatelessWidget {
  const _PulsingBell({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in [0.0, 0.5])
                Builder(builder: (_) {
                  final p = (t + offset) % 1.0;
                  return Container(
                    width: 72 + 68 * p,
                    height: 72 + 68 * p,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ThemeColors.secondary
                          .withValues(alpha: 0.35 * (1 - p)),
                    ),
                  );
                }),
              child!,
            ],
          );
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: ThemeColors.secondary,
          ),
          child: const Icon(Icons.alarm_rounded,
              size: 38, color: ThemeColors.night),
        ),
      ),
    );
  }
}
