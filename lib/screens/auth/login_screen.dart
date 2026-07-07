import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmtech_agridirect/screens/auth/signup_screen.dart';
import 'package:farmtech_agridirect/screens/auth/forgot_password_screen.dart';
import 'package:farmtech_agridirect/screens/auth/verify_otp_screen.dart';
import 'package:farmtech_agridirect/screens/home/navigation_screen.dart';
import 'package:farmtech_agridirect/screens/misc/farmer_screen.dart';
import 'package:farmtech_agridirect/screens/delivery_person_screen.dart';
import 'package:farmtech_agridirect/screens/admin_page.dart';
import 'package:farmtech_agridirect/viewmodels/auth_viewmodel.dart';
import 'package:farmtech_agridirect/viewmodels/admin_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hidePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authVm = context.read<AuthViewModel>();
    final adminVm = context.read<AdminViewModel>();

    String email = _emailCtrl.text.trim();
    final String pass = _passCtrl.text.trim();
    if (!email.contains('@')) email = "$email@gmail.com";

    final user = await authVm.login(email, pass);
    if (user != null) {
      if (email.toLowerCase() == "agrifarmadmin@gmail.com" && pass == "Farmadmin@5") {
        await authVm.handleMasterAdmin(user, email);
        adminVm.refreshAdminState();
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
        return;
      }

      if (!user.emailVerified) {
        final doc = await authVm.getUserData(user.uid);
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email, source: OtpSource.login, userData: doc?.data() as Map<String, dynamic>?)));
        return;
      }

      final doc = await authVm.getUserData(user.uid);
      final role = ((doc?.data() as Map?)?['role'] ?? 'Customer').toString();
      final normalizedRole = role.trim().toLowerCase();
      
      if (mounted) {
        Widget target;
        if (normalizedRole == 'farmer') target = const FarmerScreen();
        else if (normalizedRole == 'delivery person') target = const DeliveryPersonScreen();
        else if (normalizedRole == 'admin') target = const AdminPage();
        else target = NavigationScreen(userName: user.displayName ?? "User");
        
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
      }
    } else if (authVm.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authVm.error!), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 40)]),
                    child: Image.asset("assets/images/logo_full.png", height: 160, width: 160, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Welcome Back!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1D25))),
                const SizedBox(height: 8),
                const Text("Fresh from the farm to your home", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 45),
                
                TextFormField(
                  controller: _emailCtrl,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.isEmpty) ? "Enter email or username" : null,
                  decoration: _inputDeco("Email or Username", Icons.email_outlined),
                ),
                if (_emailCtrl.text.toLowerCase() == "agrifarmadmin@gmail.com") ...[
                  const SizedBox(height: 12),
                  _adminBanner(),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _hidePass,
                  validator: (v) => (v == null || v.isEmpty) ? "Enter password" : null,
                  decoration: _inputDeco("Password", Icons.lock_outline_rounded).copyWith(
                    suffixIcon: IconButton(icon: Icon(_hidePass ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _hidePass = !_hidePass)),
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())), child: const Text("Forgot Password?", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                ),
                
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
                    onPressed: authVm.loading ? null : _handleLogin,
                    child: authVm.loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("New here?", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text("Create Account", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint, prefixIcon: Icon(icon), filled: true, fillColor: const Color(0xFFF7F9FB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }

  Widget _adminBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
      child: const Row(children: [Icon(Icons.admin_panel_settings_rounded, color: Colors.blue), SizedBox(width: 12), Text("Admin Authentication Mode", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w800, fontSize: 13))]),
    );
  }
}
