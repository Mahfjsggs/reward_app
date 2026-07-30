import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/point_transaction_model.dart';

/// هذا السيرفس للقراءة فقط.
/// أي تعديل على النقاط يمر حصرًا عبر Cloud Functions.
class PointsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> getPointsBalanceStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (snap) => (snap.data()?['pointsBalance'] ?? 0) as int,
        );
  }

  Stream<List<PointTransactionModel>> getRecentTransactions(
    String uid, {
    int limit = 20,
  }) {
    return _firestore
        .collection('pointTransactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (query) => query.docs
              .map((d) => PointTransactionModel.fromFirestore(d))
              .toList(),
        );
  }
}
