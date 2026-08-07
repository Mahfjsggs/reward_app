import 'package:cloud_functions/cloud_functions.dart';

class RewardService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // 1. طلب مكافأة الدخول اليومية
  Future<Map<String, dynamic>> claimDailyBonus() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('claimDailyBonus');
      final response = await callable.call();
      return {
        'success': true,
        'message': response.data['message'] ?? 'تم استلام المكافأة بنجاح!',
      };
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'حدث خطأ أثناء استلام المكافأة.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الاتصال بالسيرفر.',
      };
    }
  }

  // 2. تطبيق رمز الإحالة
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('applyReferralCode');
      final response = await callable.call({'referralCode': code});
      return {
        'success': true,
        'message': response.data['message'] ?? 'تم تطبيق كود الإحالة!',
      };
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'فشل في تطبيق رمز الإحالة.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الاتصال بالسيرفر.',
      };
    }
  }
}
