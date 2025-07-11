import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/screens/friend/modify_screen.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileController _controller;
  late FriendsController _friendscontroller;
  late PostController _postController;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ProfileController());
    _friendscontroller = Get.find<FriendsController>();
    _postController = Get.find<PostController>();
  }

  // 프로필 수정 화면 이동
  void _toModifyScreen() async {
    final result = await Get.to(
      () => ModifyScreen(),
      arguments: [
        _friendscontroller.userProfile.value?.profileImageUrl,
        _friendscontroller.userProfile.value?.nickname,
        _friendscontroller.userProfile.value?.statusMessage,
      ],
    );
    if (result == true) {
      _controller.isLoading.value = true;
      await _friendscontroller.getProfile();
      _controller.isLoading.value = false;
    }
  }

  // 본체
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Obx(
          () =>
              _controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(),
        ),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: false,
      titleSpacing: Get.width * 0.02,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title: Text("profile_screen.title").tr(),
      actions: [_buildModifyBtn()],
    );
  }

  // 프로필 수정 버튼
  Widget _buildModifyBtn() {
    return IconButton(onPressed: _toModifyScreen, icon: Icon(Icons.edit));
  }

  // 바디
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(),
          _buildStatusMessage(),
          _buildAdSection(),
        ],
      ),
    );
  }

  // 프로필 이미지와 미션 기록
  Widget _buildProfileSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04),
      child: Row(
        children: [
          profileImageOrDefault(
            _friendscontroller.userProfile.value!.profileImageUrl,
            Get.width * 0.25,
          ),
          SizedBox(width: Get.width * 0.04),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                  count: _postController.creatorPostCount,
                  label: context.tr("profile_screen.sent_missions"),
                ),
                _buildStatColumn(
                  count: _postController.manitoPostCount,
                  label: context.tr("profile_screen.received_missions"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 보낸 미션, 받은 미션 횟수
  Widget _buildStatColumn({required int count, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('$count'), Text(label)],
    );
  }

  // 상태 메시지
  Widget _buildStatusMessage() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Get.width * 0.04,
        Get.width * 0.02,
        Get.width * 0.04,
        Get.width * 0.04,
      ),
      child: Text(
        _friendscontroller.userProfile.value?.statusMessage ?? '',
        softWrap: true,
      ),
    );
  }

  // 광고
  Widget _buildAdSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Get.width * 0.04,
        0,
        Get.width * 0.04,
        Get.width * 0.04,
      ),
      child: BannerAdWidget(
        borderRadius: Get.width * 0.02,
        width: Get.width * 0.92,
        androidAdId: dotenv.env['BANNER_FRIEND_DETAIL_ANDROID']!,
        iosAdId: dotenv.env['BANNER_FRIEND_DETAIL_IOS']!,
      ),
    );
  }
}
