import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:farmtech_agridirect/viewmodels/admin_viewmodel.dart';
import 'package:farmtech_agridirect/viewmodels/farmer_viewmodel.dart';
import 'package:farmtech_agridirect/viewmodels/shop_viewmodel.dart';
import 'package:farmtech_agridirect/viewmodels/auth_viewmodel.dart';
import 'package:farmtech_agridirect/viewmodels/delivery_viewmodel.dart';
import 'package:farmtech_agridirect/models/cart_model.dart';
import 'package:farmtech_agridirect/firebase_options.dart';
import 'package:farmtech_agridirect/screens/misc/splash_screen.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Hybrid Composition for MapLibre (Fixes stability on Android)
    MapLibreMap.useHybridComposition = true;

    // Optimized Firestore Settings for compatibility
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, // Disable on Web to prevent INTERNAL ASSERTION FAILED
      );
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint("Flutter Error: ${details.exception}");
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AdminViewModel()),
          ChangeNotifierProvider(create: (_) => FarmerViewModel()),
          ChangeNotifierProvider(create: (_) => ShopViewModel()),
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(create: (_) => DeliveryViewModel()),
          ChangeNotifierProvider(create: (_) => cartModel),
        ],
        child: const AgriDirectApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint("Uncaught Error: $error");
    debugPrint("Stacktrace: $stackTrace");
  });
}

class AgriDirectApp extends StatelessWidget {
  const AgriDirectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriDirect Nepal',
      themeMode: ThemeMode.light, // Forced Light Mode
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.white,
      ),
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details)
        {
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 20),
                    const Text("Something went wrong", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(details.exception.toString(), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        };
        return child!;
      },
      home: const SplashScreen(),
    );
  }
}
