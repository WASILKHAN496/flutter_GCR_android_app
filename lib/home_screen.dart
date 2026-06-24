import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/courses_screen.dart';
import 'package:best_flutter_ui_templates/deadlines_screen.dart';
import 'package:best_flutter_ui_templates/google_account_screen.dart';
import 'package:best_flutter_ui_templates/notifications_screen.dart';
import 'package:best_flutter_ui_templates/profile_screen.dart';
import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:best_flutter_ui_templates/settings_screen.dart';
import 'package:best_flutter_ui_templates/task_detail_screen.dart';
import 'package:best_flutter_ui_templates/tasks_screen.dart';
import 'package:best_flutter_ui_templates/workload_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'dart:io';
import 'package:best_flutter_ui_templates/services/app_guide_service.dart';
import 'package:best_flutter_ui_templates/notifications_screen.dart';
import 'package:best_flutter_ui_templates/services/notification_service.dart';
import 'package:best_flutter_ui_templates/services/notification_service.dart';
//line 183 to change to force notification
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> topBarAnimation;

  final ScrollController scrollController = ScrollController();

  double topBarOpacity = 0.0;
  bool multiple = true;
  bool isLoading = true;
  bool isOfflineMode = false;
  bool isBackgroundSyncing = false;
  bool hasInternetConnection = true;
  GoogleSignInAccount? dashboardAccount;
  bool hasCheckedWelcomeGuide = false;
  Timer? networkStatusTimer;

  String errorText = '';
  String studentName = 'Student';
  String syncStatusText = 'Not synced yet';

  List<RealClassroomCourse> realCourses = <RealClassroomCourse>[];
  List<RealClassroomTask> realTasks = <RealClassroomTask>[];

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    scrollController.addListener(updateTopBarOpacity);
    animationController.forward();

    loadDashboardData().then((_) {
      startNetworkWatcher();
      startBackgroundSync();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showFirstTimeGuideIfNeeded();
    });
  }

  void updateTopBarOpacity() {
    final double opacity =
    (scrollController.offset / 24).clamp(0.0, 1.0).toDouble();

    if (topBarOpacity != opacity) {
      setState(() {
        topBarOpacity = opacity;
      });
    }
  }

  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      await GoogleLoginService.instance.signInSilently();

      if (forceRefresh) {
        await ClassroomDataService.instance.refreshAllData();
      } else {
        await ClassroomDataService.instance.loadOfflineCache();
      }

      final List<RealClassroomCourse> fetchedCourses =
      await ClassroomDataService.instance.getCourses(
        forceRefresh: false,
      );

      final List<RealClassroomTask> fetchedTasks =
      await ClassroomDataService.instance.getAllCourseWork(
        forceRefresh: false,
      );

      final GoogleSignInAccount? account =
          GoogleLoginService.instance.currentUser;
      dashboardAccount = account;
      if (!mounted) {
        return;
      }

      setState(() {
        studentName = firstName(account?.displayName);
        realCourses = fetchedCourses;
        realTasks = fetchedTasks;
        isOfflineMode = ClassroomDataService.instance.isUsingOfflineData;
        syncStatusText = ClassroomDataService.instance.lastSyncText;
        isLoading = false;
        errorText = '';
      });
    } catch (error) {
      final bool offlineLoaded =
      await ClassroomDataService.instance.loadOfflineCache();

      if (offlineLoaded) {
        final List<RealClassroomCourse> offlineCourses =
        await ClassroomDataService.instance.getCourses();

        final List<RealClassroomTask> offlineTasks =
        await ClassroomDataService.instance.getAllCourseWork();

        if (!mounted) {
          return;
        }

        setState(() {
          realCourses = offlineCourses;
          realTasks = offlineTasks;
          isOfflineMode = true;
          syncStatusText = ClassroomDataService.instance.lastSyncText;
          isLoading = false;
          errorText = '';
        });

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        isOfflineMode = false;
        syncStatusText = ClassroomDataService.instance.lastSyncText;
        errorText = '';
      });
    }
  }
  Future<void> startBackgroundSync() async {
    if (isBackgroundSyncing) {
      return;
    }

    setState(() {
      isBackgroundSyncing = true;
    });

    try {
      await ClassroomDataService.instance.startBackgroundSync();

      final List<RealClassroomCourse> syncedCourses =
      await ClassroomDataService.instance.getCourses();

      final List<RealClassroomTask> syncedTasks =
      await ClassroomDataService.instance.getAllCourseWork();
      await NotificationService.instance.showClassroomSummaryNotifications(
        tasks: syncedTasks,
        //force: true,
      );
      await NotificationService.instance.scheduleAssignmentReminderNotifications(
        tasks: syncedTasks,
      );
      await NotificationService.instance.showSyncCompleteNotification(
        totalCourses: syncedCourses.length,
        totalTasks: syncedTasks.length,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        realCourses = syncedCourses;
        realTasks = syncedTasks;
        isOfflineMode = ClassroomDataService.instance.isUsingOfflineData;
        syncStatusText = ClassroomDataService.instance.lastSyncText;
        isBackgroundSyncing = false;
        errorText = '';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        isBackgroundSyncing = false;
        isOfflineMode = ClassroomDataService.instance.isUsingOfflineData;
        syncStatusText = ClassroomDataService.instance.lastSyncText;
      });
    }
  }
  void startNetworkWatcher() {
    networkStatusTimer?.cancel();

    checkInternetConnection();

    networkStatusTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        checkInternetConnection();
      },
    );
  }

  Future<void> checkInternetConnection() async {
    bool connected = false;

    try {
      final List<InternetAddress> result =
      await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 2),
      );

      connected = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      connected = false;
    }

    if (!mounted) {
      return;
    }

    if (hasInternetConnection != connected) {
      setState(() {
        hasInternetConnection = connected;

        if (!connected) {
          isOfflineMode = true;
          syncStatusText = ClassroomDataService.instance.lastSyncText;
        }
      });
    }
  }
  Future<void> showFirstTimeGuideIfNeeded() async {
    if (hasCheckedWelcomeGuide) {
      return;
    }

    hasCheckedWelcomeGuide = true;

    final bool shouldShow =
    await AppGuideService.instance.shouldShowWelcomeGuide();

    if (!mounted || !shouldShow) {
      return;
    }

    showWelcomeGuideDialog();
  }

  void showWelcomeGuideDialog() {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isLightMode ? Colors.white : AppTheme.nearlyBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Welcome to GCR HELPER',
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isLightMode ? AppTheme.darkText : AppTheme.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              guideStep(
                number: '1',
                title: 'Connect Account',
                subtitle: 'Login with your Google Classroom account.',
                isLightMode: isLightMode,
              ),
              guideStep(
                number: '2',
                title: 'Sync Data',
                subtitle: 'The app loads your courses, tasks and deadlines.',
                isLightMode: isLightMode,
              ),
              guideStep(
                number: '3',
                title: 'Check Alerts',
                subtitle: 'See Late, Due Today and Due Soon assignments.',
                isLightMode: isLightMode,
              ),
              guideStep(
                number: '4',
                title: 'Use Reminders',
                subtitle: 'Get phone notifications even when app is closed.',
                isLightMode: isLightMode,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await AppGuideService.instance.markWelcomeGuideSeen();

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);
              },
              child: const Text(
                'MAYBE LATER',
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF81818A),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await AppGuideService.instance.markWelcomeGuideSeen();

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);

                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) =>
                    const GoogleAccountScreen(),
                  ),
                ).then((_) => loadDashboardData());
              },
              child: const Text(
                'GET STARTED',
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2633C5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget guideStep({
    required String number,
    required String title,
    required String subtitle,
    required bool isLightMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 28,
            width: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF2633C5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: AppTheme.fontName,
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isLightMode ? AppTheme.darkText : AppTheme.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 12.5,
                    height: 1.3,
                    color: isLightMode
                        ? AppTheme.grey
                        : Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  String firstName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Student';
    }

    return name.trim().split(' ').first;
  }

  int get pendingCount => realTasks.length;

  int get todayCount {
    return realTasks.where((RealClassroomTask task) {
      return deadlineCategory(task.dueDateTime) == 'Today';
    }).length;
  }
  int get dashboardLateAlertCount {
    return realTasks.where((RealClassroomTask task) {
      return task.submissionStatus == 'Late Not Submitted';
    }).length;
  }

  int get dashboardDueTodayAlertCount {
    return realTasks.where((RealClassroomTask task) {
      return NotificationService.instance.isDueTodayAndNotSubmitted(task);
    }).length;
  }

  int get dashboardDueSoonAlertCount {
    return realTasks.where((RealClassroomTask task) {
      return NotificationService.instance.isDueSoonAndNotSubmitted(task);
    }).length;
  }

  int get dashboardTotalAlertCount {
    return dashboardLateAlertCount +
        dashboardDueTodayAlertCount +
        dashboardDueSoonAlertCount;
  }
  int get upcomingCount {
    return realTasks.where((RealClassroomTask task) {
      final String category = deadlineCategory(task.dueDateTime);
      return category == 'This Week' || category == 'Upcoming';
    }).length;
  }

  int get noDueDateCount {
    return realTasks.where((RealClassroomTask task) {
      return task.dueDateTime == null;
    }).length;
  }

  String get workloadLevel {
    if (pendingCount >= 10) {
      return 'High';
    }

    if (pendingCount >= 4) {
      return 'Medium';
    }

    if (pendingCount >= 1) {
      return 'Low';
    }

    return 'Clear';
  }

  List<DashboardMetric> get dashboardItems {
    return <DashboardMetric>[
      DashboardMetric(
        title: 'Pending Work',
        subtitle: '$pendingCount assignments',
        icon: Icons.pending_actions_rounded,
        startColor: const Color(0xFFFFA726),
        endColor: const Color(0xFFFF7043),
      ),
      DashboardMetric(
        title: 'Due Today',
        subtitle: '$todayCount urgent tasks',
        icon: Icons.today_rounded,
        startColor: const Color(0xFFFA7D82),
        endColor: const Color(0xFFEF5350),
      ),
      DashboardMetric(
        title: 'Upcoming',
        subtitle: '$upcomingCount deadlines',
        icon: Icons.calendar_month_rounded,
        startColor: const Color(0xFF42A5F5),
        endColor: const Color(0xFF2633C5),
      ),
      DashboardMetric(
        title: 'No Due Date',
        subtitle: '$noDueDateCount tasks',
        icon: Icons.event_busy_rounded,
        startColor: const Color(0xFF738AE6),
        endColor: const Color(0xFF5C6BC0),
      ),
      DashboardMetric(
        title: 'Courses',
        subtitle: '${realCourses.length} active classes',
        icon: Icons.menu_book_rounded,
        startColor: const Color(0xFF7E57C2),
        endColor: const Color(0xFF5E35B1),
      ),
      DashboardMetric(
        title: 'Workload',
        subtitle: '$workloadLevel level',
        icon: Icons.insights_rounded,
        startColor: const Color(0xFF26C6DA),
        endColor: const Color(0xFF0097A7),
      ),
    ];
  }

  List<DashboardTask> get upcomingTasks {
    final List<RealClassroomTask> sortedTasks =
    List<RealClassroomTask>.from(realTasks);

    sortedTasks.sort((RealClassroomTask a, RealClassroomTask b) {
      final DateTime? aDate = a.dueDateTime;
      final DateTime? bDate = b.dueDateTime;

      if (aDate == null && bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return aDate.compareTo(bDate);
    });

    return sortedTasks.take(3).toList().asMap().entries.map(
          (MapEntry<int, RealClassroomTask> item) {
        return DashboardTask.fromRealTask(item.value, item.key);
      },
    ).toList();
  }

  List<CourseProgress> get courseProgressList {
    return realCourses.take(3).toList().asMap().entries.map(
          (MapEntry<int, RealClassroomCourse> item) {
        final int pending = coursePendingCount(item.value);
        return CourseProgress.fromRealCourse(item.value, item.key, pending);
      },
    ).toList();
  }

  int coursePendingCount(RealClassroomCourse course) {
    return realTasks.where((RealClassroomTask task) {
      return task.courseId == course.id || task.courseName == course.name;
    }).length;
  }

  String deadlineCategory(DateTime? dateTime) {
    if (dateTime == null) {
      return 'No Due Date';
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime dueDay = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    final int difference = dueDay.difference(today).inDays;

    if (difference < 0) {
      return 'Late';
    }

    if (difference == 0) {
      return 'Today';
    }

    if (difference <= 7) {
      return 'This Week';
    }

    return 'Upcoming';
  }

  @override
  void dispose() {
    animationController.dispose();
    networkStatusTimer?.cancel();
    scrollController.removeListener(updateTopBarOpacity);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Container(
      color: isLightMode ? const Color(0xFFF2F3F8) : AppTheme.nearlyBlack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            getMainListViewUI(isLightMode),
            getAppBarUI(isLightMode),
          ],
        ),
      ),
    );
  }
  String get smartGuideTitle {
    if (dashboardAccount == null) {
      return 'Connect your Google account';
    }

    if (isLoading || isBackgroundSyncing) {
      return 'Syncing your Classroom data';
    }

    if (realCourses.isEmpty && realTasks.isEmpty) {
      return 'Sync Classroom data';
    }

    if (dashboardLateAlertCount > 0) {
      return 'View late assignments';
    }

    if (dashboardDueTodayAlertCount > 0) {
      return 'Check today’s deadlines';
    }

    if (dashboardDueSoonAlertCount > 0) {
      return 'Plan upcoming assignments';
    }

    return 'You are all caught up';
  }

  String get smartGuideSubtitle {
    if (dashboardAccount == null) {
      return 'Start by connecting your Google Classroom account.';
    }

    if (isLoading || isBackgroundSyncing) {
      return 'Please wait. The app is loading latest courses and assignments.';
    }

    if (realCourses.isEmpty && realTasks.isEmpty) {
      return 'No Classroom data found yet. Try syncing again.';
    }

    if (dashboardLateAlertCount > 0) {
      return '$dashboardLateAlertCount assignment(s) are late and not submitted.';
    }

    if (dashboardDueTodayAlertCount > 0) {
      return '$dashboardDueTodayAlertCount assignment(s) are due today.';
    }

    if (dashboardDueSoonAlertCount > 0) {
      return '$dashboardDueSoonAlertCount assignment(s) are due soon.';
    }

    return 'No urgent work right now. Keep checking your dashboard.';
  }

  String get smartGuideButtonText {
    if (dashboardAccount == null) {
      return 'Connect';
    }

    if (isLoading || isBackgroundSyncing) {
      return 'Syncing';
    }

    if (realCourses.isEmpty && realTasks.isEmpty) {
      return 'Sync Now';
    }

    if (dashboardLateAlertCount > 0) {
      return 'Open Late';
    }

    if (dashboardDueTodayAlertCount > 0) {
      return 'Open Today';
    }

    if (dashboardDueSoonAlertCount > 0) {
      return 'Deadlines';
    }

    return 'Reminders';
  }

  IconData get smartGuideIcon {
    if (dashboardAccount == null) {
      return Icons.login_rounded;
    }

    if (isLoading || isBackgroundSyncing) {
      return Icons.sync_rounded;
    }

    if (dashboardLateAlertCount > 0) {
      return Icons.warning_rounded;
    }

    if (dashboardDueTodayAlertCount > 0) {
      return Icons.today_rounded;
    }

    if (dashboardDueSoonAlertCount > 0) {
      return Icons.date_range_rounded;
    }

    return Icons.check_circle_rounded;
  }

  Color get smartGuideColor {
    if (dashboardAccount == null) {
      return const Color(0xFF2633C5);
    }

    if (isLoading || isBackgroundSyncing) {
      return const Color(0xFF42A5F5);
    }

    if (dashboardLateAlertCount > 0) {
      return const Color(0xFFEF5350);
    }

    if (dashboardDueTodayAlertCount > 0) {
      return const Color(0xFFFFA726);
    }

    if (dashboardDueSoonAlertCount > 0) {
      return const Color(0xFF42A5F5);
    }

    return const Color(0xFF66BB6A);
  }

  void handleSmartGuideAction() {
    if (dashboardAccount == null) {
      Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => const GoogleAccountScreen(),
        ),
      ).then((_) => loadDashboardData());
      return;
    }

    if (isLoading || isBackgroundSyncing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync is running. Please wait a moment.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (realCourses.isEmpty && realTasks.isEmpty) {
      Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => const GoogleAccountScreen(),
        ),
      ).then((_) => loadDashboardData());
      return;
    }

    if (dashboardLateAlertCount > 0) {
      Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) =>
          const TasksScreen(initialFilter: 'Late'),
        ),
      );
      return;
    }

    if (dashboardDueTodayAlertCount > 0) {
      Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) =>
          const TasksScreen(initialFilter: 'Due Today'),
        ),
      );
      return;
    }

    if (dashboardDueSoonAlertCount > 0) {
      Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => const DeadlinesScreen(),
        ),
      );
      return;
    }

    Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const NotificationsScreen(),
      ),
    );
  }

  Widget buildSmartGuideCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.15)
                  : Colors.black.withOpacity(0.22),
              offset: const Offset(1, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: smartGuideColor.withOpacity(0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                smartGuideIcon,
                color: smartGuideColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'What should I do next?',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isLightMode
                          ? AppTheme.grey
                          : Colors.white.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    smartGuideTitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    smartGuideSubtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.5,
                      height: 1.35,
                      color: isLightMode
                          ? AppTheme.grey
                          : Colors.white.withOpacity(0.68),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: handleSmartGuideAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: smartGuideColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  smartGuideButtonText,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: smartGuideColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildNotificationCountCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => const NotificationsScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isLightMode
                    ? AppTheme.grey.withOpacity(0.15)
                    : Colors.black.withOpacity(0.22),
                offset: const Offset(1, 3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA726).withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFFFA726),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Classroom Alerts',
                          style: TextStyle(
                            fontFamily: AppTheme.fontName,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isLightMode
                                ? AppTheme.darkText
                                : AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dashboardTotalAlertCount == 0
                              ? 'No urgent assignment reminders right now.'
                              : '$dashboardTotalAlertCount important reminders found.',
                          style: TextStyle(
                            fontFamily: AppTheme.fontName,
                            fontSize: 12.5,
                            height: 1.3,
                            color: isLightMode
                                ? AppTheme.grey
                                : AppTheme.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isLightMode
                        ? AppTheme.grey
                        : Colors.white.withOpacity(0.65),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  alertCountBox(
                    title: 'Late',
                    value: dashboardLateAlertCount.toString(),
                    color: const Color(0xFFEF5350),
                    icon: Icons.warning_rounded,
                    isLightMode: isLightMode,
                  ),
                  const SizedBox(width: 10),
                  alertCountBox(
                    title: 'Today',
                    value: dashboardDueTodayAlertCount.toString(),
                    color: const Color(0xFFFFA726),
                    icon: Icons.today_rounded,
                    isLightMode: isLightMode,
                  ),
                  const SizedBox(width: 10),
                  alertCountBox(
                    title: 'Due Soon',
                    value: dashboardDueSoonAlertCount.toString(),
                    color: const Color(0xFF42A5F5),
                    icon: Icons.date_range_rounded,
                    isLightMode: isLightMode,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget alertCountBox({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required bool isLightMode,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isLightMode
                    ? AppTheme.grey
                    : Colors.white.withOpacity(0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getMainListViewUI(bool isLightMode) {
    return RefreshIndicator(
      color: const Color(0xFF2633C5),
      backgroundColor: isLightMode ? Colors.white : AppTheme.nearlyBlack,
      onRefresh: () async {
        await loadDashboardData(forceRefresh: true);
      },
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: AppBar().preferredSize.height +
              MediaQuery.of(context).padding.top +
              28,
          bottom: 32 + MediaQuery.of(context).padding.bottom,
        ),
        children: <Widget>[
          animatedItem(
            index: 0,
            count: 14,
            child: overviewCard(isLightMode),
          ),
          if (!isLoading)
            animatedItem(
              index: 1,
              count: 14,
              child: syncStatusBanner(isLightMode),
            ),
          animatedItem(
            index: 2,
            count: 14,
            child: sectionTitle(
              title: 'Quick Actions',
              subtitle: 'Open fast',
              isLightMode: isLightMode,
            ),
          ),
          animatedItem(
            index: 3,
            count: 14,
            child: quickActions(isLightMode),
          ),
          animatedItem(
            index: 4,
            count: 14,
            child: buildNotificationCountCard(isLightMode),
          ),
          animatedItem(
            index: 5,
            count: 14,
            child: buildSmartGuideCard(isLightMode),
          ),
          animatedItem(
            index: 6,
            count: 14,
            child: sectionTitle(
              title: 'Workload Overview',
              subtitle: multiple ? 'Grid view' : 'List view',
              isLightMode: isLightMode,
            ),
          ),
          animatedItem(
            index: 7,
            count: 14,
            child: dashboardGrid(),
          ),
          if (isLoading)
            animatedItem(
              index: 8,
              count: 14,
              child: loadingCard(isLightMode),
            ),
          if (!isLoading && errorText.isNotEmpty)
            animatedItem(
              index: 8,
              count: 14,
              child: errorCard(isLightMode),
            ),
          animatedItem(
            index: 9,
            count: 14,
            child: sectionTitle(
              title: 'Upcoming Deadlines',
              subtitle: 'Nearest first',
              isLightMode: isLightMode,
            ),
          ),
          animatedItem(
            index: 10,
            count: 14,
            child: taskList(isLightMode),
          ),
          animatedItem(
            index: 11,
            count: 14,
            child: sectionTitle(
              title: 'Course Progress',
              subtitle: 'This week',
              isLightMode: isLightMode,
            ),
          ),
          animatedItem(
            index: 12,
            count: 14,
            child: courseList(isLightMode),
          ),
          animatedItem(
            index: 13,
            count: 14,
            child: googleClassroomCard(isLightMode),
          ),
        ],
      ),
    );
  }

  Widget animatedItem({
    required int index,
    required int count,
    required Widget child,
  }) {
    final Animation<double> animation =
    Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          (1 / count) * index,
          1.0,
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? widgetChild) {
        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              35 * (1.0 - animation.value),
              0.0,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget getAppBarUI(bool isLightMode) {
    return Column(
      children: <Widget>[
        AnimatedBuilder(
          animation: animationController,
          builder: (BuildContext context, Widget? child) {
            return FadeTransition(
              opacity: topBarAnimation,
              child: Transform(
                transform: Matrix4.translationValues(
                  0.0,
                  30 * (1.0 - topBarAnimation.value),
                  0.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isLightMode ? Colors.white : AppTheme.nearlyBlack)
                        .withOpacity(topBarOpacity),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32.0),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: isLightMode
                            ? AppTheme.grey.withOpacity(0.35 * topBarOpacity)
                            : Colors.black.withOpacity(0.40 * topBarOpacity),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: MediaQuery.of(context).padding.top),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 58,
                          right: 16,
                          top: 16 - 8.0 * topBarOpacity,
                          bottom: 12 - 8.0 * topBarOpacity,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Classroom',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontName,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28 - 6 * topBarOpacity,
                                  letterSpacing: 0.7,
                                  color: isLightMode
                                      ? AppTheme.darkText
                                      : AppTheme.white,
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(32),
                              onTap: () {
                                setState(() {
                                  multiple = !multiple;
                                });
                              },
                              child: Container(
                                height: 38,
                                width: 38,
                                decoration: BoxDecoration(
                                  color: isLightMode
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: isLightMode
                                          ? AppTheme.grey.withOpacity(0.18)
                                          : Colors.black.withOpacity(0.22),
                                      blurRadius: 8,
                                      offset: const Offset(1, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  multiple
                                      ? Icons.dashboard_rounded
                                      : Icons.view_agenda_rounded,
                                  color: isLightMode
                                      ? const Color(0xFF2633C5)
                                      : Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget overviewCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFF2633C5),
              Color(0xFF6A88E5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18.0),
            bottomLeft: Radius.circular(18.0),
            bottomRight: Radius.circular(18.0),
            topRight: Radius.circular(72.0),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF2633C5).withOpacity(0.32),
              offset: const Offset(4.0, 8.0),
              blurRadius: 16.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isLoading
                          ? 'Syncing Classroom...'
                          : 'Welcome back, $studentName',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),

                    ),

                    const SizedBox(height: 8),

                    Text(

                        errorText.isNotEmpty
                            ? 'Connect your Google account to load real courses, tasks and deadlines.'
                            : isOfflineMode
                            ? 'Waiting for internet connection... Showing last saved data for ${realCourses.length} courses and $pendingCount tasks.'
                            : 'Tracking ${realCourses.length} courses and $pendingCount active Classroom tasks in one place.',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle({
    required String title,
    required String subtitle,
    required bool isLightMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.3,
                color: isLightMode ? AppTheme.darkText : AppTheme.white,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: isLightMode
                  ? AppTheme.grey
                  : AppTheme.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
  Widget syncStatusBanner(bool isLightMode) {
    final Color statusColor =
    isOfflineMode ? const Color(0xFFFFA726) : const Color(0xFF2ECC71);

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: statusColor.withOpacity(0.22),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.13)
                  : Colors.black.withOpacity(0.22),
              offset: const Offset(1.1, 2.5),
              blurRadius: 9.0,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isOfflineMode
                    ? Icons.wifi_off_rounded
                    : Icons.cloud_done_rounded,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isBackgroundSyncing
                        ? 'Syncing in Background'
                        : !hasInternetConnection
                        ? 'No Internet Connection'
                        : isOfflineMode
                        ? 'Offline Mode Active'
                        : 'Online Sync Active',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBackgroundSyncing
                        ? 'Showing saved data now. New Classroom updates are loading silently.'
                        : !hasInternetConnection
                        ? 'Internet is off. Showing saved Classroom data. $syncStatusText'
                        : isOfflineMode
                        ? 'Showing last saved Classroom data. $syncStatusText'
                        : 'Google Classroom data is updated. Last sync: $syncStatusText',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.2,
                      height: 1.3,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.68),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.refresh_rounded,
              color: statusColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
  Widget quickActions(bool isLightMode) {
    return SizedBox(
      height: 128,
      child: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          QuickActionCard(
            title: 'Profile',
            subtitle: 'Student info',
            icon: Icons.person_rounded,
            color: const Color(0xFF42A5F5),
            isLightMode: isLightMode,
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => const ProfileScreen(),
                ),
              );
            },
          ),
          QuickActionCard(
            title: 'Reminders',
            subtitle: 'Alerts',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFFFA726),
            isLightMode: isLightMode,
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) =>
                  const NotificationsScreen(),
                ),
              );
            },
          ),
          QuickActionCard(
            title: 'Settings',
            subtitle: 'App control',
            icon: Icons.settings_rounded,
            color: const Color(0xFF7E57C2),
            isLightMode: isLightMode,
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => const SettingsScreen(),
                ),
              );
            },
          ),
          QuickActionCard(
            title: 'Google',
            subtitle: 'Account',
            icon: Icons.cloud_sync_rounded,
            color: const Color(0xFF2633C5),
            isLightMode: isLightMode,
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) =>
                  const GoogleAccountScreen(),
                ),
              ).then((_) => loadDashboardData());
            },
          ),
          QuickActionCard(
            title: 'Tasks',
            subtitle: 'Assignments',
            icon: Icons.assignment_rounded,
            color: const Color(0xFFEF5350),
            isLightMode: isLightMode,
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) =>
                  const TasksScreen(initialFilter: 'All'),
                ),
              );
            },
          ),
          QuickActionCard(
            title: 'Courses',
            subtitle: 'Subjects',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF66BB6A),
            isLightMode: isLightMode,
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => const CoursesScreen(),
                ),
              );
            },
          ),
          QuickActionCard(
            title: 'Deadlines',
            subtitle: 'Timeline',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF7E57C2),
            isLightMode: isLightMode,
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => const DeadlinesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget dashboardGrid() {
    final List<DashboardMetric> items = dashboardItems;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: multiple ? 2 : 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: multiple ? 1.46 : 3.35,
        ),
        itemBuilder: (BuildContext context, int index) {
          return DashboardMetricCard(
            item: items[index],
            onTap: () => openMetric(items[index].title),
          );
        },
      ),
    );
  }

  void openMetric(String title) {
    if (title == 'Courses') {
      Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => const CoursesScreen(),
        ),
      );
      return;
    }

    if (title == 'Upcoming') {
      Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => const DeadlinesScreen(),
        ),
      );
      return;
    }

    if (title == 'Workload') {
      Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => WorkloadScreen(),
        ),
      );
      return;
    }

    Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => TasksScreen(
          initialFilter: taskFilterForMetric(title),
        ),
      ),
    );
  }

  String taskFilterForMetric(String title) {
    if (title == 'Due Today') {
      return 'Due Today';
    }

    if (title == 'No Due Date') {
      return 'No Due Date';
    }

    return 'All';
  }

  Widget taskList(bool isLightMode) {
    if (upcomingTasks.isEmpty) {
      return emptyMiniCard(
        isLightMode: isLightMode,
        icon: Icons.assignment_turned_in_rounded,
        title: 'No upcoming tasks',
        subtitle: 'Your filtered Classroom tasks are clear for now.',
      );
    }

    return Column(
      children: List<Widget>.generate(
        upcomingTasks.length,
            (int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
            child: TaskCard(
              task: upcomingTasks[index],
              isLightMode: isLightMode,
              onTap: () {
                final DashboardTask task = upcomingTasks[index];

                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => TaskDetailScreen(
                      title: task.title,
                      course: task.course,
                      deadline: task.deadline,
                      status: task.status,
                      priority: task.priority,
                      description: task.description,
                      color: task.color,
                      icon: Icons.assignment_rounded,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget courseList(bool isLightMode) {
    if (courseProgressList.isEmpty) {
      return emptyMiniCard(
        isLightMode: isLightMode,
        icon: Icons.menu_book_rounded,
        title: 'No courses found',
        subtitle: 'Login with Google and sync Classroom data.',
      );
    }

    return Column(
      children: List<Widget>.generate(
        courseProgressList.length,
            (int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
            child: CourseProgressCard(
              course: courseProgressList[index],
              isLightMode: isLightMode,
            ),
          );
        },
      ),
    );
  }

  Widget googleClassroomCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 2, bottom: 12),
      child: InkWell(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14.0),
          bottomLeft: Radius.circular(14.0),
          bottomRight: Radius.circular(14.0),
          topRight: Radius.circular(56.0),
        ),
        onTap: () {
          Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => const GoogleAccountScreen(),
            ),
          ).then((_) => loadDashboardData());
        },
        child: Container(
          decoration: BoxDecoration(
            color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14.0),
              bottomLeft: Radius.circular(14.0),
              bottomRight: Radius.circular(14.0),
              topRight: Radius.circular(56.0),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isLightMode
                    ? AppTheme.grey.withOpacity(0.16)
                    : Colors.black.withOpacity(0.22),
                offset: const Offset(1.1, 1.1),
                blurRadius: 10.0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: (errorText.isEmpty
                        ? const Color(0xFF42A5F5)
                        : const Color(0xFFEF5350))
                        .withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    errorText.isEmpty
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: errorText.isEmpty
                        ? const Color(0xFF42A5F5)
                        : const Color(0xFFEF5350),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isOfflineMode
                            ? 'Offline Cache Active'
                            : errorText.isEmpty
                            ? 'Google Classroom Synced'
                            : 'Google Classroom Needs Login',
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color:
                          isLightMode ? AppTheme.darkText : AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isOfflineMode
                            ? 'Internet is not available. The app is showing your last saved courses, tasks and deadlines.'
                            : errorText.isEmpty
                            ? 'Real courses, assignments and deadlines are loaded from your Google Classroom account.'
                            : 'Tap here to open Google screen and reconnect your account.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.35,
                          color: isLightMode
                              ? AppTheme.grey
                              : AppTheme.white.withOpacity(0.70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget loadingCard(bool isLightMode) {
    return emptyMiniCard(
      isLightMode: isLightMode,
      icon: Icons.cloud_sync_rounded,
      title: 'Loading real dashboard...',
      subtitle: 'Fetching Google Classroom courses and assignments.',
    );
  }

  Widget errorCard(bool isLightMode) {
    return emptyMiniCard(
      isLightMode: isLightMode,
      icon: Icons.error_outline_rounded,
      title: 'Dashboard sync failed',
      subtitle: errorText,
    );
  }

  Widget emptyMiniCard({
    required bool isLightMode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.15)
                  : Colors.black.withOpacity(0.20),
              offset: const Offset(1.1, 1.1),
              blurRadius: 8.0,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: const Color(0xFF42A5F5),
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.68),
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
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final DashboardMetric item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                item.startColor,
                item.endColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: item.endColor.withOpacity(0.28),
                offset: const Offset(1.1, 4.0),
                blurRadius: 8.0,
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: -18,
                bottom: -18,
                child: Icon(
                  item.icon,
                  size: 92,
                  color: Colors.white.withOpacity(0.16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      item.icon,
                      color: Colors.white,
                      size: 27,
                    ),
                    const Spacer(),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isLightMode,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLightMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: isLightMode
                      ? AppTheme.grey.withOpacity(0.14)
                      : Colors.black.withOpacity(0.22),
                  offset: const Offset(1, 3),
                  blurRadius: 9,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isLightMode ? AppTheme.darkText : AppTheme.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 11,
                    color: isLightMode
                        ? AppTheme.grey
                        : AppTheme.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.isLightMode,
    required this.onTap,
  });

  final DashboardTask task;
  final bool isLightMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.15)
                  : Colors.black.withOpacity(0.20),
              offset: const Offset(1.1, 1.1),
              blurRadius: 8.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: task.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.assignment_rounded,
                  color: task.color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isLightMode ? AppTheme.darkText : AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.course,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: isLightMode
                            ? AppTheme.grey
                            : AppTheme.white.withOpacity(0.68),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.deadline,
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 12,
                        color: task.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: task.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task.status,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 11,
                    color: task.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseProgressCard extends StatelessWidget {
  const CourseProgressCard({
    super.key,
    required this.course,
    required this.isLightMode,
  });

  final CourseProgress course;
  final bool isLightMode;

  @override
  Widget build(BuildContext context) {
    final int percentage = (course.progress * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isLightMode
                ? AppTheme.grey.withOpacity(0.15)
                : Colors.black.withOpacity(0.20),
            offset: const Offset(1.1, 1.1),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: course.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                course.icon,
                color: course.color,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          course.course,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontName,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color:
                            isLightMode ? AppTheme.darkText : AppTheme.white,
                          ),
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: course.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    course.pending,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.68),
                    ),
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 7,
                      backgroundColor: course.color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(course.color),
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
}

class DashboardMetric {
  const DashboardMetric({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
}

class DashboardTask {
  const DashboardTask({
    required this.title,
    required this.course,
    required this.deadline,
    required this.status,
    required this.priority,
    required this.description,
    required this.color,
  });

  factory DashboardTask.fromRealTask(RealClassroomTask task, int index) {
    final Color color = colorForDeadline(task.dueDateTime, index);

    return DashboardTask(
      title: task.title,
      course: task.courseName,
      deadline: formatDeadline(task.dueDateTime),
      status: statusForDeadline(task.dueDateTime),
      priority: priorityForDeadline(task.dueDateTime),
      description: task.description.isEmpty
          ? 'This assignment was loaded from Google Classroom API.'
          : task.description,
      color: color,
    );
  }

  static String formatDeadline(DateTime? dateTime) {
    if (dateTime == null) {
      return 'No due date';
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = today.add(const Duration(days: 1));
    final DateTime dueDay = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (dueDay == today) {
      return 'Today, ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
    }

    if (dueDay == tomorrow) {
      return 'Tomorrow, ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  static String statusForDeadline(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Open';
    }

    final DateTime now = DateTime.now();

    if (dateTime.isBefore(now)) {
      return 'Late';
    }

    return 'Pending';
  }

  static String priorityForDeadline(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Low';
    }

    final int days = dateTime.difference(DateTime.now()).inDays;

    if (days <= 1) {
      return 'High';
    }

    if (days <= 5) {
      return 'Medium';
    }

    return 'Low';
  }

  static Color colorForDeadline(DateTime? dateTime, int index) {
    if (dateTime == null) {
      return const Color(0xFF738AE6);
    }

    final int days = dateTime.difference(DateTime.now()).inDays;

    if (days < 0) {
      return const Color(0xFFEF5350);
    }

    if (days <= 1) {
      return const Color(0xFFFFA726);
    }

    final List<Color> colors = <Color>[
      Color(0xFF42A5F5),
      Color(0xFF66BB6A),
      Color(0xFF738AE6),
    ];

    return colors[index % colors.length];
  }

  static String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  final String title;
  final String course;
  final String deadline;
  final String status;
  final String priority;
  final String description;
  final Color color;
}

class CourseProgress {
  const CourseProgress({
    required this.course,
    required this.pending,
    required this.progress,
    required this.color,
    required this.icon,
  });

  factory CourseProgress.fromRealCourse(
      RealClassroomCourse course,
      int index,
      int pendingCount,
      ) {
    final Color color = _colors[index % _colors.length];
    final IconData icon = _icons[index % _icons.length];

    double progress = 0.92;

    if (pendingCount >= 6) {
      progress = 0.42;
    } else if (pendingCount >= 3) {
      progress = 0.62;
    } else if (pendingCount >= 1) {
      progress = 0.76;
    }

    return CourseProgress(
      course: course.name,
      pending: pendingCount == 0 ? 'No pending tasks' : '$pendingCount pending',
      progress: progress,
      color: color,
      icon: icon,
    );
  }

  static const List<Color> _colors = <Color>[
    Color(0xFF738AE6),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
    Color(0xFF42A5F5),
    Color(0xFFEF5350),
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.psychology_rounded,
    Icons.storage_rounded,
    Icons.phone_android_rounded,
    Icons.menu_book_rounded,
    Icons.school_rounded,
  ];

  final String course;
  final String pending;
  final double progress;
  final Color color;
  final IconData icon;
}