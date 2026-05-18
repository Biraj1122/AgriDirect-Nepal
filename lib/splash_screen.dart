import 'dart:async';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> scaleAnimation;
  late Animation<double> opacityAnimation;

  @override
  void initState() {
    super.initState();

    /// LOGO ANIMATION
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    scaleAnimation = Tween<double>(
      begin: .8,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    /// NAVIGATION TIMER
    Timer(const Duration(seconds: 4), () {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
              Color(0xff8BC34A),
              Color(0xff4CAF50),
              Color(0xff1B5E20),
            ],
          ),
        ),

        child: Stack(
          children: [

            /// BACKGROUND OVERLAY IMAGE
            Positioned.fill(
              child: Opacity(
                opacity: .18,

                child: Image.asset(
                  "assets/images/logo1.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            /// DARK OVERLAY
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(.08),
              ),
            ),

            /// MAIN CONTENT
            Center(
              child: FadeTransition(

                opacity: opacityAnimation,

                child: ScaleTransition(
                  scale: scaleAnimation,

                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: [


                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white24,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.18),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),

                        child: Image.asset(
                          "assets/images/logo1.png",
                          height: 90,
                          width: 90,
                          fit: BoxFit.contain, //
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// APP NAME
                      const Text(
                        "Farmtech",

                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// SUBTITLE
                      const Text(
                        "AgriDirect Nepal",

                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffFFF3E0),
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// TAGLINE
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color:
                          Colors.white.withOpacity(.12),

                          borderRadius:
                          BorderRadius.circular(30),
                        ),

                        child: const Text(
                          "Connecting Farmers & Market",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            letterSpacing: .5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      /// LOADING INDICATOR
                      const SizedBox(
                        height: 28,
                        width: 28,

                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                          AlwaysStoppedAnimation(
                            Colors.white,
                          ),
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