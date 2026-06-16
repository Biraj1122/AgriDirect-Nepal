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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
                  "Welcome back",
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
                const SizedBox(height: 18),
                
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

                          final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                          final User? user = userCredential.user;
                          if (user == null) {
                            if (context.mounted) Navigator.pop(context);
                            return;
                          }

                          final String normalizedEmail = email.toLowerCase();
                          final bool isAdminLogin = (normalizedEmail == "farmadmin@gmail.com" || normalizedEmail == "agrifarmadmin@gmail.com") && password == "Farmadmin@1";

                          if (isAdminLogin) {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                              'email': email,
                              'role': 'Admin',
                              'fullName': 'Super Admin',
                              'lastLogin': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            if (context.mounted) {
                              Navigator.pop(context);
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}