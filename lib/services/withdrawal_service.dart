import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/withdrawal_model.dart';

class WithdrawalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// الاسترداد لا يُنشأ مباشرة في Firestore من التطبيق، ولا يحتاج المستخدم
  /// يكتب مبلغًا — السيرفر هو من يحسب النقاط المتاحة ويسترد كامل الرصيد
  /// دفعة واحدة تلقائيًا.
  Future<void> requestWithdrawal({String method = 'manual'}) async {
    await _functions.httpsCallable('requestWithdrawal').call({
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
