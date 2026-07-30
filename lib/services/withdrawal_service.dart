import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/withdrawal_model.dart';

class WithdrawalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// السحب لا يُنشأ مباشرة في Firestore من التطبيق،
  /// لأن السيرفر هو من يجب أن يتحقق من الحد الأدنى ومن withdrawableBalance
  /// قبل قبول الطلب (لمنع طلب سحب أكبر من الرصيد الفعلي).
  Future<void> requestWithdrawal({
    required double amount,
    required String method,
  }) async {
    await _functions.httpsCallable('requestWithdrawal').call({
      'amount': amount,
      'method': method,
    });
  }

  Stream<List<WithdrawalModel>> getWithdrawalHistory(String uid) {
    return _firestore
        .collection('withdrawals')
        .where('userId', isEqualTo: uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (q) => q.docs.map((d) => WithdrawalModel.fromFirestore(d)).toList(),
        );
  }
}
