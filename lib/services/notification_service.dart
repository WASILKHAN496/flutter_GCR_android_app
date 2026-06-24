import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
class NotificationPreferences {
  const NotificationPreferences({
    required this.dueTodayEnabled,
    required this.dueSoonEnabled,
    required this.lateEnabled,
    required this.syncCompleteEnabled,
    required this.vibrationEnabled,
  });

  final bool dueTodayEnabled;
  final bool dueSoonEnabled;
  final bool lateEnabled;
  final bool syncCompleteEnabled;
  final bool vibrationEnabled;
}

class NotificationService {
  bool _isTimezoneInitialized = false;
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String dueTodayEnabledKey = 'notification_due_today_enabled';
  static const String dueSoonEnabledKey = 'notification_due_soon_enabled';
  static const String lateEnabledKey = 'notification_late_enabled';
  static const String syncCompleteEnabledKey =
      'notification_sync_complete_enabled';
  static const String vibrationEnabledKey = 'notification_vibration_enabled';

  static const String _dueTodayKey = 'last_due_today_notification_date';
  static const String _lateKey = 'last_late_notification_date';
  static const String _dueSoonKey = 'last_due_soon_notification_date';
  static const String _scheduledReminderIdsKey =
      'scheduled_classroom_reminder_ids';

  static const AndroidNotificationChannel _mainChannel =
  AndroidNotificationChannel(
    'gcr_helper_main_channel',
    'GCR Helper Notifications',
    description: 'Notifications for Google Classroom reminders and updates.',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    setupTimezone();
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_mainChannel);

