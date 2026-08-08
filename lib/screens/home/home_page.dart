import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/reward_service.dart';
import '../withdraw_page.dart';
import '../subscription_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RewardService _rewardService = RewardService();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // متغير للتحكم باللغة (تلقائياً عربي)
  bool isArabic = true;

  // نصوص اللغة العربية والإنجليزية
  Map<String, Map<String, String>> get _localizedTexts => {
        'ar': {
          'app_title': 'تطبيق المكافآت',
          'points_balance': 'رصيد النقاط الحالي',
          'points_unit': 'نقطة',
          'withdraw': 'سحب الأرباح',
          'watch_ad': 'شاهد إعلان',
          'surveys': 'الاستبيانات',
          'games': 'الألعاب واربح',
          'download_apps': 'نزّل تطبيقات واربح',
          'offers': 'العروض والاشتراكات',
          'simple_tasks': 'مهام بسيطة',
          'daily_bonus': 'مكافأة الدخول اليومية',
          'referral': 'الإحالة للأصدقاء',
          'leaderboard': 'التصنيف الأسبوعي',
          'dev_message': 'هذا القسم قيد التطوير وسيتم إتاحته قريباً!',
          'enter_code': 'إدخال رمز الإحالة',
          'hint_code': 'أدخل الكود هنا',
          'cancel': 'إلغاء',
          'confirm': 'تأكيد',
          'service_unavailable': 'عذراً، الخدمة غير متوفرة حالياً.',
        },
        'en': {
          'app_title': 'Rewards App',
          'points_balance': 'Current Points Balance',
          'points_unit': 'Points',
          'withdraw': 'Withdraw Profits',
          'watch_ad': 'Watch Ad',
          'surveys': 'Surveys',
          'games': 'Play & Earn',
          'download_apps': 'Download Apps',
          'offers': 'Offers & Subscriptions',
          'simple_tasks': 'Simple Tasks',
          'daily_bonus': 'Daily Bonus',
          'referral': 'Refer Friends',
          'leaderboard': 'Weekly Leaderboard',
          'dev_message': 'This section is under development and will be available soon!',
          'enter_code': 'Enter Referral Code',
          'hint_code': 'Enter code here',
          'cancel': 'Cancel',
          'confirm': 'Confirm',
          'service_unavailable': 'Sorry, service is currently unavailable.',
        },
      };

  String _getText(String key) {
    final lang = isArabic ? 'ar' : 'en';
    return _localizedTexts[lang]?[key] ?? key;
  }

  List<Map<String, dynamic>> get rewardTasks => [
        {
          'title': _getText('withdraw'),
          'icon': Icons.account_balance_wallet_rounded,
          'color': Colors.green,
          'action': 'withdraw',
        },
        {
          'title': _getText('watch_ad'),
          'icon': Icons.play_circle_fill_rounded,
          'color': Colors.redAccent,
          'action': 'watch_ad',
        },
        {
          'title': _getText('surveys'),
          'icon': Icons.assignment_rounded,
          'color': Colors.blueAccent,
          'action': 'surveys',
        },
        {
          'title': _getText('games'),
          'icon': Icons.sports_esports_rounded,
          'color': Colors.purple,
          'action': 'games',
        },
        {
          'title': _getText('download_apps'),
          'icon': Icons.get_app_rounded,
          'color': Colors.teal,
          'action': 'download_apps',
        },
        {
          'title': _getText('offers'),
          'icon': Icons.local_offer_rounded,
          'color': Colors.orange,
          'action': 'offers',
        },
        {
          'title': _getText('simple_tasks'),
          'icon': Icons.check_box_rounded,
          'color': Colors.cyan,
          'action': 'simple_tasks',
        },
        {
          'title': _getText('daily_bonus'),
          'icon': Icons.local_fire_department_rounded,
          'color': Colors.deepOrange,
          'action': 'daily_bonus',
        },
        {
          'title': _getText('referral'),
          'icon': Icons.group_add_rounded,
          'color': Colors.indigo,
          'action': 'referral',
        },
        {
          'title': _getText('leaderboard'),
          'icon': Icons.emoji_events_rounded,
          'color': Colors.amber,
          'action': 'leaderboard',
        },
      ];

  // التعامل مع الضغط على البطاقات
  Future<void> _handleTaskTap(String action) async {
    if (action == 'withdraw') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WithdrawPage()),
      );
    } else if (action == 'offers') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionPage()),
      );
    } else if (action == 'daily_bonus') {
      _showLoadingDialog();
      final result = await _rewardService.claimDailyBonus();
      if (!mounted) return;
      Navigator.of(context).pop();

      if (result['success'] == true) {
        _showMessageSnackBar(result['message']);
      } else {
        _showMessageSnackBar(_getText('service_unavailable'));
      }
    } else if (action == 'referral') {
      _showReferralDialog();
    } else {
      _showMessageSnackBar(_getText('dev_message'));
    }
  }

  // نافذة إدخال كود الإحالة
  void _showReferralDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('enter_code'), textAlign: TextAlign.center),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: _getText('hint_code'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _showLoadingDialog();
                final result = await _rewardService.applyReferralCode(code);
                if (!mounted) return;
                Navigator.pop(context);
                _showMessageSnackBar(result['message']);
              }
            },
            child: Text(_getText('confirm')),
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
    final tasks = rewardTasks;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(_getText('app_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          // زر تغيير اللغة في شريط التطبيق العلوي
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'تغيير اللغة / Change Language',
            onPressed: () {
              setState(() {
                isArabic = !isArabic;
              });
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            // كارت عرض النقاط
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
                  Text(_getText('points_balance'), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  userId == null
                      ? Text('0 ${_getText('points_unit')}',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))
                      : StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 32,
                                width: 32,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              );
                            }
                            int points = 0;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              points = data?['points'] ?? 0;
                            }
                            return Text(
                              '$points ${_getText('points_unit')}',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            );
                          },
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
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
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
