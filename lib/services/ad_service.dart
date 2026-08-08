import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdService {
  RewardedAd? _rewardedAd;

  final String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await MobileAds.instance.initialize();
  }

  void loadRewardedAd({
    required VoidCallback onLoaded,
    required Function(Object error) onFailed,
  }) {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          onLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          onFailed(error);
        },
      ),
    );
  }

  /// يبدأ جلسة إعلان موثقة بالسيرفر قبل عرض الإعلان،
  /// ويرجع eventId يُستخدم لاحقًا للتحقق من صحة المشاهدة.
  Future<String> startAdSession() async {
    final result = await _functions.httpsCallable('startAdSession').call({
      'adNetwork': 'admob',
      'adType': 'rewarded',
    });
    return result.data['eventId'] as String;
  }

  /// يعرض الإعلان، وعند اكتمال المشاهدة يتحقق من السيرفر
  /// (grantAdReward) قبل اعتبار المستخدم مستحقًا للنقاط.
  Future<void> showAd({
    required String eventId,
    required VoidCallback onUserEarnedReward,
    required VoidCallback onAdClosed,
    required Function(Object error) onFailed,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      onFailed('الإعلان غير جاهز');
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        onFailed(error);
      },
    );

    ad.show(
      onUserEarnedReward: (RewardedAd ad, RewardItem reward) async {
        try {
          await _functions.httpsCallable('grantAdReward').call({
            'eventId': eventId,
          });
          onUserEarnedReward();
        } catch (e) {
          onFailed(e);
        }
      },
    );

    _rewardedAd = null;
  }

  /// دالة إضافية متوافقة مع الاستدعاآت التلقائية باسم showRewardedAd
  Future<void> showRewardedAd({
    required String eventId,
    required VoidCallback onUserEarnedReward,
    required VoidCallback onAdClosed,
    required Function(Object error) onFailed,
  }) async {
    await showAd(
      eventId: eventId,
      onUserEarnedReward: onUserEarnedReward,
      onAdClosed: onAdClosed,
      onFailed: onFailed,
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
