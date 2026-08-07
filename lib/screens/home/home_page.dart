import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int userPoints = 0;

  final List<Map<String, dynamic>> rewardTasks = [
    {
      'title': 'شاهد إعلان',
      'icon': Icons.play_circle_fill_rounded,
      'color': Colors.redAccent,
      'action': 'watch_ad',
    },
    {
      'title': 'الاستبيانات',
      'icon': Icons.assignment_rounded,
      'color': Colors.blueAccent,
      'action': 'surveys',
    },
    {
      'title': 'الألعاب واربح',
      'icon': Icons.sports_esports_rounded,
      'color': Colors.purple,
      'action': 'games',
    },
    {
      'title': 'نزّل تطبيقات واربح',
      'icon': Icons.get_app_rounded,
      'color': Colors.green,
      'action': 'download_apps',
    },
    {
      'title': 'العروض والاشتراكات',
      'icon': Icons.local_offer_rounded,
      'color': Colors.orange,
      'action': 'offers',
    },
    {
      'title': 'مهام بسيطة',
      'icon': Icons.check_box_rounded,
      'color': Colors.teal,
      'action': 'simple_tasks',
    },
    {
      'title': 'مكافأة الدخول اليومية',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.deepOrange,
      'action': 'daily_bonus',
    },
    {
      'title': 'الإحالة للأصدقاء',
      'icon': Icons.group_add_rounded,
      'color': Colors.indigo,
      'action': 'referral',
    },
    {
      'title': 'التصنيف الأسبوعي',
      'icon': Icons.emoji_events_rounded,
      'color': Colors.amber,
      'action': 'leaderboard',
    },
  ];

  void _handleTaskTap(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('جاري فتح الخيار: $action')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('تطبيق المكافآت', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // بطاقة الرصيد
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text('رصيد النقاط الحالي', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '$userPoints نقطة',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // قائمة المهام التسعة
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: rewardTasks.length,
                itemBuilder: (context, index) {
                  final task = rewardTasks[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _handleTaskTap(task['action']),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(task['icon'], size: 38, color: task['color']),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              task['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
