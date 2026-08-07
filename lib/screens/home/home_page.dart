import 'package:flutter/material.dart';
import '../../services/reward_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int userPoints = 0;
  final RewardService _rewardService = RewardService();

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

  // التعامل مع الضغط على البطاقات
  Future<void> _handleTaskTap(String action) async {
    if (action == 'daily_bonus') {
      _showLoadingDialog();
      final result = await _rewardService.claimDailyBonus();
      Navigator.of(context).pop(); // إغلاق تحميل

      _showMessageSnackBar(result['message']);
    } else if (action == 'referral') {
      _showReferralDialog();
    } else {
      _showMessageSnackBar('قسم $action قيد التطوير والربط.');
    }
  }

  // نافذة إدخال كود الإحالة
  void _showReferralDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال رمز الإحالة', textAlign: TextAlign.center),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'أدخل الكود هنا',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _showLoadingDialog();
                final result = await _rewardService.applyReferralCode(code);
                Navigator.pop(context);
                _showMessageSnackBar(result['message']);
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showMessageSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
