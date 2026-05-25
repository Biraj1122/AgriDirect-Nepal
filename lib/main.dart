import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'user_data.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize UserData (SharedPreferences)
  await UserData.init();

  try {
    // Adding a timeout to prevent the app from hanging indefinitely if Firebase fails
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization failed: $e");
    // You can still choose to run the app even if Firebase fails, 
    // or show a specific error screen.
  }

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