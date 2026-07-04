import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmtech_agridirect/screens/auth/signup_screen.dart';
import 'package:farmtech_agridirect/screens/auth/forgot_password_screen.dart';
import 'package:farmtech_agridirect/screens/auth/verify_otp_screen.dart';
import 'package:farmtech_agridirect/screens/home/navigation_screen.dart';
import 'package:farmtech_agridirect/screens/misc/farmer_screen.dart';
import 'package:farmtech_agridirect/screens/delivery_person_screen.dart';
import 'package:farmtech_agridirect/screens/admin_page.dart';
import 'package:farmtech_agridirect/services/social_auth_service.dart';

import 'package:provider/provider.dart';
import 'package:farmtech_agridirect/viewmodels/admin_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final SocialAuthService _socialAuthService = SocialAuthService();
  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleSocialSignIn(Future<UserCredential?> signInMethod) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final UserCredential? userCredential = await signInMethod;
      if (userCredential?.user != null) {
        if (!mounted) return;
        Navigator.pop(context); // Pop loading

        final user = userCredential!.user!;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        // Handle new social user creation
        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fullName': user.displayName ?? 'New User',
            'email': user.email,
            'role': 'Customer', // Default role
            'createdAt': FieldValue.serverTimestamp(),
          });
          userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        }

        final userData = userDoc.data() as Map<String, dynamic>?;

        if (mounted) {
          String role = userData?['role'] ?? 'Customer';
          Widget target;
          if (role == 'Farmer') {
            target = const FarmerScreen();
          } else if (role == 'Delivery Person') {
            target = const DeliveryPersonScreen();
          } else if (role == 'Admin') {
            if (mounted) context.read<AdminViewModel>().refreshAdminState();
            target = const AdminPage();
          } else {
            target = NavigationScreen(userName: user.displayName ?? user.email ?? "User");
          }
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => target));
        }
      } else {
        if (mounted) Navigator.pop(context); // Pop loading
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        String errorMsg = e.toString();
        if (errorMsg.contains("ApiException: 10")) {
          errorMsg = "Google Sign-In Error: Please register your SHA-1 key in Firebase Console.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 50),
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                      ],
                    ),
                    child: Image.asset("assets/images/logo_full.png", height: 100, width: 70, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Farmtech",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 1.2),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Welcome!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Fresh from the farm to your home",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 40),
                
                // Email field
                TextFormField(
                  controller: emailController,
                  onChanged: (val) => setState(() {}), 
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Please enter email";
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Email or Username",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                if (emailController.text.toLowerCase() == "agrifarmadmin@gmail.com")
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "Admin Panel Login Mode",
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                
                // Password field
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Please enter password";
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                      icon: Icon(hidePassword ? Icons.visibility_off : Icons.visibility),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: const Text("Forgot Password?", style: TextStyle(color: Colors.green)),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        String email = emailController.text.trim();
                        final String password = passwordController.text.trim();

                        if (!email.contains('@')) {
                          email = "$email@gmail.com";
                        }

                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );

                          final String normalizedEmail = email.toLowerCase();
                          final bool isMasterAdmin = (normalizedEmail == "agrifarmadmin@gmail.com") && password == "Farmadmin@5";

                          UserCredential? userCredential;
                          
                          try {
                            userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                          } on FirebaseAuthException catch (e) {
                            if (context.mounted) Navigator.pop(context); // Pop loading

                            String errorMessage = "Login failed. Please try again.";
                            
                            switch (e.code) {
                              case 'invalid-email':
                                errorMessage = "The email address is badly formatted.";
                                break;
                              case 'user-disabled':
                                errorMessage = "This user account has been disabled.";
                                break;
                              case 'user-not-found':
                                errorMessage = "No user found with this email.";
                                break;
                              case 'wrong-password':
                                errorMessage = "Incorrect password. Please try again.";
                                break;
                              case 'invalid-credential':
                                errorMessage = "Incorrect email or password.";
                                break;
                              case 'too-many-requests':
                                errorMessage = "Too many attempts. Please try again later.";
                                break;
                              case 'network-request-failed':
                                errorMessage = "Network error. Please check your connection.";
                                break;
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }

                          final User? user = userCredential.user;
                          if (user == null) {
                            if (context.mounted) Navigator.pop(context);
                            return;
                          }

                          if (isMasterAdmin) {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                              'email': email,
                              'role': 'Admin',
                              'fullName': 'Super Admin',
                              'lastLogin': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            if (context.mounted) {
                              context.read<AdminViewModel>().refreshAdminState();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Admin Panel Access Granted"),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminPage()));
                            }
                            return;
                          }

                          if (!user.emailVerified) {
                            await user.sendEmailVerification();
                            DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                            final userData = userDoc.data() as Map<String, dynamic>?;

                            if (context.mounted) {
                              context.read<AdminViewModel>().refreshAdminState();
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => VerifyEmailScreen(email: email, source: OtpSource.login, userData: userData)));
                            }
                            return;
                          }

                          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                          final userData = userDoc.data() as Map<String, dynamic>?;

                          if (context.mounted) {
                            Navigator.pop(context);
                            String role = userData?['role'] ?? 'Customer';
                            Widget target;
                            if (role == 'Farmer') {
                              target = const FarmerScreen();
                            } else if (role == 'Delivery Person') {
                              target = const DeliveryPersonScreen();
                            } else if (role == 'Admin') {
                              target = const AdminPage();
                            } else {
                              target = NavigationScreen(userName: user.displayName ?? user.email ?? "User");
                            }
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => target));
                          }
                        } on FirebaseAuthException catch (e) {
                          if (context.mounted) {
                            try { Navigator.pop(context); } catch (_) {}
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            try { Navigator.pop(context); } catch (_) {}
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
                          }
                        }
                      }
                    },
                    child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: const Text("Sign Up", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("OR", style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Social Login Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(
                      asset: "assets/images/Gmail_icon_(2020).svg.png",
                      onTap: () => _handleSocialSignIn(_socialAuthService.signInWithGoogle()),
                    ),
                    const SizedBox(width: 20),
                    _socialButton(
                      asset: "assets/images/Facebook.png",
                      onTap: () => _handleSocialSignIn(_socialAuthService.signInWithFacebook()),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({required String asset, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset(asset, height: 30),
      ),
    );
  }
}
