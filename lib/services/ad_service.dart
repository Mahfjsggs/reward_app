import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  final String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await MobileAds.instance.initialize();
  }

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  /// يعرض الإعلان فقط. لا يضيف أي نقاط هنا مباشرة —
  /// إضافة النقاط تصير حصرًا عبر Cloud Functions (startAdSession +
  /// grantAdReward) بعد تأكيد مدة المشاهدة من طرف السيرفر.
  void showRewardedAd({
    required BuildContext context,
    required Function() onAdCompleted,
    required Function() onAdFailed,
  }) {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      onAdFailed();
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        loadRewardedAd();
        onAdFailed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutViewUnscoped ad, RewardItem reward) {
        onAdCompleted();
      },
    );

    _rewardedAd = null;
    _isRewardedAdReady = false;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
  }
}
