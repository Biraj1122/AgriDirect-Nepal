import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  bool isHidden = true;

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  /// EMAIL VALIDATION
  bool isValidEmail(String email) {
    String pattern =
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$';
    return RegExp(pattern).hasMatch(email);
  }

  /// PHONE VALIDATION
  bool isValidPhone(String phone) {
    String pattern = r'^[0-9]{7,15}$';
    return RegExp(pattern).hasMatch(phone);
  }

  /// EMAIL OR PHONE
  bool isValidLoginInput(String input) {
    input = input.trim();
    return isValidEmail(input) || isValidPhone(input);
  }

  /// PASSWORD VALIDATION
  bool isValidPassword(String password) {
    String pattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$';

    return RegExp(pattern).hasMatch(password);
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
          padding:
          const EdgeInsets.symmetric(horizontal: 28),

          child: Form(
            key: _formKey,

            child: Column(
              children: [

                const SizedBox(height: 20),

                /// LOGIN TEXT
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// LOGO
                Image.asset(
                  "assets/images/logo.png",
                  height: 165,
                ),

                const SizedBox(height: 10),

                /// TAGLINE
                const Text(
                  "Fresh from the farm to your home",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 35),

                /// EMAIL OR PHONE FIELD
                TextFormField(
                  controller: emailController,
                  keyboardType:
                  TextInputType.emailAddress,

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Enter email or phone number";
                    }

                    if (!isValidLoginInput(value)) {
                      return "Enter valid email or phone number";
                    }

                    return null;
                  },

                  decoration: InputDecoration(
                    hintText: "Phone number or Email",

                    contentPadding:
                    const EdgeInsets.symmetric(
                        vertical: 16),

                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),

                    filled: true,
                    fillColor:
                    const Color(0xFFF7F7F7),

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// PASSWORD FIELD
                TextFormField(
                  controller: passwordController,
                  obscureText: isHidden,

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Please enter password";
                    }

                    if (!isValidPassword(value)) {
                      return "Invalid password";
                    }

                    return null;
                  },

                  decoration: InputDecoration(
                    hintText: "Password",

                    contentPadding:
                    const EdgeInsets.symmetric(
                        vertical: 16),

                    prefixIcon: Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isHidden = !isHidden;
                        });
                      },
                      icon: Icon(
                        isHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    filled: true,
                    fillColor:
                    const Color(0xFFF7F7F7),

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// FORGOT PASSWORD
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const ForgotPasswordScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF56B947),

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(5),
                      ),
                    ),

                    onPressed: () {
                      if (_formKey.currentState!
                          .validate()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const HomeScreen(),
                          ),
                        );
                      }
                    },

                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                /// DIVIDER
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color:
                        Colors.black.withOpacity(.3),
                      ),
                    ),

                    const Padding(
                      padding:
                      EdgeInsets.symmetric(
                          horizontal: 8),
                      child: Text(
                        "or continue with",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),

                    Expanded(
                      child: Divider(
                        color:
                        Colors.black.withOpacity(.3),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// SOCIAL BUTTONS
                Row(
                  children: [

                    Expanded(
                      child: socialButton(
                        "assets/images/Gmail_icon_(2020).svg.png",
                        "Google",
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: socialButton(
                        "assets/images/Facebook.png",
                        "Facebook",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// SIGN UP
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    const Text(
                      "Create an account? ",
                      style: TextStyle(fontSize: 13),
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const SignupScreen(),
                          ),
                        );
                      },

                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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

  /// SOCIAL BUTTON
  Widget socialButton(String image, String text) {
    return Container(
      height: 46,

      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(3),
      ),

      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Image.asset(
            image,
            height: 24,
          ),

          const SizedBox(width: 10),

          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}