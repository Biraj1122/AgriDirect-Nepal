import 'package:farmtech_agridirect/verify_otp_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'navigation_screen.dart';
import 'screens/admin_page.dart';
import 'farmer_screen.dart';
import 'package:farmtech_agridirect/screens/delivery_person_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isHidden = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// GOOGLE SIGN IN
  Future<void> _signInWithGoogle() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      UserCredential userCredential;

      if (kIsWeb) {
        // Use Firebase Auth's direct popup for Web (more stable than google_sign_in package)
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        // You can add scopes if needed: googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Standard flow for Android/iOS
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          if (mounted) Navigator.pop(context);
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final User? user = userCredential.user;

      if (user != null && mounted) {
        // Sync with Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fullName': user.displayName ?? 'Google User',
            'email': user.email,
            'role': 'Customer', // Default role
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          Navigator.pop(context); // Pop loading
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NavigationScreen(userName: user.displayName ?? "User"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Sign-In failed: $e")));
      }
    }
  }

  /// EMAIL OR USERNAME VALIDATION
  bool isValidEmailOrUsername(String input) {
    if (input.contains('@')) {
      String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$';
      return RegExp(pattern).hasMatch(input);
    }
    // If no @, check if it's a valid username (alphanumeric, dots, underscores)
    return input.isNotEmpty && !input.contains(' ');
  }

  /// PHONE VALIDATION
  bool isValidPhone(String phone) {
    String pattern = r'^[0-9]{7,15}$';
    return RegExp(pattern).hasMatch(phone);
  }

  /// EMAIL OR PHONE
  bool isValidLoginInput(String input) {
    input = input.trim();
    return isValidEmailOrUsername(input) || isValidPhone(input);
  }

  /// PASSWORD VALIDATION (At least 6 characters)
  bool isValidPassword(String password) {
    return password.length >= 6 || password == "Farmadmin@1";
  }

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
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      "Login",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Image.asset("assets/images/logo.png", height: 165),
                const SizedBox(height: 10),
                const Text(
                  "Fresh from the farm to your home",
                  style: TextStyle(color: Colors.green, fontSize: 13),
                ),
                const SizedBox(height: 35),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Enter your email or username";
                    if (!isValidEmailOrUsername(value.trim())) return "Enter a valid email or username";
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Email or Gmail Username",
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    prefixIcon: Icon(Icons.email_outlined, size: 20, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: passwordController,
                  obscureText: isHidden,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Please enter password";
                    if (!isValidPassword(value)) return "Invalid password";
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Password",
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    prefixIcon: Icon(Icons.lock_outline, size: 20, color: Colors.grey.shade600),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => isHidden = !isHidden),
                      icon: Icon(isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey.shade600),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                    child: const Text("Forgot password?", style: TextStyle(color: Colors.green, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF56B947),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        String email = emailController.text.trim();
                        final String password = passwordController.text.trim();

                        // Auto-append @gmail.com if no domain is provided
                        if (!email.contains('@')) {
                          email = "$email@gmail.com";
                        }

                        try {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );

                          // 1. Authenticate user with Firebase Auth
                          final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                          final User? user = userCredential.user;

                          if (user != null && mounted) {
                            // --- ADMIN EXCEPTION ---
                            if (email == "farmadmin@gmail.com") {
                                Navigator.pop(context); // Pop loading
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminPage()));
                                return;
                            }

                            // --- REAL EMAIL VERIFICATION CHECK ---
                            if (user.emailVerified) {
                              // If already verified, go straight to appropriate dashboard
                              DocumentSnapshot userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .get();
                              
                              final userData = userDoc.data() as Map<String, dynamic>?;

                              if (mounted) {
                                Navigator.pop(context); // Pop loading
                                String role = userData?['role'] ?? 'Customer';
                                
                                Widget target;
                                if (role == 'Farmer') target = const FarmerScreen();
                                else if (role == 'Delivery Person') target = const DeliveryPersonScreen();
                                else target = NavigationScreen(userName: user.displayName ?? user.email ?? "User");
                                
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => target));
                              }
                              return;
                            } else {
                              // If NOT verified, send REAL verification email and show OTP UI
                              await user.sendEmailVerification();
                              
                              DocumentSnapshot userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .get();
                              
                              final userData = userDoc.data() as Map<String, dynamic>?;

                              if (mounted) {
                                Navigator.pop(context); // Pop loading
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VerifyOtpScreen(
                                      email: email,
                                      source: OtpSource.login,
                                      userData: userData,
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                          }
                        } on FirebaseAuthException catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Pop loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message ?? "Login failed")),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Pop loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("An error occurred: $e")),
                            );
                          }
                        }
                      }
                    },
                    child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 35),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.3))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("or continue with", style: TextStyle(fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _signInWithGoogle,
                        child: socialButton("assets/images/Gmail_icon_(2020).svg.png", "Google"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(child: socialButton("assets/images/Facebook.png", "Facebook")),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Create an account? ", style: TextStyle(fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                      child: const Text("Sign up", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget socialButton(String image, String text) {
    return Container(
      height: 46,
      decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image, 
            height: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.public, size: 24),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}