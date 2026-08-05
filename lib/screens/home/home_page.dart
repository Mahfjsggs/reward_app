import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../features/withdrawals_feed/withdrawals_page.dart';
import '../../features/leaderboard/leaderboard_page.dart';
import '../spin_wheel_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول')));
    }

    final userService = UserService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: userService.getUserStream(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('لم يتم العثور على بيانات المستخدم'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'مرحبًا ${user.name}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.stars, size: 60),
                      const SizedBox(height: 10),
                      const Text('نقاطك', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text(
                        '${user.pointsBalance}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('الرصيد القابل للسحب'),
                  subtitle: Text(
                    '\$${(user.pointsBalance / 500).toStringAsFixed(2)}',
                  ),
                  onTap: () => Navigator.pushNamed(context, '/wallet'),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/rewards'),
                icon: const Icon(Icons.play_circle),
                label: const Text('شاهد إعلانًا واربح نقاط'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpinWheelScreen(),
                  ),
                ),
                icon: const Icon(Icons.casino),
                label: const Text('عجلة الحظ اليومية 🎡'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.leaderboard),
                  title: const Text('التصنيف الأسبوعي'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaderboardPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: const Text('آخر السحوبات'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WithdrawalsFeedPage(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
