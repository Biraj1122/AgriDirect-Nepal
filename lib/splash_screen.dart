import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'user_data.dart';
import 'cart_model.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> scaleAnimation;
  late Animation<double> opacityAnimation;
  bool _isNavigated = false;
  String? _errorMessage;
  bool _showSkipButton = false;
  Timer? _skipTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    
    // Show skip button after 7 seconds if still loading
    _skipTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        setState(() => _showSkipButton = true);
      }
    });

    // Start Initialization after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    try {
      debugPrint("Starting Initialization...");
      
      // 1. Initialize Firebase
      debugPrint("Initializing Firebase...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
      debugPrint("Firebase Initialized.");

      // 2. Initialize App Data
      debugPrint("Initializing UserData...");
      await UserData.init();
      
      debugPrint("Initializing CartModel...");
      try {
        cartModel.initialize();
      } catch (e) {
        debugPrint("CartModel Init Warning: $e");
      }

      // 3. Small delay for animation smoothness
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint("Navigating to Login...");
      _navigateToLogin();
    } catch (e) {
      debugPrint("Startup Error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
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
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _skipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8BC34A),
              Color(0xFF4CAF50),
              Color(0xFF1B5E20),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  "assets/images/logo1.png",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Image.asset(
                          "assets/images/logo1.png",
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.eco, size: 80, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Farmtech",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        "AgriDirect Nepal",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFFF3E0),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_errorMessage == null) ...[
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 3,
                        ),
                        if (_showSkipButton)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: TextButton(
                              onPressed: _navigateToLogin,
                              child: const Text("Taking too long? Skip to Login", 
                                style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              const Icon(Icons.wifi_off, color: Colors.white70, size: 30),
                              const SizedBox(height: 10),
                              Text(
                                "Connection Error: $_errorMessage",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _errorMessage = null);
                                  _initApp();
                                },
                                child: const Text("Try Again"),
                              ),
                              TextButton(
                                onPressed: _navigateToLogin,
                                child: const Text("Skip to Login", style: TextStyle(color: Colors.white60)),
                              )
                            ],
                          ),
                        ),
                    ],
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
