import 'package:flutter/material.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({Key? key}) : super(key: key);

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController _accountController = TextEditingController();
  String? _selectedMethod;

  final List<Map<String, dynamic>> _methods = [
    {
      'name': 'Zain Cash - زين كاش',
      'icon': Icons.phone_android,
      'color': Colors.redAccent,
      'hint': 'أدخل رقم المحفظة (078xxxxxxx)',
    },
    {
      'name': 'PayPal - بايبال',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
      'hint': 'أدخل البريد الإلكتروني الخاص بـ PayPal',
    },
    {
      'name': 'USDT (TRC20)',
      'icon': Icons.currency_bitcoin,
      'color': Colors.green,
      'hint': 'أدخل عنوان المحفظة (TRC20)',
    },
  ];

  void _submitWithdrawal() {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار طريقة السحب أولاً')),
      );
      return;
    }

    final accountInfo = _accountController.text.trim();
    if (accountInfo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال تفاصيل الحساب/الرقم')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الطلب', textAlign: TextAlign.center),
        content: Text('هل أنت متأكد من تقديم طلب سحب عبر:\n$_selectedMethod\nإلى: $accountInfo؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _accountController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال طلب السحب بنجاح! سيتم مراجعته قريباً.')),
              );
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سحب الأرباح'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر طريقة السحب:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _methods.length,
                  itemBuilder: (context, index) {
                    final method = _methods[index];
                    final isSelected = _selectedMethod == method['name'];
                    return Card(
                      color: isSelected ? Colors.indigo.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isSelected ? Colors.indigo : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(method['icon'], color: method['color']),
                        title: Text(method['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.indigo) : null,
                        onTap: () {
                          setState(() {
                            _selectedMethod = method['name'];
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              if (_selectedMethod != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    labelText: 'بيانات الحساب / الرقم',
                    hintText: _methods.firstWhere((m) => m['name'] == _selectedMethod)['hint'],
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitWithdrawal,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    child: const Text('تقديم طلب السحب', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
