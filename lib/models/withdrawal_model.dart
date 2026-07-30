import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalModel {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String status; // pending | approved | processing | paid | rejected
  final String method;
  final DateTime? requestedAt;

  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.method,
    this.requestedAt,
  });

  factory WithdrawalModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? {};
    return WithdrawalModel(
      id: snap.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      status: data['status'] ?? 'pending',
      method: data['method'] ?? 'manual',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate(),
    );
  }
}
