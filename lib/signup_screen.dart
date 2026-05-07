import 'package:flutter/material.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() =>
      _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController firstNameController =
  TextEditingController();

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  final TextEditingController phoneController =
  TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  bool _confirmTouched = false;

  /// EMAIL VALIDATION
  bool isValidEmail(String email) {
    String pattern =
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$';
    return RegExp(pattern).hasMatch(email);
  }

  /// PHONE VALIDATION (Nepal)
  bool isValidNepaliPhone(String phone) {
    String pattern = r'^(98|97)\d{8}$';
    return RegExp(pattern).hasMatch(phone);
  }

  /// PASSWORD VALIDATION (UPDATED: min 8 + strong rules)
  bool isValidPassword(String password) {
    String pattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$';

    return RegExp(pattern).hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 28),

          child: Form(
            key: _formKey,

            child: Column(
              children: [

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                          Icons.arrow_back_ios),
                    ),

                    Text(
                      "Sign up",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Image.asset(
                  "assets/images/logo.png",
                  height: 140,
                ),

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
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 35),

                buildTextField(
                  controller: firstNameController,
                  hintText: "Full Name",
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 18),

                /// EMAIL
                TextFormField(
                  controller: emailController,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Please enter email";
                    }

                    if (!isValidEmail(value)) {
                      return "Enter valid email";
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Email Address",
                    prefixIcon:
                    const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// PHONE
                TextFormField(
                  controller: phoneController,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Please enter phone number";
                    }

                    if (!isValidNepaliPhone(value)) {
                      return "Enter valid Nepali number";
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Phone Number",
                    prefixIcon:
                    const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
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
                    if (_confirmTouched) {
                      setState(() {});
                    }
                  },

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Please enter password";
                    }

                    if (!isValidPassword(value)) {
                      return "Password must be 8+ chars with Upper"
                          "\n, lower, number & symbol";
                    }

                    return null;
                  },

                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon:
                    const Icon(Icons.lock_outline),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword =
                          !hidePassword;
                        });
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),

                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// CONFIRM PASSWORD (FIXED UX)
                TextFormField(
                  controller:
                  confirmPasswordController,
                  obscureText: hideConfirmPassword,

                  onChanged: (_) {
                    setState(() {
                      _confirmTouched = true;
                    });
                  },

                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return "Please confirm password";
                    }

                    if (_confirmTouched &&
                        value !=
                            passwordController.text) {
                      return "Passwords do not match";
                    }

                    return null;
                  },

                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    prefixIcon:
                    const Icon(Icons.lock_outline),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hideConfirmPassword =
                          !hideConfirmPassword;
                        });
                      },
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),

                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
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
                        borderRadius:
                        BorderRadius.circular(5),
                      ),
                    ),

                    onPressed: () {
                      if (_formKey.currentState!
                          .validate()) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const LoginScreen(),
                          ),
                        );
                      }
                    },

                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
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
        if (value == null ||
            value.trim().isEmpty) {
          return "Field cannot be empty";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}