    _isInitialized = true;
  }

  Future<void> requestPermission() async {
    await init();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {
      // Some Android versions/devices do not show this permission screen.
    }
  }
  Future<void> scheduleAssignmentReminderNotifications({
    required List<RealClassroomTask> tasks,
  }) async {
    await init();
    await requestPermission();

    final NotificationPreferences preferences = await getPreferences();

    await cancelScheduledClassroomReminders();

    final List<int> scheduledIds = <int>[];

    for (final RealClassroomTask task in tasks) {
      if (task.submissionStatus == 'Submitted') {
        continue;
      }

      if (task.dueDateTime == null) {
        continue;
      }

      if (preferences.dueTodayEnabled && isDueTodayAndNotSubmitted(task)) {
        final int id = stableNotificationId('today_${task.id}', 300000);
        final timezone.TZDateTime scheduleTime =
        nextUsefulTodayReminderTime(task.dueDateTime!);

        await scheduleNotification(
          id: id,
          title: 'Due Today',
          body: '"${task.title}" is due today.',
          scheduledTime: scheduleTime,
          enableVibration: preferences.vibrationEnabled,
        );

        scheduledIds.add(id);
      }

      if (preferences.dueSoonEnabled && isDueSoonAndNotSubmitted(task)) {
        final int id = stableNotificationId('soon_${task.id}', 400000);
        final timezone.TZDateTime scheduleTime =
        dueSoonReminderTime(task.dueDateTime!);

        await scheduleNotification(
          id: id,
          title: 'Upcoming Assignment',
          body: '"${task.title}" is due soon.',
          scheduledTime: scheduleTime,
          enableVibration: preferences.vibrationEnabled,
        );

        scheduledIds.add(id);
      }

      if (preferences.lateEnabled &&
          task.submissionStatus == 'Late Not Submitted') {
        final int id = stableNotificationId('late_${task.id}', 500000);
        final timezone.TZDateTime scheduleTime = nextDailyLateReminderTime();

        await scheduleRepeatingDailyNotification(
          id: id,
          title: 'Late Assignment',
          body: '"${task.title}" is late and not submitted.',
          scheduledTime: scheduleTime,
          enableVibration: preferences.vibrationEnabled,
        );

        scheduledIds.add(id);
      }
    }

    await saveScheduledReminderIds(scheduledIds);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required timezone.TZDateTime scheduledTime,
    required bool enableVibration,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'gcr_helper_main_channel',
      'GCR Helper Notifications',
      channelDescription:
      'Notifications for Google Classroom reminders and updates.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: enableVibration,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleRepeatingDailyNotification({
    required int id,
    required String title,
    required String body,
    required timezone.TZDateTime scheduledTime,
    required bool enableVibration,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'gcr_helper_main_channel',
      'GCR Helper Notifications',
      channelDescription:
      'Notifications for Google Classroom reminders and updates.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: enableVibration,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  timezone.TZDateTime nextUsefulTodayReminderTime(DateTime dueDateTime) {
    final timezone.TZDateTime now = timezone.TZDateTime.now(timezone.local);

    timezone.TZDateTime oneHourBeforeDue = timezone.TZDateTime(
      timezone.local,
      dueDateTime.year,
      dueDateTime.month,
      dueDateTime.day,
      dueDateTime.hour,
      dueDateTime.minute,
    ).subtract(const Duration(hours: 1));

    if (oneHourBeforeDue.isAfter(now)) {
      return oneHourBeforeDue;
    }

    return now.add(const Duration(minutes: 5));
  }

  timezone.TZDateTime dueSoonReminderTime(DateTime dueDateTime) {
    final timezone.TZDateTime now = timezone.TZDateTime.now(timezone.local);

    timezone.TZDateTime oneDayBeforeDue = timezone.TZDateTime(
      timezone.local,
      dueDateTime.year,
      dueDateTime.month,
      dueDateTime.day,
      9,
    ).subtract(const Duration(days: 1));

    if (oneDayBeforeDue.isAfter(now)) {
      return oneDayBeforeDue;
    }

    return now.add(const Duration(minutes: 10));
  }

  timezone.TZDateTime nextDailyLateReminderTime() {
    final timezone.TZDateTime now = timezone.TZDateTime.now(timezone.local);

    timezone.TZDateTime nextReminder = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      9,
    );

    if (nextReminder.isBefore(now)) {
      nextReminder = nextReminder.add(const Duration(days: 1));
    }

    return nextReminder;
  }

  int stableNotificationId(String text, int base) {
    int hash = 0;

    for (int i = 0; i < text.length; i++) {
      hash = (hash * 31 + text.codeUnitAt(i)) & 0x7fffffff;
    }

    return base + (hash % 90000);
  }

  Future<void> saveScheduledReminderIds(List<int> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _scheduledReminderIdsKey,
      ids.map((int id) => id.toString()).toList(),
    );
  }

  Future<void> cancelScheduledClassroomReminders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<String> savedIds =
        prefs.getStringList(_scheduledReminderIdsKey) ?? <String>[];

    for (final String idText in savedIds) {
      final int? id = int.tryParse(idText);

      if (id != null) {
        await _notificationsPlugin.cancel(id: id);
      }
    }

    await prefs.remove(_scheduledReminderIdsKey);
  }
  Future<NotificationPreferences> getPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return NotificationPreferences(
      dueTodayEnabled: prefs.getBool(dueTodayEnabledKey) ?? true,
      dueSoonEnabled: prefs.getBool(dueSoonEnabledKey) ?? true,
      lateEnabled: prefs.getBool(lateEnabledKey) ?? true,
      syncCompleteEnabled: prefs.getBool(syncCompleteEnabledKey) ?? false,
      vibrationEnabled: prefs.getBool(vibrationEnabledKey) ?? true,
    );
  }

  Future<void> scheduleTestNotificationAfterTwoMinutes() async {
    await init();
    await requestPermission();

    final NotificationPreferences preferences = await getPreferences();

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'gcr_helper_main_channel',
      'GCR Helper Notifications',
      channelDescription:
      'Notifications for Google Classroom reminders and updates.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: preferences.vibrationEnabled,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final timezone.TZDateTime scheduledTime =
    timezone.TZDateTime.now(timezone.local).add(
      const Duration(minutes: 2),
    );

    await _notificationsPlugin.zonedSchedule(
      id: 9001,
      title: 'GCR HELPER Scheduled Test',
      body: 'This notification was scheduled and can appear even if app is closed.',
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
  Future<void> savePreference({
    required String key,
    required bool value,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> showTestNotification() async {
    await init();
    await requestPermission();

    final NotificationPreferences preferences = await getPreferences();

    await showNotification(
      id: 1001,
      title: 'GCR HELPER',
      body: 'Test notification is working successfully.',
      enableVibration: preferences.vibrationEnabled,
    );
  }

  Future<void> showClassroomSummaryNotifications({
    required List<RealClassroomTask> tasks,
    bool force = false,
  }) async {
    await init();
    await requestPermission();

    final NotificationPreferences preferences = await getPreferences();

    final List<RealClassroomTask> dueTodayTasks =
    tasks.where(isDueTodayAndNotSubmitted).toList();

    final List<RealClassroomTask> lateTasks =
    tasks.where((RealClassroomTask task) {
      return task.submissionStatus == 'Late Not Submitted';
    }).toList();

    final List<RealClassroomTask> dueSoonTasks =
    tasks.where(isDueSoonAndNotSubmitted).toList();

    if (preferences.dueTodayEnabled &&
        dueTodayTasks.isNotEmpty &&
        await canSendToday(_dueTodayKey, force: force)) {
      await showNotification(
        id: 2001,
        title: 'Assignments Due Today',
        body: buildTaskMessage(
          dueTodayTasks,
          'assignment is due today',
          'assignments are due today',
        ),
        enableVibration: preferences.vibrationEnabled,
      );
    }

    if (preferences.lateEnabled &&
        lateTasks.isNotEmpty &&
        await canSendToday(_lateKey, force: force)) {
      await showNotification(
        id: 2002,
        title: 'Late Assignments',
        body: buildTaskMessage(
          lateTasks,
          'assignment is late and not submitted',
          'assignments are late and not submitted',
        ),
        enableVibration: preferences.vibrationEnabled,
      );
    }

    if (preferences.dueSoonEnabled &&
        dueSoonTasks.isNotEmpty &&
        await canSendToday(_dueSoonKey, force: force)) {
      await showNotification(
        id: 2003,
        title: 'Upcoming Assignments',
        body: buildTaskMessage(
          dueSoonTasks,
          'assignment is due soon',
          'assignments are due soon',
        ),
        enableVibration: preferences.vibrationEnabled,
      );
    }
  }

  void setupTimezone() {
    if (_isTimezoneInitialized) {
      return;
    }

    timezone_data.initializeTimeZones();

    // Pakistan timezone for your app demo and university project.
    timezone.setLocalLocation(timezone.getLocation('Asia/Karachi'));

    _isTimezoneInitialized = true;
  }
  Future<void> showSyncCompleteNotification({
    required int totalCourses,
    required int totalTasks,
  }) async {
    await init();

    final NotificationPreferences preferences = await getPreferences();

    if (!preferences.syncCompleteEnabled) {
      return;
    }

    await showNotification(
      id: 2004,
      title: 'Classroom Sync Complete',
      body: '$totalCourses courses and $totalTasks assignments synced.',
      enableVibration: preferences.vibrationEnabled,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required bool enableVibration,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'gcr_helper_main_channel',
      'GCR Helper Notifications',
      channelDescription:
      'Notifications for Google Classroom reminders and updates.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: enableVibration,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  bool isDueTodayAndNotSubmitted(RealClassroomTask task) {
    if (task.submissionStatus == 'Submitted') {
      return false;
    }

    final DateTime? dueDate = task.dueDateTime;

    if (dueDate == null) {
      return false;
    }

    final DateTime now = DateTime.now();

    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  bool isDueSoonAndNotSubmitted(RealClassroomTask task) {
    if (task.submissionStatus == 'Submitted') {
      return false;
    }

    if (task.submissionStatus == 'Late Not Submitted') {
      return false;
    }

    final DateTime? dueDate = task.dueDateTime;

    if (dueDate == null) {
      return false;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime dueDay = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    );

    final int difference = dueDay.difference(today).inDays;

    return difference > 0 && difference <= 3;
  }

  String buildTaskMessage(
      List<RealClassroomTask> tasks,
      String singleText,
      String multipleText,
      ) {
    if (tasks.length == 1) {
      return '"${tasks.first.title}" $singleText.';
    }

    return '${tasks.length} $multipleText. First: ${tasks.first.title}';
  }

  Future<bool> canSendToday(
      String key, {
        required bool force,
      }) async {
    if (force) {
      return true;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final DateTime now = DateTime.now();
    final String today = '${now.year}-${now.month}-${now.day}';

    final String? lastDate = prefs.getString(key);

    if (lastDate == today) {
      return false;
    }

    await prefs.setString(key, today);
    return true;
  }
}