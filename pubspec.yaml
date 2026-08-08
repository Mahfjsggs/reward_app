import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  // معرف إعلان الفيديو التجريبي المعتمد رسمياً من Google AdMob
  final String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // تهيئة AdMob عند تشغيل التطبيق
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await MobileAds.instance.initialize();
  }

  // تحميل إعلان الفيديو بمكافأة (Rewarded Ad)
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

  // عرض الإعلان وإضافة النقاط للمستخدم فور اكتمال المشاهدة
  void showRewardedAd({
    required BuildContext context,
    required Function(int pointsEarned) onRewardEarned,
    required Function() onAdFailed,
  }) {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      onAdFailed();
      loadRewardedAd(); // إعادة التحميل للمرة القادمة
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        loadRewardedAd(); // تحميل إعلان جديد بعد إغلاق الحالي
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        loadRewardedAd();
        onAdFailed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutViewUnscoped ad, RewardItem reward) async {
        const int rewardAmount = 10; // عدد النقاط المضافة عند مشاهدة الإعلان
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId != null) {
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'points': FieldValue.increment(rewardAmount),
          });
        }

        onRewardEarned(rewardAmount);
      },
    );

    _rewardedAd = null;
    _isRewardedAdReady = false;
  }
}
