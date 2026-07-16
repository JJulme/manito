import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/widget/banner_ad_widget.dart';
import 'package:manito/core/widget/common_error_widget.dart';
import 'package:manito/core/widget/common_loading_widget.dart';
import 'package:manito/core/widget/common_badge.dart';
import 'package:manito/core/widget/common_popup_menu_item.dart';
import 'package:manito/core/widget/main_appbar.dart';
import 'package:manito/core/widget/profile_item.dart';
import 'package:manito/features_new/profile/presentation/providers/my_profile_provider.dart';
import 'package:manito/main.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 추가해서 추가
    final myProfileAsync = ref.watch(myProfileProvider);
    // 프로필 정보 검사
    ref.listen(myProfileProvider, (prev, next) {
      final previousState = prev;
      final nextProfile = next.value;
      if (previousState != null && previousState.isLoading && nextProfile != null && !nextProfile.isProfileComplete) {
        context.push('/edit_profile', extra: false);
      }
    });
    return myProfileAsync.when(
      loading: () => const CommonLoadingWidget(),
      error:
          (error, stackTrace) => CommonErrorWidget(
            error: error,
            onRetry: () => ref.invalidate(myProfileProvider),
          ),
      data: (profie) {
        return SafeArea(
          child: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: MainAppbar(
                title: Text(
                  'manito',
                  style: TextStyle(
                    fontFamily: 'CookieRun',
                    fontStyle: FontStyle.italic,
                    fontSize: TextTheme.of(context).headlineSmall!.fontSize,
                  ),
                ),
                actions: [_buildPopupMenu()],
              ),
              body: Column(
                children: [
                  ProfileItem(
                    profileImageUrl: profie?.profileImageUrl ?? '',
                    name: profie?.nickname ?? '',
                    statusMessage: profie?.statusMessage ?? '',
                  ),
                  SizedBox(height: width * 0.03),
                  _buildBannerAd(),
                  SizedBox(height: width * 0.03),
                  TabBar(
                    tabs: [
                      CommonBadge(
                        badgeCount: 0,
                        child: Tab(
                          child: Text(
                            '보낸미션',
                            style: TextTheme.of(context).titleMedium,
                          ),
                        ),
                      ),
                      CommonBadge(
                        badgeCount: 0,
                        child: Tab(
                          child: Text(
                            '받은미션',
                            style: TextTheme.of(context).titleMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(child: TabBarView(children: [Center(), Center()])),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 앱바 팝업 버튼
  Widget _buildPopupMenu() {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert),
      position: PopupMenuPosition.under,
      onSelected: (value) => context.push(value),
      itemBuilder:
          (context) => [
            CommonPopupMenuItem(
              icon: Icon(Icons.edit),
              text: '프로필 수정',
              value: '/edit_profile',
            ),
            CommonPopupMenuItem(
              icon: Icon(Icons.settings_rounded),
              text: '설정',
              value: '/setting',
            ),
          ],
    );
  }

  // 광고
  Widget _buildBannerAd() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03),
      child: BannerAdWidget(
        borderRadius: width * 0.02,
        androidAdId: dotenv.env['BANNER_MISSION_ANDROID']!,
        iosAdId: dotenv.env['BANNER_MISSION_IOS']!,
      ),
    );
  }
}
