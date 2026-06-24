import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _dueTodayKey = 'last_due_today_notification_date';
  static const String _lateKey = 'last_late_notification_date';
  static const String _dueSoonKey = 'last_due_soon_notification_date';

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
  }

  Future<void> showTestNotification() async {
    await init();
    await requestPermission();

    await showNotification(
      id: 1001,
      title: 'GCR HELPER',
      body: 'Test notification is working successfully.',
    );
  }

  Future<void> showClassroomSummaryNotifications({
    required List<RealClassroomTask> tasks,
    bool force = false,
  }) async {
    await init();
    await requestPermission();

    final List<RealClassroomTask> dueTodayTasks =
    tasks.where(isDueTodayAndNotSubmitted).toList();

    final List<RealClassroomTask> lateTasks =
    tasks.where((RealClassroomTask task) {
      return task.submissionStatus == 'Late Not Submitted';
    }).toList();

    final List<RealClassroomTask> dueSoonTasks =
    tasks.where(isDueSoonAndNotSubmitted).toList();

    if (dueTodayTasks.isNotEmpty &&
        await canSendToday(_dueTodayKey, force: force)) {
      await showNotification(
        id: 2001,
        title: 'Assignments Due Today',
        body: buildTaskMessage(
          dueTodayTasks,
          'assignment is due today',
          'assignments are due today',
        ),
      );
    }

    if (lateTasks.isNotEmpty && await canSendToday(_lateKey, force: force)) {
      await showNotification(
        id: 2002,
        title: 'Late Assignments',
        body: buildTaskMessage(
          lateTasks,
          'assignment is late and not submitted',
          'assignments are late and not submitted',
        ),
      );
    }

    if (dueSoonTasks.isNotEmpty &&
        await canSendToday(_dueSoonKey, force: force)) {
      await showNotification(
        id: 2003,
        title: 'Upcoming Assignments',
        body: buildTaskMessage(
          dueSoonTasks,
          'assignment is due soon',
          'assignments are due soon',
        ),
      );
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'gcr_helper_main_channel',
      'GCR Helper Notifications',
      channelDescription:
      'Notifications for Google Classroom reminders and updates.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
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