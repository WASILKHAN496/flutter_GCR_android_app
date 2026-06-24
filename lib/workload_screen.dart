import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/deadlines_screen.dart';
import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:best_flutter_ui_templates/tasks_screen.dart';
import 'package:flutter/material.dart';

class WorkloadScreen extends StatefulWidget {
  const WorkloadScreen({super.key});

  @override
  State<WorkloadScreen> createState() => _WorkloadScreenState();
}

class _WorkloadScreenState extends State<WorkloadScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  final ScrollController scrollController = ScrollController();

  double topBarOpacity = 0.0;
  bool isLoading = true;
  String errorText = '';

  List<RealClassroomTask> tasks = <RealClassroomTask>[];

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    scrollController.addListener(updateTopBarOpacity);
    animationController.forward();

    loadWorkload();
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

  Future<void> loadWorkload() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      await GoogleLoginService.instance.signInSilently();

      final List<RealClassroomTask> fetchedTasks =
      await ClassroomDataService.instance.getAllCourseWork();

      if (!mounted) {
        return;
      }

      setState(() {
        tasks = fetchedTasks;
        isLoading = false;
      });
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

  int get totalTasks => tasks.length;

  int get todayTasks {
    return tasks.where((RealClassroomTask task) {
      return categoryForDate(task.dueDateTime) == 'Today';
    }).length;
  }

  int get weekTasks {
    return tasks.where((RealClassroomTask task) {
      return categoryForDate(task.dueDateTime) == 'This Week';
    }).length;
  }

  int get lateTasks {
    return tasks.where((RealClassroomTask task) {
      return categoryForDate(task.dueDateTime) == 'Late';
    }).length;
  }

  int get noDueTasks {
    return tasks.where((RealClassroomTask task) {
      return task.dueDateTime == null;
    }).length;
  }

  String get workloadLevel {
    if (totalTasks >= 10 || todayTasks >= 4 || lateTasks >= 3) {
      return 'High';
    }

    if (totalTasks >= 5 || todayTasks >= 2 || weekTasks >= 3) {
      return 'Medium';
    }

    if (totalTasks >= 1) {
      return 'Low';
    }

    return 'Clear';
  }

  Color get workloadColor {
    if (workloadLevel == 'High') {
      return const Color(0xFFEF5350);
    }

    if (workloadLevel == 'Medium') {
      return const Color(0xFFFFA726);
    }

    if (workloadLevel == 'Low') {
      return const Color(0xFF42A5F5);
    }

    return const Color(0xFF66BB6A);
  }

  double get workloadProgress {
    if (workloadLevel == 'High') {
      return 0.90;
    }

    if (workloadLevel == 'Medium') {
      return 0.62;
    }

    if (workloadLevel == 'Low') {
      return 0.35;
    }

    return 0.12;
  }

  List<CourseLoad> get courseLoads {
    final Map<String, int> counts = <String, int>{};

    for (final RealClassroomTask task in tasks) {
      counts[task.courseName] = (counts[task.courseName] ?? 0) + 1;
    }

    final List<MapEntry<String, int>> sorted = counts.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        return b.value.compareTo(a.value);
      });

    return sorted.asMap().entries.map((MapEntry<int, MapEntry<String, int>> e) {
      return CourseLoad(
        course: e.value.key,
        count: e.value.value,
        color: courseColor(e.key),
      );
    }).toList();
  }

  String categoryForDate(DateTime? dateTime) {
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

  Color courseColor(int index) {
    const List<Color> colors = <Color>[
      Color(0xFF42A5F5),
      Color(0xFF738AE6),
      Color(0xFF66BB6A),
      Color(0xFFFFA726),
      Color(0xFFEF5350),
    ];

    return colors[index % colors.length];
  }

  @override
  void dispose() {
    animationController.dispose();
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
            buildBody(isLightMode),
            buildAppBar(isLightMode),
          ],
        ),
      ),
    );
  }

  Widget buildBody(bool isLightMode) {
    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: AppBar().preferredSize.height +
            MediaQuery.of(context).padding.top +
            28,
        bottom: 32 + MediaQuery.of(context).padding.bottom,
      ),
      children: <Widget>[
        animatedWidget(0, buildHeaderCard(isLightMode)),
        if (isLoading) animatedWidget(1, loadingCard(isLightMode)),
        if (!isLoading && errorText.isNotEmpty)
          animatedWidget(1, errorCard(isLightMode)),
        if (!isLoading && errorText.isEmpty) ...<Widget>[
          animatedWidget(1, buildWorkloadLevelCard(isLightMode)),
          animatedWidget(
            2,
            buildSectionTitle(
              title: 'Workload Summary',
              subtitle: '$totalTasks active',
              isLightMode: isLightMode,
            ),
          ),
          animatedWidget(3, buildSummaryGrid(isLightMode)),
          animatedWidget(
            4,
            buildSectionTitle(
              title: 'Course Load',
              subtitle: '${courseLoads.length} courses',
              isLightMode: isLightMode,
            ),
          ),
          animatedWidget(5, buildCourseLoadList(isLightMode)),
          animatedWidget(6, buildActionButtons(isLightMode)),
        ],
      ],
    );
  }

  Widget animatedWidget(int index, Widget child) {
    final Animation<double> animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          index * 0.10,
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
              30 * (1.0 - animation.value),
              0.0,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget buildAppBar(bool isLightMode) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: (isLightMode ? Colors.white : AppTheme.nearlyBlack)
                .withOpacity(topBarOpacity),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isLightMode
                    ? AppTheme.grey.withOpacity(0.35 * topBarOpacity)
                    : Colors.black.withOpacity(0.40 * topBarOpacity),
                blurRadius: 10,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).padding.top),
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16 - 8 * topBarOpacity,
                  bottom: 12 - 8 * topBarOpacity,
                ),
                child: Row(
                  children: <Widget>[
                    circleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isLightMode: isLightMode,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Workload',
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontSize: 28 - 6 * topBarOpacity,
                          fontWeight: FontWeight.w800,
                          color:
                          isLightMode ? AppTheme.darkText : AppTheme.white,
                        ),
                      ),
                    ),
                    circleButton(
                      icon: Icons.refresh_rounded,
                      isLightMode: isLightMode,
                      onTap: loadWorkload,
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

  Widget circleButton({
    required IconData icon,
    required bool isLightMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          boxShadow: cardShadow(isLightMode),
        ),
        child: Icon(
          icon,
          color: isLightMode ? const Color(0xFF2633C5) : Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget buildHeaderCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
            topRight: Radius.circular(76),
          ),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Analyze your',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 13,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Classroom Workload',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Real workload is calculated from Google Classroom assignments and due dates.',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.5,
                      height: 1.35,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            workloadIconBox(),
          ],
        ),
      ),
    );
  }

  Widget workloadIconBox() {
    const Color color = Color(0xFF26C6DA);

    return Container(
      height: 86,
      width: 86,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                color,
                color.withOpacity(0.65),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget buildWorkloadLevelCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              workloadColor,
              workloadColor.withOpacity(0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
            topRight: Radius.circular(72),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: workloadColor.withOpacity(0.30),
              offset: const Offset(4, 8),
              blurRadius: 16,
            ),
          ],
        ),
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
                Icons.speed_rounded,
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
                    '$workloadLevel Workload',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: workloadProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalTasks active tasks • $todayTasks due today • $weekTasks this week',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.92),
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

  Widget buildSectionTitle({
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
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isLightMode ? AppTheme.darkText : AppTheme.white,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isLightMode
                  ? AppTheme.grey
                  : AppTheme.white.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryGrid(bool isLightMode) {
    final List<WorkloadMetric> items = <WorkloadMetric>[
      WorkloadMetric(
        title: 'Total',
        value: totalTasks.toString(),
        icon: Icons.assignment_rounded,
        color: const Color(0xFF42A5F5),
      ),
      WorkloadMetric(
        title: 'Today',
        value: todayTasks.toString(),
        icon: Icons.today_rounded,
        color: const Color(0xFFEF5350),
      ),
      WorkloadMetric(
        title: 'Week',
        value: weekTasks.toString(),
        icon: Icons.date_range_rounded,
        color: const Color(0xFFFFA726),
      ),
      WorkloadMetric(
        title: 'Late',
        value: lateTasks.toString(),
        icon: Icons.warning_rounded,
        color: const Color(0xFFEF5350),
      ),
      WorkloadMetric(
        title: 'No Due',
        value: noDueTasks.toString(),
        icon: Icons.event_busy_rounded,
        color: const Color(0xFF738AE6),
      ),
      WorkloadMetric(
        title: 'Level',
        value: workloadLevel,
        icon: Icons.insights_rounded,
        color: workloadColor,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.46,
        ),
        itemBuilder: (BuildContext context, int index) {
          return WorkloadMetricCard(item: items[index]);
        },
      ),
    );
  }

  Widget buildCourseLoadList(bool isLightMode) {
    if (courseLoads.isEmpty) {
      return messageCard(
        isLightMode: isLightMode,
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFFFA726),
        title: 'No course load found',
        subtitle: 'There are no active assignments to analyze right now.',
        isLoading: false,
      );
    }

    final int maxCount = courseLoads
        .map((CourseLoad item) => item.count)
        .reduce((int a, int b) => a > b ? a : b);

    return Column(
      children: courseLoads.map((CourseLoad item) {
        final double value = maxCount == 0 ? 0 : item.count / maxCount;

        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
          child: CourseLoadCard(
            item: item,
            value: value,
            isLightMode: isLightMode,
          ),
        );
      }).toList(),
    );
  }

  Widget buildActionButtons(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: actionButton(
              title: 'Open Tasks',
              color1: const Color(0xFFFFA726),
              color2: const Color(0xFFFF7043),
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: actionButton(
              title: 'Deadlines',
              color1: const Color(0xFF42A5F5),
              color2: const Color(0xFF2633C5),
              onTap: () {
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) =>
                    const DeadlinesScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton({
    required String title,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: <Color>[color1, color2]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.fontName,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget loadingCard(bool isLightMode) {
    return messageCard(
      isLightMode: isLightMode,
      icon: Icons.cloud_sync_rounded,
      color: const Color(0xFF42A5F5),
      title: 'Loading workload...',
      subtitle: 'Fetching assignments from Google Classroom API.',
      isLoading: true,
    );
  }

  Widget errorCard(bool isLightMode) {
    return messageCard(
      isLightMode: isLightMode,
      icon: Icons.error_outline_rounded,
      color: const Color(0xFFEF5350),
      title: 'Unable to load workload',
      subtitle: errorText,
      isLoading: false,
    );
  }

  Widget messageCard({
    required bool isLightMode,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isLoading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Row(
          children: <Widget>[
            isLoading
                ? const SizedBox(
              height: 34,
              width: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
                : Icon(icon, color: color, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12,
                      height: 1.35,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.65),
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

  List<BoxShadow> cardShadow(bool isLightMode) {
    return <BoxShadow>[
      BoxShadow(
        color: isLightMode
            ? AppTheme.grey.withOpacity(0.15)
            : Colors.black.withOpacity(0.22),
        offset: const Offset(1, 3),
        blurRadius: 10,
      ),
    ];
  }
}

class WorkloadMetricCard extends StatelessWidget {
  const WorkloadMetricCard({
    super.key,
    required this.item,
  });

  final WorkloadMetric item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            item.color,
            item.color.withOpacity(0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: item.color.withOpacity(0.28),
            offset: const Offset(1.1, 4),
            blurRadius: 8,
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
                Icon(item.icon, color: Colors.white, size: 27),
                const Spacer(),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.90),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CourseLoadCard extends StatelessWidget {
  const CourseLoadCard({
    super.key,
    required this.item,
    required this.value,
    required this.isLightMode,
  });

  final CourseLoad item;
  final double value;
  final bool isLightMode;

  @override
  Widget build(BuildContext context) {
    final double safeValue = value.clamp(0.0, 1.0);

    return Container(
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
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: item.color,
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
                        item.course,
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
                      '${item.count} tasks',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: safeValue,
                    minHeight: 7,
                    backgroundColor: item.color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkloadMetric {
  const WorkloadMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class CourseLoad {
  const CourseLoad({
    required this.course,
    required this.count,
    required this.color,
  });

  final String course;
  final int count;
  final Color color;
}