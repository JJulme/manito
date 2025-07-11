import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:manito/controllers/auth_controller.dart';
import 'package:manito/screens/kakao_login_webview.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      body: SafeArea(
        child: IntroductionScreen(
          pages: [
            // 화면 1
            PageViewModel(
              title: context.tr('login_screen.page1'),
              body: '',
              image: Image.asset(
                'assets/images/manito_dog_phone.png',
                width: 0.7 * width,
                height: 0.7 * width,
              ),
              decoration: getPageDecoration(),
            ),
            // 화면 2
            PageViewModel(
              title: context.tr('login_screen.page2'),
              body: '',
              image: Image.asset(
                'assets/images/manito_dog_thinking.png',
                width: 0.7 * width,
                height: 0.7 * width,
              ),
              decoration: getPageDecoration(),
            ),
            // 화면 3
            PageViewModel(
              title: context.tr('login_screen.page3'),
              body: '',
              image: Image.asset(
                'assets/images/manito_dog_sunglass.png',
                width: 0.7 * width,
                height: 0.7 * width,
              ),
              decoration: getPageDecoration(),
            ),
            // 화면 4
            PageViewModel(
              title: context.tr('login_screen.page4'),
              body: '',
              image: Image.asset(
                'assets/images/manito_dog_selfie.png',
                width: 0.7 * width,
                height: 0.7 * width,
              ),
              decoration: getPageDecoration(),
            ),
            // 화면 5
            PageViewModel(
              title: context.tr('login_screen.page5'),
              bodyWidget: Column(
                children: [
                  // 구글 로그인 버튼
                  AuthButton(
                    imagePath: 'assets/images/btn_google.png',
                    onTap: () async {
                      await CookieManager.instance().deleteAllCookies();
                      await authController.loginWithGoogle();
                    },
                  ),
                  SizedBox(height: width * 0.03),
                  // 카카오 로그인 버튼
                  AuthButton(
                    imagePath: 'assets/images/btn_kakao.png',
                    onTap: () async {
                      await CookieManager.instance().deleteAllCookies();
                      Get.to(() => KakaoLoginWebview());
                      // await authController.loginWithKakao();
                    },
                  ),
                  SizedBox(height: width * 0.03),

                  // 애플 로그인 버튼
                  AuthButton(
                    imagePath: 'assets/images/apple_login_large_wide.png',
                    onTap: () async {
                      await CookieManager.instance().deleteAllCookies();
                      await authController.loginInWithApple();
                    },
                  ),
                ],
              ),
              image: Image.asset(
                'assets/images/manito_dog.png',
                width: 0.7 * width,
                height: 0.7 * width,
              ),
              decoration: getPageDecoration(),
            ),
          ],
          next: Icon(Icons.arrow_forward_ios_rounded),
          back: Icon(Icons.arrow_back_ios_rounded),
          showBackButton: true,
          showDoneButton: false,
        ),
      ),
    );
  }

  PageDecoration getPageDecoration() {
    double width = Get.width;
    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 0.065 * width,
        fontWeight: FontWeight.w600,
      ),
      imageAlignment: Alignment.center,
      imagePadding: EdgeInsets.zero,
      bodyPadding: EdgeInsets.zero,
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
    return SizedBox(
      height: width * 0.15,
      child: InkWell(
        onTap: onTap,
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}
