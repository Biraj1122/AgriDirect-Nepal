import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;  // ← Changed

import 'firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await firebase_core.Firebase.initializeApp(          // ← Changed
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
    );
  }
}