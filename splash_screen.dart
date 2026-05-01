import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readify_app/core/routes.dart';
import 'package:readify_app/viewmodel/auth_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Logo Animations
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Alignment> _logoSlideAnimation;

  // Text Animations
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _subTextFadeAnimation;
  late Animation<Offset> _subTextSlideAnimation;

  @override
  void initState() {
    super.initState();

    // ➤ 3-Second Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // 1. Logo Appearance (0.0s - 0.9s)
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // 2. Logo Movement (1.1s - 1.9s)
    _logoSlideAnimation = Tween<Alignment>(
      begin: Alignment.center,
      end: const Alignment(0.0, -0.2),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.375, 0.625, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Text Reveal (1.5s - 2.25s)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    // 4. Subtitle Reveal (1.8s - 2.55s)
    _subTextFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.85, curve: Curves.easeIn),
      ),
    );

    _subTextSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // ➤ 3-Second Splash Delay
    // Ensures the splash screen stays for exactly 3 seconds before navigating.
    Future.delayed(const Duration(seconds: 3), _checkAuthStatus);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user == null) {
        final prefs = await SharedPreferences.getInstance();
        final hasSeenAppIntro = prefs.getBool('hasSeenAppIntro') ?? false;

        if (hasSeenAppIntro) {
          Navigator.pushReplacementNamed(context, Routes.signIn);
        } else {
          Navigator.pushReplacementNamed(context, Routes.appIntro);
        }
        return;
      }

      // User logged in, prepare fetching via ViewModel
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      try {
        // Safely await data fetching and verify/create user document
        await authViewModel.signInWithExistingUser(user).timeout(
          const Duration(seconds: 10),
          onTimeout: () => debugPrint("Splash: Firestore fetch timed out"),
        );
      } catch (e) {
        debugPrint("Splash Screen Error fetching user: $e");
        // Proceeding anyway prevents frozen state 
      }

      if (!mounted) return;

      final role = authViewModel.getUserRole; // Defaults to 'user'
      final isFirstTime = authViewModel.userModel?.isFirstTime ?? true;

      // Navigate based on fetched data
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, Routes.adminDashboard);
      } else if (isFirstTime) {
        Navigator.pushReplacementNamed(context, Routes.onboarding);
      } else {
        Navigator.pushReplacementNamed(context, Routes.home);
      }
    } catch (e, stackTrace) {
      debugPrint("Critical Splash Screen error: $e\n$stackTrace");
      if (mounted) {
        // Fallback sign in screen to avoid total deadlock
        Navigator.pushReplacementNamed(context, Routes.signIn);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Cinematic Background
          _buildBackground(),

          // 2. Floating Dots Animation
          const Positioned.fill(
            child: FloatingDotsBackground(),
          ),

          // 3. Animated Content
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  // Logo Layer
                  Align(
                    alignment: _logoSlideAnimation.value,
                    child: Opacity(
                      opacity: _logoFadeAnimation.value,
                      child: Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: _buildGlowingLogo(),
                      ),
                    ),
                  ),

                  // Text Layer
                  Align(
                    alignment: const Alignment(0.0, 0.25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Name
                        SlideTransition(
                          position: _textSlideAnimation,
                          child: FadeTransition(
                            opacity: _textFadeAnimation,
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFF64B5F6), Color(0xFFFFFFFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                'Readify',
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 4.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // 4. Premium Loading Indicator
          Align(
             alignment: Alignment.bottomCenter,
             child: Padding(
               padding: const EdgeInsets.only(bottom: 60.0),
               child: FadeTransition(
                 opacity: _textFadeAnimation,
                 child: const SizedBox(
                   width: 38,
                   height: 38,
                   child: CircularProgressIndicator(
                     valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
                     backgroundColor: Colors.white12,
                     strokeWidth: 2.5,
                   ),
                 ),
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Deep Gradient Base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B2A), // deep blue top
                Color(0xFF1B263B), // slightly lighter blue bottom
              ],
            ),
          ),
        ),

        // Central Glow
        Center(
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.15),
                  Colors.transparent,
                ],
                radius: 0.6,
              ),
            ),
          ),
        ),

        // Subtle Ambient Blobs
        Positioned(
          top: -100,
          right: -100,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.08),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlowingLogo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1B263B).withOpacity(0.5),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.5,
            ),
            boxShadow: [
              // Pulsating soft glow around logo
              BoxShadow(
                color: const Color(0xFF3A86FF).withOpacity(0.35 * _pulseAnimation.value),
                blurRadius: 50 * _pulseAnimation.value,
                spreadRadius: 15 * _pulseAnimation.value,
              ),
              // Inner core brightness
              BoxShadow(
                color: Colors.white.withOpacity(0.1 * _pulseAnimation.value),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 85,
                height: 85,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.auto_stories_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Floating Dots Animation Widget ---

class FloatingDotsBackground extends StatefulWidget {
  const FloatingDotsBackground({super.key});

  @override
  State<FloatingDotsBackground> createState() => _FloatingDotsBackgroundState();
}

class _FloatingDotsBackgroundState extends State<FloatingDotsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Dot> _dots = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(); // Infinite loop

    // Initialize dots
    for (int i = 0; i < 25; i++) {
      _dots.add(_generateDot());
    }
  }

  Dot _generateDot() {
    return Dot(
      position: Offset(
        _random.nextDouble(), // x: 0.0 to 1.0 (relative)
        _random.nextDouble(), // y: 0.0 to 1.0 (relative)
      ),
      speed: _random.nextDouble() * 0.0005 + 0.0002, // Slow upward speed
      radius: _random.nextDouble() * 2.5 + 1.5, // 1.5 to 4.0 px
      opacity: _random.nextDouble() * 0.5 + 0.1, // 0.1 to 0.6
      color: _random.nextBool()
          ? Colors.white
          : Colors.lightBlueAccent, // Random color
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: DotsPainter(_dots, _random),
          size: Size.infinite,
        );
      },
    );
  }
}

class Dot {
  Offset position;
  final double speed;
  final double radius;
  final double opacity;
  final Color color;

  Dot({
    required this.position,
    required this.speed,
    required this.radius,
    required this.opacity,
    required this.color,
  });
}

class DotsPainter extends CustomPainter {
  final List<Dot> dots;
  final math.Random random;

  DotsPainter(this.dots, this.random);

  @override
  void paint(Canvas canvas, Size size) {
    for (var dot in dots) {
      // Update position (move up)
      double newY = dot.position.dy - dot.speed;
      
      // Reset if goes off screen
      if (newY < -0.1) {
        newY = 1.1;
        dot.position = Offset(random.nextDouble(), newY);
      } else {
        dot.position = Offset(dot.position.dx, newY);
      }

      final paint = Paint()
        ..color = dot.color.withOpacity(dot.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, dot.radius * 0.8);

      // Draw dot
      canvas.drawCircle(
        Offset(dot.position.dx * size.width, dot.position.dy * size.height),
        dot.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint every frame for animation
  }
}
