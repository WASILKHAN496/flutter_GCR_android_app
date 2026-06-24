import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/theme_controller.dart';
import 'package:flutter/material.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({
    super.key,
    this.screenIndex,
    this.iconAnimationController,
    this.callBackIndex,
  });

  final AnimationController? iconAnimationController;
  final DrawerIndex? screenIndex;
  final Function(DrawerIndex)? callBackIndex;

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  List<DrawerList> drawerList = <DrawerList>[];

  @override
  void initState() {
    setDrawerListArray();
    super.initState();
  }

  void setDrawerListArray() {
    drawerList = <DrawerList>[
      DrawerList(
        index: DrawerIndex.HOME,
        labelName: 'Dashboard',
        icon: const Icon(Icons.dashboard_rounded),
      ),
      DrawerList(
        index: DrawerIndex.Notifications,
        labelName: 'Notifications',
        icon: const Icon(Icons.notifications_active_rounded),
      ),
      DrawerList(
        index: DrawerIndex.Help,
        labelName: 'Help',
        icon: const Icon(Icons.help_outline_rounded),
      ),
      DrawerList(
        index: DrawerIndex.FeedBack,
        labelName: 'FeedBack',
        icon: const Icon(Icons.feedback_outlined),
      ),
      DrawerList(
        index: DrawerIndex.Invite,
        labelName: 'Invite Friend',
        icon: const Icon(Icons.group_add_rounded),
      ),
      DrawerList(
        index: DrawerIndex.Share,
        labelName: 'Rate the app',
        icon: const Icon(Icons.star_rate_rounded),
      ),
      DrawerList(
        index: DrawerIndex.About,
        labelName: 'About Us',
        icon: const Icon(Icons.info_outline_rounded),
      ),
      DrawerList(
        index: DrawerIndex.Profile,
        labelName: 'Profile',
        icon: const Icon(Icons.person_rounded),
      ),
      DrawerList(
        index: DrawerIndex.Settings,
        labelName: 'Setting',
        icon: const Icon(Icons.settings_rounded),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor:
      isLightMode ? AppTheme.notWhite.withOpacity(0.96) : AppTheme.nearlyBlack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          buildProfileHeader(isLightMode),
          Divider(
            height: 1,
            color: AppTheme.grey.withOpacity(0.35),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: drawerList.length,
              itemBuilder: (BuildContext context, int index) {
                return drawerItem(drawerList[index], isLightMode);
              },
            ),
          ),
          Divider(
            height: 1,
            color: AppTheme.grey.withOpacity(0.35),
          ),
          buildThemeToggle(isLightMode),
          buildManageAccount(isLightMode),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget buildProfileHeader(bool isLightMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 42),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedBuilder(
              animation: widget.iconAnimationController!,
              builder: (BuildContext context, Widget? child) {
                return ScaleTransition(
                  scale: AlwaysStoppedAnimation<double>(
                    1.0 - (widget.iconAnimationController!.value) * 0.2,
                  ),
                  child: RotationTransition(
                    turns: AlwaysStoppedAnimation<double>(
                      Tween<double>(begin: 0.0, end: 24.0)
                          .animate(
                        CurvedAnimation(
                          parent: widget.iconAnimationController!,
                          curve: Curves.fastOutSlowIn,
                        ),
                      )
                          .value /
                          360,
                    ),
                    child: Container(
                      height: 108,
                      width: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppTheme.grey.withOpacity(0.45),
                            offset: const Offset(2, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                        const BorderRadius.all(Radius.circular(54)),
                        child: Image.asset(
                          'assets/images/userImage.png',
                          fit: BoxFit.cover,
                          errorBuilder: (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                              ) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF2633C5),
                                    Color(0xFF6A88E5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 54,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'GCR HELPER',
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w800,
                color: isLightMode ? AppTheme.darkText : AppTheme.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Student Classroom Assistant',
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w600,
                color: isLightMode
                    ? AppTheme.grey
                    : AppTheme.white.withOpacity(0.65),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.13),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Google Classroom Tracker',
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2ECC71),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(DrawerList listData, bool isLightMode) {
    final bool selected = widget.screenIndex == listData.index;
    final Color selectedColor = const Color(0xFF2633C5);
    final Color normalColor =
    isLightMode ? AppTheme.nearlyBlack : AppTheme.white.withOpacity(0.82);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: selectedColor.withOpacity(0.08),
        highlightColor: Colors.transparent,
        onTap: () {
          navigationToScreen(listData.index!);
        },
        child: Stack(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected ? selectedColor : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    listData.icon?.icon,
                    color: selected ? selectedColor : normalColor,
                    size: 23,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      listData.labelName,
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15.5,
                        color: selected ? selectedColor : normalColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            selected
                ? AnimatedBuilder(
              animation: widget.iconAnimationController!,
              builder: (BuildContext context, Widget? child) {
                return Transform(
                  transform: Matrix4.translationValues(
                    (MediaQuery.of(context).size.width * 0.75 - 64) *
                        (1.0 -
                            widget.iconAnimationController!.value -
                            1.0),
                    0,
                    0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Container(
                      width:
                      MediaQuery.of(context).size.width * 0.75 - 64,
                      height: 46,
                      decoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.13),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget buildThemeToggle(bool isLightMode) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (BuildContext context, ThemeMode mode, Widget? child) {
        final bool isDark = mode == ThemeMode.dark;

        return Padding(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLightMode
                  ? Colors.white.withOpacity(0.65)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark
                      ? const Color(0xFFFFA726)
                      : const Color(0xFF2633C5),
                  size: 23,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Theme Changer',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.82,
                  child: Switch(
                    value: isDark,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF2633C5),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppTheme.grey.withOpacity(0.35),
                    onChanged: (bool value) {
                      ThemeController.toggleTheme(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildManageAccount(bool isLightMode) {
    return ListTile(
      title: Text(
        'Connect / Manage Account',
        style: TextStyle(
          fontFamily: AppTheme.fontName,
          fontWeight: FontWeight.w700,
          fontSize: 15.5,
          color: isLightMode ? AppTheme.darkText : AppTheme.white,
        ),
      ),
      trailing: const Icon(
        Icons.cloud_sync_rounded,
        color: Color(0xFF2ECC71),
      ),
      onTap: () {
        navigationToScreen(DrawerIndex.GoogleAccount);
      },
    );
  }

  Future<void> navigationToScreen(DrawerIndex indexScreen) async {
    widget.callBackIndex?.call(indexScreen);
  }
}

enum DrawerIndex {
  HOME,
  Notifications,
  Help,
  FeedBack,
  Invite,
  Share,
  About,
  Profile,
  Settings,
  GoogleAccount,

  // Kept for internal project navigation if needed later.
  Courses,
  Tasks,
  Deadlines,
  Workload,
}

class DrawerList {
  DrawerList({
    this.labelName = '',
    this.icon,
    this.index,
  });

  String labelName;
  Icon? icon;
  DrawerIndex? index;
}