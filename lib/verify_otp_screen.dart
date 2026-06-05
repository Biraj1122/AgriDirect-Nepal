import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'reset_password_screen.dart';
import 'Success/shared_widgets.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  // Separate focus nodes for KeyboardListener to avoid creating new ones in build
  final List<FocusNode> _keyboardFocusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _timer;
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
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _startResendTimer();
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
    _animController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) {
      setState(() => _errorText = 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      // Simulation of OTP verification since cloud_functions might not be set up
      await Future.delayed(const Duration(seconds: 2));
      
      // If you have cloud functions, uncomment this:
      /*
      final fn = FirebaseFunctions.instance.httpsCallable('verifyPasswordResetOTP');
      await fn.call({'email': widget.email, 'otp': _otp});
      */

      if (!mounted) return;
      setState(() => _isVerifying = false);

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) =>
              ResetPasswordScreen(email: widget.email),
          transitionsBuilder: (_, animation, secondaryAnimation, child) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = 'Invalid code. Please try again.';
      });
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() => _isResending = true);

    try {
      // Simulation of resending OTP
      await Future.delayed(const Duration(seconds: 1));
      
      /*
      final fn = FirebaseFunctions.instance.httpsCallable('sendPasswordResetOTP');
      await fn.call({'email': widget.email});
      */

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
        SnackBar(
          content: const Text('New code sent!'),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isResending = false);
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) {
      _verifyOtp();
    }
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child:
            const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _ink),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  IconBadge(teal: _teal, blue: _blue, icon: Icons.mark_email_read_outlined),
                  const SizedBox(height: 28),
                  Heading(
                    title: 'Check your email',
                    subtitle: 'We sent a 6-digit code to\n${widget.email}',
                  ),
                  const SizedBox(height: 24),
                  const StepIndicator(currentStep: 1),
                  const SizedBox(height: 36),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 46,
                        height: 56,
                        child: KeyboardListener(
                          focusNode: _keyboardFocusNodes[i],
                          onKeyEvent: (e) {
                            _onKeyEvent(e, i);
                          },
                          child: TextFormField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                            onChanged: (v) {
                              _onDigitChanged(v, i);
                            },
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: _errorText != null
                                  ? Colors.red.shade50
                                  : _surface,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                const BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _errorText != null
                                      ? Colors.redAccent
                                      : _border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: _teal, width: 2),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 14, color: Colors.redAccent),
                        const SizedBox(width: 6),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                              fontSize: 12.5, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  GradientButton(
                    label: 'Verify code',
                    icon: Icons.verified_outlined,
                    isLoading: _isVerifying,
                    teal: _teal,
                    blue: _blue,
                    onTap: _verifyOtp,
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: _resendCountdown > 0
                        ? Text(
                      'Resend code in ${_resendCountdown}s',
                      style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade400),
                    )
                        : GestureDetector(
                      onTap: _resendOtp,
                      child: _isResending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _teal),
                      )
                          : const Text(
                        'Resend code',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _teal,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}