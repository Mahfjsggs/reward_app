import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/withdrawal_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WithdrawalService _withdrawalService = WithdrawalService();
  bool _submitting = false;

  static const int minPointsToRedeem = 7500;

  Future<void> _submit(int currentPoints) async {
    if (currentPoints < minPointsToRedeem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نقاطك غير كافية للاسترداد بعد')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _withdrawalService.requestWithdrawal(method: 'manual');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الاسترداد، بانتظار المراجعة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الطلب: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('استرداد النقاط')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (uid != null)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final points =
                      (snapshot.data?.data()?['pointsBalance'] ?? 0) as int;

                  return Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text('نقاطك الحالية'),
                              const SizedBox(height: 8),
                              Text(
                                '$points',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        points >= minPointsToRedeem
                            ? 'رصيدك كافٍ لطلب الاسترداد'
                            : 'تحتاج $minPointsToRedeem نقطة على الأقل للاسترداد',
                        style: TextStyle(
                          color: points >= minPointsToRedeem
                              ? Colors.green
                              : Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : () => _submit(points),
                        child: Text(
                          _submitting ? 'جاري الإرسال...' : 'استرداد المكافأة',
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            const Text(
              'سجل الاستردادات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: uid == null
                  ? const SizedBox()
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('withdrawals')
                          .where('userId', isEqualTo: uid)
                          .orderBy('requestedAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final items = snapshot.data?.docs ?? [];

                        if (items.isEmpty) {
                          return const Center(
                            child: Text('لا توجد طلبات استرداد بعد'),
                          );
                        }

                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final data = items[index].data();
                            final points = data['pointsRedeemed'] ?? 0;
                            final status = data['status'] ?? '';
                            return ListTile(
                              title: Text('$points نقطة'),
                              subtitle: Text(_statusLabel(status)),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'تمت الموافقة';
      case 'processing':
        return 'قيد التحويل';
      case 'paid':
        return 'تم الاسترداد';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}
