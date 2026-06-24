import 'package:shared_preferences/shared_preferences.dart';

class AppGuideService {
  AppGuideService._internal();

  static final AppGuideService instance = AppGuideService._internal();

  static const String _welcomeGuideSeenKey = 'welcome_guide_seen';

  Future<bool> shouldShowWelcomeGuide() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return !(prefs.getBool(_welcomeGuideSeenKey) ?? false);
  }

  Future<void> markWelcomeGuideSeen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_welcomeGuideSeenKey, true);
  }

  Future<void> resetWelcomeGuide() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove(_welcomeGuideSeenKey);
  }
}