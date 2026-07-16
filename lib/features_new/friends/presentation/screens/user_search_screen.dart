import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';
import 'package:manito/core/widget/common_toast.dart';
import 'package:manito/core/widget/profile_image_view.dart';
import 'package:manito/core/widget/sub_appbar.dart';
import 'package:manito/features/theme/theme.dart';
import 'package:manito/features_new/friends/presentation/providers/friend_list_provider.dart';
import 'package:manito/features_new/friends/presentation/providers/user_search_provider.dart';
import 'package:manito/features_new/profile/presentation/providers/my_profile_provider.dart';
import 'package:manito/main.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // 이메일 검증
  String? _emailValidator(String? email) {
    return (GetUtils.isEmail(email ?? '')
        ? null
        : context.tr('friends_search_screen.validator'));
  }

  // 입력값 지우기
  void _clearText() {
    emailController.clear();
    ref.read(userSearchProvider.notifier).clearSearch();
  }

  // 검색버튼 동작 함수
  Future<void> _searchEmail() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(userSearchProvider.notifier)
          .searchUser(emailController.text);
    }
  }

  // 내 이메일 복사 완료 스넥바
  void _copyEmailToClipboard(String email) {
    Clipboard.setData(ClipboardData(text: email));
    showCommonToast(context.tr("friends_search_screen.copy_message"));
  }

  // 친구 신청 처리
  Future<void> _handleFriendRequest(String userId) async {
    // 이미 친구인지 확인
    final isFriend = ref
        .read(friendListProvider.notifier)
        .isAlreadyFriend(userId);
    if (isFriend) {
      showCommonToast('이미 친구입니다');
      return;
    }

    // 친구 신청
    final result = await ref
        .read(userSearchProvider.notifier)
        .requestFriend(userId);
    if (result.isNotEmpty) {
      if (!mounted) return;
      showCommonToast(context.tr("friends_search_screen.$result"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchProvider);
    final myProfile = ref.watch(myProfileProvider).value;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(title: Text('친구 찾기')),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchForm(),
              SizedBox(height: width * 0.03),
              _buildMyEmailSection(myProfile!.email),
              SizedBox(height: width * 0.03),
              _buildProfileSection(searchState),
            ],
          ),
        ),
      ),
    );
  }

  // 검색창
  Widget _buildSearchForm() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: emailController,
          validator: _emailValidator,
          onFieldSubmitted: (_) => _searchEmail(),
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.emailAddress,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            labelStyle: Theme.of(context).textTheme.bodyLarge,
            hintText: context.tr("friends_search_screen.hint"),
            hintStyle: Theme.of(context).textTheme.bodySmall,
            prefixIcon: Icon(Icons.search_rounded, size: width * 0.06),
            suffixIcon: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.cancel_rounded, size: width * 0.06),
              onPressed: _clearText,
            ),
          ),
        ),
      ),
    );
  }

  // 내 이메일
  Widget _buildMyEmailSection(String email) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.04),
          margin: EdgeInsets.symmetric(horizontal: width * 0.05),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(width * 0.02),
          ),
          child: GestureDetector(
            onTap: () => _copyEmailToClipboard(email),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.mail_outline_rounded),
                Expanded(
                  child: AutoSizeText(
                    email,
                    style: Theme.of(context).textTheme.bodySmall,
                    minFontSize: 7,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 검색 결과
  Widget _buildProfileSection(UserSearchState state) {
    if (state.isLoading) {
      return Container(
        height: width * 0.53,
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      );
    } else if (state.isInitial) {
      return SizedBox.shrink();
    } else if (state.noResult) {
      return Container(
        height: width * 0.53,
        alignment: Alignment.center,
        child: Text('검색결과가 없습니다.'),
      );
    } else {
      final searchedUser = state.searchedUser!;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.all(width * 0.06),
          decoration: BoxDecoration(
            color: ColorScheme.of(context).primaryContainer,
            borderRadius: BorderRadius.circular(width * 0.02),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileImageView(
                size: width * 0.3,
                profileImageUrl: searchedUser.profileImageUrl,
              ),
              SizedBox(height: width * 0.03),
              Text(
                searchedUser.nickname,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: width * 0.02),
              ElevatedButton(
                onPressed: () => _handleFriendRequest(searchedUser.id),
                child:
                    Text(
                      "friends_search_screen.request_btn",
                      style: TextStyle(
                        color: kOffBlack,
                        fontSize: TextTheme.of(context).bodyMedium!.fontSize,
                      ),
                    ).tr(),
              ),
            ],
          ),
        ),
      );
    }
  }
}
