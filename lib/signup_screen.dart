import 'package:farmtech_agridirect/verify_otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Farmer-specific controllers
  final TextEditingController farmNameController = TextEditingController();
  final TextEditingController farmLocationController = TextEditingController();

  String selectedRole = 'Customer';
  final List<String> roles = ['Customer', 'Farmer', 'Delivery Person'];

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool _confirmTouched = false;

  bool isValidEmailOrUsername(String input) {
    if (input.contains('@')) {
      String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$';
      return RegExp(pattern).hasMatch(input);
    }
    return input.isNotEmpty && !input.contains(' ');
  }

  bool isValidNepaliPhone(String phone) {
    String pattern = r'^(98|97)\d{8}$';
    return RegExp(pattern).hasMatch(phone);
  }

  bool isValidPassword(String password) {
    String pattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$';
    return RegExp(pattern).hasMatch(password);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    farmNameController.dispose();
    farmLocationController.dispose();
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

                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios),
                    ),
                    Text(
                      "Sign up",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Image.asset("assets/images/logo.png", height: 140),

                const SizedBox(height: 10),

                const Text(
                  "Create Account",
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

                const SizedBox(height: 25),

                /// ROLE SELECTION DROPDOWN
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    hintText: "Sign up as",
                    prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
                  },
                ),

                const SizedBox(height: 18),

                // Full Name
                buildTextField(
                  controller: firstNameController,
                  hintText: "Full Name",
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 18),

                // --- FARMER-SPECIFIC FIELDS ---
                if (selectedRole == 'Farmer') ...[
                  // Farm Name
                  TextFormField(
                    controller: farmNameController,
                    validator: (value) {
                      if (selectedRole == 'Farmer' &&
                          (value == null || value.trim().isEmpty)) {
                        return "Please enter your farm name";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "Farm Name",
                      prefixIcon: const Icon(Icons.agriculture_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Farm Location
                  TextFormField(
                    controller: farmLocationController,
                    validator: (value) {
                      if (selectedRole == 'Farmer' &&
                          (value == null || value.trim().isEmpty)) {
                        return "Please enter your farm location";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "Farm Location (e.g. Chitwan, Nepal)",
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                /// EMAIL
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter email or username";
                    }
                    if (!isValidEmailOrUsername(value.trim())) {
                      return "Enter valid email or username";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Email or Gmail Username",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// PHONE
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter phone number";
                    }
                    if (!isValidNepaliPhone(value)) {
                      return "Enter valid Nepali number (98xxxxxxxx or 97xxxxxxxx)";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Phone Number",
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// PASSWORD
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  onChanged: (_) {
                    if (_confirmTouched) setState(() {});
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter password";
                    }
                    if (!isValidPassword(value)) {
                      return "Password must be 8+ chars with Upper,\nlower, number & symbol";
                    }
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// CONFIRM PASSWORD
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: hideConfirmPassword,
                  onChanged: (_) => setState(() => _confirmTouched = true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm password";
                    }
                    if (_confirmTouched && value != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => hideConfirmPassword = !hideConfirmPassword),
                      icon: Icon(
                          hideConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                /// SIGNUP BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        
                        String email = emailController.text.trim();
                        if (!email.contains('@')) {
                          email = "$email@gmail.com";
                        }

                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                          );

                          UserCredential userCredential =
                          await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: email,
                            password: passwordController.text.trim(),
                          );

                          // Build Firestore document — includes farmer fields if applicable
                          final Map<String, dynamic> userData = {
                            'uid': userCredential.user!.uid,
                            'fullName': firstNameController.text.trim(),
                            'email': email,
                            'phone': phoneController.text.trim(),
                            'role': selectedRole,
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          if (selectedRole == 'Farmer') {
                            userData['farmName'] = farmNameController.text.trim();
                            userData['farmLocation'] = farmLocationController.text.trim();
                            
                            // Save to dedicated farmers collection
                            await FirebaseFirestore.instance
                                .collection('farmers')
                                .doc(userCredential.user!.uid)
                                .set(userData);
                          } else if (selectedRole == 'Delivery Person') {
                            // Save to dedicated riders collection
                            await FirebaseFirestore.instance
                                .collection('riders')
                                .doc(userCredential.user!.uid)
                                .set(userData);
                          }

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userCredential.user!.uid)
                              .set(userData);

                          await userCredential.user
                              ?.updateDisplayName(firstNameController.text.trim());

                          // --- SEND VERIFICATION EMAIL ---
                          await userCredential.user?.sendEmailVerification();

                          if (!mounted) return;
                          
                          navigator.pop(); // Pop loading
                          
                          // --- NAVIGATE TO OTP ---
                          navigator.pushReplacement(
                            MaterialPageRoute(
                                builder: (context) => VerifyOtpScreen(
                                  email: email,
                                  source: OtpSource.signup,
                                  userData: userData,
                                )),
                          );
                        } on FirebaseAuthException catch (e) {
                          if (!mounted) return;
                          navigator.pop(); // Pop loading
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.message ?? "Registration failed")),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          navigator.pop(); // Pop loading
                          messenger.showSnackBar(
                            SnackBar(content: Text("An error occurred: $e")),
                          );
                        }
                      }
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Field cannot be empty";
        return null;
      },
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}