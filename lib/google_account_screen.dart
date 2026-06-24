import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/courses_screen.dart';
import 'package:best_flutter_ui_templates/deadlines_screen.dart';
import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:best_flutter_ui_templates/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAccountScreen extends StatefulWidget {
  const GoogleAccountScreen({super.key});

  @override
  State<GoogleAccountScreen> createState() => _GoogleAccountScreenState();
}

class _GoogleAccountScreenState extends State<GoogleAccountScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  final ScrollController scrollController = ScrollController();

  bool isLoading = true;
  bool isSyncing = false;
  bool autoSync = true;

  String errorText = '';
  String lastSyncedText = 'Not synced yet';

  GoogleSignInAccount? account;

  List<RealClassroomCourse> courses = <RealClassroomCourse>[];
  List<RealClassroomTask> tasks = <RealClassroomTask>[];

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    animationController.forward();
    loadAccount();
  }

  bool get isConnected => account != null;

  int get totalCourses => courses.length;

  int get totalTasks => tasks.length;

  int get todayTasks {
    return tasks.where((RealClassroomTask task) {
      return dateCategory(task.dueDateTime) == 'Today';
    }).length;
  }

  int get upcomingTasks {
    return tasks.where((RealClassroomTask task) {
      final String category = dateCategory(task.dueDateTime);
      return category == 'This Week' || category == 'Upcoming';
    }).length;
  }

  int get lateTasks {
    return tasks.where((RealClassroomTask task) {
      return dateCategory(task.dueDateTime) == 'Late';
    }).length;
  }

  Future<void> loadAccount() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      final GoogleSignInAccount? user =
      await GoogleLoginService.instance.signInSilently();

      if (!mounted) {
        return;
      }

      setState(() {
        account = user;
        isLoading = false;
      });

      if (user != null && autoSync) {
        await syncClassroomData();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorText = error.toString();
      });
    }
  }

  Future<void> loginGoogle() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      final GoogleSignInAccount? user = await GoogleLoginService.instance.signIn();

      if (!mounted) {
        return;
      }

      if (user == null) {
        setState(() {
          isLoading = false;
        });
        showMessage('Google login cancelled.');
        return;
      }

      setState(() {
        account = user;
        isLoading = false;
      });

      showMessage('Google Classroom account connected.');
      await syncClassroomData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorText = error.toString();
      });
    }
  }

  Future<void> logoutGoogle() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    ClassroomDataService.instance.clearCache();
    await GoogleLoginService.instance.signOut();

    if (!mounted) {
      return;
    }

    setState(() {
      account = null;
      courses.clear();
      tasks.clear();
      lastSyncedText = 'Not synced yet';
      isLoading = false;
    });

    showMessage('Google account disconnected.');
  }

  Future<void> syncClassroomData() async {
    if (!isConnected) {
      setState(() {
        errorText = 'Please connect your Google account first.';
      });
      return;
    }

    setState(() {
      isSyncing = true;
      errorText = '';
    });

    try {
      final List<RealClassroomCourse> fetchedCourses =
      await ClassroomDataService.instance.getCourses();

      final List<RealClassroomTask> fetchedTasks =
      await ClassroomDataService.instance.getAllCourseWork();

      if (!mounted) {
        return;
      }

      setState(() {
        courses = fetchedCourses;
        tasks = fetchedTasks;
        lastSyncedText = currentTimeText();
        isSyncing = false;
      });

      showMessage('Classroom data synced successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSyncing = false;
        errorText = error.toString();
      });
    }
  }

  String currentTimeText() {
    final DateTime now = DateTime.now();
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');

    return 'Today at $hour:$minute';
  }

  String dateCategory(DateTime? dateTime) {
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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLightMode ? Colors.white : AppTheme.nearlyBlack,
      body: SafeArea(
        child: FadeTransition(
          opacity: animationController,
          child: ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 28),
            children: <Widget>[
              buildTopBar(isLightMode),
              const SizedBox(height: 18),
              buildTitle(isLightMode),
              const SizedBox(height: 24),
              buildAccountSection(isLightMode),
              buildDivider(isLightMode),
              buildSyncSection(isLightMode),
              buildDivider(isLightMode),
              buildSummarySection(isLightMode),
              buildDivider(isLightMode),
              buildNavigationSection(isLightMode),
              if (errorText.isNotEmpty) buildErrorBox(isLightMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTopBar(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 18, top: 8),
      child: Row(
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isLightMode ? const Color(0xFF4A4A4A) : Colors.white,
                size: 25,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: isSyncing ? null : syncClassroomData,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: isSyncing
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
                  : Icon(
                Icons.sync_rounded,
                color: isLightMode
                    ? const Color(0xFF4A4A4A)
                    : Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTitle(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Google Classroom Sync',
        style: TextStyle(
          fontFamily: AppTheme.fontName,
          fontSize: 25,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: isLightMode ? const Color(0xFF4A4A4A) : Colors.white,
        ),
      ),
    );
  }

  Widget buildAccountSection(bool isLightMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionHeader(
          title: 'CONNECTED ACCOUNT',
          icon: Icons.account_circle_outlined,
          isLightMode: isLightMode,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 12),
          child: Row(
            children: <Widget>[
              accountAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isLoading
                          ? 'Checking account...'
                          : account?.displayName ?? 'No account connected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color:
                        isLightMode ? const Color(0xFF3F3F46) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account?.email ?? 'Connect account to sync Classroom data.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 12.5,
                        height: 1.25,
                        color: isConnected
                            ? const Color(0xFF2ECC71)
                            : isLightMode
                            ? const Color(0xFF81818A)
                            : Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isConnected
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: isConnected
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFFFA726),
                size: 25,
              ),
            ],
          ),
        ),
        settingArrowTile(
          title: isConnected ? 'Reconnect Google Account' : 'Connect Google Account',
          subtitle: isConnected
              ? 'Refresh permissions and account connection.'
              : 'Login with your student Google account.',
          isLightMode: isLightMode,
          onTap: loginGoogle,
        ),
        settingArrowTile(
          title: 'Disconnect Account',
          subtitle: 'Logout and clear synced Classroom data from this session.',
          isLightMode: isLightMode,
          textColor: const Color(0xFFEF5350),
          onTap: isConnected ? logoutGoogle : null,
        ),
      ],
    );
  }

  Widget accountAvatar() {
    if (account?.photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          account!.photoUrl!,
          height: 48,
          width: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => defaultAvatar(),
        ),
      );
    }

    return defaultAvatar();
  }

  Widget defaultAvatar() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: isConnected
            ? const Color(0xFF2ECC71).withOpacity(0.13)
            : const Color(0xFFFFA726).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isConnected ? Icons.verified_user_rounded : Icons.person_outline_rounded,
        color: isConnected ? const Color(0xFF2ECC71) : const Color(0xFFFFA726),
        size: 27,
      ),
    );
  }

  Widget buildSyncSection(bool isLightMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionHeader(
          title: 'SYNC SETTINGS',
          icon: Icons.cloud_sync_outlined,
          isLightMode: isLightMode,
        ),
        settingSwitchTile(
          title: 'Auto Sync',
          subtitle: 'Automatically fetch courses and assignments when opened.',
          value: autoSync,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              autoSync = value;
            });
          },
        ),
        settingArrowTile(
          title: 'Sync Classroom Data',
          subtitle: isSyncing
              ? 'Syncing courses, tasks and deadlines...'
              : 'Last synced: $lastSyncedText',
          isLightMode: isLightMode,
          onTap: isSyncing ? null : syncClassroomData,
        ),
      ],
    );
  }

  Widget buildSummarySection(bool isLightMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionHeader(
          title: 'SYNC SUMMARY',
          icon: Icons.insights_outlined,
          isLightMode: isLightMode,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 18),
          child: Row(
            children: <Widget>[
              summaryBox(
                title: 'Courses',
                value: totalCourses.toString(),
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF42A5F5),
                isLightMode: isLightMode,
              ),
              const SizedBox(width: 10),
              summaryBox(
                title: 'Tasks',
                value: totalTasks.toString(),
                icon: Icons.assignment_rounded,
                color: const Color(0xFFFFA726),
                isLightMode: isLightMode,
              ),
              const SizedBox(width: 10),
              summaryBox(
                title: 'Today',
                value: todayTasks.toString(),
                icon: Icons.today_rounded,
                color: const Color(0xFFEF5350),
                isLightMode: isLightMode,
              ),
            ],
          ),
        ),
        settingInfoTile(
          title: 'Upcoming Deadlines',
          subtitle: '$upcomingTasks upcoming • $lateTasks late tasks',
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF7E57C2),
          isLightMode: isLightMode,
        ),
      ],
    );
  }

  Widget summaryBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLightMode,
  }) {
    return Expanded(
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLightMode ? const Color(0xFFF7F7FA) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 23),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 11,
                color: isLightMode
                    ? const Color(0xFF81818A)
                    : Colors.white.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNavigationSection(bool isLightMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionHeader(
          title: 'OPEN CLASSROOM DATA',
          icon: Icons.open_in_new_rounded,
          isLightMode: isLightMode,
        ),
        settingArrowTile(
          title: 'View Courses',
          subtitle: 'Open real Google Classroom courses.',
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
        settingArrowTile(
          title: 'View Assignments',
          subtitle: 'Open real coursework and tasks.',
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
        settingArrowTile(
          title: 'View Deadlines',
          subtitle: 'Open upcoming due dates and reminder timeline.',
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
    );
  }

  Widget sectionHeader({
    required String title,
    required IconData icon,
    required bool isLightMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 12),
      child: Row(
        children: <Widget>[
          SizedBox(
            height: 25,
            width: 30,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: 0,
                  top: 4,
                  child: Icon(
                    icon,
                    size: 20,
                    color: isLightMode
                        ? const Color(0xFF4A4A4A)
                        : Colors.white.withOpacity(0.85),
                  ),
                ),
                Positioned(
                  right: 3,
                  top: 0,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: isConnected
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFFA726),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isLightMode
                  ? const Color(0xFF4A4A4A)
                  : Colors.white.withOpacity(0.86),
            ),
          ),
        ],
      ),
    );
  }

  Widget settingSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool isLightMode,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: settingText(
              title: title,
              subtitle: subtitle,
              isLightMode: isLightMode,
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.86,
            child: Switch(
              value: value,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF2ECC71),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: isLightMode
                  ? const Color(0xFFD5D5D5)
                  : Colors.white.withOpacity(0.22),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget settingArrowTile({
    required String title,
    required String subtitle,
    required bool isLightMode,
    required VoidCallback? onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: settingText(
                title: title,
                subtitle: subtitle,
                isLightMode: isLightMode,
                titleColor: textColor,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isLightMode
                    ? const Color(0xFF4A4A4A)
                    : Colors.white.withOpacity(0.75),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget settingInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLightMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 22),
      child: Row(
        children: <Widget>[
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: settingText(
              title: title,
              subtitle: subtitle,
              isLightMode: isLightMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget settingText({
    required String title,
    required String subtitle,
    required bool isLightMode,
    Color? titleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            color: titleColor ??
                (isLightMode ? const Color(0xFF4A4A4A) : Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 12.5,
            height: 1.25,
            fontWeight: FontWeight.w500,
            color: isLightMode
                ? const Color(0xFF7A7A82)
                : Colors.white.withOpacity(0.62),
          ),
        ),
      ],
    );
  }

  Widget buildDivider(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 22),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isLightMode
            ? const Color(0xFFE1E1E1)
            : Colors.white.withOpacity(0.10),
      ),
    );
  }

  Widget buildErrorBox(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350).withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF5350).withOpacity(0.30),
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF5350),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorText,
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 12.5,
                  height: 1.35,
                  color: isLightMode
                      ? const Color(0xFFEF5350)
                      : Colors.red.shade200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}