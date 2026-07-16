import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/widget/banner_ad_widget.dart';
import 'package:manito/core/widget/common_error_widget.dart';
import 'package:manito/core/widget/common_loading_widget.dart';
import 'package:manito/core/widget/common_popup_menu_item.dart';
import 'package:manito/core/widget/profile_item.dart';
import 'package:manito/core/widget/sub_appbar.dart';
import 'package:manito/features_new/friends/presentation/providers/user_relation_provider.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/features_new/profile/presentation/providers/user_profile_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/core/widget/common_dialog.dart';

// 수정 필요
class UserDetailSceen extends ConsumerStatefulWidget {
  final String userId;
  const UserDetailSceen({super.key, required this.userId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserDetailSceenState();
}

class _UserDetailSceenState extends ConsumerState<UserDetailSceen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void _toEditFriendNickname(UserEntity profile) {
    context.pushNamed(
      'editNickname',
      pathParameters: {'userId': profile.id},
      extra: profile,
    );
  }

  Future<void> _handleBlackFriend() async {
    final result = await DialogHelper.showConfirmDialog(
      context,
      title: context.tr("friends_detail_screen.dialog_title"),
      message: context.tr("friends_detail_screen.dialog_message"),
    );
    if (result == true) {
      await ref.read(userRelationProvider.notifier).blockUser(widget.userId);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider(widget.userId));
    return Scaffold(
      appBar: SubAppbar(
        title: SizedBox.shrink(),
        actions: [_buildPopupMenu(userProfileAsync)],
      ),
      body: userProfileAsync.when(
        loading: () => CommonLoadingWidget(),
        error: (error, stackTrace) => CommonErrorWidget(error: error),
        data:
            (profile) => SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ProfileItem(
                      profileImageUrl: profile.profileImageUrl ?? '',
                      name: profile.displayName,
                      statusMessage: profile.statusMessage ?? '',
                    ),
                    SizedBox(height: width * 0.03),
                    _buildBannerAd(),
                    SizedBox(height: width * 0.03),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // 팝업 메뉴
  Widget _buildPopupMenu(AsyncValue<UserEntity> userProfileAsync) {
    return userProfileAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data:
          (profile) => PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder:
                (context) => [
                  CommonPopupMenuItem(
                    icon: Icon(Icons.edit),
                    text: '이름 수정',
                    value: '',
                    onTap: () => _toEditFriendNickname(profile),
                  ),
                  CommonPopupMenuItem(
                    icon: Icon(Icons.no_accounts_rounded),
                    text: '친구 차단',
                    value: '',
                    onTap: _handleBlackFriend,
                  ),
                  CommonPopupMenuItem(
                    icon: Icon(Icons.report_problem_rounded),
                    text: '신고하기',
                    value: '',
                    // onTap: _handleReportUser,
                  ),
                ],
          ),
    );
  }

  // 광고
  Widget _buildBannerAd() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03),
      child: BannerAdWidget(
        borderRadius: width * 0.02,
        androidAdId: dotenv.env['BANNER_FRIEND_DETAIL_ANDROID']!,
        iosAdId: dotenv.env['BANNER_FRIEND_DETAIL_IOS']!,
      ),
    );
  }
}
