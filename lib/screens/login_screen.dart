import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:manito/arch_new/features/auth/auth_provider.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:manito/arch_new/features/auth/kakao_login_webview.dart';

class LoginScreen extends ConsumerWidget {
  LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    imagePath: 'assets/images/long_google2.png',
                    onTap: () async {
                      ref.read(authNotifierProvider.notifier).loginWithGoogle();
                    },
                  ),
                  SizedBox(height: width * 0.04),
                  // 카카오 로그인 버튼
                  AuthButton(
                    imagePath: 'assets/images/long_kakao2.png',
                    onTap: () async {
                      Get.to(() => KakaoLoginWebview());
                      // ref.read(authNotifierProvider.notifier).loginWithKakao();
                    },
                  ),
                  SizedBox(height: width * 0.04),

                  // 애플 로그인 버튼
                  Platform.isIOS
                      ? AuthButton(
                        imagePath: 'assets/images/long_apple2.png',
                        onTap: () async {
                          ref
                              .read(authNotifierProvider.notifier)
                              .loginWithApple();
                        },
                      )
                      : SizedBox.shrink(),
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
      bodyAlignment: Alignment.topCenter,
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
      height: width * 0.125,
      child: InkWell(
        onTap: onTap,
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}
