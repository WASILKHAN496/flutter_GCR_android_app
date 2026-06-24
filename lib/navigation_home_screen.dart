import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/courses_screen.dart';
import 'package:best_flutter_ui_templates/custom_drawer/drawer_user_controller.dart';
import 'package:best_flutter_ui_templates/custom_drawer/home_drawer.dart';
import 'package:best_flutter_ui_templates/deadlines_screen.dart';
import 'package:best_flutter_ui_templates/feedback_screen.dart';
import 'package:best_flutter_ui_templates/google_account_screen.dart';
import 'package:best_flutter_ui_templates/help_screen.dart';
import 'package:best_flutter_ui_templates/home_screen.dart';
import 'package:best_flutter_ui_templates/invite_friend_screen.dart';
import 'package:best_flutter_ui_templates/notifications_screen.dart';
import 'package:best_flutter_ui_templates/profile_screen.dart';
import 'package:best_flutter_ui_templates/settings_screen.dart';
import 'package:best_flutter_ui_templates/tasks_screen.dart';
import 'package:best_flutter_ui_templates/workload_screen.dart';
import 'package:flutter/material.dart';
import 'package:best_flutter_ui_templates/invite_friend_screen.dart';

class NavigationHomeScreen extends StatefulWidget {
  const NavigationHomeScreen({super.key});

  @override
  State<NavigationHomeScreen> createState() => _NavigationHomeScreenState();
}

class _NavigationHomeScreenState extends State<NavigationHomeScreen> {
  Widget? screenView;
  DrawerIndex? drawerIndex;

  @override
  void initState() {
    super.initState();
    drawerIndex = DrawerIndex.HOME;
    screenView = const MyHomePage();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Container(
      color: isLightMode ? AppTheme.nearlyWhite : AppTheme.nearlyBlack,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          backgroundColor:
          isLightMode ? AppTheme.nearlyWhite : AppTheme.nearlyBlack,
          body: DrawerUserController(
            screenIndex: drawerIndex,
            drawerWidth: MediaQuery.of(context).size.width * 0.75,
            onDrawerCall: (DrawerIndex drawerIndexData) {
              changeIndex(drawerIndexData);
            },
            screenView: screenView,
          ),
        ),
      ),
    );
  }

  void changeIndex(DrawerIndex drawerIndexData) {
    drawerIndex = drawerIndexData;

    if (drawerIndex == DrawerIndex.HOME) {
      setState(() {
        screenView = const MyHomePage();
      });
    } else if (drawerIndex == DrawerIndex.Help) {
      setState(() {
        screenView = const HelpScreen();
      });
    } else if (drawerIndex == DrawerIndex.FeedBack) {
      setState(() {
        screenView = const FeedbackScreen();
      });
    } else if (drawerIndex == DrawerIndex.Invite) {
      setState(() {
        screenView = const InviteFriend();
      });
    } else if (drawerIndex == DrawerIndex.Share) {
      showSnackMessage(
        'Rate the app feature can be connected before publishing.',
      );
    } else if (drawerIndex == DrawerIndex.About) {
      showAboutAppDialog();
    } else if (drawerIndex == DrawerIndex.Profile) {
      setState(() {
        screenView = const ProfileScreen();
      });
    } else if (drawerIndex == DrawerIndex.Settings) {
      setState(() {
        screenView = const SettingsScreen();
      });
    } else if (drawerIndex == DrawerIndex.GoogleAccount) {
      setState(() {
        screenView = const GoogleAccountScreen();
      });
    } else if (drawerIndex == DrawerIndex.Courses) {
      setState(() {
        screenView = const CoursesScreen();
      });
    } else if (drawerIndex == DrawerIndex.Tasks) {
      setState(() {
        screenView = const TasksScreen(initialFilter: 'All');
      });
    } else if (drawerIndex == DrawerIndex.Deadlines) {
      setState(() {
        screenView = const DeadlinesScreen();
      });
    } else if (drawerIndex == DrawerIndex.Workload) {
      setState(() {
        screenView = const WorkloadScreen();
      });
    } else if (drawerIndex == DrawerIndex.Notifications) {
      setState(() {
        screenView = const NotificationsScreen();
      });
    } else {
      setState(() {
        drawerIndex = DrawerIndex.HOME;
        screenView = const MyHomePage();
      });
    }
  }

  void showSnackMessage(String message) {
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

  void showAboutAppDialog() {
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
          'GCR HELPER is a Google Classroom helper app for students. '
              'It tracks courses, tasks, deadlines, workload, reminders, profile, '
              'settings and Google account sync using Google Classroom API.',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}