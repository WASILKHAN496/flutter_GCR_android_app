import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:best_flutter_ui_templates/task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:best_flutter_ui_templates/widgets/app_state_widgets.dart';
class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    this.initialFilter = 'All',
  });

  final String initialFilter;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  double topBarOpacity = 0.0;
  bool isLoading = true;

  String selectedFilter = 'All';
  String errorText = '';

  List<RealClassroomTask> realTasks = <RealClassroomTask>[];

  final List<String> filters = const <String>[
    'All',
    'Submitted',
    'Pending',
    'Late',
    'Due Today',
    'No Due Date',
  ];

  @override
  void initState() {
    super.initState();

    selectedFilter = widget.initialFilter;

    if (!filters.contains(selectedFilter)) {
      selectedFilter = 'All';
    }

    animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    scrollController.addListener(updateTopBarOpacity);
    animationController.forward();

    loadTasks();
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

  Future<void> loadTasks({bool forceRefresh = false}) async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      await GoogleLoginService.instance.signInSilently();

      final List<RealClassroomTask> fetchedTasks =
      await ClassroomDataService.instance.getAllCourseWork(
        forceRefresh: forceRefresh,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        realTasks = fetchedTasks;
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

  List<TaskViewData> get tasks {
    return realTasks.asMap().entries.map(
          (MapEntry<int, RealClassroomTask> item) {
        return TaskViewData.fromRealTask(item.value, item.key);
      },
    ).toList();
  }

  List<TaskViewData> get visibleTasks {
    final String query = searchController.text.toLowerCase().trim();

    return tasks.where((TaskViewData task) {
      bool filterOk = false;

      if (selectedFilter == 'All') {
        filterOk = true;
      } else if (selectedFilter == 'Late') {
        filterOk = task.status == 'Late Not Submitted';
      } else {
        filterOk = task.status == selectedFilter ||
            task.dueCategory == selectedFilter;
      }

      final bool searchOk = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.course.toLowerCase().contains(query) ||
          task.workType.toLowerCase().contains(query) ||
          task.status.toLowerCase().contains(query);

      return filterOk && searchOk;
    }).toList();
  }

  int get submittedCount {
    return tasks.where((TaskViewData task) => task.status == 'Submitted').length;
  }

  int get pendingCount {
    return tasks.where((TaskViewData task) => task.status == 'Pending').length;
  }

  int get lateCount {
    return tasks
        .where((TaskViewData task) => task.status == 'Late Not Submitted')
        .length;
  }

  int get dueTodayCount {
    return tasks
        .where((TaskViewData task) => task.dueCategory == 'Due Today')
        .length;
  }

  int get noDueDateCount {
    return tasks
        .where((TaskViewData task) => task.dueCategory == 'No Due Date')
        .length;
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.removeListener(updateTopBarOpacity);
    scrollController.dispose();
    searchController.dispose();
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
    return RefreshIndicator(
      color: const Color(0xFF2633C5),
      backgroundColor: isLightMode ? Colors.white : AppTheme.nearlyBlack,
      onRefresh: () async {
        await loadTasks(forceRefresh: true);
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
          animatedWidget(0, buildHeaderCard(isLightMode)),
          animatedWidget(1, buildSearchBox(isLightMode)),
          animatedWidget(2, buildFilterSection(isLightMode)),
          animatedWidget(3, buildSummaryRow(isLightMode)),
          animatedWidget(
            4,
            buildSectionTitle(
              title: 'Classroom Tasks',
              subtitle:
              isLoading ? 'Loading' : '${visibleTasks.length} found',
              isLightMode: isLightMode,
            ),
          ),
          if (isLoading) animatedWidget(5, loadingCard(isLightMode)),
          if (!isLoading && errorText.isNotEmpty)
            animatedWidget(5, errorCard(isLightMode)),
          if (!isLoading && errorText.isEmpty && visibleTasks.isEmpty)
            animatedWidget(5, emptyCard(isLightMode)),
          if (!isLoading && errorText.isEmpty && visibleTasks.isNotEmpty)
            animatedWidget(5, buildTaskList(isLightMode)),
          animatedWidget(6, buildInfoCard(isLightMode)),
        ],
      ),
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
          index * 0.09,
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
                        'Tasks',
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
                      onTap: () => loadTasks(forceRefresh: true),
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
                    'Track your',
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
                    'Classroom Tasks',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Submitted, pending and late assignments are loaded from your Google Classroom account.',
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
            taskIconBox(),
          ],
        ),
      ),
    );
  }

  Widget taskIconBox() {
    const Color color = Color(0xFFFFA726);

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
            Icons.assignment_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget buildSearchBox(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          boxShadow: cardShadow(isLightMode),
        ),
        child: TextField(
          controller: searchController,
          onChanged: (_) {
            setState(() {});
          },
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            color: isLightMode ? AppTheme.darkText : AppTheme.white,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Search assignment, course or status',
            hintStyle: TextStyle(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.75)
                  : AppTheme.white.withOpacity(0.45),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isLightMode ? AppTheme.grey : Colors.white54,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(top: 12),
          ),
        ),
      ),
    );
  }

  Widget buildFilterSection(bool isLightMode) {
    return Column(
      children: <Widget>[
        buildSectionTitle(
          title: 'Filter',
          subtitle: selectedFilter,
          isLightMode: isLightMode,
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: filters.length,
            itemBuilder: (BuildContext context, int index) {
              final String filter = filters[index];
              final bool selected = selectedFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(left: 4, right: 8, bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                        colors: <Color>[
                          Color(0xFF2633C5),
                          Color(0xFF6A88E5),
                        ],
                      )
                          : null,
                      color: selected
                          ? null
                          : isLightMode
                          ? Colors.white
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : isLightMode
                              ? AppTheme.darkText
                              : AppTheme.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildSummaryRow(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Row(
        children: <Widget>[
          summaryBox(
            title: 'Total',
            value: tasks.length.toString(),
            icon: Icons.assignment_rounded,
            color: const Color(0xFF42A5F5),
            isLightMode: isLightMode,
          ),
          const SizedBox(width: 8),
          summaryBox(
            title: 'Done',
            value: submittedCount.toString(),
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF66BB6A),
            isLightMode: isLightMode,
          ),
          const SizedBox(width: 8),
          summaryBox(
            title: 'Pending',
            value: pendingCount.toString(),
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFFFA726),
            isLightMode: isLightMode,
          ),
          const SizedBox(width: 8),
          summaryBox(
            title: 'Late',
            value: lateCount.toString(),
            icon: Icons.warning_rounded,
            color: const Color(0xFFEF5350),
            isLightMode: isLightMode,
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 10,
                color: isLightMode
                    ? AppTheme.grey
                    : AppTheme.white.withOpacity(0.65),
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
      padding: const EdgeInsets.only(left: 24, right: 24, top: 6, bottom: 10),
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

  Widget loadingCard(bool isLightMode) {
    return const AppLoadingCard(
      title: 'Loading assignments...',
      subtitle: 'Fetching tasks and submission status from Google Classroom.',
      icon: Icons.cloud_sync_rounded,
      color: Color(0xFF42A5F5),
    );
  }

  Widget errorCard(bool isLightMode) {
    return AppErrorCard(
      title: 'Unable to load assignments',
      subtitle: errorText,
      icon: Icons.error_outline_rounded,
      color: const Color(0xFFEF5350),
      onRetry: () {
        loadTasks(forceRefresh: true);
      },
    );
  }

  Widget emptyCard(bool isLightMode) {
    return AppEmptyCard(
      title: 'No assignments found',
      subtitle: selectedFilter == 'All'
          ? 'Google Classroom returned zero assignments for this account.'
          : 'No assignment matched the "$selectedFilter" filter.',
      icon: Icons.inbox_rounded,
      color: const Color(0xFFFFA726),
      buttonText: 'Refresh',
      onButtonTap: () {
        loadTasks(forceRefresh: true);
      },
    );
  }



  Widget buildTaskList(bool isLightMode) {
    return Column(
      children: visibleTasks.map((TaskViewData task) {
        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
          child: TaskCard(
            task: task,
            isLightMode: isLightMode,
            onTap: () {
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
                    icon: task.icon,
                    workType: task.workType,
                    maxPointsText: task.maxPointsText,
                    gradeText: task.gradeText,
                    submissionState: task.submissionState,
                    alternateLink: task.alternateLink,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget buildInfoCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.cloud_done_rounded,
              color: Color(0xFF66BB6A),
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'This screen uses real Google Classroom coursework and student submission data from the signed-in account.',
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 13,
                  height: 1.4,
                  color: isLightMode
                      ? AppTheme.darkText
                      : AppTheme.white.withOpacity(0.75),
                ),
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

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.isLightMode,
    required this.onTap,
  });

  final TaskViewData task;
  final bool isLightMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.14)
                  : Colors.black.withOpacity(0.20),
              offset: const Offset(1, 3),
              blurRadius: 9,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: task.statusColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                task.icon,
                color: task.statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: buildContent(),
            ),
            const SizedBox(width: 8),
            buildDateBox(),
          ],
        ),
      ),
    );
  }

  Widget buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 15,
            fontWeight: FontWeight.w800,
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
            fontSize: 12,
            color:
            isLightMode ? AppTheme.grey : AppTheme.white.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: <Widget>[
            pill(task.status, task.statusColor),
            pill(task.priority, task.priorityColor),
            pill(task.workType, task.color),
          ],
        ),
      ],
    );
  }

  Widget buildDateBox() {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: task.statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        task.deadline,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.fontName,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: task.statusColor,
        ),
      ),
    );
  }

  Widget pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.fontName,
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TaskViewData {
  const TaskViewData({
    required this.title,
    required this.course,
    required this.deadline,
    required this.status,
    required this.priority,
    required this.description,
    required this.workType,
    required this.dueCategory,
    required this.color,
    required this.statusColor,
    required this.priorityColor,
    required this.icon,
    required this.maxPointsText,
    required this.gradeText,
    required this.submissionState,
    required this.alternateLink,
  });

  factory TaskViewData.fromRealTask(RealClassroomTask task, int index) {
    final String status = task.submissionStatus;
    final Color baseColor = _colors[index % _colors.length];
    final Color statusColor = _statusColor(status);
    final IconData icon = _iconForTask(task.workType, status);

    return TaskViewData(
      title: task.title,
      course: task.courseName,
      deadline: _formatDate(task.dueDateTime),
      status: status,
      priority: _priority(task.dueDateTime, status),
      description: task.description.isEmpty
          ? 'This assignment was loaded from Google Classroom API.'
          : task.description,
      workType: task.workType.isEmpty ? 'COURSE_WORK' : task.workType,
      dueCategory: _dueCategory(task.dueDateTime),
      color: baseColor,
      statusColor: statusColor,
      priorityColor: _priorityColor(_priority(task.dueDateTime, status)),
      icon: icon,
      maxPointsText: task.maxPoints == null
          ? 'No points'
          : '${task.maxPoints!.toStringAsFixed(1)} points',
      gradeText: task.gradeText,
      submissionState:
      task.submissionState.isEmpty ? 'Unknown' : task.submissionState,
      alternateLink: task.alternateLink,
    );
  }

  static String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return 'No due date';
    }

    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/${dateTime.year}\n$hour:$minute';
  }

  static String _dueCategory(DateTime? dateTime) {
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
      return 'Due Today';
    }

    return 'Upcoming';
  }

  static String _priority(DateTime? dateTime, String status) {
    if (status == 'Submitted') {
      return 'Done';
    }

    if (status == 'Late Not Submitted') {
      return 'High';
    }

    if (dateTime == null) {
      return 'Low';
    }

    final int difference = dateTime.difference(DateTime.now()).inDays;

    if (difference <= 1) {
      return 'High';
    }

    if (difference <= 5) {
      return 'Medium';
    }

    return 'Low';
  }

  static Color _statusColor(String status) {
    if (status == 'Submitted') {
      return const Color(0xFF66BB6A);
    }

    if (status == 'Late Not Submitted') {
      return const Color(0xFFEF5350);
    }

    return const Color(0xFFFFA726);
  }

  static Color _priorityColor(String priority) {
    if (priority == 'High') {
      return const Color(0xFFEF5350);
    }

    if (priority == 'Medium') {
      return const Color(0xFFFFA726);
    }

    if (priority == 'Done') {
      return const Color(0xFF66BB6A);
    }

    return const Color(0xFF42A5F5);
  }

  static IconData _iconForTask(String type, String status) {
    if (status == 'Submitted') {
      return Icons.task_alt_rounded;
    }

    if (status == 'Late Not Submitted') {
      return Icons.warning_rounded;
    }

    final String value = type.toUpperCase();

    if (value.contains('QUIZ')) {
      return Icons.quiz_rounded;
    }

    if (value.contains('MATERIAL')) {
      return Icons.menu_book_rounded;
    }

    return Icons.assignment_rounded;
  }

  static const List<Color> _colors = <Color>[
    Color(0xFFFFA726),
    Color(0xFF42A5F5),
    Color(0xFF738AE6),
    Color(0xFF66BB6A),
    Color(0xFFEF5350),
  ];

  final String title;
  final String course;
  final String deadline;
  final String status;
  final String priority;
  final String description;
  final String workType;
  final String dueCategory;
  final Color color;
  final Color statusColor;
  final Color priorityColor;
  final IconData icon;
  final String maxPointsText;
  final String gradeText;
  final String submissionState;
  final String alternateLink;
}