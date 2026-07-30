import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/ad_service.dart';
import '../../services/points_service.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final AdService _adService = AdService();
  final PointsService _pointsService = PointsService();

  bool _adReady = false;
  bool _busy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _adService.loadRewardedAd(
      onLoaded: () => setState(() => _adReady = true),
      onFailed: (e) => setState(() {
        _adReady = false;
        _statusMessage = 'تعذر تحميل الإعلان، حاول لاحقًا';
      }),
    );
  }

  Future<void> _watchAd() async {
    if (!_adReady || _busy) return;

    setState(() {
      _busy = true;
      _statusMessage = 'جاري تجهيز الإعلان...';
    });

    try {
      final eventId = await _adService.startAdSession();

      await _adService.showAd(
        eventId: eventId,
        onUserEarnedReward: () {
          setState(() {
            _statusMessage = '✅ تمت إضافة نقاطك بنجاح';
            _busy = false;
            _adReady = false;
          });
          _loadAd();
        },
        onAdClosed: () {
          // إذا لم يُكمل المستخدم المشاهدة لن تُمنح نقاط أصلاً
        },
        onFailed: (e) {
          setState(() {
            _statusMessage = 'حدث خطأ: $e';
            _busy = false;
          });
          _loadAd();
        },
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'تعذر بدء الإعلان، حاول مرة أخرى';
        _busy = false;
      });
    }
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('اربح نقاط')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (uid != null)
              StreamBuilder<int>(
                stream: _pointsService.getPointsBalanceStream(uid),
                builder: (context, snapshot) {
                  final points = snapshot.data ?? 0;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('رصيدك الحالي'),
                          const SizedBox(height: 8),
                          Text(
                            '$points نقطة',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _adReady && !_busy ? _watchAd : null,
              icon: const Icon(Icons.play_circle),
              label: Text(
                _busy ? 'جاري التحميل...' : 'شاهد إعلانًا واربح نقاط',
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
