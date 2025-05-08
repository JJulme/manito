import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd; // 로드된 리워드 광고 객체를 저장하는 변수 (nullable)
  bool _isRewardedAdReady = false; // 리워드 광고가 준비되었는지 여부를 나타내는 변수

  // 리워드 광고 준비 상태를 외부에서 읽을 수 있도록 제공하는 getter
  bool get isRewardedAdReady => _isRewardedAdReady;

  // 로드된 리워드 광고 객체를 외부에서 읽을 수 있도록 제공하는 getter (nullable)
  RewardedAd? get rewardedAd => _rewardedAd;

  // 플랫폼에 따른 광고 단위 ID (테스트 ID)
  final adUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Android 테스트 광고 단위 ID
          : 'ca-app-pub-3940256099942544/1712485313'; // iOS 테스트 광고 단위 ID

  // 리워드 광고 로드 함수
  void loadRewardedAd(VoidCallback onAdLoaded) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(), // 광고 요청 객체 (const로 생성하여 불필요한 재생성 방지)
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        // 광고 로드 성공 시 호출되는 콜백
        onAdLoaded: (ad) {
          debugPrint('$ad load');
          _rewardedAd = ad; // 로드된 광고 객체를 저장
          _isRewardedAdReady = true; // 광고 준비 상태를 true로 업데이트
          ad.fullScreenContentCallback = FullScreenContentCallback(
            // 광고가 전체 화면 콘텐츠로 표시되었을 때 호출되는 콜백
            onAdShowedFullScreenContent: (ad) {},
            // 광고에서 노출이 발생했을 때 호출되는 콜백
            onAdImpression: (ad) {},
            // 광고가 전체 화면 콘텐츠를 표시하는 데 실패했을 때 호출되는 콜백
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('광고 표시 실패: $err');
              ad.dispose(); // 실패 시 광고 리소스 해제
              _rewardedAd = null; // 광고 객체 null 처리
              _isRewardedAdReady = false; // 광고 준비 상태를 false로 업데이트
            },
            // 광고가 전체 화면 콘텐츠에서 닫혔을 때 호출되는 콜백
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('$ad dismissed.');
              ad.dispose(); // 닫힐 때 광고 리소스 해제
              _rewardedAd = null; // 광고 객체 null 처리
              _isRewardedAdReady = false; // 광고 준비 상태를 false로 업데이트
              loadRewardedAd(onAdLoaded); // 광고가 닫히면 다음 광고를 미리 로드
            },
            // 광고 클릭이 기록되었을 때 호출되는 콜백
            onAdClicked: (ad) {},
          );
          debugPrint('$ad 로드됨.');
          onAdLoaded(); // 광고 로드 완료를 알리는 콜백 함수 호출
        },
        // 광고 로드 실패 시 호출되는 콜백
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('보상형 광고 로드 실패: $error');
          _isRewardedAdReady = false; // 광고 준비 상태를 false로 업데이트
        },
      ),
    );
  }

  // 리워드 광고 보여주기 함수
  void showRewardedAd(VoidCallback onUserEarnedReward) {
    // 광고가 준비되었고 광고 객체가 null이 아닌 경우에만 광고를 보여줌
    if (_rewardedAd != null && _isRewardedAdReady) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('User earned reward: ${reward.amount}');
          onUserEarnedReward(); // 사용자가 보상을 획득했을 때 호출되는 콜백
        },
      );
    } else {
      print('Rewarded Ad is not ready yet'); // 광고가 아직 준비되지 않았을 때 로그 출력
      // 광고가 준비되지 않았을 때 사용자에게 알림 등을 표시하는 로직 추가 가능
    }
  }

  // 광고 폐기 함수 (리소스 해제)
  void disposeRewardedAd() {
    _rewardedAd?.dispose(); // 광고 객체가 null이 아닌 경우에만 dispose 호출
    _rewardedAd = null; // 광고 객체 null 처리
    _isRewardedAdReady = false; // 광고 준비 상태를 false로 업데이트
  }
}
