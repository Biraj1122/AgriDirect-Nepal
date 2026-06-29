import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../../models/user_data.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _subtitleOpacity;
  
  bool _isNavigated = false;
  String? _errorMessage;
  bool _showSkipButton = false;
  Timer? _skipTimer;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();
    
    _skipTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() => _showSkipButton = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    final stopwatch = Stopwatch()..start();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));

      await UserData.init();
      
      final int elapsed = stopwatch.elapsedMilliseconds;
      final int remaining = 4000 - elapsed;

      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      }
      
      _navigateToLogin();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      stopwatch.stop();
    }
  }

  void _navigateToLogin() {
    if (!mounted || _isNavigated) return;
    _isNavigated = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _skipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLargeScreen = size.height > 800;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade900,
              Colors.green.shade700,
              Colors.green.shade500,
              Colors.lightGreen.shade400,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.eco, size: isLargeScreen ? 300 : 200, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Opacity(
                opacity: 0.05,
                child: Icon(Icons.agriculture, size: isLargeScreen ? 250 : 180, color: Colors.white),
              ),
            ),
            
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SlideTransition(
                      position: _logoSlide,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Container(
                            padding: EdgeInsets.all(isLargeScreen ? 10 : 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                "assets/images/logo_adaptive.png",
                                height: isLargeScreen ? 160 : 160,
                                width: isLargeScreen ? 160 : 160,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.eco, size: isLargeScreen ? 100 : 80, color: Colors.green),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isLargeScreen ? 40 : 30),
                    
                    FadeTransition(
                      opacity: _textOpacity,
                      child: const Column(
                        children: [
                          Text(
                            "Farmtech",
                            style: TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "AgriDirect Nepal",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isLargeScreen ? 80 : 60),
                    
                    if (_errorMessage == null) ...[
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 2.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      if (_showSkipButton)
                        Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: TextButton(
                            onPressed: _navigateToLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: const Text(
                              "Continue to App",
                              style: TextStyle(decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white70, size: 40),
                            const SizedBox(height: 16),
                            Text(
                              "Startup Issue: $_errorMessage",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                setState(() => _errorMessage = null);
                                _initApp();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green.shade900,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _subtitleOpacity,
                child: const Text(
                  "Connecting Farmers, Empowering Nepal",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
