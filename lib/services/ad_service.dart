import 'package:cloud_functions/cloud_functions.dart';

class AdService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool isAdReady = true;

  Future<void> loadRewardedAd({
    required void Function() onLoaded,
    required void Function(String error) onFailed,
  }) async {
    onLoaded();
  }

  Future<String> startAdSession() async {
    final result = await _functions
        .httpsCallable('startAdSession')
        .call({'adNetwork': 'admob', 'adType': 'rewarded'});

    return result.data['eventId'] as String;
  }

  Future<void> showAd({
    required String eventId,
    required void Function() onUserEarnedReward,
    required void Function() onAdClosed,
    required void Function(String error) onFailed,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      await _confirmAdCompletion(eventId);
      onUserEarnedReward();
      onAdClosed();
    } catch (e) {
      onFailed(e.toString());
    }
  }

  Future<void> _confirmAdCompletion(String eventId) async {
    await _functions
        .httpsCallable('grantAdReward')
        .call({'eventId': eventId});
  }

  void dispose() {}
}
