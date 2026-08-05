import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

// نفس ترتيب الجوائز الموجود بـ spinWheel.ts بالسيرفر - لازم يطابق بالضبط
const List<int> wheelPrizes = [20, 50, 30, 20, 50, 30, 20, 50];

const List<List<Color>> segmentGradients = [
  [Color(0xFF6C3FC5), Color(0xFF9B6FEA)], // بنفسجي
  [Color(0xFFD4AF37), Color(0xFFF5D97A)], // ذهبي
  [Color(0xFF6C3FC5), Color(0xFF9B6FEA)],
  [Color(0xFFD4AF37), Color(0xFFF5D97A)],
  [Color(0xFF6C3FC5), Color(0xFF9B6FEA)],
  [Color(0xFFD4AF37), Color(0xFFF5D97A)],
  [Color(0xFF6C3FC5), Color(0xFF9B6FEA)],
  [Color(0xFFD4AF37), Color(0xFFF5D97A)],
];

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _errorMessage = null;
    });

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('spinWheel');
      final result = await callable.call();

      final int prizeIndex = result.data['prizeIndex'];
      final int prizePoints = result.data['prizePoints'];

      const anglePerSegment = 2 * pi / 8;
      const extraFullSpins = 6;

      final targetAngle = (extraFullSpins * 2 * pi) -
          (prizeIndex + 0.5) * anglePerSegment;

      _rotationAnimation = Tween<double>(
        begin: _currentAngle,
        end: _currentAngle + targetAngle,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      _controller.reset();
      await _controller.forward();

      _currentAngle = (_currentAngle + targetAngle) % (2 * pi);

      if (mounted) {
        setState(() => _isSpinning = false);
        _showPrizeDialog(prizePoints);
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _isSpinning = false;
        _errorMessage = e.message ?? 'حدث خطأ، حاول مرة أخرى';
      });
      _showErrorSnackBar(_errorMessage!);
    } catch (e) {
      setState(() {
        _isSpinning = false;
        _errorMessage = 'حدث خطأ بالاتصال، تأكد من الإنترنت';
      });
      _showErrorSnackBar(_errorMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: const Color(0xFF2B2B2B),
      ),
    );
  }

  void _showPrizeDialog(int points) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF2B1B4A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'مبروك!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ربحت $points نقطة',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B6FEA),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'تمام',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('عجلة الحظ اليومية'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // توهج نيون خارجي
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9B6FEA).withOpacity(0.6),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                          blurRadius: 60,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // العجلة نفسها
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final angle = _controller.isAnimating
                          ? _rotationAnimation.value
                          : _currentAngle;
                      return Transform.rotate(
                        angle: angle,
                        child: child,
                      );
                    },
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: _WheelPainter(),
                    ),
                  ),
                  // المؤشر بالأعلى
                  Positioned(
                    top: -6,
                    child: Container(
                      width: 0,
                      height: 0,
                      decoration: const BoxDecoration(),
                      child: CustomPaint(
                        size: const Size(30, 36),
                        painter: _PointerPainter(),
                      ),
                    ),
                  ),
                  // زر الدوران بالمنتصف
                  GestureDetector(
                    onTap: _spin,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B6FEA), Color(0xFF6C3FC5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.8),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isSpinning
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'دور!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'دورة واحدة مجانية كل يوم',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const anglePerSegment = 2 * pi / 8;

    for (int i = 0; i < 8; i++) {
      final startAngle = -pi / 2 + i * anglePerSegment;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: segmentGradients[i],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        anglePerSegment,
        true,
        paint,
      );

      // خط فاصل ذهبي بين كل قطاع
      final linePaint = Paint()
        ..color = const Color(0xFFD4AF37)
        ..strokeWidth = 2;
      canvas.drawLine(
        center,
        center +
            Offset(cos(startAngle), sin(startAngle)) * radius,
        linePaint,
      );

      // نص عدد النقاط بمنتصف كل قطاع
      final textAngle = startAngle + anglePerSegment / 2;
      final textOffset = center +
          Offset(cos(textAngle), sin(textAngle)) * (radius * 0.65);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${wheelPrizes[i]}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        textOffset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // إطار خارجي ذهبي
    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    final paint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    canvas.drawShadow(path, Colors.black, 6, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
