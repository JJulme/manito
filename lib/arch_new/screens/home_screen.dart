import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/arch_new/features/badge/badge_provider.dart';
import 'package:manito/arch_new/features/profiles/profile_provider.dart';
import 'package:manito/arch_new/screens/manito/manito_tab.dart';
import 'package:manito/arch_new/screens/missions/mission_tab.dart';
import 'package:manito/arch_new/share/custom_badge.dart';
import 'package:manito/arch_new/share/custom_popup_menu_item.dart';
import 'package:manito/arch_new/share/main_appbar.dart';
import 'package:manito/arch_new/widgets/profile_item.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  static const double _horizontalPadding = 0.03;
  static const double _borderRadius = 0.02;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProfileProvider.notifier).getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final double width = MediaQuery.of(context).size.width;
    final userProfileState = ref.watch(userProfileProvider);
    final badgeState = ref.watch(badgeProvider);

    if (userProfileState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (userProfileState.userProfile != null) {
      final userProfile = userProfileState.userProfile;
      return SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: MainAppbar(
              width: width,
              text: 'manito',
              actions: [_buildPopupMenu(width)],
            ),
            body: Column(
              children: [
                // 프로필 사진, 이름, 상태메시지
                ProfileItem(
                  profileImageUrl: userProfile!.profileImageUrl!,
                  name: userProfile.nickname,
                  statusMessage: userProfile.statusMessage!,
                ),
                SizedBox(height: width * 0.03),
                _buildBannerAd(width),
                SizedBox(height: width * 0.03),
                TabBar(
                  tabs: [
                    customBadgeIconWithLabel(
                      badgeState.badgeMissionCount,
                      child: Tab(text: '보낸미션'),
                    ),
                    customBadgeIconWithLabel(
                      badgeState.badgeManitoCount,
                      child: Tab(text: '받은미션'),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(children: [MissionTab(), ManitoTab()]),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Center(child: Text('Error: ${userProfileState.error}'));
    }
  }

  // 앱바 팝업 버튼
  Widget _buildPopupMenu(double width) {
    return Padding(
      padding: EdgeInsets.only(right: width * 0.02),
      child: PopupMenuButton(
        icon: Icon(Icons.more_vert, size: width * 0.06),
        position: PopupMenuPosition.under,
        onSelected: (value) => context.push(value),
        itemBuilder:
            (context) => [
              CustomPopupMenuItem(
                width: width,
                icon: Icon(Icons.edit),
                text: '프로필 수정',
                value: '/profile_modify',
              ),
              CustomPopupMenuItem(
                width: width,
                icon: Icon(Icons.settings_rounded),
                text: '설정',
                value: '/setting',
              ),
            ],
      ),
    );
  }

  // 광고
  Widget _buildBannerAd(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * _horizontalPadding,
      ),
      child: BannerAdWidget(
        borderRadius: screenWidth * _borderRadius,
        width: screenWidth - (_horizontalPadding * 2) * screenWidth,
        androidAdId: dotenv.env['BANNER_MISSION_ANDROID']!,
        iosAdId: dotenv.env['BANNER_MISSION_IOS']!,
      ),
    );
  }
}
