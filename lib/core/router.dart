import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/auth/auth_provider.dart';
import 'package:manito/features/auth/kakao_login_webview.dart';
import 'package:manito/features/fcm/fcm_provider.dart';
import 'package:manito/features/manito/manito.dart';
import 'package:manito/screens/manito/album_screen.dart';
import 'package:manito/screens/manito/manito_post_screen.dart';
import 'package:manito/features/missions/mission.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/screens/bottom_nav.dart';
import 'package:manito/screens/friends/friends_blacklist_screen.dart';
import 'package:manito/screens/friends/friends_detail_screen.dart';
import 'package:manito/screens/friends/friends_edit_screen.dart';
import 'package:manito/screens/friends/friends_request_screen.dart';
import 'package:manito/screens/friends/friends_search_screen.dart';
import 'package:manito/screens/login_screen.dart';
import 'package:manito/screens/manito/manito_propose_screen.dart';
import 'package:manito/screens/missions/mission_create_screen.dart';
import 'package:manito/screens/missions/mission_friends_search_screen.dart';
import 'package:manito/screens/missions/mission_guess_screen.dart';
import 'package:manito/screens/posts/post_detail_screen.dart';
import 'package:manito/screens/profile_edit_screen.dart';
import 'package:manito/screens/setting_screen.dart';
import 'package:manito/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  // ✅ public 메서드로 래핑
  void refresh() {
    notifyListeners(); // 클래스 내부에서는 사용 가능
  }
}

final goRouterRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier();

  ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (prev, next) {
    Future.microtask(() => notifier.refresh()); // ✅ public 메서드 호출
  });

  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(fcmListenerProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: ref.read(goRouterRefreshProvider),
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      return authState.when(
        data: (auth) {
          FlutterNativeSplash.remove();
          final isLoggedIn = auth.session?.user != null;
          final location = state.matchedLocation;
          if (isLoggedIn) {
            if (location == '/splash' || location == '/login') {
              return '/bottom_nav';
            }
            return null;
          } else {
            if (location == '/login' || location == '/kakao_login') {
              return null;
            }
            return '/login';
          }
        },
        loading: () {
          return state.matchedLocation == '/splash' ? null : '/splash';
        },
        error: (error, stackTrace) => null,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/bottom_nav',
        name: 'bottom_nav',
        builder: (context, state) => const BottomNav(),
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
        path: '/album',
        name: 'album',
        builder: (context, state) {
          final ManitoAccept manitoAccept = state.extra as ManitoAccept;
          return AlbumScreen(manitoAccept: manitoAccept);
        },
      ),
      GoRoute(
        path: '/setting',
        name: 'setting',
        builder: (context, state) => const SettingScreen(),
      ),
      GoRoute(
        path: '/profile_modify',
        name: 'profileModify',
        builder: (context, state) {
          final canGoBack = state.extra as bool? ?? true;
          return ProfileEditScreen(canGoback: canGoBack);
        },
      ),
      // GoRoute(
      //   path: '/post_detail',
      //   name: 'postDetail',
      //   builder: (context, state) {
      //     final args = state.extra as Map<String, dynamic>;
      //     final Post post = args['post'];
      //     final FriendProfile manitoProfile = args['manitoProfile'];
      //     final FriendProfile creatorProfile = args['creatorProfile'];
      //     return PostDetailScreen(
      //       post: post,
      //       manitoProfile: manitoProfile,
      //       creatorProfile: creatorProfile,
      //     );
      //   },
      // ),
      GoRoute(
        path: '/post/:postId',
        name: 'postDetail',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/mission_create',
        name: 'missionCreate',
        builder: (context, state) => const MissionCreateScreen(),
      ),
      GoRoute(
        path: '/mission_friends_search',
        name: 'missionFriendsSearch',
        builder: (context, state) => const MissionFriendsSearchScreen(),
      ),
      GoRoute(
        path: '/mission_guess',
        name: 'missionGuess',
        builder: (context, state) {
          final MyMission mission = state.extra as MyMission;
          return MissionGuessScreen(mission: mission);
        },
      ),
      GoRoute(
        path: '/manito_propose',
        name: 'manitoPropose',
        builder: (context, state) {
          final ManitoPropose propose = state.extra as ManitoPropose;
          return ManitoProposeScreen(propose: propose);
        },
      ),
      GoRoute(
        path: '/manito_post',
        name: 'manitoPost',
        builder: (context, state) {
          final ManitoAccept manitoAccept = state.extra as ManitoAccept;
          return ManitoPostScreen(manitoAccept: manitoAccept);
        },
      ),
      GoRoute(
        path: '/friends_search',
        name: 'friendsSearch',
        builder: (context, state) => const FriendsSearchScreen(),
      ),
      GoRoute(
        path: '/friends_request',
        name: 'friendsRequest',
        builder: (context, state) => const FriendsRequestScreen(),
      ),
      GoRoute(
        path: '/friends_blacklist',
        name: 'friendsBlacklist',
        builder: (context, state) => const FriendsBlacklistScreen(),
      ),
      GoRoute(
        path: '/friends_edit',
        name: 'friendsEdit',
        builder: (context, state) {
          final FriendProfile friendProfile = state.extra as FriendProfile;
          return FriendsEditScreen(friendProfile: friendProfile);
        },
      ),
      // GoRoute(
      //   path: '/friends_detail',
      //   name: 'friendsDetail',
      //   builder: (context, state) {
      //     final FriendProfile friendProfile = state.extra as FriendProfile;
      //     return FriendsDetailScreen(friendProfile: friendProfile);
      //   },
      // ),
      GoRoute(
        path: '/friends_detail/:friendId',
        name: 'friendsDetail',
        builder: (context, state) {
          final friendId = state.pathParameters['friendId']!;
          return FriendsDetailScreen(friendId: friendId);
        },
      ),
    ],
  );
});
