import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdManager {
  late RewardedAd _rewardedAd;
  bool _isRewardedAdReady = false;

  bool get isRewardedAdReady => _isRewardedAdReady;
  RewardedAd get rewardedAd => _rewardedAd;

  final adUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';

  // 리워드 광고 로드
  void loadRewardedAd(Function onAdLoaded) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('$ad load');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            // 광고가 전체 화면 콘텐츠로 표시되었을 때 호출됩니다.
            onAdShowedFullScreenContent: (ad) {},
            // 광고에서 노출이 발생했을 때 호출됩니다.
            onAdImpression: (ad) {},
            // 광고가 전체 화면 콘텐츠를 표시하는 데 실패했을 때 호출됩니다.
            onAdFailedToShowFullScreenContent: (ad, err) {
              // 리소스를 해제하기 위해 여기서 광고를 폐기합니다.
              ad.dispose();
            },
            // 광고가 전체 화면 콘텐츠에서 닫혔을 때 호출됩니다.
            onAdDismissedFullScreenContent: (ad) {
              // 리소스를 해제하기 위해 여기서 광고를 폐기합니다.
              ad.dispose();
            },
            // 광고 클릭이 기록되었을 때 호출됩니다.
            onAdClicked: (ad) {},
          );
          debugPrint('$ad 로드됨.');
          // 나중에 광고를 표시할 수 있도록 광고 객체를 참조합니다.
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('보상형 광고 오류: $error');
        },
      ),
    );
  }
}
