import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // نفس منطق تحديد "الأسبوع" لازم يطابق كيف يتم إنشاء weekId
    // في السيرفر لاحقًا (سنستخدم سنة+رقم الأسبوع كمعرف)
    final weekId = _weekId(now);

    return Scaffold(
      appBar: AppBar(title: const Text('التصنيف الأسبوعي')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('weeklyLeaderboards')
            .doc(weekId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ أثناء تحميل التصنيف: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('لم يبدأ التصنيف الأسبوعي بعد'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final entries = (data['entries'] as List<dynamic>?) ?? [];

          if (entries.isEmpty) {
            return const Center(
              child: Text('لا توجد نتائج بعد لهذا الأسبوع'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index] as Map<String, dynamic>;
              final rank = index + 1;
              final name = entry['displayName'] ?? 'مستخدم';
              final points = entry['points'] ?? 0;
              final adsWatched = entry['adsWatched'] ?? 0;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: rank <= 3
                        ? const Color(0xFFFFD54F)
                        : null,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank <= 3 ? Colors.black : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text('$adsWatched إعلان'),
                  trailing: Text(
                    '$points نقطة',
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

  String _weekId(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysPassed = date.difference(firstDayOfYear).inDays;
    final weekNumber = ((daysPassed + firstDayOfYear.weekday) / 7).ceil();
    return '${date.year}-W$weekNumber';
  }
}
