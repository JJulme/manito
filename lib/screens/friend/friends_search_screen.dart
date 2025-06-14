import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class FriendsSearchScreen extends StatefulWidget {
  const FriendsSearchScreen({super.key});

  @override
  State<FriendsSearchScreen> createState() => _FriendsSearchScreenState();
}

class _FriendsSearchScreenState extends State<FriendsSearchScreen> {
  final FriendSearchController _controller = Get.put(FriendSearchController());
  final FriendsController _friendsController = Get.find<FriendsController>();
  // 이메일 입력 폼키
  final _formKey = GlobalKey<FormState>();
  // Constants for responsive design
  static const double _horizontalPadding = 0.05;
  static const double _containerPadding = 0.04;
  static const double _iconSizeRatio = 0.06;
  static const double _borderRadiusRatio = 0.02;
  static const double _profileImageRatio = 0.3;
  static const double _spacingRatio = 0.03;

  // 이메일 검증
  String? _emailValidator(String? email) {
    return (GetUtils.isEmail(email ?? '')
        ? null
        : context.tr('friends_search_screen.validator'));
  }

  // 입력된 값 한번에 지워주기
  void _clearText() {
    _controller.emailController.clear();
  }

  // 검색버튼 동작 함수
  Future<void> _searchEmail() async {
    if (_formKey.currentState!.validate()) {
      await _controller.searchEmail();
    }
  }

  // 내 이메일 복사 완료 스넥바
  void _copyEmailToClipboard(String email) {
    Clipboard.setData(ClipboardData(text: email));
    customSnackbar(
      title: context.tr("friends_search_screen.snack_title"),
      message: context.tr("friends_search_screen.copy_message"),
    );
  }

  // 친구 신청
  Future<void> _friendRequest() async {
    final result = await _controller.sendFriendRequest();
    // 마운틴된 상태 확인
    if (!mounted) return;
    customSnackbar(
      title: context.tr("friends_search_screen.snack_title"),
      message: context.tr("friends_search_screen.$result"),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(width),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchForm(width),
              SizedBox(height: width * _spacingRatio),
              _buildSearchResult(width),
            ],
          ),
        ),
      ),
    );
  }

  // 앱바
  PreferredSizeWidget _buildAppBar(double width) {
    return AppBar(
      centerTitle: false,
      titleSpacing: width * 0.02,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title:
          Text(
            'friends_search_screen.title',
            style: Get.textTheme.headlineMedium,
          ).tr(),
    );
  }

  // 검색창
  Widget _buildSearchForm(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding * width),
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller.emailController,
          validator: _emailValidator,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => _searchEmail(),
          decoration: InputDecoration(
            labelStyle: Get.textTheme.bodyLarge,
            hintText: context.tr("friends_search_screen.hint"),
            hintStyle: Get.textTheme.bodySmall,
            prefixIcon: Icon(
              Icons.search_rounded,
              size: _iconSizeRatio * width,
            ),
            suffixIcon: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.cancel_rounded, size: _iconSizeRatio * width),
              onPressed: _clearText,
            ),
          ),
        ),
      ),
    );
  }

  // 검색결과
  Widget _buildSearchResult(double width) {
    return Obx(() {
      final profile = _controller.searchProfile.value;

      return profile == null
          ? _buildMyEmailSection(width)
          : _buildProfileSection(profile, width);
    });
  }

  // 내 이메일
  Widget _buildMyEmailSection(double width) {
    final userEmail = _friendsController.userProfile.value?.email ?? '';
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(_containerPadding * width),
          margin: EdgeInsets.symmetric(horizontal: _horizontalPadding * width),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(_borderRadiusRatio * width),
          ),
          child: GestureDetector(
            onTap: () => _copyEmailToClipboard(userEmail),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'friends_search_screen.my_email',
                  style: Get.textTheme.bodySmall,
                ).tr(),
                Text(userEmail, style: Get.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 검색된 결과
  Widget _buildProfileSection(dynamic profile, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding * width),
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.all(_containerPadding * 1.5 * width),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(_borderRadiusRatio * width),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            profileImageOrDefault(
              profile.profileImageUrl ?? '',
              _profileImageRatio * width,
            ),
            SizedBox(height: _spacingRatio * width),
            Text(profile.nickname ?? '', style: Get.textTheme.bodyMedium),
            SizedBox(height: _borderRadiusRatio * width),
            ElevatedButton(
              onPressed: _friendRequest,
              child:
                  Text(
                    "friends_search_screen.request_btn",
                    style: Get.textTheme.bodySmall,
                  ).tr(),
            ),
          ],
        ),
      ),
    );
  }
}
