import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  final double width;
  final String androidAdId;
  final String iosAdId;
  final double borderRadius;

  const BannerAdWidget({
    super.key,
    required this.width,
    required this.androidAdId,
    required this.iosAdId,
    this.borderRadius = 0.0,
  });

  @override
  State<BannerAdWidget> createState() => _AdmobBannerState();
}

class _AdmobBannerState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  // 테스트 광고 ID
  static const Map<String, String> _testAdUnitIds = {
    'android': 'ca-app-pub-3940256099942544/6300978111',
    // 'ios': 'ca-app-pub-3940256099942544/2934735716',
    'ios': 'ca-app-pub-3940256099942544/2435281174',
  };

  // 배너 기본 크기 상수
  static const double bannerDefaultWidth = 320.0;
  static const double bannerDefaultHeight = 50.0;

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
    else {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return widget.androidAdId;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return widget.iosAdId;
      }
    }
    return '';
  }

  // 너비에 맞는 높이 계산 (50/320 비율 유지)
  double get _height =>
      widget.width * (bannerDefaultHeight / bannerDefaultWidth);

  void _loadAd() {
    _bannerAd = BannerAd(
      size: AdSize.banner, // 항상 AdSize.banner 사용 (320x50)
      adUnitId: _getAdUnitId(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
            _isAdFailed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint(_getAdUnitId());
          debugPrint('광고 로딩 실패 (Code ${error.code}): ${error.message}');
          setState(() {
            _isAdLoaded = false;
            _isAdFailed = true;
          });
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
      child: Builder(
        // 광고 로딩 성공
        builder: (context) {
          if (_isAdLoaded && _bannerAd != null) {
            return SizedBox(
              width: widget.width,
              height: _height,
              child: Center(
                child: Transform.scale(
                  scale: widget.width / bannerDefaultWidth,
                  child: SizedBox(
                    width: bannerDefaultWidth,
                    height: bannerDefaultHeight,
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              ),
            );
          }
          // 광고 로딩 실패
          else if (_isAdFailed) {
            return SizedBox.shrink();
            // Container(
            //   width: widget.width,
            //   height: _height,
            //   color: Colors.grey[200],
            //   child: Center(child: Text('광고 오류')),
            // );
          }
          // 광고 로딩중
          else {
            return Container(
              width: widget.width,
              height: _height,
              decoration: BoxDecoration(color: Colors.grey[200]),
            );
          }
        },
      ),
      // _isAdLoaded
      //     ? SizedBox(
      //       width: widget.width,
      //       height: _height,
      //       child: Center(
      //         child: Transform.scale(
      //           scale: widget.width / bannerDefaultWidth,
      //           child: SizedBox(
      //             width: bannerDefaultWidth,
      //             height: bannerDefaultHeight,
      //             child: AdWidget(ad: _bannerAd!),
      //           ),
      //         ),
      //       ),
      //     )
      //     : Container(
      //       width: widget.width,
      //       height: _height,
      //       decoration: BoxDecoration(
      //         color: Colors.grey[200],
      //         borderRadius: BorderRadius.circular(widget.borderRadius),
      //       ),
      //       child: const Center(child: CircularProgressIndicator()),
      //     ),
    );
  }
}
