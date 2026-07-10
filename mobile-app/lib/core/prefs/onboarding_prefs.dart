import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has completed first-run onboarding.
class OnboardingPrefs {
  OnboardingPrefs(this._prefs);

  static const _key = 'xm_onboarding_complete';

  final SharedPreferences _prefs;

  static Future<OnboardingPrefs> create() async {
    return OnboardingPrefs(await SharedPreferences.getInstance());
  }

  bool get isComplete => _prefs.getBool(_key) ?? false;

  Future<void> markComplete() => _prefs.setBool(_key, true);
}
