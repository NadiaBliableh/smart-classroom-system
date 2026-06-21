import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LearnRoomApp());
}

class LearnRoomApp extends StatelessWidget {
  const LearnRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learn Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1325),
      ),
      home: const LearnRoomLoading(),
    );
  }
}

class LearnRoomLoading extends StatefulWidget {
  const LearnRoomLoading({super.key});

  @override
  State<LearnRoomLoading> createState() => _LearnRoomLoadingState();
}

class _LearnRoomLoadingState extends State<LearnRoomLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userName = prefs.getString('userName');
    final userRole = prefs.getString('userRole');

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            isLoggedIn && userName != null && userRole != null
                ? HomeScreen(userName: userName, userRole: userRole)
                : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = screenWidth * 0.13;
    final plusSize = screenWidth * 0.10;
    final verticalOffset = -(baseFontSize * 0.7);

    final baseStyle = TextStyle(
      fontSize: baseFontSize,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      letterSpacing: -1.5,
    );

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Learn", style: baseStyle),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Transform.translate(
                        offset: Offset(-5, verticalOffset),
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4DA3FF)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 35,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  size: Size(plusSize, plusSize),
                                  painter: PlusLogoPainter(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: "Room", style: baseStyle),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "SMART UNIVERSITY CLASSROOM",
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 90),
              SizedBox(
                width: screenWidth * 0.7,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: const LinearProgressIndicator(
                        backgroundColor: Color(0xFF1E244A),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4DA3FF),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "INITIALIZING SMART SYSTEM...",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlusLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF4DA3FF),
          Color(0xFF12C2A2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final thickness = size.width * 0.32;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width,
          height: thickness,
        ),
        const Radius.circular(6),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: thickness,
          height: size.height,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}