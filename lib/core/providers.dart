import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/constants/app_constants.dart';
import 'package:manito/i18n/strings.g.dart';
import 'models/models.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabase = ref.watch(supabaseProvider);
  final response = await supabase
      .from('users')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();

  if (response == null) return null;
  return UserModel.fromJson(response);
});

final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, AppLocale>((ref) {
  return AppLocaleNotifier();
});

class AppLocaleNotifier extends StateNotifier<AppLocale> {
  static const String _key = 'selected_app_locale';

  AppLocaleNotifier() : super(LocaleSettings.currentLocale) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_key);
      if (savedCode != null) {
        final locale = AppLocaleUtils.parse(savedCode);
        LocaleSettings.setLocale(locale);
        state = locale;
      }
    } catch (_) {}
  }

  Future<void> setLocale(AppLocale newLocale) async {
    LocaleSettings.setLocale(newLocale);
    state = newLocale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, newLocale.languageCode);
    } catch (_) {}
  }
}

final languageCodeProvider = Provider<String>((ref) {
  final locale = ref.watch(appLocaleProvider);
  return locale.languageCode;
});

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  } catch (e) {
    return AppConstants.versionFallback;
  }
});
