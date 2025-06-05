import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:manito/controllers/auth_controller.dart';
import 'package:manito/screens/kakao_login_webview.dart';

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
              title: '미션을 만들고\n나만의 마니또를 만들어 보세요!',
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
              title: '나를 도와준 마니또가\n누구인지 추측해 보세요!',
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
              title: '마니또가 되어서\n친구를 몰래 도와주세요!',
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
              title: '친구를 어떻게\n도와주었는지 남겨보세요!',
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
              title: '일상에서 친구들과\n마니또를 즐겨보세요!',
              bodyWidget: AuthButton(
                imagePath: 'assets/images/kakao_login_large_wide.png',
                onTap: () async {
                  await CookieManager.instance().deleteAllCookies();
                  Get.to(() => KakaoLoginWebview());
                },
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
      imagePadding: EdgeInsets.zero,
      bodyPadding: EdgeInsets.only(top: 0.06 * width),
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
