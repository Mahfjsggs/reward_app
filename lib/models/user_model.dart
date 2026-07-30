import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String status;

  final int pointsBalance;
  final int totalPointsEarned;
  final int totalPointsSpent;

  final double withdrawableBalance;

  final String referralCode;

  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.pointsBalance,
    required this.totalPointsEarned,
    required this.totalPointsSpent,
    required this.withdrawableBalance,
    required this.referralCode,
    this.createdAt,
    this.lastLoginAt,
    this.lastActiveAt,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return UserModel(
      uid: snapshot.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      status: data['status'] ?? 'active',
      pointsBalance: data['pointsBalance'] ?? 0,
      totalPointsEarned: data['totalPointsEarned'] ?? 0,
      totalPointsSpent: data['totalPointsSpent'] ?? 0,
      withdrawableBalance: (data['withdrawableBalance'] ?? 0).toDouble(),
      referralCode: data['referralCode'] ?? '',
      createdAt: _dateFromTimestamp(data['createdAt']),
      lastLoginAt: _dateFromTimestamp(data['lastLoginAt']),
      lastActiveAt: _dateFromTimestamp(data['lastActiveAt']),
    );
  }

  static DateTime? _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
