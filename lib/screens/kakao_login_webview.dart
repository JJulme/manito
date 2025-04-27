import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:manito/screens/splash_screen.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KakaoLoginWebview extends StatefulWidget {
  const KakaoLoginWebview({super.key});

  @override
  State<KakaoLoginWebview> createState() => _KakaoLoginWebviewState();
}

class _KakaoLoginWebviewState extends State<KakaoLoginWebview> {
  InAppWebViewController? _webViewController;
  String? _kakaoLoginUrl;
  @override
  void initState() {
    super.initState();
    _loadKakaoLoginUrl();
  }

  Future<void> _loadKakaoLoginUrl() async {
    try {
      final response = await Supabase.instance.client.auth.getOAuthSignInUrl(
        provider: OAuthProvider.kakao,
      );
      setState(() {
        _kakaoLoginUrl = response.url;
      });
    } catch (e) {
      print('카카오 로그인 URL 요청 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child:
            _kakaoLoginUrl == null
                ? Center(child: CircularProgressIndicator())
                : InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri.uri(Uri.parse(_kakaoLoginUrl!)),
                  ),
                  onWebViewCreated:
                      (controller) => _webViewController = controller,
                  shouldOverrideUrlLoading: (
                    controller,
                    navigationAction,
                  ) async {
                    final url = navigationAction.request.url.toString();

                    if (url.startsWith(
                      'kakao1a36ff49b64f62a81bd117e504fe332b://oauth',
                    )) {
                      final uri = Uri.parse(url);
                      final code = uri.queryParameters['code'];
                      if (code != null) {
                        try {
                          await Supabase.instance.client.auth
                              .exchangeCodeForSession(code);
                          Get.offAll(() => SplashScreen());
                        } catch (e) {
                          customSnackbar(
                            title: '로그인 오류',
                            message: '인증 처리에 오류가 발생했습니다.',
                          );
                          debugPrint('인증 처리에 오류가 발생했습니다. $e');
                        }
                      } else {
                        customSnackbar(
                          title: '로그인 실패',
                          message: '인증 코드를 받지 못했습니다.',
                        );
                        debugPrint('인증 코드를 받지 못했습니다.');
                      }
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
      ),
    );
  }
}
