import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/arch_new/features/auth/auth_provider.dart';
import 'package:manito/arch_new/features/auth/kakao_login_webview.dart';
import 'package:manito/arch_new/features/fcm/fcm_provider.dart';
import 'package:manito/arch_new/features/manito/manito.dart';
import 'package:manito/arch_new/screens/manito/album_screen.dart';
import 'package:manito/arch_new/screens/manito/manito_post_screen.dart';
import 'package:manito/arch_new/features/missions/mission.dart';
import 'package:manito/arch_new/features/posts/post.dart';
import 'package:manito/arch_new/features/profiles/profile.dart';
import 'package:manito/arch_new/screens/bottom_nav.dart';
import 'package:manito/arch_new/screens/friends/friends_blacklist_screen.dart';
import 'package:manito/arch_new/screens/friends/friends_detail_screen.dart';
import 'package:manito/arch_new/screens/friends/friends_edit_screen.dart';
import 'package:manito/arch_new/screens/friends/friends_request_screen.dart';
import 'package:manito/arch_new/screens/friends/friends_search_screen.dart';
import 'package:manito/arch_new/screens/login_screen.dart';
import 'package:manito/arch_new/screens/manito/manito_propose_screen.dart';
import 'package:manito/arch_new/screens/missions/mission_create_screen.dart';
import 'package:manito/arch_new/screens/missions/mission_friends_search_screen.dart';
import 'package:manito/arch_new/screens/missions/mission_guess_screen.dart';
import 'package:manito/arch_new/screens/posts/post_detail_screen.dart';
import 'package:manito/arch_new/screens/profile_edit_screen.dart';
import 'package:manito/arch_new/screens/setting_screen.dart';
import 'package:manito/arch_new/screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(fcmListenerProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authStateAsync = ref.read(authStateChangesProvider);
      return authStateAsync.when(
        data: (authState) {
          final isLoggedIn = authState.session?.user != null;
          return _handleAuthenticatedRedirect(state, isLoggedIn);
        },
        loading: () {
          return state.matchedLocation == '/splash' ? null : '/splash';
        },
        error: (error, stack) {
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
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/post_detail',
        name: 'postDetail',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final Post post = args['post'];
          final FriendProfile manitoProfile = args['manitoProfile'];
          final FriendProfile creatorProfile = args['creatorProfile'];
          return PostDetailScreen(
            post: post,
            manitoProfile: manitoProfile,
            creatorProfile: creatorProfile,
          );
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
      GoRoute(
        path: '/friends_detail',
        name: 'friendsDetail',
        builder: (context, state) {
          final FriendProfile friendProfile = state.extra as FriendProfile;
          return FriendsDetailScreen(friendProfile: friendProfile);
        },
      ),
    ],
  );
});

// 헬퍼 함수
String? _handleAuthenticatedRedirect(GoRouterState state, bool isLoggedIn) {
  FlutterNativeSplash.remove();

  final location = state.matchedLocation;

  if (isLoggedIn) {
    // 로그인된 사용자: 보호된 화면 접근 가능
    if (location == '/splash' || location == '/login') {
      return '/bottom_nav'; // 스플래시/로그인에서 벗어남
    }
    return null; // 다른 화면은 유지
  } else {
    // 미로그인 사용자: 로그인 관련 화면만 접근 가능
    if (location == '/login' || location == '/kakao_login') {
      return null; // 로그인 화면 유지
    }
    return '/login'; // 다른 화면은 로그인으로
  }
}
