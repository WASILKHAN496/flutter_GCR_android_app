import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.title,
    required this.course,
    required this.deadline,
    required this.status,
    required this.priority,
    required this.description,
    required this.color,
    required this.icon,
    this.workType = 'COURSE_WORK',
    this.maxPointsText = 'No points',
    this.gradeText = 'Not graded',
    this.submissionState = 'Unknown',
    this.alternateLink = '',
  });

  final String title;
  final String course;
  final String deadline;
  final String status;
  final String priority;
  final String description;
  final Color color;
  final IconData icon;

  final String workType;
  final String maxPointsText;
  final String gradeText;
  final String submissionState;
  final String alternateLink;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;

  final List<String> checklist = const <String>[
    'Read assignment instructions',
    'Complete required work',
    'Review before submission',
    'Submit on Google Classroom',
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
  }

  void updateTopBarOpacity() {
    final double opacity = (scrollController.offset / 24).clamp(0.0, 1.0);

    if (topBarOpacity != opacity) {
      setState(() {
        topBarOpacity = opacity;
      });
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(updateTopBarOpacity);
    scrollController.dispose();
    animationController.dispose();
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
        animatedWidget(0, buildHeroCard()),
        animatedWidget(1, buildStatusBanner(isLightMode)),
        animatedWidget(2, buildInfoCards(isLightMode)),
        animatedWidget(3, buildSubmissionInfoCard(isLightMode)),
        animatedWidget(4, buildDescriptionCard(isLightMode)),
        animatedWidget(5, buildChecklistCard(isLightMode)),
        animatedWidget(6, buildActionButtons(isLightMode)),
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
              0,
              30 * (1.0 - animation.value),
              0,
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
                      'Task Detail',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 28 - 6 * topBarOpacity,
                        fontWeight: FontWeight.w800,
                        color: isLightMode ? AppTheme.darkText : AppTheme.white,
                      ),
                    ),
                  ),
                  circleButton(
                    icon: Icons.link_rounded,
                    isLightMode: isLightMode,
                    onTap: copyClassroomLink,
                  ),
                ],
              ),
            ),
          ],
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

  Widget buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              statusColor,
              statusColor.withOpacity(0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
            topRight: Radius.circular(78),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: statusColor.withOpacity(0.32),
              offset: const Offset(4, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcon,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.course,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.88),
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

  Widget buildStatusBanner(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withOpacity(0.22)),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.13),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.status,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    statusMessage,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.5,
                      height: 1.35,
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

  Widget buildInfoCards(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
      child: Row(
        children: <Widget>[
          smallInfoCard(
            title: 'Deadline',
            value: widget.deadline.replaceAll('\n', ' '),
            icon: Icons.schedule_rounded,
            color: statusColor,
            isLightMode: isLightMode,
          ),
          const SizedBox(width: 10),
          smallInfoCard(
            title: 'Priority',
            value: widget.priority,
            icon: Icons.flag_rounded,
            color: priorityColor,
            isLightMode: isLightMode,
          ),
          const SizedBox(width: 10),
          smallInfoCard(
            title: 'Status',
            value: widget.status,
            icon: statusIcon,
            color: statusColor,
            isLightMode: isLightMode,
          ),
        ],
      ),
    );
  }

  Widget smallInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLightMode,
  }) {
    return Expanded(
      child: Container(
        height: 104,
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
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 11,
                color: isLightMode
                    ? AppTheme.grey
                    : AppTheme.white.withOpacity(0.60),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 11.2,
                fontWeight: FontWeight.w800,
                color: isLightMode ? AppTheme.darkText : AppTheme.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSubmissionInfoCard(bool isLightMode) {
    return infoSection(
      title: 'Submission Info',
      icon: Icons.fact_check_rounded,
      isLightMode: isLightMode,
      child: Column(
        children: <Widget>[
          infoRow(
            label: 'Work Type',
            value: widget.workType,
            color: widget.color,
            isLightMode: isLightMode,
          ),
          infoRow(
            label: 'Max Points',
            value: widget.maxPointsText,
            color: const Color(0xFF42A5F5),
            isLightMode: isLightMode,
          ),
          infoRow(
            label: 'Grade',
            value: widget.gradeText,
            color: const Color(0xFF66BB6A),
            isLightMode: isLightMode,
          ),
          infoRow(
            label: 'Google State',
            value: widget.submissionState,
            color: statusColor,
            isLightMode: isLightMode,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget infoRow({
    required String label,
    required String value,
    required Color color,
    required bool isLightMode,
    bool showDivider = true,
  }) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.circle,
                color: color,
                size: 11,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isLightMode
                      ? AppTheme.grey
                      : AppTheme.white.withOpacity(0.62),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isLightMode ? AppTheme.darkText : AppTheme.white,
                ),
              ),
            ),
          ],
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 46, top: 10, bottom: 10),
            child: Divider(
              height: 1,
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.18)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
      ],
    );
  }

  Widget buildDescriptionCard(bool isLightMode) {
    return infoSection(
      title: 'Description',
      icon: Icons.notes_rounded,
      isLightMode: isLightMode,
      child: Text(
        widget.description,
        style: TextStyle(
          fontFamily: AppTheme.fontName,
          fontSize: 13,
          height: 1.45,
          color: isLightMode
              ? AppTheme.grey
              : AppTheme.white.withOpacity(0.68),
        ),
      ),
    );
  }

  Widget buildChecklistCard(bool isLightMode) {
    return infoSection(
      title: 'Submission Steps',
      icon: Icons.checklist_rounded,
      isLightMode: isLightMode,
      child: Column(
        children: checklist.map((String item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: <Widget>[
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: checklistColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    checklistIcon,
                    size: 15,
                    color: checklistColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 13,
                      color: isLightMode
                          ? AppTheme.darkText
                          : AppTheme.white.withOpacity(0.78),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget infoSection({
    required String title,
    required IconData icon,
    required bool isLightMode,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: statusColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isLightMode ? AppTheme.darkText : AppTheme.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget buildActionButtons(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: showCourseMessage,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isLightMode
                      ? Colors.white
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: cardShadow(isLightMode),
                ),
                child: Center(
                  child: Text(
                    'Course',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: copyClassroomLink,
              child: Container(
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color(0xFF00AEEF),
                      Color(0xFF2633C5),
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: const Center(
                  child: Text(
                    'Copy Link',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void copyClassroomLink() {
    if (widget.alternateLink.trim().isEmpty) {
      showSnack('No Classroom link available for this assignment.');
      return;
    }

    Clipboard.setData(
      ClipboardData(text: widget.alternateLink),
    );

    showSnack('Google Classroom link copied.');
  }

  void showCourseMessage() {
    showSnack('Course: ${widget.course}');
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color get statusColor {
    if (widget.status == 'Submitted') {
      return const Color(0xFF66BB6A);
    }

    if (widget.status == 'Late Not Submitted') {
      return const Color(0xFFEF5350);
    }

    return const Color(0xFFFFA726);
  }

  IconData get statusIcon {
    if (widget.status == 'Submitted') {
      return Icons.task_alt_rounded;
    }

    if (widget.status == 'Late Not Submitted') {
      return Icons.warning_rounded;
    }

    return Icons.pending_actions_rounded;
  }

  String get statusMessage {
    if (widget.status == 'Submitted') {
      return 'This assignment is submitted according to Google Classroom submission data.';
    }

    if (widget.status == 'Late Not Submitted') {
      return 'This assignment is past the due date and is not submitted yet.';
    }

    return 'This assignment is pending and still needs to be submitted.';
  }

  Color get priorityColor {
    if (widget.priority == 'High') {
      return const Color(0xFFEF5350);
    }

    if (widget.priority == 'Medium') {
      return const Color(0xFFFFA726);
    }

    if (widget.priority == 'Done') {
      return const Color(0xFF66BB6A);
    }

    return const Color(0xFF42A5F5);
  }

  Color get checklistColor {
    if (widget.status == 'Submitted') {
      return const Color(0xFF66BB6A);
    }

    if (widget.status == 'Late Not Submitted') {
      return const Color(0xFFEF5350);
    }

    return const Color(0xFFFFA726);
  }

  IconData get checklistIcon {
    if (widget.status == 'Submitted') {
      return Icons.check_rounded;
    }

    if (widget.status == 'Late Not Submitted') {
      return Icons.close_rounded;
    }

    return Icons.radio_button_unchecked_rounded;
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