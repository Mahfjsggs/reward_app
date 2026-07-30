import 'package:cloud_firestore/cloud_firestore.dart';

class PointTransactionModel {
  final String id;
  final String userId;
  final String type;
  final int points;
  final String referenceId;
  final DateTime? createdAt;

  PointTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    required this.referenceId,
    this.createdAt,
  });

  factory PointTransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? {};
    return PointTransactionModel(
      id: snap.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      points: data['points'] ?? 0,
      referenceId: data['referenceId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
