import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/auth/auth_provider.dart';
import 'package:manito/features/error/error_provider.dart';

class KakaoLoginWebview extends ConsumerStatefulWidget {
  const KakaoLoginWebview({super.key});

  @override
  ConsumerState<KakaoLoginWebview> createState() => _KakaoLoginWebviewState();
}

class _KakaoLoginWebviewState extends ConsumerState<KakaoLoginWebview> {
  String? _kakaoLoginUrl;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    try {
      final authService = ref.read(authServiceProvider);
      final url = await authService.getKakaoLoginUrl();
      if (!mounted) return;
      setState(() {
        _kakaoLoginUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ref.read(errorProvider.notifier).setError('카카오 로그인 URL 로드 실패: $e');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ authProvider 감시 - 로그인 완료되면 자동으로 화면 닫음
    ref.listen(authProvider, (previous, next) {
      next.whenData((auth) {
        // 로그인 성공 (세션이 있으면)
        if (auth.session?.user != null && mounted) {
          context.pop();
        }
      });
    });

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body:
            _kakaoLoginUrl == null
                ? const Center(child: CircularProgressIndicator())
                : InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri.uri(Uri.parse(_kakaoLoginUrl!)),
                  ),
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
                        ref
                            .read(authProvider.notifier)
                            .exchangeKakaoCodeForSession(code);
                      } else {
                        if (mounted) {
                          ref
                              .read(errorProvider.notifier)
                              .setError('카카오 로그인 실패: 인증 코드 없음');

                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) context.pop();
                          });
                        }
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
