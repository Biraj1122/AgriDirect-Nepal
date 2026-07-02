import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'verify_otp_screen.dart';
import '../misc/farm_osm_screen.dart';

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

  final TextEditingController farmNameController = TextEditingController();
  final TextEditingController farmLocationController = TextEditingController();
  double? farmLat;
  double? farmLng;

  String selectedRole = 'Customer';
  final List<String> roles = ['Customer', 'Farmer', 'Delivery Person'];

  bool hidePassword = true;
  bool hideConfirmPassword = true;

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
                    child: Image.asset("assets/images/logo_full.png", height: 90, width: 90, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "AgriDirect Nepal",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Fresh from the farm to your home",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 25),
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
                buildTextField(
                  controller: firstNameController,
                  hintText: "Full Name",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 18),
                if (selectedRole == 'Farmer') ...[
                  buildTextField(
                    controller: farmNameController,
                    hintText: "Farm Name",
                    icon: Icons.agriculture_outlined,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: farmLocationController,
                    readOnly: true,
                    onTap: () async {
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(builder: (_) => const FarmOsmScreen()),
                      );
                      if (result != null) {
                        setState(() {
                          farmLocationController.text = result['address'];
                          farmLat = result['lat'];
                          farmLng = result['lng'];
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Farm Location (Tap to pick)",
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 18),
                ],
                buildTextField(
                  controller: emailController,
                  hintText: "Email",
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                buildTextField(
                  controller: phoneController,
                  hintText: "Phone Number",
                  icon: Icons.phone_android_outlined,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Password required";
                    if (!isValidPassword(value)) return "Too weak";
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
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: hideConfirmPassword,
                  validator: (value) {
                    if (value != passwordController.text) return "Passwords must match";
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
                        String email = emailController.text.trim();
                        if (!email.contains('@')) {
                          email = "$email@gmail.com";
                        }
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );
                          UserCredential userCredential =
                          await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: email,
                            password: passwordController.text.trim(),
                          );
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
                            userData['farmLat'] = farmLat;
                            userData['farmLng'] = farmLng;
                          }
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userCredential.user!.uid)
                              .set(userData);
                          await userCredential.user
                              ?.updateDisplayName(firstNameController.text.trim());
                          await userCredential.user?.sendEmailVerification();
                          
                          if (!mounted) return;
                          
                          Navigator.of(context).pop(); // Dismiss loading dialog
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VerifyEmailScreen(
                                email: email,
                                source: OtpSource.signup,
                                userData: userData,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.of(context).pop(); // Dismiss loading dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      }
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
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

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: (value) {
        if (value == null || value.isEmpty) return "Required";
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
