import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// كل التفاعل مع الإعلانات يمر عبر Cloud Functions.
/// التطبيق لا يقرر وحده أن المستخدم يستحق نقاط.
class AdService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  /// ضع هنا Ad Unit ID الحقيقي الخاص بك من AdMob.
  /// هذا المعرف أدناه تجريبي (Test Ad Unit من Google).
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  Future<void> loadRewardedAd({
    required void Function() onLoaded,
    required void Function(String error) onFailed,
  }) async {
    if (_isLoading) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          onLoaded();
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          onFailed(error.message);
        },
      ),
    );
  }

  /// الخطوة 1: نطلب من السيرفر فتح جلسة إعلان (بدل أن يكتبها التطبيق مباشرة).
  Future<String> startAdSession() async {
    final result = await _functions
        .httpsCallable('startAdSession')
        .call({'adNetwork': 'admob', 'adType': 'rewarded'});

    return result.data['eventId'] as String;
  }

  /// الخطوة 2: نعرض الإعلان. لا نمنح نقاط هنا محليًا أبدًا.
  Future<void> showAd({
    required String eventId,
    required void Function() onUserEarnedReward,
    required void Function() onAdClosed,
    required void Function(String error) onFailed,
  }) async {
    final ad = _rewardedAd;

    if (ad == null) {
      onFailed('لا يوجد إعلان محمّل حاليًا');
      return;
    }

    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdClosed();

        // الخطوة 3: نخبر السيرفر أن الإعلان انتهى ليتحقق ويمنح النقاط.
        if (earned) {
          _confirmAdCompletion(eventId).then((_) {
            onUserEarnedReward();
          }).catchError((e) {
            onFailed(e.toString());
          });
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onFailed(error.message);
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
      },
    );
  }

  /// الخطوة 3: نطلب من الـ Cloud Function التحقق من إتمام الإعلان
  /// ومنح النقاط بشكل آمن. هذا الاستدعاء وحده لا يكفي كدليل،
  /// السيرفر يجب أن يتحقق من حالة الجلسة أيضًا (انظر functions/src/rewards.ts).
  Future<void> _confirmAdCompletion(String eventId) async {
    await _functions
        .httpsCallable('grantAdReward')
        .call({'eventId': eventId});
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
