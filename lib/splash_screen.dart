import 'dart:async';

import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:best_flutter_ui_templates/navigation_home_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController logoController;
  late AnimationController fadeController;
  late Animation<double> logoScaleAnimation;
  late Animation<double> fadeAnimation;

  String titleText = 'GCR HELPER';
  String statusText = 'Preparing your workspace...';
  String detailText = 'Checking app services';
  bool hasError = false;

  @override
  void initState() {
    super.initState();

    logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    fadeController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );

    logoScaleAnimation = CurvedAnimation(
      parent: logoController,
      curve: Curves.elasticOut,
    );

    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeOut,
    );

    logoController.forward();
    fadeController.forward();

    startAppLoading();
  }

  Future<void> startAppLoading() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    updateStatus(
      title: 'Checking Google Account',
      detail: 'Looking for previous sign-in session',
    );

    try {
      final GoogleSignInAccount? account =
      await GoogleLoginService.instance.signInSilently();

      if (account != null) {
        updateStatus(
          title: 'Syncing Classroom',
          detail: 'Fetching courses, assignments and deadlines',
        );

        await ClassroomDataService.instance.preloadClassroomData();
        await ClassroomDataService.instance.preloadClassroomData();


        updateStatus(
          title: 'Classroom Ready',
          detail: 'Your latest study data is loaded',
        );



      } else {
        updateStatus(
          title: 'Guest Mode Ready',
          detail: 'Login later to sync Google Classroom data',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        hasError = true;
        statusText = 'Sync skipped';
        detailText = 'Open Google screen later to reconnect Classroom';
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 850));

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) => NavigationHomeScreen(),
      ),
    );
  }

  void updateStatus({
    required String title,
    required String detail,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      statusText = title;
      detailText = detail;
    });
  }

  @override
  void dispose() {
    logoController.dispose();
    fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLightMode ? Colors.white : AppTheme.nearlyBlack,
      body: SafeArea(
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: <Widget>[
                const Spacer(),
                buildLogo(isLightMode),
                const SizedBox(height: 34),
                buildTitle(isLightMode),
                const SizedBox(height: 34),
                buildStatusCard(isLightMode),
                const Spacer(),
                buildBottomText(isLightMode),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLogo(bool isLightMode) {
    return ScaleTransition(
      scale: logoScaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            height: 142,
            width: 142,
            decoration: BoxDecoration(
              color: const Color(0xFF2633C5).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            height: 108,
            width: 108,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[
                  Color(0xFF2633C5),
                  Color(0xFF6A88E5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF2633C5).withOpacity(0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 56,
            ),
          ),
          Positioned(
            right: 12,
            top: 16,
            child: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: hasError
                    ? const Color(0xFFFFA726)
                    : const Color(0xFF2ECC71),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLightMode ? Colors.white : AppTheme.nearlyBlack,
                  width: 4,
                ),
              ),
              child: Icon(
                hasError ? Icons.info_rounded : Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTitle(bool isLightMode) {
    return Column(
      children: <Widget>[
        Text(
          titleText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: isLightMode ? const Color(0xFF3F3F46) : Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Google Classroom API powered study tracker',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.35,
            color: isLightMode
                ? const Color(0xFF81818A)
                : Colors.white.withOpacity(0.65),
          ),
        ),
      ],
    );
  }

  Widget buildStatusCard(bool isLightMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLightMode ? const Color(0xFFF7F7FA) : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLightMode
              ? const Color(0xFFE8E8EE)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            height: 42,
            width: 42,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    hasError
                        ? const Color(0xFFFFA726)
                        : const Color(0xFF2633C5),
                  ),
                  backgroundColor: isLightMode
                      ? const Color(0xFFE1E1EA)
                      : Colors.white.withOpacity(0.12),
                ),
                Icon(
                  hasError ? Icons.info_outline_rounded : Icons.cloud_sync_rounded,
                  size: 19,
                  color: hasError
                      ? const Color(0xFFFFA726)
                      : const Color(0xFF2633C5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Column(
                key: ValueKey<String>(statusText),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isLightMode
                          ? const Color(0xFF4A4A4A)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    detailText,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.5,
                      height: 1.30,
                      fontWeight: FontWeight.w500,
                      color: isLightMode
                          ? const Color(0xFF7A7A82)
                          : Colors.white.withOpacity(0.62),
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

  Widget buildBottomText(bool isLightMode) {
    return Column(
      children: <Widget>[
        Text(
          'Please wait a moment',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isLightMode
                ? const Color(0xFF4A4A4A)
                : Colors.white.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Your modules will open with synced Classroom data.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: isLightMode
                ? const Color(0xFF8A8A94)
                : Colors.white.withOpacity(0.55),
          ),
        ),
      ],
    );
  }
}