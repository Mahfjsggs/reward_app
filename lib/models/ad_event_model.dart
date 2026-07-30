import 'package:cloud_firestore/cloud_firestore.dart';

class AdEventModel {
  final String id;
  final String userId;
  final String adNetwork;
  final String adType;
  final String status; // started | completed | verified | rejected
  final int rewardPoints;
  final DateTime? startedAt;
  final DateTime? completedAt;

  AdEventModel({
    required this.id,
    required this.userId,
    required this.adNetwork,
    required this.adType,
    required this.status,
    required this.rewardPoints,
    this.startedAt,
    this.completedAt,
  });

  factory AdEventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? {};
    return AdEventModel(
      id: snap.id,
      userId: data['userId'] ?? '',
      adNetwork: data['adNetwork'] ?? '',
      adType: data['adType'] ?? '',
      status: data['status'] ?? 'started',
      rewardPoints: data['rewardPoints'] ?? 0,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}
