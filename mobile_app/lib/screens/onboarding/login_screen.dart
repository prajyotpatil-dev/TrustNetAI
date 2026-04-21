import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthMethod { phone, email }
enum AuthStep { credentials, otp }

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  AuthMethod _method = AuthMethod.phone;
  AuthStep _step = AuthStep.credentials;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  String? _verificationId;
  int? _resendToken;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool get _isBusiness => widget.role == 'business';
  Color get _primaryColor =>
      _isBusiness ? const Color(0xFF2563EB) : const Color(0xFF16A34A);
  IconData get _roleIcon =>
      _isBusiness ? Icons.business : Icons.local_shipping;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── EMAIL LOGIN ──────────────────────────────────────────────────────────

  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showSnackBar('Email and password are required.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      await _ensureUserProvisioned(cred.user!);
      if (!mounted) return;
      final actualRole =
          context.read<UserProvider>().user?.role ?? widget.role;
      if (actualRole != widget.role) {
        _showSnackBar(
            'You are registered as a $actualRole. Redirecting...');
      } else {
        _showSnackBar('Login successful!');
      }
      context.go(actualRole == 'business'
          ? '/business/dashboard'
          : '/transporter/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      final msg = switch (e.code) {
        'user-not-found' => 'No account found for this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-email' => 'Invalid email address.',
        _ => e.message ?? 'Authentication failed.',
      };
      _showSnackBar(msg, isError: true);
    }
  }

  // ─── PHONE OTP AUTH ───────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Please enter a phone number.', isError: true);
      return;
    }
    final formatted = phone.startsWith('+') ? phone : '+91$phone';
    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatted,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential cred) async {
        await _signInWithCredential(cred);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        _showSnackBar(
            e.message ?? 'Verification failed. Check the number.',
            isError: true);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
          _verificationId = verificationId;
          _resendToken = resendToken;
          _step = AuthStep.otp;
        });
        _showSnackBar('OTP sent to $formatted');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || _verificationId == null) {
      _showSnackBar('Please enter the 6-digit OTP.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!, smsCode: otp);
    await _signInWithCredential(credential);
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await _ensureUserProvisioned(userCred.user!);
      if (!mounted) return;
      setState(() => _isLoading = false);
      final actualRole =
          context.read<UserProvider>().user?.role ?? widget.role;
      if (actualRole != widget.role) {
        _showSnackBar(
            'You are registered as a $actualRole. Redirecting...');
      } else {
        _showSnackBar('Login successful!');
      }
      context.go(actualRole == 'business'
          ? '/business/dashboard'
          : '/transporter/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        e.code == 'invalid-verification-code'
            ? 'Invalid OTP.'
            : (e.message ?? 'Sign in failed.'),
        isError: true,
      );
    }
  }

  // ─── FIRESTORE HELPER ─────────────────────────────────────────────────────

  Future<void> _ensureUserProvisioned(User user) async {
    if (!mounted) return;
    try {
      await context.read<UserProvider>().ensureUserExists(
            user,
            role: widget.role,
            email: _emailController.text.isNotEmpty
                ? _emailController.text.trim()
                : null,
            phone: _phoneController.text.isNotEmpty
                ? _phoneController.text.trim()
                : null,
          );
    } catch (e) {
      debugPrint('Error provisioning user: $e');
      if (mounted) {
        _showSnackBar('Error setting up user profile: $e', isError: true);
      }
      rethrow;
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // ── Back Button ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/role-selection'),
                        icon: const Icon(Icons.arrow_back, size: 16,
                            color: Colors.black87),
                        label: const Text('Back',
                            style: TextStyle(color: Colors.black87)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Card ──
                    Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Gradient Header ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 28, horizontal: 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _primaryColor,
                                  _primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(_roleIcon,
                                      color: Colors.white, size: 32),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '${_isBusiness ? 'Business' : 'Transporter'} Login',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Welcome back to TrustNet AI',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Form Body ──
                          Padding(
                            padding: const EdgeInsets.all(28),
                            child: _step == AuthStep.credentials
                                ? _buildCredentialsForm()
                                : _buildOtpForm(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 11, color: Colors.black38),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── CREDENTIALS FORM ─────────────────────────────────────────────────────

  Widget _buildCredentialsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone / Email method toggle
        _buildMethodToggle(),
        const SizedBox(height: 24),

        // Method-specific fields
        if (_method == AuthMethod.phone) ...[
          _buildFormField(
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            hint: '+91 98765 43210',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter with country code, e.g. +91xxxxxxxxxx',
            style: TextStyle(fontSize: 11, color: Colors.black38),
          ),
        ] else ...[
          _buildFormField(
            label: 'Email Address',
            icon: Icons.email_outlined,
            controller: _emailController,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildPasswordField(),
        ],

        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_method == AuthMethod.phone
                    ? _sendOtp
                    : _handleEmailLogin),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primaryColor.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _method == AuthMethod.phone
                            ? Icons.sms_outlined
                            : Icons.login,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _method == AuthMethod.phone
                            ? 'Send OTP'
                            : 'Login with Email',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Register link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            GestureDetector(
              onTap: () =>
                  context.go('/register', extra: widget.role),
              child: Text(
                'Register',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── OTP FORM ─────────────────────────────────────────────────────────────

  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.sms_rounded, size: 52, color: _primaryColor),
        const SizedBox(height: 12),
        const Text(
          'Enter OTP',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a 6-digit code to\n${_phoneController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 10),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 1.5),
            ),
            hintText: '------',
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() {
                          _step = AuthStep.credentials;
                          _otpController.clear();
                        }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Verify & Login',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _isLoading ? null : _sendOtp,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Resend OTP'),
        ),
      ],
    );
  }

  // ─── METHOD TOGGLE ────────────────────────────────────────────────────────

  Widget _buildMethodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleButton(
            label: '📱  Phone OTP',
            isActive: _method == AuthMethod.phone,
            onTap: () => setState(() => _method = AuthMethod.phone),
          ),
          _buildToggleButton(
            label: '✉️  Email',
            isActive: _method == AuthMethod.email,
            onTap: () => setState(() => _method = AuthMethod.email),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isActive ? _primaryColor : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }

  // ─── FORM FIELD BUILDER ───────────────────────────────────────────────────

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black38, size: 20),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ─── PASSWORD FIELD ───────────────────────────────────────────────────────

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline,
                color: Colors.black38, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.black38,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            hintText: 'Enter your password',
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
