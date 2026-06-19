import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'verify_otp_screen.dart';
import 'navigation_screen.dart';
import 'farmer_screen.dart';
import 'screens/delivery_person_screen.dart';
import 'screens/admin_page.dart';
import 'services/social_auth_service.dart';

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
        final userData = userDoc.data() as Map<String, dynamic>?;

        if (mounted) {
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
      } else {
        if (mounted) Navigator.pop(context); // Pop loading
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login failed: $e")));
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
                Image.asset("assets/images/logo.png", height: 140),
                const SizedBox(height: 10),
                const Text(
                  "Welcome!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
                  onChanged: (val) => setState(() {}), // Update UI to show Admin hint
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
                          // Admin credentials updated to match your screenshot
                          final bool isMasterAdmin = (normalizedEmail == "agrifarmadmin@gmail.com") && password == "Farmadmin@5";

                          UserCredential? userCredential;
                          
                          try {
                            userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                          } on FirebaseAuthException catch (e) {
                            // If it's the master admin and it failed, give a specific hint
                            if (isMasterAdmin) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Admin Login Failed: Please check if 'Farmadmin@5' is set as the password in Firebase Console."),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                              }
                              return;
                            }
                            rethrow;
                          }

                          final User? user = userCredential?.user;
                          if (user == null) {
                            if (context.mounted) Navigator.pop(context);
                            return;
                          }

                          if (isMasterAdmin) {
                            // Create/Update Admin record in Firestore
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                              'email': email,
                              'role': 'Admin',
                              'fullName': 'Super Admin',
                              'lastLogin': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            if (context.mounted) {
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
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => VerifyOtpScreen(email: email, source: OtpSource.login, userData: userData)));
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
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
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
