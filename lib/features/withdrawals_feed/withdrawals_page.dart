import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WithdrawalsFeedPage extends StatelessWidget {
  const WithdrawalsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آخر السحوبات')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('publicWithdrawals')
            .orderBy('completedAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ أثناء تحميل السحوبات: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('لا توجد سحوبات بعد'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['displayName'] ?? 'مستخدم';
              final amount = data['amount'] ?? 0;
              final currency = data['currency'] ?? 'USD';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet),
                  ),
                  title: Text(name),
                  trailing: Text(
                    '$amount $currency',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
