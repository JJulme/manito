import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class PostAdWidget extends StatefulWidget {
  final double width;
  final String adUnitId;
  final double borderRadius;

  const PostAdWidget({
    super.key,
    required this.width,
    required this.adUnitId,
    this.borderRadius = 0.0,
  });

  @override
  State<PostAdWidget> createState() => _AdmobBannerState();
}

class _AdmobBannerState extends State<PostAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // 테스트 광고 ID
  static const Map<String, String> _testAdUnitIds = {
    'android': 'ca-app-pub-3940256099942544/6300978111',
    'ios': 'ca-app-pub-3940256099942544/2934735716',
  };

  // 배너 기본 크기 상수
  static const double BANNER_DEFAULT_WIDTH = 320.0;
  static const double BANNER_DEFAULT_HEIGHT = 100.0;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // 현재 플랫폼과 빌드 모드에 따라 적절한 광고 단위 ID 반환
  String _getAdUnitId() {
    // kDebugMode가 true면 테스트 광고 ID 사용
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _testAdUnitIds['android']!;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _testAdUnitIds['ios']!;
      }
    }
    // 릴리스 모드일 경우 실제 광고 ID 사용
    return widget.adUnitId;
  }

  // 너비에 맞는 높이 계산 (50/320 비율 유지)
  double get _height =>
      widget.width * (BANNER_DEFAULT_HEIGHT / BANNER_DEFAULT_WIDTH);

  void _loadAd() {
    _bannerAd = BannerAd(
      size: AdSize.largeBanner, // 항상 AdSize.banner 사용 (320x50)
      adUnitId: _getAdUnitId(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('광고 로딩 실패: ${error.message}');
        },
      ),
      request: const AdRequest(),
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: _isAdLoaded
          ? SizedBox(
              width: widget.width,
              height: _height,
              child: Center(
                child: Transform.scale(
                  scale: widget.width / BANNER_DEFAULT_WIDTH,
                  child: SizedBox(
                    width: BANNER_DEFAULT_WIDTH,
                    height: BANNER_DEFAULT_HEIGHT,
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              ),
            )
          : Container(
              width: widget.width,
              height: _height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }
}
