import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _ringController;
  double _goalsOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    print('OnboardingScreen initState called');
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _goalsOpacity = 1.0);
    });
  }

  @override
  void dispose() {
    print('OnboardingScreen dispose called');
    _glowController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void handleNext(BuildContext context) {
    print('OnboardingScreen handleNext called');
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    print('OnboardingScreen build called');
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final baseFont = width * 0.045;
    final titleFont = width * 0.08;
    final subtitleFont = width * 0.045;
    final buttonSize = width * 0.28;

    return Scaffold(
      body: Stack(
        children: [
          // Lottie sports animation as full background
          Lottie.asset(
            'assets/animations/sports.json',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            repeat: true,
          ),
          // Premium gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEAF6F6).withOpacity(0.85),
                  Color(0xFFA0D2DB).withOpacity(0.85),
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () async {
                final shouldExit = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Exit Onboarding'),
                    content: const Text('Do you really want to exit?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
                if (shouldExit == true) {
                  SystemNavigator.pop();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child:
                      Icon(Icons.arrow_back, color: Colors.black54, size: 26),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.07,
                vertical: height * 0.04,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      SizedBox(height: height * 0.04),
                      Text(
                        "Crush Your",
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      AnimatedOpacity(
                        opacity: _goalsOpacity,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeInOut,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF4AAB9),
                                Color(0xFFA0D2DB),
                              ],
                            ),
                          ),
                          child: Text(
                            "Health Goals",
                            style: TextStyle(
                              fontSize: baseFont + 2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.04),
                      Text(
                        'Track your progress. Stay consistent. Become unstoppable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: subtitleFont,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: height * 0.04),
                    child: Center(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _scale = 0.92),
                        onTapUp: (_) => setState(() => _scale = 1.0),
                        onTapCancel: () => setState(() => _scale = 1.0),
                        onTap: () {
                          print('Next button tapped');
                          handleNext(context);
                        },
                        child: AnimatedScale(
                          scale: _scale,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF3366FF),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'NEXT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: baseFont + 2,
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = const Color(0xFF92B6D5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final startAngle = -math.pi / 2 + progress * 2 * math.pi;
    final sweepAngle = 2 * math.pi * 0.3;
    canvas.drawArc(rect.deflate(6), startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
