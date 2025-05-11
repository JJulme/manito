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

  /// 이메일 입력 폼키
  final _formKey = GlobalKey<FormState>();

  /// 이메일 입력 컨트롤러
  // TextEditingController emailController = TextEditingController();

  /// 이메일 검증
  String? _emailVaildator(String? email) {
    return (GetUtils.isEmail(email ?? '') ? null : '이메일을 입력해주세요.');
  }

  /// 입력된 값 한번에 지워주기
  void _clearText() {
    _controller.emailController.clear();
  }

  /// 검색버튼 동작 함수
  Future<void> _searchEmail() async {
    if (_formKey.currentState!.validate()) {
      await _controller.searchEmail();
    }
  }

  /// 친구 신청
  Future<void> _friendRequest() async {
    final result = await _controller.sendFriendRequest();
    customSnackbar(title: '알림', message: result);
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0.02 * width,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Get.back(),
          ),
          title: Text('친구 찾기', style: Get.textTheme.headlineMedium),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 이메일 검색 텍스트 폼 필드
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _controller.emailController,
                    validator: _emailVaildator,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelStyle: Get.textTheme.bodyLarge,
                      hintText: '친구의 이메일을 입력하세요.',
                      hintStyle: Get.textTheme.bodySmall,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 0.06 * width,
                      ),
                      suffixIcon: IconButton(
                        padding: EdgeInsets.all(0),
                        icon: Icon(Icons.cancel_rounded, size: 0.06 * width),
                        onPressed: _clearText,
                      ),
                    ),
                    onFieldSubmitted: (_) => _searchEmail(),
                  ),
                ),
              ),
              SizedBox(height: 0.03 * width),
              // 내 이메일, 검색
              Obx(() {
                final profile = _controller.searchProfile.value;
                // 검색 전 화면
                if (profile == null) {
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // 내 이메일
                      Container(
                        padding: EdgeInsets.all(0.04 * width),
                        margin: EdgeInsets.symmetric(horizontal: 0.05 * width),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(0.02 * width),
                        ),
                        // 내 이메일
                        child: GestureDetector(
                          onTap:
                              () => Clipboard.setData(
                                ClipboardData(
                                  text:
                                      _friendsController
                                          .userProfile
                                          .value!
                                          .email,
                                ),
                              ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('내 이메일', style: Get.textTheme.bodySmall),
                              Text(
                                _friendsController.userProfile.value!.email,
                                style: Get.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                // 검색 후 화면
                else {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                    child: Container(
                      // height: 0.35 * di,
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(0.06 * width),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(0.02 * width),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          profileImageOrDefault(
                            profile.profileImageUrl!,
                            0.3 * width,
                          ),
                          SizedBox(height: 0.03 * width),
                          Text(
                            profile.nickname,
                            style: Get.textTheme.bodyMedium,
                          ),
                          SizedBox(height: 0.02 * width),
                          ElevatedButton(
                            child: Text(
                              '친구 신청',
                              style: Get.textTheme.bodySmall,
                            ),
                            onPressed: () => _friendRequest(),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
