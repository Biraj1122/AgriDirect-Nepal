import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';
import '../../models/user_data.dart';
import '../auth/login_screen.dart';
import '../home/navigation_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'farmer_screen.dart';
import '../delivery_person_screen.dart';
import '../admin_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  
  bool _isNavigated = false;
  String? _errorMessage;
  bool _showSkipButton = false;
  Timer? _skipTimer;
  
  String _appVersion = "";
  String _userRole = "Default";
  String _loadingMessage = "Initializing app...";

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

    _mainController.forward();
    
    _skipTimer = Timer(const Duration(seconds: 8), () {
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
      setState(() => _loadingMessage = "Getting version info...");
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = packageInfo.version);

      setState(() => _loadingMessage = "Connecting to Firebase...");
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 15));
      }

      setState(() => _loadingMessage = "Loading user data...");
      await UserData.init();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() => _loadingMessage = "Securing session...");
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (doc.exists && mounted) {
          final role = doc.data()?['role'] ?? 'Customer';
          setState(() {
            _userRole = role;
            _loadingMessage = "Welcome back, $role!";
          });
        }
      }
      
      final int elapsed = stopwatch.elapsedMilliseconds;
      final int remaining = 2500 - elapsed;

      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      }
      
      _handleNavigation();
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

  void _handleNavigation() async {
    if (!mounted || _isNavigated) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (doc.exists && mounted) {
          final role = doc.data()?['role'] ?? 'Customer';
          final name = doc.data()?['fullName'] ?? user.displayName ?? "User";
          
          // Mandatory Profile Photo Check for Partners
          if (role == 'Farmer' || role == 'Delivery Person') {
            final profileImg = doc.data()?['profileImageUrl'];
            if (profileImg == null || profileImg.toString().isEmpty) {
              _isNavigated = true;
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => EditProfileScreen(
                  currentName: name,
                  currentPhone: doc.data()?['phone'] ?? "Not set",
                  mandatoryPhoto: true,
                ))
              );
              return;
            }
          }

          Widget target;
          if (role == 'Farmer') {
            target = const FarmerScreen();
          } else if (role == 'Delivery Person') {
            target = const DeliveryPersonScreen();
          } else if (role == 'Admin') {
            target = const AdminPage();
          } else {
            target = NavigationScreen(userName: name);
          }
          
          _isNavigated = true;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
          return;
        }
      } catch (e) {
        debugPrint("Auto-login error: $e");
      }
    }
    
    _navigateToLogin();
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

    // Define Role-Based Themes
    List<Color> gradientColors;
    IconData decorativeIcon;
    String roleMessage;

    switch (_userRole) {
      case 'Farmer':
        gradientColors = [
          Colors.brown.shade900,
          Colors.brown.shade700,
          Colors.green.shade800,
          Colors.green.shade600,
        ];
        decorativeIcon = Icons.agriculture_rounded;
        roleMessage = "Your digital farm hub";
        break;
      case 'Delivery Person':
        gradientColors = [
          Colors.orange.shade900,
          Colors.deepOrange.shade700,
          Colors.blue.shade900,
          Colors.blue.shade700,
        ];
        decorativeIcon = Icons.local_shipping_outlined;
        roleMessage = "Ready for the next delivery?";
        break;
      case 'Admin':
        gradientColors = [
          Colors.blueGrey.shade900,
          Colors.blueGrey.shade700,
          Colors.teal.shade800,
          Colors.teal.shade600,
        ];
        decorativeIcon = Icons.admin_panel_settings_outlined;
        roleMessage = "System Overview Control";
        break;
      default: // Customer or Guest
        gradientColors = [
          Colors.green.shade900,
          Colors.green.shade700,
          Colors.green.shade500,
          Colors.lightGreen.shade400,
        ];
        decorativeIcon = Icons.eco;
        roleMessage = "Fresh from farm to your home";
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
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
                child: Icon(decorativeIcon, size: isLargeScreen ? 300 : 200, color: Colors.white),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SlideTransition(
                          position: _logoSlide,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoOpacity,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 40,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Hero(
                                  tag: 'app_logo',
                                  child: Image.asset(
                                    "assets/images/logo_full.png",
                                    height: 180,
                                    width: 180,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.eco, size: 120, color: Colors.green),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Main App Title (Consistent)
                        const Text(
                          "AgriDirect Nepal",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Dynamic Role-Based Message
                        Text(
                          roleMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        if (_errorMessage == null) ...[
                          Column(
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _loadingMessage,
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                          if (_showSkipButton)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: TextButton(
                                onPressed: _navigateToLogin,
                                child: const Text(
                                  "Continue to Login",
                                  style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                                ),
                              ),
                            ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                Text(
                                  "Startup Issue: $_errorMessage",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _errorMessage = null;
                                      _userRole = "Default";
                                    });
                                    _initApp();
                                  },
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // App Version at Bottom
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      "Version $_appVersion",
                      style: const TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
