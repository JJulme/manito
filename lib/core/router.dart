import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/util/app_logger.dart';

import 'package:manito/features/auth/presentation/auth_provider.dart';
import 'package:manito/features/auth/presentation/screens/kakao_login_webview.dart';
import 'package:manito/features/auth/presentation/screens/login_screen.dart';
import 'package:manito/features/auth/presentation/screens/splash_screen.dart';
import 'package:manito/features/feed/presentation/screens/result_feed_screen.dart';
import 'package:manito/features/friends/presentation/screens/add_friend_screen.dart';
import 'package:manito/features/friends/presentation/screens/invite_friends_screen.dart';
import 'package:manito/features/game/presentation/screens/main_play_dashboard_screen.dart';
import 'package:manito/features/main/main_nav_screen.dart';
import 'package:manito/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:manito/features/profile/presentation/screens/profile_screen.dart';
import 'package:manito/features/rooms/presentation/screens/group_lobby_screen.dart';
import 'package:manito/features/settings/presentation/screens/settings_screen.dart';
import 'package:manito/features/setup/presentation/screens/mission_setup_screen.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final goRouterRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier();

  ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (prev, next) {
    Future.microtask(() => notifier.refresh());
  });

  ref.listen<AsyncValue<UserModel?>>(currentUserProfileProvider, (prev, next) {
    Future.microtask(() => notifier.refresh());
  });

  return notifier;
});

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: ref.read(goRouterRefreshProvider),
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      return authState.when(
        data: (auth) {
          FlutterNativeSplash.remove();
          final isLoggedIn = auth.session?.user != null;
          final location = state.matchedLocation;

          if (!isLoggedIn) {
            if (location == '/login' || location == '/kakao_login') {
              return null;
            }
            AppLogger.i('User not logged in, redirecting: $location -> /login', tag: 'ROUTER');
            return '/login';
          }

          // User is logged in: Check profile completeness
          final profileAsync = ref.read(currentUserProfileProvider);
          return profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return location == '/splash' ? null : '/splash';
              }

              final isComplete = profile.isProfileComplete;
              if (!isComplete) {
                if (location != '/edit_profile') {
                  AppLogger.w('Profile incomplete for ${profile.userId}, forcing redirect to /edit_profile', tag: 'ROUTER');
                  return '/edit_profile';
                }
                return null;
              }

              // Profile is complete!
              if (location == '/splash' || location == '/login' || location == '/edit_profile') {
                AppLogger.i('Profile complete, redirecting: $location -> /bottom_nav2', tag: 'ROUTER');
                return '/bottom_nav2';
              }
              return null;
            },
            loading: () {
              return location == '/splash' ? null : '/splash';
            },
            error: (error, stackTrace) {
              AppLogger.e('Error loading profile in router: $error', tag: 'ROUTER', error: error, stackTrace: stackTrace);
              return null;
            },
          );
        },
        loading: () {
          return state.matchedLocation == '/splash' ? null : '/splash';
        },
        error: (error, stackTrace) {
          AppLogger.e('Router auth state error: $error', tag: 'ROUTER', error: error, stackTrace: stackTrace);
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'root',
        redirect: (_, __) => '/bottom_nav2',
      ),
      GoRoute(
        path: '/bottom_nav2',
        name: 'bottom_nav2',
        builder: (context, state) => const MainNavScreen(),
      ),
      GoRoute(
        path: '/add_friend',
        name: 'addFriend',
        builder: (context, state) => const AddFriendScreen(),
      ),
      GoRoute(
        path: '/invite_friends',
        name: 'inviteFriends',
        builder: (context, state) => const InviteFriendsScreen(),
      ),
      GoRoute(
        path: '/lobby/:roomId',
        name: 'lobby',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return GroupLobbyScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/mission_setup/:roomId',
        name: 'missionSetup',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return MissionSetupScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/game/:roomId',
        name: 'game',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return MainPlayDashboardScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/result_feed/:roomId',
        name: 'resultFeed',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return ResultFeedScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/kakao_login',
        name: 'kakaoLogin',
        builder: (context, state) => const KakaoLoginWebview(),
      ),
      GoRoute(
        path: '/setting',
        name: 'setting',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit_profile',
        name: 'editProfile',
        builder: (context, state) {
          final isFirstSetup = state.extra as bool? ?? false;
          return EditProfileScreen(isFirstSetup: isFirstSetup);
        },
      ),
    ],
  );
});
