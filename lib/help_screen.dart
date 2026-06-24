import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/deadlines_screen.dart';
import 'package:best_flutter_ui_templates/google_account_screen.dart';
import 'package:best_flutter_ui_templates/notifications_screen.dart';
import 'package:best_flutter_ui_templates/services/app_guide_service.dart';
import 'package:best_flutter_ui_templates/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> topBarAnimation;

  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;

  final List<HelpFeature> helpFeatures = <HelpFeature>[
    HelpFeature(
      title: 'Dashboard',
      subtitle: 'See your full Classroom overview.',
      icon: Icons.dashboard_rounded,
      startColor: const Color(0xFF738AE6),
      endColor: const Color(0xFF5C5EDD),
    ),
    HelpFeature(
      title: 'Sync',
      subtitle: 'Load latest courses and assignments.',
      icon: Icons.sync_rounded,
      startColor: const Color(0xFF42A5F5),
      endColor: const Color(0xFF2633C5),
    ),
    HelpFeature(
      title: 'Alerts',
      subtitle: 'Late, Due Today and Due Soon.',
      icon: Icons.notifications_active_rounded,
      startColor: const Color(0xFFFFA726),
      endColor: const Color(0xFFFF7043),
    ),
    HelpFeature(
      title: 'Offline',
      subtitle: 'Use saved data without internet.',
      icon: Icons.offline_bolt_rounded,
      startColor: const Color(0xFF66BB6A),
      endColor: const Color(0xFF2E7D32),
    ),
  ];

  final List<HelpStep> helpSteps = <HelpStep>[
    HelpStep(
      title: '1. Connect Google Account',
      description:
      'Open Manage Account and login with the same Google account that you use for Google Classroom.',
      icon: Icons.login_rounded,
      color: const Color(0xFF2633C5),
    ),
    HelpStep(
      title: '2. Sync Classroom Data',
      description:
      'Sync means the app is getting your latest courses, assignments, deadlines and submission status from Google Classroom.',
      icon: Icons.cloud_sync_rounded,
      color: const Color(0xFF42A5F5),
    ),
    HelpStep(
      title: '3. Check Classroom Alerts',
      description:
      'Dashboard shows Late, Due Today and Due Soon counts so you immediately know which work needs attention.',
      icon: Icons.warning_rounded,
      color: const Color(0xFFFFA726),
    ),
    HelpStep(
      title: '4. Open Tasks or Deadlines',
      description:
      'Use Tasks to see Submitted, Pending and Late work. Use Deadlines to view assignments by date.',
      icon: Icons.assignment_rounded,
      color: const Color(0xFFEF5350),
    ),
    HelpStep(
      title: '5. Use Phone Notifications',
      description:
      'The app can send reminders for due today, due soon and late assignments, even when the app is closed.',
      icon: Icons.phone_android_rounded,
      color: const Color(0xFF66BB6A),
    ),
    HelpStep(
      title: '6. Understand Offline Mode',
      description:
      'If internet is off, the app shows your last saved Classroom data. Sync again when internet is available.',
      icon: Icons.wifi_off_rounded,
      color: const Color(0xFF7E57C2),
    ),
  ];

  final List<InfoItem> syncMeanings = <InfoItem>[
    InfoItem(
      title: 'Syncing in Background',
      description:
      'The app is loading latest Classroom data. You can still view saved data while sync is running.',
      icon: Icons.sync_rounded,
      color: const Color(0xFF42A5F5),
    ),
    InfoItem(
      title: 'Online Sync Active',
      description:
      'Your Classroom data has been updated successfully from Google Classroom.',
      icon: Icons.cloud_done_rounded,
      color: const Color(0xFF66BB6A),
    ),
    InfoItem(
      title: 'Offline Mode Active',
      description:
      'Internet is not available. The app is showing saved data from the last successful sync.',
      icon: Icons.offline_bolt_rounded,
      color: const Color(0xFFFFA726),
    ),
    InfoItem(
      title: 'No Google Account Connected',
      description:
      'Connect your Google account first to see real courses, assignments and deadlines.',
      icon: Icons.account_circle_rounded,
      color: const Color(0xFFEF5350),
    ),
  ];

  final List<InfoItem> troubleshooting = <InfoItem>[
    InfoItem(
      title: 'No assignments showing?',
      description:
      'Open Manage Account and tap Sync Classroom Data. Make sure internet is connected.',
      icon: Icons.refresh_rounded,
      color: const Color(0xFF42A5F5),
    ),
    InfoItem(
      title: 'Wrong account data?',
      description:
      'Logout and login with the Google account that is enrolled in your Classroom courses.',
      icon: Icons.switch_account_rounded,
      color: const Color(0xFF7E57C2),
    ),
    InfoItem(
      title: 'Notifications not coming?',
      description:
      'Allow notifications and alarms/reminders from phone settings. Also avoid force-stopping the app.',
      icon: Icons.notifications_off_rounded,
      color: const Color(0xFFFFA726),
    ),
    InfoItem(
      title: 'Data looks old?',
      description:
      'You may be offline. Connect internet and sync again to refresh latest Classroom data.',
      icon: Icons.update_rounded,
      color: const Color(0xFF66BB6A),
    ),
  ];

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
        curve: const Interval(0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    scrollController.addListener(updateTopBarOpacity);
    animationController.forward();
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

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void openScreen(Widget screen) {
    Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => screen,
      ),
    );
  }

  Future<void> resetWelcomeGuide() async {
    await AppGuideService.instance.resetWelcomeGuide();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Welcome guide will show again next time.'),
        duration: Duration(seconds: 2),
      ),
    );
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

  Widget getMainListViewUI(bool isLightMode) {
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
        animatedItem(
          index: 0,
          count: 10,
          child: heroGuideCard(isLightMode),
        ),
        animatedItem(
          index: 1,
          count: 10,
          child: sectionTitle(
            title: 'Main Features',
            subtitle: 'Student friendly',
            isLightMode: isLightMode,
          ),
        ),
        animatedItem(
          index: 2,
          count: 10,
          child: featureList(),
        ),
        animatedItem(
          index: 3,
          count: 10,
          child: quickHelpActions(isLightMode),
        ),
        animatedItem(
          index: 4,
          count: 10,
          child: sectionTitle(
            title: 'How To Use GCR HELPER',
            subtitle: 'Step by step',
            isLightMode: isLightMode,
          ),
        ),
        animatedItem(
          index: 5,
          count: 10,
          child: stepsList(isLightMode),
        ),
        animatedItem(
          index: 6,
          count: 10,
          child: sectionTitle(
            title: 'Sync Status Meaning',
            subtitle: 'Know what is happening',
            isLightMode: isLightMode,
          ),
        ),
        animatedItem(
          index: 7,
          count: 10,
          child: infoList(syncMeanings, isLightMode),
        ),
        animatedItem(
          index: 8,
          count: 10,
          child: sectionTitle(
            title: 'Troubleshooting',
            subtitle: 'Common problems',
            isLightMode: isLightMode,
          ),
        ),
        animatedItem(
          index: 9,
          count: 10,
          child: Column(
            children: <Widget>[
              infoList(troubleshooting, isLightMode),
              developerInfoCard(isLightMode),
              resetGuideCard(isLightMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget animatedItem({
    required int index,
    required int count,
    required Widget child,
  }) {
    final Animation<double> animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
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
                                'Help & Guide',
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
                            Container(
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
                                Icons.support_agent_rounded,
                                color: isLightMode
                                    ? const Color(0xFF2633C5)
                                    : Colors.white,
                                size: 22,
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

  Widget heroGuideCard(bool isLightMode) {
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
        child: const Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 20, bottom: 20),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 58,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Smart Student Guide',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Learn how to connect your account, sync Classroom data, understand alerts and use reminders.',
                      style: TextStyle(
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
                fontWeight: FontWeight.w800,
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

  Widget featureList() {
    return SizedBox(
      height: 178,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: helpFeatures.length,
        itemBuilder: (BuildContext context, int index) {
          return FeatureCard(feature: helpFeatures[index]);
        },
      ),
    );
  }

  Widget quickHelpActions(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(14),
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
          children: <Widget>[
            helpActionRow(
              title: 'Manage Account',
              subtitle: 'Connect Google account or sync data.',
              icon: Icons.account_circle_rounded,
              color: const Color(0xFF2633C5),
              isLightMode: isLightMode,
              onTap: () => openScreen(const GoogleAccountScreen()),
            ),
            divider(isLightMode),
            helpActionRow(
              title: 'Open Notifications',
              subtitle: 'Check due today, due soon and late reminders.',
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFFFFA726),
              isLightMode: isLightMode,
              onTap: () => openScreen(const NotificationsScreen()),
            ),
            divider(isLightMode),
            helpActionRow(
              title: 'View Today Tasks',
              subtitle: 'Open assignments that are due today.',
              icon: Icons.today_rounded,
              color: const Color(0xFFEF5350),
              isLightMode: isLightMode,
              onTap: () => openScreen(const TasksScreen(initialFilter: 'Due Today')),
            ),
            divider(isLightMode),
            helpActionRow(
              title: 'View Deadlines',
              subtitle: 'See your assignment timeline.',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF42A5F5),
              isLightMode: isLightMode,
              onTap: () => openScreen(const DeadlinesScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget helpActionRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLightMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: <Widget>[
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
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
            Icon(
              Icons.chevron_right_rounded,
              color: isLightMode
                  ? AppTheme.grey
                  : Colors.white.withOpacity(0.65),
            ),
          ],
        ),
      ),
    );
  }

  Widget divider(bool isLightMode) {
    return Divider(
      color: isLightMode
          ? AppTheme.grey.withOpacity(0.14)
          : Colors.white.withOpacity(0.10),
    );
  }

  Widget stepsList(bool isLightMode) {
    return Column(
      children: List<Widget>.generate(
        helpSteps.length,
            (int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
            child: StepGuideCard(
              step: helpSteps[index],
              isLightMode: isLightMode,
            ),
          );
        },
      ),
    );
  }

  Widget infoList(List<InfoItem> items, bool isLightMode) {
    return Column(
      children: List<Widget>.generate(
        items.length,
            (int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
            child: InfoCard(
              item: items[index],
              isLightMode: isLightMode,
            ),
          );
        },
      ),
    );
  }

  Widget resetGuideCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: resetWelcomeGuide,
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
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2633C5).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.replay_rounded,
                  color: Color(0xFF2633C5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Show Welcome Guide Again',
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isLightMode ? AppTheme.darkText : AppTheme.white,
                  ),
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
        ),
      ),
    );
  }
  Widget developerInfoCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 14),
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
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2633C5).withOpacity(0.13),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.code_rounded,
                    color: Color(0xFF2633C5),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Developer Information',
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isLightMode ? AppTheme.darkText : AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Built with Flutter and Google Classroom API',
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontSize: 12.5,
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
            const SizedBox(height: 16),
            developerInfoRow(
              title: 'Developer',
              value: 'WASIL KHAN',
              icon: Icons.person_rounded,
              isLightMode: isLightMode,
            ),
            developerInfoRow(
              title: 'Contact',
              value: '+92 346 0509611',
              icon: Icons.phone_rounded,
              isLightMode: isLightMode,
            ),
            developerInfoRow(
              title: 'Project Name',
              value: 'GCR HELPER',
              icon: Icons.school_rounded,
              isLightMode: isLightMode,
            ),
            developerInfoRow(
              title: 'Category',
              value: 'Google Classroom Student Tracker',
              icon: Icons.category_rounded,
              isLightMode: isLightMode,
            ),
            developerInfoRow(
              title: 'Technology',
              value: 'Flutter, Dart, Google APIs, Local Notifications',
              icon: Icons.memory_rounded,
              isLightMode: isLightMode,
            ),
            developerInfoRow(
              title: 'Purpose',
              value: 'To help students track assignments, deadlines and reminders easily.',
              icon: Icons.flag_rounded,
              isLightMode: isLightMode,
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await Clipboard.setData(
                  const ClipboardData(text: 'prakajsharma30@gmail.com'),
                );

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Developer email copied.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.email_rounded,
                      color: Color(0xFF42A5F5),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'prakajsharma30@gmail.com',
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                          isLightMode ? AppTheme.darkText : AppTheme.white,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.copy_rounded,
                      color: Color(0xFF42A5F5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget developerInfoRow({
    required String title,
    required String value,
    required IconData icon,
    required bool isLightMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF2633C5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isLightMode
                          ? AppTheme.grey
                          : Colors.white.withOpacity(0.70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.feature,
  });

  final HelpFeature feature;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 28, left: 8, right: 8, bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    feature.startColor,
                    feature.endColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(10.0),
                  bottomLeft: Radius.circular(10.0),
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(54.0),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: feature.endColor.withOpacity(0.42),
                    offset: const Offset(1.1, 4.0),
                    blurRadius: 8.0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 56, left: 14, right: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      feature.title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      feature.subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 1.25,
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 10,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 13,
            left: 24,
            child: Icon(
              feature.icon,
              size: 46,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class StepGuideCard extends StatelessWidget {
  const StepGuideCard({
    super.key,
    required this.step,
    required this.isLightMode,
  });

  final HelpStep step;
  final bool isLightMode;

  @override
  Widget build(BuildContext context) {
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
                color: step.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                step.icon,
                color: step.color,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    step.title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
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
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.item,
    required this.isLightMode,
  });

  final InfoItem item;
  final bool isLightMode;

  @override
  Widget build(BuildContext context) {
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
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
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
}

class HelpFeature {
  HelpFeature({
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

class HelpStep {
  HelpStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class InfoItem {
  InfoItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}