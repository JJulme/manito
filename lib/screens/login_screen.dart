import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/auth_controller.dart';
import 'package:manito/screens/kakao_login_webview.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 비례한 수
    double width = Get.width;
    return Scaffold(
      body: SafeArea(
        // 중앙에 배치
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 앱 대표 이미지
              Image.asset(
                'assets/images/manito_dog.png',
                width: 0.6 * width,
                height: 0.6 * width,
              ),
              SizedBox(height: 0.01 * width),
              Container(
                height: 0.2 * width,
                width: width,
                padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '지금 친구들과\n마니또를 즐겨보세요!',
                    style: Get.textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 0.04 * width),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                child: InkWell(
                  // onTap: () => authController.loginWithKakao(),
                  onTap: () async {
                    await CookieManager.instance().deleteAllCookies();
                    Get.to(() => KakaoLoginWebview());
                  },
                  child: Image.asset(
                    'assets/images/kakao_login_large_wide.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 0.05 * width),
              if (GetPlatform.isIOS)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                  child: InkWell(
                    onTap: () async {
                      await authController.signInWithApple();
                    },
                    child: Container(
                      height: 0.14 * width,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(0.015 * width),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 0.027 * width),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apple_sharp,
                            color: Colors.white,
                            size: 0.08 * width,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Apple 로그인  ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 0.0445 * width,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
