import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:weekup/core/blocs/locale_cubit.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/screens/alarm_logs_screen.dart';
import 'package:weekup/services/alarm_service.dart';
import 'package:weekup/services/settings_service.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/widgets/devmeup_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  AppSettings? settings;
  final Map<Permission, PermissionStatus> _status = {};

  List<Permission> get _permissions => [
        Permission.notification,
        if (Alarm.android) Permission.scheduleExactAlarm,
        if (Alarm.android) Permission.ignoreBatteryOptimizations,
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppSettings.load().then((s) {
      if (mounted) setState(() => settings = s);
    });
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retour depuis les réglages système
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    for (final p in _permissions) {
      final status = await p.status;
      if (mounted) setState(() => _status[p] = status);
    }
  }

  Future<void> _update(AppSettings next) async {
    setState(() => settings = next);
    await next.save();
    // La montée progressive est portée par les alarmes planifiées
    if (mounted) {
      await AlarmService().syncAlarms(AlarmNotificationTexts.of(context));
    }
  }

  Future<void> _fixPermission(Permission p) async {
    final status = await p.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    await _refreshPermissions();
  }

  Future<T?> _choose<T>({
    required String title,
    required List<T> values,
    required T current,
    required String Function(T) label,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final v in values)
              ListTile(
                title: Text(label(v)),
                trailing: v == current
                    ? const Icon(Icons.check_rounded,
                        color: ThemeColors.secondary)
                    : null,
                onTap: () => Navigator.pop(ctx, v),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: ThemeColors.textMuted,
                letterSpacing: 1.1,
              ),
        ),
      );

  Widget _card(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      );

  Widget _value(String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style:
                  const TextStyle(fontSize: 15, color: ThemeColors.secondary)),
          const Icon(Icons.chevron_right_rounded, color: ThemeColors.textMuted),
        ],
      );

  String _minutes(int m) =>
      context.translate('duration.minutes', translationParams: {'n': '$m'});

  String _fade(int s) => s == 0
      ? context.translate('settings.off')
      : context.translate('duration.seconds', translationParams: {'n': '$s'});

  String _silence(int m) =>
      m == 0 ? context.translate('settings.never') : _minutes(m);

  String _lead(int m) {
    if (m == 0) return context.translate('settings.off');
    if (m % 60 == 0) {
      return context
          .translate('duration.hours', translationParams: {'n': '${m ~/ 60}'});
    }
    return _minutes(m);
  }

  Widget _permissionTile(Permission p) {
    final status = _status[p];
    final granted = status?.isGranted ?? false;
    final key = switch (p) {
      Permission.notification => 'notifications',
      Permission.scheduleExactAlarm => 'exact_alarm',
      _ => 'battery',
    };
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
        color: granted ? ThemeColors.success : ThemeColors.warning,
      ),
      title: Text(context.translate('settings.perm.$key')),
      subtitle: Text(
        context.translate('settings.perm.${key}_hint'),
        style: const TextStyle(color: ThemeColors.textMuted),
      ),
      trailing: granted || status == null
          ? null
          : TextButton(
              onPressed: () => _fixPermission(p),
              child: Text(context.translate('settings.fix')),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final locale = context.watch<LocaleCubit>().state;

    return Scaffold(
      appBar: AppBar(title: Text(context.translate('settings.title'))),
      body: s == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _header(context.translate('settings.ringing')),
                _card([
                  ListTile(
                    leading: const Icon(Icons.snooze_rounded),
                    title: Text(context.translate('settings.snooze_duration')),
                    trailing: _value(_minutes(s.snoozeMinutes)),
                    onTap: () async {
                      final v = await _choose<int>(
                        title: context.translate('settings.snooze_duration'),
                        values: AppSettings.snoozeChoices,
                        current: s.snoozeMinutes,
                        label: _minutes,
                      );
                      if (v != null) {
                        await _update(s.copyWith(snoozeMinutes: v));
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.repeat_one_rounded),
                    title: Text(context.translate('settings.max_snoozes')),
                    trailing: _value('${s.maxSnoozes}'),
                    onTap: () async {
                      final v = await _choose<int>(
                        title: context.translate('settings.max_snoozes'),
                        values: AppSettings.maxSnoozeChoices,
                        current: s.maxSnoozes,
                        label: (n) => '$n',
                      );
                      if (v != null) await _update(s.copyWith(maxSnoozes: v));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_off_outlined),
                    title: Text(context.translate('settings.silence')),
                    subtitle: Text(context.translate('settings.silence_hint'),
                        style: const TextStyle(color: ThemeColors.textMuted)),
                    trailing: _value(_silence(s.silenceAfterMinutes)),
                    onTap: () async {
                      final v = await _choose<int>(
                        title: context.translate('settings.silence'),
                        values: AppSettings.silenceChoices,
                        current: s.silenceAfterMinutes,
                        label: _silence,
                      );
                      if (v != null) {
                        await _update(s.copyWith(silenceAfterMinutes: v));
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.trending_up_rounded),
                    title: Text(context.translate('settings.fade')),
                    subtitle: Text(context.translate('settings.fade_hint'),
                        style: const TextStyle(color: ThemeColors.textMuted)),
                    trailing: _value(_fade(s.fadeSeconds)),
                    onTap: () async {
                      final v = await _choose<int>(
                        title: context.translate('settings.fade'),
                        values: AppSettings.fadeChoices,
                        current: s.fadeSeconds,
                        label: _fade,
                      );
                      if (v != null) await _update(s.copyWith(fadeSeconds: v));
                    },
                  ),
                ]),
                _header(context.translate('upcoming.section')),
                _card([
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(context.translate('upcoming.setting')),
                    subtitle: Text(context.translate('upcoming.setting_hint'),
                        style: const TextStyle(color: ThemeColors.textMuted)),
                    trailing: _value(_lead(s.upcomingMinutes)),
                    onTap: () async {
                      final v = await _choose<int>(
                        title: context.translate('upcoming.setting'),
                        values: AppSettings.upcomingChoices,
                        current: s.upcomingMinutes,
                        label: _lead,
                      );
                      if (v != null) {
                        await _update(s.copyWith(upcomingMinutes: v));
                      }
                    },
                  ),
                ]),
                _header(context.translate('settings.reliability')),
                _card([for (final p in _permissions) _permissionTile(p)]),
                _header(context.translate('settings.general')),
                _card([
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: Text(context.translate('logs_title')),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: ThemeColors.textMuted),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AlarmLogsScreen()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: Text(context.translate('settings.language')),
                    trailing: _value(
                        context.translate('languages.${locale.languageCode}')),
                    onTap: () async {
                      final v = await _choose<Locale>(
                        title: context.translate('settings.language'),
                        values: LocalizationApp.supportedLocales,
                        current: LocalizationApp.supportedLocales.firstWhere(
                          (l) => l.languageCode == locale.languageCode,
                          orElse: () => LocalizationApp.forcedLocale,
                        ),
                        label: (l) =>
                            context.translate('languages.${l.languageCode}'),
                      );
                      if (v != null && context.mounted) {
                        context.read<LocaleCubit>().changeLocale(v);
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                const Center(child: DevMeUpWidget()),
              ],
            ),
    );
  }
}
