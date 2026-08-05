import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/withdrawal_model.dart';
import '../../services/withdrawal_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WithdrawalService _withdrawalService = WithdrawalService();
  final _amountController = TextEditingController();
  bool _submitting = false;

  static const int pointsPerDollar = 500;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مبلغًا صحيحًا')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _withdrawalService.requestWithdrawal(
        amount: amount,
        method: 'manual',
      );

      if (!mounted) return;
      _amountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب السحب، بانتظار المراجعة')),
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
      appBar: AppBar(title: const Text('المحفظة')),
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
                  final pointsBalance =
                      (snapshot.data?.data()?['pointsBalance'] ?? 0)
                          .toDouble();
                  final balance = pointsBalance / pointsPerDollar;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('الرصيد القابل للسحب'),
                          const SizedBox(height: 8),
                          Text(
                            '\$${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'المبلغ المطلوب سحبه (USD)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'جاري الإرسال...' : 'طلب سحب'),
            ),
            const SizedBox(height: 24),
            const Text(
              'سجل السحوبات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: uid == null
                  ? const SizedBox()
                  : StreamBuilder<List<WithdrawalModel>>(
                      stream: _withdrawalService.getWithdrawalHistory(uid),
                      builder: (context, snapshot) {
                        final items = snapshot.data ?? [];

                        if (items.isEmpty) {
                          return const Center(
                            child: Text('لا توجد طلبات سحب بعد'),
                          );
                        }

                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final w = items[index];
                            return ListTile(
                              title: Text('\$${w.amount.toStringAsFixed(2)}'),
                              subtitle: Text(_statusLabel(w.status)),
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
        return 'تم الدفع';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}
