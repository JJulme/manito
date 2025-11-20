import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';
import 'package:manito/features/friends/friends.dart';
import 'package:manito/features/friends/friends_provider.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/profile_image_view.dart';

class FriendsSearchScreen extends ConsumerStatefulWidget {
  const FriendsSearchScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FriendsSearchScreenState();
}

class _FriendsSearchScreenState extends ConsumerState<FriendsSearchScreen> {
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
    ref.read(friendSearchProvider.notifier).clear();
  }

  // 검색버튼 동작 함수
  Future<void> _searchEmail() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(friendSearchProvider.notifier)
          .searchEmail(emailController.text);
    }
  }

  // 내 이메일 복사 완료 스넥바
  void _copyEmailToClipboard(String email) {
    Clipboard.setData(ClipboardData(text: email));
    customToast(msg: context.tr("friends_search_screen.copy_message"));
  }

  // ✅ 친구 신청 처리 (개선)
  Future<void> _handleFriendRequest(String friendId) async {
    // 이미 친구인지 확인
    final isFriend = ref
        .read(friendProfilesProvider.notifier)
        .searchFriendProfile(friendId);

    if (isFriend == 'unknown') {
      customToast(msg: '이미 친구입니다');
      return;
    }

    // 친구 신청
    final result =
        await ref.read(friendSearchProvider.notifier).sendFriendRequest();

    if (result.isNotEmpty) {
      customToast(msg: context.tr("friends_search_screen.$result"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(friendSearchProvider); // ✅ AsyncValue
    final userProfileState = ref.watch(userProfileProvider).value!.userProfile;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(title: Text('친구 찾기')),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchForm(),
              SizedBox(height: width * 0.03),
              _buildMyEmailSection(userProfileState!.email),
              SizedBox(height: width * 0.03),
              // ✅ AsyncValue.when 사용
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
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => _searchEmail(),
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

  // ✅ AsyncValue.when 패턴으로 변경
  Widget _buildProfileSection(AsyncValue<FriendSearchState> searchState) {
    return searchState.when(
      // 로딩 중
      loading:
          () => Container(
            height: width * 0.53,
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          ),

      // 에러 발생
      error:
          (error, stack) => Container(
            height: width * 0.53,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: width * 0.15,
                  color: Colors.red,
                ),
                SizedBox(height: width * 0.03),
                Text('검색 중 오류가 발생했습니다'),
                SizedBox(height: width * 0.02),
                TextButton(onPressed: _clearText, child: Text('다시 시도')),
              ],
            ),
          ),

      // 성공 (데이터 있음)
      data: (state) {
        // 검색 전
        if (state.isEmpty) {
          return SizedBox.shrink();
        }

        // 검색 결과 없음
        if (state.noResult) {
          return Container(
            height: width * 0.53,
            alignment: Alignment.center,
            child: Text('검색결과가 없습니다.'),
          );
        }

        // 검색 결과 있음
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: EdgeInsets.all(width * 0.06),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(width * 0.02),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileImageView(
                  size: width * 0.3,
                  profileImageUrl: state.friendProfile!.profileImageUrl!,
                ),
                SizedBox(height: width * 0.03),
                Text(
                  state.friendProfile!.nickname,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: width * 0.02),
                ElevatedButton(
                  onPressed:
                      () => _handleFriendRequest(state.friendProfile!.id),
                  child:
                      Text(
                        "friends_search_screen.request_btn",
                        style: Theme.of(context).textTheme.bodySmall,
                      ).tr(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
