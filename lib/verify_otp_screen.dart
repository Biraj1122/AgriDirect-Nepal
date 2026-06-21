import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Success/shared_widgets.dart';
import 'navigation_screen.dart';
import 'farmer_screen.dart';
import 'screens/delivery_person_screen.dart';
import 'screens/admin_page.dart';

enum OtpSource { login, signup, forgotPassword }

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final OtpSource source;
  final Map<String, dynamic>? userData;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.source = OtpSource.forgotPassword,
    this.userData,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<FocusNode> _keyboardFocusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _animController;

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _timer;
  Timer? _autoCheckTimer;
  String? _errorText;

  static const _teal = Color(0xFF1D9E75);
  static const _blue = Color(0xFF378ADD);
  static const _surface = Color(0xFFF7F9FB);
  static const _border = Color(0xFFE8ECF0);
  static const _ink = Color(0xFF1A1D25);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _animController.forward();
    _startResendTimer();
    
    // Auto-check for verification status every 3 seconds
    if (widget.source != OtpSource.forgotPassword) {
      _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _checkVerificationStatus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final f in _keyboardFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    _autoCheckTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        _autoCheckTimer?.cancel();
        _proceedToHome();
      }
    }
  }

  void _proceedToHome() {
    if (!mounted) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String role = widget.userData?['role'] ?? 'Customer';
      
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => target),
        (route) => false,
      );
    }
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    // If it's a real password reset flow, we use the simulation or wait for link
    if (widget.source == OtpSource.forgotPassword) {
       // For forgot password, we still rely on the user clicking the link.
       // Firebase doesn't have an "OTP to Reset" API for email.
       // We'll show a message or just check verification.
       setState(() {
         _isVerifying = true;
         _errorText = null;
       });
       
       await Future.delayed(const Duration(seconds: 1));
       
       if (mounted) {
         setState(() => _isVerifying = false);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Please check your email for the password reset link.")),
         );
       }
       return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          if (!mounted) return;
          setState(() => _isVerifying = false);
          _proceedToHome();
        } else {
          if (!mounted) return;
          setState(() {
            _isVerifying = false;
            _errorText = 'Email not yet verified. Please click the link in your email.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (widget.source == OtpSource.forgotPassword) {
           await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
        } else {
           await user.sendEmailVerification();
        }
      }
      
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorText = null;
      });
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('New verification link sent!'), backgroundColor: _teal),
      );
    } catch (_) {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) _verifyOtp();
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              IconBadge(teal: _teal, blue: _blue, icon: Icons.mark_email_read_outlined),
              const SizedBox(height: 28),
              Heading(
                title: widget.source == OtpSource.forgotPassword ? 'Reset Password' : 'Verify Email',
                subtitle: widget.source == OtpSource.forgotPassword 
                    ? 'We sent a password reset link to\n${widget.email}'
                    : 'We sent a verification link to\n${widget.email}. Click it to proceed.',
              ),
              const SizedBox(height: 24),
              StepIndicator(currentStep: 1), // Step 1 is "Verify"
              const SizedBox(height: 36),
              const Center(
                child: Text(
                  "Waiting for verification...",
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              // We keep the 6-digit boxes for the UI look you like, 
              // but they are optional now.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: _keyboardFocusNodes[i],
                      onKeyEvent: (e) => _onKeyEvent(e, i),
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _ink),
                        onChanged: (v) => _onDigitChanged(v, i),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _errorText != null ? Colors.red.shade50 : _surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: _errorText != null ? Colors.redAccent : _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _teal, width: 2),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(_errorText!, style: const TextStyle(fontSize: 12.5, color: Colors.redAccent)),
              ],
              const SizedBox(height: 28),
              GradientButton(
                label: 'Check Verification Status',
                icon: Icons.refresh_rounded,
                isLoading: _isVerifying,
                teal: _teal,
                blue: _blue,
                onTap: _verifyOtp,
              ),
              const SizedBox(height: 20),
              Center(
                child: _resendCountdown > 0
                    ? Text('Resend code in ${_resendCountdown}s', style: TextStyle(color: Colors.grey.shade400))
                    : GestureDetector(
                        onTap: _resendOtp,
                        child: _isResending
                            ? const CircularProgressIndicator()
                            : const Text('Resend code', style: TextStyle(color: _teal, fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
