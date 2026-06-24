import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:best_flutter_ui_templates/task_detail_screen.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  final ScrollController scrollController = ScrollController();

  double topBarOpacity = 0.0;
  bool isLoading = true;
  bool reminderEnabled = true;
  bool todayOnly = false;

  String selectedFilter = 'All';
  String errorText = '';

  List<RealClassroomTask> tasks = <RealClassroomTask>[];

  final List<String> filters = const <String>[
    'All',
    'Today',
    'This Week',
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

    loadNotifications();
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

  Future<void> loadNotifications() async {
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

  List<ReminderItem> get reminders {
    return tasks.asMap().entries.map((MapEntry<int, RealClassroomTask> item) {
      return ReminderItem.fromTask(item.value, item.key);
    }).toList();
  }

  List<ReminderItem> get visibleReminders {
    List<ReminderItem> list = reminders;

    if (todayOnly) {
      list = list.where((ReminderItem item) => item.category == 'Today').toList();
    }

    if (selectedFilter != 'All') {
      list = list.where((ReminderItem item) {
        return item.category == selectedFilter;
      }).toList();
    }

    return list;
  }

  int get todayCount {
    return reminders.where((ReminderItem item) => item.category == 'Today').length;
  }

  int get weekCount {
    return reminders.where((ReminderItem item) {
      return item.category == 'This Week';
    }).length;
  }

  int get lateCount {
    return reminders.where((ReminderItem item) => item.category == 'Late').length;
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
        animatedWidget(1, buildSettingsCard(isLightMode)),
        animatedWidget(2, buildSummaryRow(isLightMode)),
        animatedWidget(3, buildFilterSection(isLightMode)),
        animatedWidget(
          4,
          buildSectionTitle(
            title: 'Reminder Alerts',
            subtitle: isLoading ? 'Loading' : '${visibleReminders.length} found',
            isLightMode: isLightMode,
          ),
        ),
        if (isLoading) animatedWidget(5, loadingCard(isLightMode)),
        if (!isLoading && errorText.isNotEmpty)
          animatedWidget(5, errorCard(isLightMode)),
        if (!isLoading && errorText.isEmpty && visibleReminders.isEmpty)
          animatedWidget(5, emptyCard(isLightMode)),
        if (!isLoading && errorText.isEmpty && visibleReminders.isNotEmpty)
          animatedWidget(5, buildReminderList(isLightMode)),
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
                        'Reminders',
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
                      onTap: loadNotifications,
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
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFFFFA726),
              Color(0xFFFF7043),
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
              color: const Color(0xFFFF7043).withOpacity(0.30),
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
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Classroom Reminders',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'See important deadline alerts from your real Google Classroom assignments.',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget buildSettingsCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Column(
          children: <Widget>[
            switchRow(
              title: 'Reminder Alerts',
              subtitle: reminderEnabled ? 'Enabled' : 'Disabled',
              value: reminderEnabled,
              color: const Color(0xFFFFA726),
              isLightMode: isLightMode,
              onChanged: (bool value) {
                setState(() {
                  reminderEnabled = value;
                });
              },
            ),
            Divider(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.16)
                  : Colors.white.withOpacity(0.10),
            ),
            switchRow(
              title: 'Today Only',
              subtitle: todayOnly ? 'Showing today tasks' : 'Showing all alerts',
              value: todayOnly,
              color: const Color(0xFF42A5F5),
              isLightMode: isLightMode,
              onChanged: (bool value) {
                setState(() {
                  todayOnly = value;
                  if (value) {
                    selectedFilter = 'All';
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required bool isLightMode,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: <Widget>[
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            value ? Icons.notifications_active_rounded : Icons.notifications_off,
            color: color,
          ),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isLightMode ? AppTheme.darkText : AppTheme.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 12,
                  color: isLightMode
                      ? AppTheme.grey
                      : AppTheme.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: color,
          onChanged: onChanged,
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

  Widget buildFilterSection(bool isLightMode) {
    return Column(
      children: <Widget>[
        buildSectionTitle(
          title: 'Filter',
          subtitle: todayOnly ? 'Today Only' : selectedFilter,
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
                  onTap: todayOnly
                      ? null
                      : () {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: selected && !todayOnly
                          ? const LinearGradient(
                        colors: <Color>[
                          Color(0xFF2633C5),
                          Color(0xFF6A88E5),
                        ],
                      )
                          : null,
                      color: selected && !todayOnly
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
                          color: selected && !todayOnly
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

  Widget buildReminderList(bool isLightMode) {
    if (!reminderEnabled) {
      return messageCard(
        isLightMode: isLightMode,
        icon: Icons.notifications_off_rounded,
        color: const Color(0xFFEF5350),
        title: 'Reminder alerts are disabled',
        subtitle: 'Turn on Reminder Alerts to view Classroom alert cards.',
        isLoading: false,
      );
    }

    return Column(
      children: visibleReminders.map((ReminderItem item) {
        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
          child: ReminderCard(
            item: item,
            isLightMode: isLightMode,
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => TaskDetailScreen(
                    title: item.title,
                    course: item.course,
                    deadline: item.dateText,
                    status: item.status,
                    priority: item.priority,
                    description: item.description,
                    color: item.color,
                    icon: item.icon,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget loadingCard(bool isLightMode) {
    return messageCard(
      isLightMode: isLightMode,
      icon: Icons.cloud_sync_rounded,
      color: const Color(0xFF42A5F5),
      title: 'Loading reminders...',
      subtitle: 'Fetching upcoming assignments from Google Classroom.',
      isLoading: true,
    );
  }

  Widget errorCard(bool isLightMode) {
    return messageCard(
      isLightMode: isLightMode,
      icon: Icons.error_outline_rounded,
      color: const Color(0xFFEF5350),
      title: 'Unable to load reminders',
      subtitle: errorText,
      isLoading: false,
    );
  }

  Widget emptyCard(bool isLightMode) {
    return messageCard(
      isLightMode: isLightMode,
      icon: Icons.notifications_none_rounded,
      color: const Color(0xFF66BB6A),
      title: 'No reminders found',
      subtitle: 'No relevant Classroom reminders were found.',
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

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.item,
    required this.isLightMode,
    required this.onTap,
  });

  final ReminderItem item;
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
                color: item.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                item.icon,
                color: item.color,
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
          item.title,
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
          item.course,
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
            pill(item.category, item.color),
            pill(item.priority, priorityColor),
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
        color: item.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        item.dateText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.fontName,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: item.color,
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
    if (item.priority == 'High') {
      return const Color(0xFFEF5350);
    }

    if (item.priority == 'Medium') {
      return const Color(0xFFFFA726);
    }

    return const Color(0xFF66BB6A);
  }
}

class ReminderItem {
  const ReminderItem({
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

  factory ReminderItem.fromTask(RealClassroomTask task, int index) {
    final String category = getCategory(task.dueDateTime);
    final Color color = getColor(category, index);
    final String priority = getPriority(task.dueDateTime);

    return ReminderItem(
      title: task.title,
      course: task.courseName,
      dateText: formatDate(task.dueDateTime),
      category: category,
      status: 'Pending',
      priority: priority,
      description: task.description.isEmpty
          ? 'This reminder was loaded from Google Classroom API.'
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

    final int difference = dateTime.difference(DateTime.now()).inDays;

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

    return Icons.notifications_active_rounded;
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