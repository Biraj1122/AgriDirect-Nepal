import 'package:farmtech_agridirect/splash_screen.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'splash_screen.dart';
import 'home_screen.dart';
import 'navigation_screen.dart';
void main() {
=======
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main()
{
>>>>>>> biraj
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.green,
      ),

      home: const SplashScreen(),
<<<<<<< HEAD
=======

>>>>>>> biraj
    );
  }
}