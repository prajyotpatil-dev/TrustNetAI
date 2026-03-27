import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthMode { login, register }
enum AuthMethod { phone, email }
enum AuthStep { credentials, otp }

class _LoginScreenState extends State<LoginScreen> {
  AuthMode _mode = AuthMode.login;
  AuthMethod _method = AuthMethod.phone;
  AuthStep _step = AuthStep.credentials;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _otpController = TextEditingController();

  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _gstinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // ─── EMAIL AUTH ──────────────────────────────────────────────────────────────

  Future<void> _handleEmail() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showSnackBar('Email and password are required.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_mode == AuthMode.login) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
        await _ensureUserProvisioned(cred.user!);
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
        // Optionally update display name
        if (_nameController.text.isNotEmpty) {
          await cred.user?.updateDisplayName(_nameController.text.trim());
        }
        await _ensureUserProvisioned(cred.user!);
      }
      if (!mounted) return;
      final actualRole = context.read<UserProvider>().user?.role ?? widget.role;
      if (actualRole != widget.role) {
        _showSnackBar('You are registered as a $actualRole. Redirecting...');
      } else {
        _showSnackBar('${_mode == AuthMode.login ? 'Login' : 'Registration'} successful!');
      }
      context.go(actualRole == 'business' ? '/business/dashboard' : '/transporter/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      final msg = switch (e.code) {
        'user-not-found'    => 'No account found for this email.',
        'wrong-password'    => 'Incorrect password.',
        'email-already-in-use' => 'An account already exists with this email.',
        'weak-password'     => 'Password is too weak (min 6 characters).',
        'invalid-email'     => 'Invalid email address.',
        _ => e.message ?? 'Authentication failed.',
      };
      _showSnackBar(msg, isError: true);
    }
  }

  // ─── PHONE OTP AUTH ──────────────────────────────────────────────────────────

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
        _showSnackBar(e.message ?? 'Verification failed. Check the number.', isError: true);
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
    final credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: otp);
    await _signInWithCredential(credential);
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      await _ensureUserProvisioned(userCred.user!);
      if (!mounted) return;
      setState(() => _isLoading = false);
      final actualRole = context.read<UserProvider>().user?.role ?? widget.role;
      if (actualRole != widget.role) {
        _showSnackBar('You are registered as a $actualRole. Redirecting...');
      } else {
        _showSnackBar('Login successful!');
      }
      context.go(actualRole == 'business' ? '/business/dashboard' : '/transporter/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        e.code == 'invalid-verification-code' ? 'Invalid OTP.' : (e.message ?? 'Sign in failed.'),
        isError: true,
      );
    }
  }

  // ─── FIRESTORE HELPER ───────────────────────────────────────────────────────

  Future<void> _ensureUserProvisioned(User user) async {
    if (!mounted) return;
    try {
      await context.read<UserProvider>().ensureUserExists(
        user,
        role: widget.role,
        name: _nameController.text.isNotEmpty ? _nameController.text.trim() : null,
        email: _emailController.text.isNotEmpty ? _emailController.text.trim() : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
        gstin: _gstinController.text.isNotEmpty ? _gstinController.text.trim() : null,
      );
    } catch (e) {
      debugPrint('Error provisioning user: $e');
      if (mounted) _showSnackBar('Error setting up user profile: $e', isError: true);
      rethrow;
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isBusiness = widget.role == 'business';
    final primaryColor = isBusiness ? const Color(0xFF2563EB) : const Color(0xFF16A34A);
    final bgColor = isBusiness ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7);
    final iconData = isBusiness ? Icons.business : Icons.local_shipping;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 200,
        leading: TextButton.icon(
          onPressed: () => context.go('/role-selection'),
          icon: const Icon(Icons.arrow_back, size: 16, color: Colors.black87),
          label: const Text('Back', style: TextStyle(color: Colors.black87)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                    child: Icon(iconData, color: primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isBusiness ? 'Business Owner' : 'Transporter',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('Welcome to TrustNet AI', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ]),
                ]),

                const SizedBox(height: 28),

                // Login / Register tab
                _tabBar(['Login', 'Register'],
                    selected: _mode == AuthMode.login ? 0 : 1,
                    primaryColor: primaryColor,
                    onTap: (i) => setState(() {
                          _mode = i == 0 ? AuthMode.login : AuthMode.register;
                          _step = AuthStep.credentials;
                          _otpController.clear();
                        })),

                const SizedBox(height: 20),

                // Phone / Email method tab (only on credentials step)
                if (_step == AuthStep.credentials) ...[
                  _tabBar(['📱  Phone OTP', '✉️  Email'],
                      selected: _method == AuthMethod.phone ? 0 : 1,
                      primaryColor: primaryColor,
                      onTap: (i) => setState(() => _method = i == 0 ? AuthMethod.phone : AuthMethod.email)),

                  const SizedBox(height: 24),

                  // Register-only fields
                  if (_mode == AuthMode.register) ...[
                    _buildTextField('Full Name', Icons.person, _nameController),
                    const SizedBox(height: 14),
                    if (_method == AuthMethod.email || (isBusiness)) ...[
                      _buildTextField('Email', Icons.email, _emailController,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                    ],
                  ],

                  // Method-specific fields
                  if (_method == AuthMethod.phone) ...[
                    _buildTextField('Phone Number', Icons.phone, _phoneController,
                        keyboardType: TextInputType.phone, hint: '+91 98765 43210'),
                    const SizedBox(height: 4),
                    const Text('Enter with country code, e.g. +91xxxxxxxxxx',
                        style: TextStyle(fontSize: 11, color: Colors.black38)),
                  ] else ...[
                    if (_mode == AuthMode.login) ...[
                      _buildTextField('Email', Icons.email, _emailController,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                    ],
                    _buildPasswordField(primaryColor),
                  ],

                  if (_mode == AuthMode.register && isBusiness && _method == AuthMethod.phone) ...[
                    const SizedBox(height: 14),
                    _buildTextField('GSTIN', Icons.description, _gstinController,
                        hint: '22AAAAA0000A1Z5', helperText: 'Required for business verification'),
                  ],

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (_method == AuthMethod.phone ? _sendOtp : _handleEmail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _method == AuthMethod.phone
                                  ? 'Send OTP'
                                  : (_mode == AuthMode.login ? 'Login with Email' : 'Create Account'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ] else ...[
                  // ── OTP Verification Step ──
                  const Icon(Icons.sms_rounded, size: 52, color: Color(0xFF2563EB)),
                  const SizedBox(height: 12),
                  const Text('Enter OTP', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('We sent a 6-digit code to\n${_phoneController.text.trim()}',
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 10),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: '------',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  _step = AuthStep.credentials;
                                  _otpController.clear();
                                }),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Verify & Login',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _sendOtp,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Resend OTP'),
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBar(List<String> labels, {required int selected, required Color primaryColor, required Function(int) onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive
                      ? [BoxShadow(color: primaryColor.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isActive ? primaryColor : Colors.black45,
                    )),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPasswordField(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: Colors.black45),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black45),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: _mode == AuthMode.login ? 'Enter your password' : 'Create a password (min 6 chars)',
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller,
      {TextInputType? keyboardType, String? hint, String? helperText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black45),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: hint ?? 'Enter your $label',
            helperText: helperText,
          ),
        ),
      ],
    );
  }
}
