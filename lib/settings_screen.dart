import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/google_account_screen.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:best_flutter_ui_templates/services/notification_service.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  final ScrollController scrollController = ScrollController();

  bool isLoading = true;

  bool classroomSync = true;
  bool dueTodayNotifications = true;
  bool dueSoonNotifications = true;
  bool lateNotifications = true;
  bool syncCompleteNotifications = false;
  bool reminderVibration = true;
  bool weeklySummary = true;
  bool darkModePreference = false;

  String errorText = '';
  GoogleSignInAccount? account;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    animationController.forward();
    loadNotificationSettings();
    loadAccount();
  }
  Future<void> loadNotificationSettings() async {
    final NotificationPreferences preferences =
    await NotificationService.instance.getPreferences();

    if (!mounted) {
      return;
    }

    setState(() {
      dueTodayNotifications = preferences.dueTodayEnabled;
      dueSoonNotifications = preferences.dueSoonEnabled;
      lateNotifications = preferences.lateEnabled;
      syncCompleteNotifications = preferences.syncCompleteEnabled;
      reminderVibration = preferences.vibrationEnabled;
    });
  }

  Future<void> saveNotificationSetting({
    required String key,
    required bool value,
  }) async {
    await NotificationService.instance.savePreference(
      key: key,
      value: value,
    );
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
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorText = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> connectGoogle() async {
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

      await ClassroomDataService.instance.refreshAllData();

      if (!mounted) {
        return;
      }

      setState(() {
        account = user;
        isLoading = false;
      });

      showMessage('Google Classroom connected and synced.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorText = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> disconnectGoogle() async {
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
      isLoading = false;
    });

    showMessage('Google account disconnected.');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get isConnected => account != null;

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
            padding: const EdgeInsets.only(bottom: 26),
            children: <Widget>[
              buildTopBar(isLightMode),
              const SizedBox(height: 18),
              buildTitle(isLightMode),
              const SizedBox(height: 24),
              buildAccountSection(isLightMode),
              buildDivider(isLightMode),
              buildClassroomSection(isLightMode),
              buildDivider(isLightMode),
              buildNotificationSection(isLightMode),
              buildDivider(isLightMode),
              buildAppSection(isLightMode),
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
            onTap: loadAccount,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.refresh_rounded,
                color: isLightMode ? const Color(0xFF4A4A4A) : Colors.white,
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
        'Settings',
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
          title: 'GOOGLE CLASSROOM ACCOUNT',
          icon: Icons.cloud_sync_outlined,
          isLightMode: isLightMode,
        ),
        accountTile(isLightMode),
        settingArrowTile(
          title: 'Manage Google Account',
          subtitle: isConnected
              ? 'Open account screen and fetch Classroom data.'
              : 'Login to sync courses, assignments and deadlines.',
          isLightMode: isLightMode,
          onTap: () {
            Navigator.push<dynamic>(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => const GoogleAccountScreen(),
              ),
            ).then((_) => loadAccount());
          },
        ),
        settingArrowTile(
          title: isConnected ? 'Disconnect Google Account' : 'Connect Google Account',
          subtitle: isConnected
              ? 'Logout from current Classroom account.'
              : 'Sign in with your student Google account.',
          isLightMode: isLightMode,
          textColor: isConnected ? const Color(0xFFEF5350) : null,
          onTap: isConnected ? disconnectGoogle : connectGoogle,
        ),
      ],
    );
  }

  Widget accountTile(bool isLightMode) {
    return Padding(
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
                    color: isLightMode
                        ? const Color(0xFF3F3F46)
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account?.email ?? 'Google Classroom sync is not active.',
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
            isConnected ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: isConnected ? const Color(0xFF2ECC71) : const Color(0xFFFFA726),
            size: 25,
          ),
        ],
      ),
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

  Widget buildClassroomSection(bool isLightMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionHeader(
          title: 'CLASSROOM SYNC',
          icon: Icons.school_outlined,
          isLightMode: isLightMode,
        ),
        settingSwitchTile(
          title: 'Classroom Sync',
          subtitle: 'Automatically fetch courses, assignments and deadlines.',
          value: classroomSync,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              classroomSync = value;
            });
          },
        ),
        settingSwitchTile(
          title: 'Auto Refresh Data',
          subtitle: 'Refresh Classroom data when app screens are opened.',
          value: autoRefreshValue,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              classroomSync = value;
            });
          },
        ),
        settingArrowTile(
          title: 'Sync Now',
          subtitle: 'Refresh Google Classroom connection and account status.',
          isLightMode: isLightMode,
          onTap: loadAccount,
        ),
      ],
    );
  }

  bool get autoRefreshValue => classroomSync;

  Widget buildNotificationSection(bool isLightMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionHeader(
          title: 'NOTIFICATION SETTINGS',
          icon: Icons.notifications_none_rounded,
          isLightMode: isLightMode,
        ),
        settingSwitchTile(
          title: 'Due Today Notifications',
          subtitle: 'Notify when assignments are due today.',
          value: dueTodayNotifications,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              dueTodayNotifications = value;
            });

            saveNotificationSetting(
              key: NotificationService.dueTodayEnabledKey,
              value: value,
            );
          },
        ),
        settingSwitchTile(
          title: 'Due Soon Notifications',
          subtitle: 'Notify when assignments are due within the next 3 days.',
          value: dueSoonNotifications,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              dueSoonNotifications = value;
            });

            saveNotificationSetting(
              key: NotificationService.dueSoonEnabledKey,
              value: value,
            );
          },
        ),
        settingSwitchTile(
          title: 'Late Assignment Alerts',
          subtitle: 'Notify when assignments are late and not submitted.',
          value: lateNotifications,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              lateNotifications = value;
            });

            saveNotificationSetting(
              key: NotificationService.lateEnabledKey,
              value: value,
            );
          },
        ),
        settingSwitchTile(
          title: 'Sync Complete Notification',
          subtitle: 'Notify when Classroom sync completes successfully.',
          value: syncCompleteNotifications,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              syncCompleteNotifications = value;
            });

            saveNotificationSetting(
              key: NotificationService.syncCompleteEnabledKey,
              value: value,
            );
          },
        ),
        settingSwitchTile(
          title: 'Vibrate',
          subtitle: 'Vibrate when a notification is shown.',
          value: reminderVibration,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              reminderVibration = value;
            });

            saveNotificationSetting(
              key: NotificationService.vibrationEnabledKey,
              value: value,
            );
          },
        ),
      ],
    );
  }

  Widget buildAppSection(bool isLightMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionHeader(
          title: 'APP PREFERENCES',
          icon: Icons.tune_rounded,
          isLightMode: isLightMode,
        ),
        settingSwitchTile(
          title: 'Weekly Summary',
          subtitle: 'Show a weekly overview of workload and deadlines.',
          value: weeklySummary,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              weeklySummary = value;
            });
          },
        ),
        settingSwitchTile(
          title: 'Dark Mode Preference',
          subtitle: 'Use system theme from app theme controller.',
          value: darkModePreference,
          isLightMode: isLightMode,
          onChanged: (bool value) {
            setState(() {
              darkModePreference = value;
            });
            showMessage('Theme is controlled from main app theme settings.');
          },
        ),
        settingArrowTile(
          title: 'About Project',
          subtitle: 'Student Classroom Tracker with Google Classroom API.',
          isLightMode: isLightMode,
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'GCR HELPER',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(
                Icons.school_rounded,
                color: Color(0xFF2633C5),
                size: 38,
              ),
              children: const <Widget>[
                Text(
                  'This project tracks Google Classroom courses, assignments, deadlines and workload using Google Classroom API.',
                ),
              ],
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
                const Positioned(
                  right: 3,
                  top: 0,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: Color(0xFF2ECC71),
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