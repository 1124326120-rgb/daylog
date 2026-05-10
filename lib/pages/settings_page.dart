import 'package:flutter/material.dart';
import 'this_day_last_year_page.dart';
import '../services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Daily reminder section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Daily Reminder',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable daily reminder'),
            subtitle: const Text('Get reminded to write your diary'),
            value: _reminderEnabled,
            onChanged: _toggleReminder,
          ),
          ListTile(
            title: const Text('Reminder time'),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: _pickTime,
          ),
          if (_reminderEnabled)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Preview notification text'),
              subtitle: const Text('Today has something worth remembering?'),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('DayLog'),
            subtitle: const Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}


