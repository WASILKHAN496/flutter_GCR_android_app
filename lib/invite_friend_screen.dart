import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InviteFriend extends StatefulWidget {
  const InviteFriend({super.key});

  @override
  State<InviteFriend> createState() => _InviteFriendState();
}

class _InviteFriendState extends State<InviteFriend>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> topBarAnimation;

  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;

  final List<AppFeature> futureFeatures = <AppFeature>[
    AppFeature(
      title: 'Google Login',
      subtitle: 'Connect student account',
      icon: Icons.login_rounded,
      startColor: const Color(0xFF738AE6),
      endColor: const Color(0xFF5C5EDD),
    ),
    AppFeature(
      title: 'Classroom Sync',
      subtitle: 'Fetch real assignments',
      icon: Icons.cloud_sync_rounded,
      startColor: const Color(0xFF42A5F5),
      endColor: const Color(0xFF2633C5),
    ),
    AppFeature(
      title: 'Smart Alerts',
      subtitle: 'Deadline reminders',
      icon: Icons.notifications_active_rounded,
      startColor: const Color(0xFFFA7D82),
      endColor: const Color(0xFFFFB295),
    ),
    AppFeature(
      title: 'Progress Report',
      subtitle: 'Submitted work history',
      icon: Icons.insights_rounded,
      startColor: const Color(0xFF66BB6A),
      endColor: const Color(0xFF26A69A),
    ),
  ];

  final List<ProjectPoint> projectPoints = <ProjectPoint>[
    ProjectPoint(
      title: 'Project Purpose',
      description:
      'This app is designed to help students track assignments, deadlines, submitted work and course workload in one clean dashboard.',
      icon: Icons.school_rounded,
      color: const Color(0xFF42A5F5),
    ),
    ProjectPoint(
      title: 'Current Version',
      description:
      'The current version uses sample classroom data. It focuses on UI, navigation, dashboard cards, animations and student workflow.',
      icon: Icons.phone_android_rounded,
      color: const Color(0xFFFFA726),
    ),
    ProjectPoint(
      title: 'Next Improvement',
      description:
      'The next phase will add Google account connection and Google Classroom API integration for real student data.',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF66BB6A),
    ),
  ];

  @override
  void initState() {
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

    scrollController.addListener(() {
      if (scrollController.offset >= 24) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (scrollController.offset <= 24 &&
          scrollController.offset >= 0) {
        if (topBarOpacity != scrollController.offset / 24) {
          setState(() {
            topBarOpacity = scrollController.offset / 24;
          });
        }
      } else if (scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() {
            topBarOpacity = 0.0;
          });
        }
      }
    });

    animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    return true;
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
    return FutureBuilder<bool>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

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
              count: 7,
              child: heroShareCard(),
            ),
            animatedItem(
              index: 1,
              count: 7,
              child: shareActionCard(isLightMode),
            ),
            animatedItem(
              index: 2,
              count: 7,
              child: sectionTitle(
                title: 'About Project',
                subtitle: 'Student app idea',
                isLightMode: isLightMode,
              ),
            ),
            animatedItem(
              index: 3,
              count: 7,
              child: projectPointList(isLightMode),
            ),
            animatedItem(
              index: 4,
              count: 7,
              child: sectionTitle(
                title: 'Future Features',
                subtitle: 'Coming soon',
                isLightMode: isLightMode,
              ),
            ),
            animatedItem(
              index: 5,
              count: 7,
              child: featureList(),
            ),
            animatedItem(
              index: 6,
              count: 7,
              child: versionCard(isLightMode),
            ),
          ],
        );
      },
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
                                'Share App',
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
                                Icons.share_rounded,
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

  Widget heroShareCard() {
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
          padding: const EdgeInsets.only(
            left: 18,
            right: 18,
            top: 20,
            bottom: 20,
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Share With Students',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A simple classroom tracker app for students to manage tasks, deadlines and courses.',
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

  Widget shareActionCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
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
                  color: const Color(0xFF42A5F5).withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF42A5F5),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Copy App Info',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: isLightMode ? AppTheme.darkText : AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Copy a short project description and share it with friends or your teacher.',
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
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  copyShareText();
                },
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFF2633C5),
                        Color(0xFF6A88E5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF2633C5).withOpacity(0.25),
                        offset: const Offset(3, 6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
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

  Widget projectPointList(bool isLightMode) {
    return Column(
      children: List<Widget>.generate(
        projectPoints.length,
            (int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
            child: ProjectPointCard(
              point: projectPoints[index],
              isLightMode: isLightMode,
            ),
          );
        },
      ),
    );
  }

  Widget featureList() {
    return SizedBox(
      height: 215,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: futureFeatures.length,
        itemBuilder: (BuildContext context, int index) {
          return AppFeatureCard(feature: futureFeatures[index]);
        },
      ),
    );
  }

  Widget versionCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 2, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
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
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.verified_rounded,
              color: Color(0xFF66BB6A),
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Version 1.0 focuses on UI conversion from template to a student classroom dashboard. Backend integration will be added step by step.',
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontWeight: FontWeight.w500,
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

  Future<void> copyShareText() async {
    const String shareText =
        'Student Classroom Tracker App: A Flutter Android app that helps students track Google Classroom assignments, deadlines, pending work, submitted tasks and course workload.';

    await Clipboard.setData(const ClipboardData(text: shareText));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App information copied.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class ProjectPointCard extends StatelessWidget {
  const ProjectPointCard({
    super.key,
    required this.point,
    required this.isLightMode,
  });

  final ProjectPoint point;
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
                color: point.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                point.icon,
                color: point.color,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    point.title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    point.description,
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

class AppFeatureCard extends StatelessWidget {
  const AppFeatureCard({
    super.key,
    required this.feature,
  });

  final AppFeature feature;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Stack(
        children: <Widget>[
          Padding(
            padding:
            const EdgeInsets.only(top: 28, left: 8, right: 8, bottom: 12),
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
                padding: const EdgeInsets.only(
                  top: 56,
                  left: 14,
                  right: 12,
                  bottom: 12,
                ),
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

class AppFeature {
  AppFeature({
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

class ProjectPoint {
  ProjectPoint({
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