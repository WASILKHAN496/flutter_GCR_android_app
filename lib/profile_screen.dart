import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  final ScrollController scrollController = ScrollController();

  final TextEditingController nameController =
  TextEditingController(text: 'Student Name');
  final TextEditingController emailController =
  TextEditingController(text: 'student@gmail.com');
  final TextEditingController departmentController =
  TextEditingController(text: 'Computer Science');
  final TextEditingController semesterController =
  TextEditingController(text: '6th Semester');
  final TextEditingController rollNoController =
  TextEditingController(text: 'CS-2026-001');

  double topBarOpacity = 0.0;
  bool editMode = false;
  bool googleConnected = false;

  GoogleSignInAccount? googleAccount;

  final List<ProfileStat> stats = const <ProfileStat>[
    ProfileStat(
      title: 'Courses',
      value: '4',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF42A5F5),
    ),
    ProfileStat(
      title: 'Pending',
      value: '5',
      icon: Icons.pending_actions_rounded,
      color: Color(0xFFFFA726),
    ),
    ProfileStat(
      title: 'Submitted',
      value: '12',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF66BB6A),
    ),
  ];

  final List<ProfileSummary> summaries = const <ProfileSummary>[
    ProfileSummary(
      title: 'Active Courses',
      subtitle: '4 classroom courses',
      icon: Icons.school_rounded,
      color: Color(0xFF42A5F5),
    ),
    ProfileSummary(
      title: 'Deadline Alerts',
      subtitle: '7 upcoming reminders',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFFEF5350),
    ),
    ProfileSummary(
      title: 'Workload Level',
      subtitle: 'Medium this week',
      icon: Icons.insights_rounded,
      color: Color(0xFF26A69A),
    ),
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

    loadGoogleAccount();
  }

  Future<void> loadGoogleAccount() async {
    final GoogleSignInAccount? user =
    await GoogleLoginService.instance.signInSilently();

    if (!mounted) {
      return;
    }

    setState(() {
      googleAccount = user;

      if (user != null) {
        nameController.text = user.displayName ?? 'Student';
        emailController.text = user.email;
        googleConnected = true;
      } else {
        googleConnected = false;
      }
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

  @override
  void dispose() {
    animationController.dispose();
    scrollController.removeListener(updateTopBarOpacity);
    scrollController.dispose();
    nameController.dispose();
    emailController.dispose();
    departmentController.dispose();
    semesterController.dispose();
    rollNoController.dispose();
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
        animatedWidget(1, buildStatsRow(isLightMode)),
        animatedWidget(
          2,
          buildSectionTitle(
            title: 'Student Information',
            subtitle: editMode ? 'Editing' : 'Profile',
            isLightMode: isLightMode,
          ),
        ),
        animatedWidget(3, buildStudentInfoCard(isLightMode)),
        animatedWidget(
          4,
          buildSectionTitle(
            title: 'Academic Summary',
            subtitle: 'This semester',
            isLightMode: isLightMode,
          ),
        ),
        animatedWidget(5, buildSummaryList(isLightMode)),
        animatedWidget(6, buildGoogleAccountCard(isLightMode)),
        animatedWidget(7, buildActionButtons(isLightMode)),
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
                        'Profile',
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
                      icon:
                      editMode ? Icons.check_rounded : Icons.edit_rounded,
                      isLightMode: isLightMode,
                      onTap: toggleEditMode,
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
                    googleConnected ? 'Google account' : 'Welcome back',
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
                    nameController.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    googleConnected
                        ? emailController.text
                        : '${departmentController.text} • ${semesterController.text}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            profileIconBox(),
          ],
        ),
      ),
    );
  }

  Widget profileIconBox() {
    const Color color = Color(0xFF42A5F5);

    if (googleAccount?.photoUrl != null) {
      return Container(
        height: 86,
        width: 86,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.network(
              googleAccount!.photoUrl!,
              height: 58,
              width: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => defaultProfileIcon(color),
            ),
          ),
        ),
      );
    }

    return defaultProfileIcon(color);
  }

  Widget defaultProfileIcon(Color color) {
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
            Icons.person_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget buildStatsRow(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Row(
        children: stats.map((ProfileStat stat) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: statBox(stat, isLightMode),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget statBox(ProfileStat stat, bool isLightMode) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardShadow(isLightMode),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            stat.icon,
            color: stat.color,
            size: 24,
          ),
          const Spacer(),
          Text(
            stat.value,
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: stat.color,
            ),
          ),
          Text(
            stat.title,
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

  Widget buildStudentInfoCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Column(
          children: <Widget>[
            profileField(
              label: 'Name',
              icon: Icons.person_rounded,
              controller: nameController,
              isLightMode: isLightMode,
            ),
            dividerLine(isLightMode),
            profileField(
              label: 'Email',
              icon: Icons.email_rounded,
              controller: emailController,
              isLightMode: isLightMode,
            ),
            dividerLine(isLightMode),
            profileField(
              label: 'Department',
              icon: Icons.apartment_rounded,
              controller: departmentController,
              isLightMode: isLightMode,
            ),
            dividerLine(isLightMode),
            profileField(
              label: 'Semester',
              icon: Icons.school_rounded,
              controller: semesterController,
              isLightMode: isLightMode,
            ),
            dividerLine(isLightMode),
            profileField(
              label: 'Roll No',
              icon: Icons.badge_rounded,
              controller: rollNoController,
              isLightMode: isLightMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget profileField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isLightMode,
  }) {
    return Row(
      children: <Widget>[
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF42A5F5).withOpacity(0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF42A5F5),
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: editMode
              ? TextField(
            controller: controller,
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isLightMode ? AppTheme.darkText : AppTheme.white,
            ),
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontName,
                color: isLightMode
                    ? AppTheme.grey
                    : AppTheme.white.withOpacity(0.60),
              ),
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 11.5,
                  color: isLightMode
                      ? AppTheme.grey
                      : AppTheme.white.withOpacity(0.60),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color:
                  isLightMode ? AppTheme.darkText : AppTheme.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget dividerLine(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: isLightMode
            ? AppTheme.grey.withOpacity(0.16)
            : Colors.white.withOpacity(0.10),
      ),
    );
  }

  Widget buildSummaryList(bool isLightMode) {
    return Column(
      children: summaries.map((ProfileSummary item) {
        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
          child: SummaryCard(
            item: item,
            isLightMode: isLightMode,
          ),
        );
      }).toList(),
    );
  }

  Widget buildGoogleAccountCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: googleConnected
                    ? const Color(0xFF66BB6A).withOpacity(0.13)
                    : const Color(0xFFEF5350).withOpacity(0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                googleConnected
                    ? Icons.verified_user_rounded
                    : Icons.person_add_alt_rounded,
                color: googleConnected
                    ? const Color(0xFF66BB6A)
                    : const Color(0xFFEF5350),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Google Account',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    googleConnected
                        ? 'Connected: ${emailController.text}'
                        : 'Not connected',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12,
                      color: googleConnected
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFFEF5350),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              googleConnected
                  ? Icons.check_circle_rounded
                  : Icons.info_rounded,
              color: googleConnected
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFFFA726),
            ),
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
              onTap: toggleEditMode,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color:
                  isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: cardShadow(isLightMode),
                ),
                child: Center(
                  child: Text(
                    editMode ? 'Cancel Edit' : 'Edit Profile',
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
              onTap: saveProfile,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xFF00AEEF),
                      Color(0xFF2633C5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Save Profile',
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

  void toggleEditMode() {
    setState(() {
      editMode = !editMode;
    });
  }

  void saveProfile() {
    setState(() {
      editMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved successfully.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<BoxShadow> cardShadow(bool isLightMode) {
    return <BoxShadow>[
      BoxShadow(
        color: isLightMode
            ? AppTheme.grey.withOpacity(0.14)
            : Colors.black.withOpacity(0.22),
        offset: const Offset(1, 3),
        blurRadius: 9,
      ),
    ];
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.item,
    required this.isLightMode,
  });

  final ProfileSummary item;
  final bool isLightMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: <Widget>[
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.13),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isLightMode ? AppTheme.darkText : AppTheme.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
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
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: isLightMode ? AppTheme.grey : Colors.white54,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class ProfileStat {
  const ProfileStat({
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

class ProfileSummary {
  const ProfileSummary({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}