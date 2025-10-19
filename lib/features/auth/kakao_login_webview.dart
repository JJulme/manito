import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/auth/auth_provider.dart';

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
    final authService = ref.read(authServiceProvider);
    final url = await authService.getKakaoLoginUrl();
    if (!mounted) return;
    setState(() {
      _kakaoLoginUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                            .read(authNotifierProvider.notifier)
                            .exchangeKakaoCodeForSession(code);
                        if (mounted) context.pop();
                      } else {
                        // fail
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
