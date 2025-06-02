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
    // final isTablet = MediaQuery.of(context).size.shortestSide > 600;
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
              // 문구
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
              // 카카오 로그인 버튼
              AuthButton(
                imagePath: 'assets/images/kakao_login_large_wide.png',
                onTap: () async {
                  await CookieManager.instance().deleteAllCookies();
                  Get.to(() => KakaoLoginWebview());
                },
              ),
              // AuthButton(
              //   imagePath: 'assets/images/kakao_login_large_wide.png',
              //   onTap: () async {
              //     await CookieManager.instance().deleteAllCookies();
              //     await authController.loginWithKakao();
              //   },
              // ),
              // SizedBox(height: isTablet ? 0.03 * width : 0.05 * width),

              // // 애플 로그인
              // if (GetPlatform.isIOS)
              //   AuthButton(
              //     imagePath: 'assets/images/apple_login_large_wide.png',
              //     onTap: () async {
              //       await authController.signInWithApple();
              //     },
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;
  const AuthButton({super.key, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
      child: InkWell(
        onTap: onTap,
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}
