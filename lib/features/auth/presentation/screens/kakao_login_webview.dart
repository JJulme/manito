import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';

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
      final repository = ref.read(authRepositoryProvider);
      final url = await repository.getKakaoLoginUrl();
      if (!mounted) return;
      setState(() {
        _kakaoLoginUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 URL 로드 실패: $e')),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      next.whenData((auth) {
        if (auth.session?.user != null && mounted) {
          context.pop();
        }
      });
    });

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: _kakaoLoginUrl == null
            ? const Center(child: CircularProgressIndicator())
            : InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri.uri(Uri.parse(_kakaoLoginUrl!)),
                ),
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url.toString();
                  if (url.startsWith('kakao1a36ff49b64f62a81bd117e504fe332b://oauth')) {
                    final uri = Uri.parse(url);
                    final code = uri.queryParameters['code'];
                    if (code != null) {
                      ref.read(authProvider.notifier).exchangeKakaoCodeForSession(code);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('카카오 로그인 실패: 인증 코드 없음')),
                        );
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
