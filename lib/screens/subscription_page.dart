import 'package:flutter/material.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String _selectedPlan = 'weekly';

  void _processSubscription() {
    final planName = _selectedPlan == 'weekly' ? 'الأسبوعي (\$1)' : 'الشهري (\$10)';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاشتراك', textAlign: TextAlign.center),
        content: Text('هل ترغب في تفعيل الاشتراك $planName والاستفادة من مميزات VIP؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سيتم ربط بوابة الدفع الإلكتروني قريباً لتفعيل الاشتراك!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
            child: const Text('تأكيد وشراء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اشتراك VIP'),
        centerTitle: true,
        backgroundColor: Colors.amber.shade800,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade700, Colors.orangeAccent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.workspace_premium, size: 50, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'عضوية VIP المميزة',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ضاعف أرباحك وتصفح بدون إعلانات منبثقة',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerRight,
                child: Text('مميزات الاشتراك:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              _buildFeatureRow(Icons.bolt, 'مضاعفة النقاط (2x) على مشاهدة الإعلانات والمهام'),
              _buildFeatureRow(Icons.block, 'إلغاء الإعلانات المنبثقة والمفاجئة أثناء التصفح'),
              _buildFeatureRow(Icons.card_giftcard, 'مكافأة دخول يومية مضاعفة'),
              _buildFeatureRow(Icons.speed, 'أولوية وسرعة فائقة في معالجة طلبات السحب'),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: _buildPlanCard(
                      id: 'weekly',
                      title: 'أسبوعي',
                      price: '\$1.00',
                      period: 'لكل أسبوع',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPlanCard(
                      id: 'monthly',
                      title: 'شهري',
                      price: '\$10.00',
                      period: 'لكل شهر (أفضل قيمة)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _processSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'اشترك الآن - ${_selectedPlan == 'weekly' ? '\$1 / أسبوع' : '\$10 / شهر'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildPlanCard({required String id, required String title, required String price, required String period}) {
    final isSelected = _selectedPlan == id;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.amber.shade800 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(price, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
            const SizedBox(height: 4),
            Text(period, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
