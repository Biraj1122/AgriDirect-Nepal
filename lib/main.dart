import 'dart:async';
import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Global Error Handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint("Flutter Error: ${details.exception}");
    };

    runApp(const AgriDirectApp());
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.white,
      ),
      builder: (context, child) {
        // Custom Error Screen for the entire app
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 20),
                    const Text("Something went wrong!", 
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
