import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features_new/auth/presentation/providers/auth_provider.dart';
import 'package:manito/features_new/auth/presentation/screens/kakao_login_webview.dart';
import 'package:manito/core/fcm/fcm_provider.dart';
import 'package:manito/features_new/manito/domain/entities/manito_entity.dart';
import 'package:manito/features_new/friends/presentation/screens/blocked_users_screen.dart';
import 'package:manito/features_new/friends/presentation/screens/edit_friend_nickname_screen.dart';
import 'package:manito/features_new/friends/presentation/screens/friend_requests_screen.dart';
import 'package:manito/features_new/friends/presentation/screens/user_detail_sceen.dart';
import 'package:manito/features_new/friends/presentation/screens/user_search_screen.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:manito/screens/manito/album_screen.dart';
import 'package:manito/screens/manito/manito_post_screen.dart';
import 'package:manito/features_new/missions/domain/entities/mission_entity.dart';
import 'package:manito/features/auth/presentation/screens/login_screen.dart';
import 'package:manito/screens/manito/manito_propose_screen.dart';
import 'package:manito/screens/missions/mission_create_screen.dart';
import 'package:manito/screens/missions/mission_friends_search_screen.dart';
import 'package:manito/screens/missions/mission_group_create_screen.dart';
import 'package:manito/screens/missions/mission_group_screen.dart';
import 'package:manito/screens/missions/mission_guess_screen.dart';
import 'package:manito/screens/missions/mission_search_screen.dart';
import 'package:manito/features_new/posts/presentation/screens/post_detail_screen.dart';
import 'package:manito/screens/splash_screen.dart';
import 'package:manito/features/main/main_nav_screen.dart';
import 'package:manito/features/friends/presentation/screens/add_friend_screen.dart';
import 'package:manito/features/friends/presentation/screens/invite_friends_screen.dart';
import 'package:manito/features/profile/presentation/screens/profile_screen.dart';
import 'package:manito/features/rooms/presentation/screens/group_lobby_screen.dart';
import 'package:manito/features/setup/presentation/screens/mission_setup_screen.dart';
import 'package:manito/features/game/presentation/screens/main_play_dashboard_screen.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/features/feed/presentation/screens/result_feed_screen.dart';
import 'package:manito/features/settings/presentation/screens/settings_screen.dart';
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
                // Profile record is being generated or fetched
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
      // GoRoute(
      //   path: '/bottom_nav',
      //   name: 'bottom_nav',
      //   builder: (context, state) => const BottomNav(),
      // ),
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
        path: '/album',
        name: 'album',
        builder: (context, state) {
          final ManitoAcceptEntity manitoAccept = state.extra as ManitoAcceptEntity;
          return AlbumScreen(manitoAccept: manitoAccept);
        },
      ),
      GoRoute(
        path: '/setting',
        name: 'setting',
        builder: (context, state) => const SettingsScreen(),
      ),
      // GoRoute(
      //   path: '/profile_edit',
      //   name: 'profileEdit',
      //   builder: (context, state) {
      //     final canGoBack = state.extra as bool? ?? true;
      //     return ProfileEditScreen(canGoback: canGoBack);
      //   },
      // ),
      GoRoute(
        path: '/edit_profile',
        name: 'editProfile',
        builder: (context, state) {
          final isFirstSetup = state.extra as bool? ?? false;
          return EditProfileScreen(isFirstSetup: isFirstSetup);
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
        path: '/mission_group_create',
        name: 'missionGroupCreate',
        builder: (context, state) => const MissionGroupCreateScreen(),
      ),
      GoRoute(
        path: '/mission_group_room/:roomId',
        name: 'missionGroupRoom',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return MissionGroupScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/mission_search',
        name: 'missionSearch',
        builder: (context, state) => const MissionSearchScreen(),
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
          final MyMissionEntity mission = state.extra as MyMissionEntity;
          return MissionGuessScreen(mission: mission);
        },
      ),
      GoRoute(
        path: '/manito_propose',
        name: 'manitoPropose',
        builder: (context, state) {
          final ManitoProposeEntity propose = state.extra as ManitoProposeEntity;
          return ManitoProposeScreen(propose: propose);
        },
      ),
      GoRoute(
        path: '/manito_post',
        name: 'manitoPost',
        builder: (context, state) {
          final ManitoAcceptEntity manitoAccept = state.extra as ManitoAcceptEntity;
          return ManitoPostScreen(manitoAccept: manitoAccept);
        },
      ),
      // GoRoute(
      //   path: '/friends_search',
      //   name: 'friendsSearch',
      //   builder: (context, state) => const FriendsSearchScreen(),
      // ),
      GoRoute(
        path: '/user_search',
        name: 'userSearch',
        builder: (context, state) => const UserSearchScreen(),
      ),
      // GoRoute(
      //   path: '/friends_request',
      //   name: 'friendsRequest',
      //   builder: (context, state) => const FriendsRequestScreen(),
      // ),
      GoRoute(
        path: '/friend_requests',
        name: 'friendRequests',
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      // GoRoute(
      //   path: '/friends_blacklist',
      //   name: 'friendsBlacklist',
      //   builder: (context, state) => const FriendsBlacklistScreen(),
      // ),
      GoRoute(
        path: '/blocked_users',
        name: 'blockedUsers',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      // GoRoute(
      //   path: '/friends_edit',
      //   name: 'friendsEdit',
      //   builder: (context, state) {
      //     final FriendProfile friendProfile = state.extra as FriendProfile;
      //     return FriendsEditScreen(friendProfile: friendProfile);
      //   },
      // ),
      GoRoute(
        path: '/edit-nickname/:userId',
        name: 'editNickname',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          // extra로 전달된 모델을 캐스팅합니다.
          final user = state.extra as UserEntity;

          return EditFriendNicknameScreen(
            userId: userId,
            profile: user, // 모델 내부의 필드 사용
          );
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
      // GoRoute(
      //   path: '/friends_detail/:friendId',
      //   name: 'friendsDetail',
      //   builder: (context, state) {
      //     final friendId = state.pathParameters['friendId']!;
      //     return FriendsDetailScreen(friendId: friendId);
      //   },
      // ),
      GoRoute(
        path: '/user_detail/:userId',
        name: 'userDetail',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserDetailSceen(userId: userId);
        },
      ),
    ],
  );
});

// String? _handleRedirect(
//   String location, {
//   required bool isLoggedIn,
//   required bool hasUserProfile,
//   required bool isProfileComplete,
// }) {
//   // 로그인 안 됨
//   if (!isLoggedIn) {
//     if (location == '/login' || location == '/splash') {
//       return null; // 현재 위치 유지
//     }
//     return '/login'; // 로그인 화면으로
//   }

//   // 로그인은 됐는데 사용자 정보 없음
//   if (!hasUserProfile) {
//     if (location == '/profile_edit') {
//       return null;
//     }
//     return '/profile_edit'; // 프로필 설정 화면으로
//   }

//   // 로그인 + 사용자 정보 있음 + 프로필 불완전
//   if (!isProfileComplete) {
//     if (location == '/profile_edit') {
//       return null;
//     }
//     return '/profile_edit';
//   }

//   // 모든 조건 만족 (로그인 + 정보 있음 + 프로필 완성)
//   if (location == '/splash' ||
//       location == '/login' ||
//       location == '/profile_edit') {
//     return '/bottom_nav'; // 홈으로
//   }

//   return null; // 현재 위치 유지
// }
