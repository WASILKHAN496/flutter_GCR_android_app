import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:best_flutter_ui_templates/task_detail_screen.dart';
import 'package:flutter/material.dart';

class DeadlinesScreen extends StatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  State<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends State<DeadlinesScreen>
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
    'Today',
    'This Week',
    'Upcoming',
    'Late',
    'No Due Date',
  ];

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    scrollController.addListener(updateTopBarOpacity);
    animationController.forward();

    loadDeadlines();
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

  Future<void> loadDeadlines() async {
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

  List<DeadlineViewData> get deadlines {
    return realTasks
        .asMap()
        .entries
        .map((MapEntry<int, RealClassroomTask> item) {
      return DeadlineViewData.fromRealTask(item.value, item.key);
    }).toList();
  }

  List<DeadlineViewData> get visibleDeadlines {
    final String query = searchController.text.toLowerCase().trim();

    return deadlines.where((DeadlineViewData item) {
      final bool filterOk =
          selectedFilter == 'All' || item.category == selectedFilter;

      final bool searchOk = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.course.toLowerCase().contains(query) ||
          item.priority.toLowerCase().contains(query);

      return filterOk && searchOk;
    }).toList();
  }

  int get todayCount {
    return deadlines.where((DeadlineViewData item) {
      return item.category == 'Today';
    }).length;
  }

  int get weekCount {
    return deadlines.where((DeadlineViewData item) {
      return item.category == 'This Week';
    }).length;
  }

  int get lateCount {
    return deadlines.where((DeadlineViewData item) {
      return item.category == 'Late';
    }).length;
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
        animatedWidget(1, buildSearchBox(isLightMode)),
        animatedWidget(2, buildFilterSection(isLightMode)),
        animatedWidget(3, buildSummaryRow(isLightMode)),
        animatedWidget(
          4,
          buildSectionTitle(
            title: 'Classroom Deadlines',
            subtitle: isLoading ? 'Loading' : '${visibleDeadlines.length} found',
            isLightMode: isLightMode,
          ),
        ),
        if (isLoading) animatedWidget(5, loadingCard(isLightMode)),
        if (!isLoading && errorText.isNotEmpty)
          animatedWidget(5, errorCard(isLightMode)),
        if (!isLoading && errorText.isEmpty && visibleDeadlines.isEmpty)
          animatedWidget(5, emptyCard(isLightMode)),
        if (!isLoading && errorText.isEmpty && visibleDeadlines.isNotEmpty)
          animatedWidget(5, buildDeadlineList(isLightMode)),
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
                        'Deadlines',
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
                      onTap: loadDeadlines,
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
                    'Manage your',
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
                    'Classroom Deadlines',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upcoming dates are loaded from your real Google Classroom assignments.',
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
            deadlineIconBox(),
          ],
        ),
      ),
    );
  }

  Widget deadlineIconBox() {
    const Color color = Color(0xFFEF5350);

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
            Icons.event_available_rounded,
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
            hintText: 'Search deadline or course',
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
            title: 'Today',
            value: todayCount.toString(),
            icon: Icons.today_rounded,
            color: const Color(0xFFEF5350),
            isLightMode: isLightMode,
          ),
          const SizedBox(width: 10),
          summaryBox(
            title: 'Week',
            value: weekCount.toString(),
            icon: Icons.date_range_rounded,
            color: const Color(0xFFFFA726),
            isLightMode: isLightMode,
          ),
          const SizedBox(width: 10),
          summaryBox(
            title: 'Late',
            value: lateCount.toString(),
            icon: Icons.warning_rounded,
            color: const Color(0xFF42A5F5),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow(isLightMode),
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
    return messageCard(
      isLightMode: isLightMode,
      icon: Icons.cloud_sync_rounded,
      color: const Color(0xFF42A5F5),
      title: 'Loading real deadlines...',
      subtitle: 'Fetching due dates from Google Classroom API.',
      isLoading: true,
    );
  }

  Widget errorCard(bool isLightMode) {
    return messageCard(
      isLightMode: isLightMode,
      icon: Icons.error_outline_rounded,
      color: const Color(0xFFEF5350),
      title: 'Unable to load deadlines',
      subtitle: errorText,
      isLoading: false,
    );
  }

  Widget emptyCard(bool isLightMode) {
    return messageCard(
      isLightMode: isLightMode,
      icon: Icons.inbox_rounded,
      color: const Color(0xFFFFA726),
      title: 'No deadlines found',
      subtitle: 'No relevant Google Classroom deadlines were found.',
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

  Widget buildDeadlineList(bool isLightMode) {
    return Column(
      children: visibleDeadlines.map((DeadlineViewData deadline) {
        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
          child: DeadlineCard(
            deadline: deadline,
            isLightMode: isLightMode,
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => TaskDetailScreen(
                    title: deadline.title,
                    course: deadline.course,
                    deadline: deadline.dateText,
                    status: deadline.status,
                    priority: deadline.priority,
                    description: deadline.description,
                    color: deadline.color,
                    icon: deadline.icon,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
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

class DeadlineCard extends StatelessWidget {
  const DeadlineCard({
    super.key,
    required this.deadline,
    required this.isLightMode,
    required this.onTap,
  });

  final DeadlineViewData deadline;
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
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: deadline.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                deadline.icon,
                color: deadline.color,
                size: 29,
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
          deadline.title,
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
          deadline.course,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 12,
            color: isLightMode
                ? AppTheme.grey
                : AppTheme.white.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: <Widget>[
            pill(deadline.category, deadline.color),
            pill(deadline.priority, priorityColor),
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
        color: deadline.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        deadline.dateText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.fontName,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: deadline.color,
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

  Color get priorityColor {
    if (deadline.priority == 'High') {
      return const Color(0xFFEF5350);
    }

    if (deadline.priority == 'Medium') {
      return const Color(0xFFFFA726);
    }

    return const Color(0xFF66BB6A);
  }
}

class DeadlineViewData {
  const DeadlineViewData({
    required this.title,
    required this.course,
    required this.dateText,
    required this.category,
    required this.status,
    required this.priority,
    required this.description,
    required this.color,
    required this.icon,
  });

  factory DeadlineViewData.fromRealTask(RealClassroomTask task, int index) {
    final String category = getCategory(task.dueDateTime);
    final Color color = getColor(category, index);
    final String priority = getPriority(task.dueDateTime);

    return DeadlineViewData(
      title: task.title,
      course: task.courseName,
      dateText: formatDate(task.dueDateTime),
      category: category,
      status: 'Pending',
      priority: priority,
      description: task.description.isEmpty
          ? 'This deadline was loaded from Google Classroom API.'
          : task.description,
      color: color,
      icon: getIcon(category),
    );
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return 'No due date';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  static String getCategory(DateTime? dateTime) {
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

  static String getPriority(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Low';
    }

    final DateTime now = DateTime.now();
    final int difference = dateTime.difference(now).inDays;

    if (difference <= 1) {
      return 'High';
    }

    if (difference <= 5) {
      return 'Medium';
    }

    return 'Low';
  }

  static IconData getIcon(String category) {
    if (category == 'Late') {
      return Icons.warning_rounded;
    }

    if (category == 'Today') {
      return Icons.today_rounded;
    }

    if (category == 'This Week') {
      return Icons.date_range_rounded;
    }

    if (category == 'No Due Date') {
      return Icons.event_busy_rounded;
    }

    return Icons.event_available_rounded;
  }

  static Color getColor(String category, int index) {
    if (category == 'Late') {
      return const Color(0xFFEF5350);
    }

    if (category == 'Today') {
      return const Color(0xFFFFA726);
    }

    if (category == 'This Week') {
      return const Color(0xFF42A5F5);
    }

    if (category == 'No Due Date') {
      return const Color(0xFF738AE6);
    }

    final List<Color> colors = <Color>[
      Color(0xFF66BB6A),
      Color(0xFF42A5F5),
      Color(0xFFFFA726),
      Color(0xFF738AE6),
    ];

    return colors[index % colors.length];
  }

  final String title;
  final String course;
  final String dateText;
  final String category;
  final String status;
  final String priority;
  final String description;
  final Color color;
  final IconData icon;
}