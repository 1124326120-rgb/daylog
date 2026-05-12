import 'package:flutter/material.dart';
import 'this_day_last_year_page.dart';
import '../services/notification_service.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final LocaleProvider localeProvider;

  const ProfilePage({super.key, required this.localeProvider});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await NotificationService.instance.isReminderEnabled();
    final time = await NotificationService.instance.getReminderTime();
    if (mounted) {
      setState(() {
        _reminderEnabled = enabled;
        _reminderTime = time ?? const TimeOfDay(hour: 21, minute: 0);
      });
    }
  }

  Future<void> _toggleReminder(bool value) async {
    await NotificationService.instance.setReminderEnabled(value);
    setState(() => _reminderEnabled = value);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null) {
      await NotificationService.instance.setReminderTime(time);
      if (_reminderEnabled) {
        await NotificationService.instance.scheduleDailyReminder(time.hour, time.minute);
      }
      setState(() => _reminderTime = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Language section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.languageButtonLabel),
            subtitle: Text(l10n.languageStatus),
            value: widget.localeProvider.isChinese,
            onChanged: (val) {
              widget.localeProvider.setLocale(val ? 'zh' : 'en');
            },
          ),
          const Divider(),
          // Daily reminder section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.dailyReminder,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.enableReminder),
            subtitle: Text(l10n.reminderSubtitle),
            value: _reminderEnabled,
            onChanged: _toggleReminder,
          ),
          ListTile(
            title: Text(l10n.reminderTime),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: _pickTime,
          ),
          if (_reminderEnabled)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.previewNotification),
              subtitle: Text(l10n.notificationPreviewText),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.about,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.appName),
            subtitle: Text('${l10n.version} 1.0.0'),
          ),
        ],
      ),
    );
  }
}
