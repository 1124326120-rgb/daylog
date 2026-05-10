import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._init();

  static const List<String> _reminderMessages = [
    '今天有什么值得记住的事吗？',
    '记录今天的点滴，明天会感谢现在的自己。',
    '忙碌的一天结束了，来写写今天的心情吧。',
    '生活中的小确幸，值得被记录下来。',
    '今天过得怎么样？和我分享一下吧。',
    '睡前花几分钟，回顾今天的收获。',
    '每一天都是独一无二的，别让它溜走。',
  ];

  Future<void> initialize() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await initialize();
    _plugin.cancelAll();

    final msgIndex = DateTime.now().day % _reminderMessages.length;
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: 'Reminds you to write your diary',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.periodicallyShow(
      0,
      'DayLog',
      _reminderMessages[msgIndex],
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  Future<TimeOfDay?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_hour') ?? 21;
    final minute = prefs.getInt('reminder_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);
  }

  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('reminder_enabled') ?? false;
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    if (enabled) {
      final time = await getReminderTime();
      if (time != null) {
        await scheduleDailyReminder(time.hour, time.minute);
      }
    } else {
      await cancelAllReminders();
    }
  }
}
