import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/gst_verification_service.dart';
import '../../providers/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // GST verification state
  bool _isVerifyingGST = false;
  bool _gstVerified = false;
  String? _gstError;
  String? _gstBusinessName;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
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

  // ─── GST VERIFICATION ─────────────────────────────────────────────────────

  Future<bool> _validateAndVerifyGST() async {
    final gst = _gstinController.text.trim().toUpperCase();
    if (gst.isEmpty) {
      setState(() => _gstError = 'GSTIN is required for business registration');
      return false;
    }

    final formatError = GSTVerificationService.validateFormat(gst);
    if (formatError != null) {
      setState(() {
        _gstError = formatError;
        _gstVerified = false;
        _gstBusinessName = null;
      });
      return false;
    }

    if (_gstVerified && _gstBusinessName != null) return true;

    setState(() {
      _isVerifyingGST = true;
      _gstError = null;
    });

    final result = await GSTVerificationService.verify(gst);

    if (!mounted) return false;
    setState(() {
      _isVerifyingGST = false;
      _gstVerified = result.isValid;
      _gstBusinessName = result.businessName;
      _gstError = result.errorMessage;
    });

    if (!result.isValid) {
      _showSnackBar(result.errorMessage ?? 'GST verification failed',
          isError: true);
    }

    return result.isValid;
  }

  // ─── REGISTER ─────────────────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Verify GST for business accounts
      if (_isBusiness) {
        final gstValid = await _validateAndVerifyGST();
        if (!gstValid) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Create Firebase Auth user with email/password
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Set display name
      await cred.user?.updateDisplayName(_nameController.text.trim());

      // Store user profile in Firestore
      if (!mounted) return;
      await context.read<UserProvider>().ensureUserExists(
            cred.user!,
            role: widget.role,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            gstin: _isBusiness
                ? _gstinController.text.trim().toUpperCase()
                : null,
            gstVerified: _gstVerified,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Success toast
      _showSnackBar(
        '🎉 Account created successfully! Welcome to TrustNet AI.',
      );

      // Auto-login → navigate to dashboard
      context.go(_isBusiness
          ? '/business/dashboard'
          : '/transporter/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      final msg = switch (e.code) {
        'email-already-in-use' =>
          'An account already exists with this email.',
        'weak-password' => 'Password is too weak (min 6 characters).',
        'invalid-email' => 'Invalid email address.',
        _ => e.message ?? 'Registration failed.',
      };
      _showSnackBar(msg, isError: true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Registration failed: $e', isError: true);
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
                                  'Create ${_isBusiness ? 'Business' : 'Transporter'} Account',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Join TrustNet AI in seconds',
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Full Name
                                  _buildFormField(
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    controller: _nameController,
                                    hint: 'Enter your full name',
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Name is required';
                                      }
                                      if (v.trim().length < 2) {
                                        return 'Name must be at least 2 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // Email
                                  _buildFormField(
                                    label: 'Email Address',
                                    icon: Icons.email_outlined,
                                    controller: _emailController,
                                    hint: 'you@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      final emailRegex = RegExp(
                                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                      if (!emailRegex.hasMatch(v.trim())) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // Password
                                  _buildPasswordField(),
                                  const SizedBox(height: 18),

                                  // Phone Number
                                  _buildFormField(
                                    label: 'Phone Number',
                                    icon: Icons.phone_outlined,
                                    controller: _phoneController,
                                    hint: '+91 98765 43210',
                                    keyboardType: TextInputType.phone,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Phone number is required';
                                      }
                                      final digits = v.replaceAll(
                                          RegExp(r'[^\d]'), '');
                                      if (digits.length < 10) {
                                        return 'Enter a valid phone number';
                                      }
                                      return null;
                                    },
                                  ),

                                  // GSTIN (Business only)
                                  if (_isBusiness) ...[
                                    const SizedBox(height: 18),
                                    _buildGSTField(),
                                  ],

                                  const SizedBox(height: 28),

                                  // Submit button
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryColor,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            _primaryColor.withOpacity(0.5),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.app_registration,
                                                    size: 20),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Create Account',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Login link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Already have an account? ',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => context.go('/login',
                                            extra: widget.role),
                                        child: Text(
                                          'Login',
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'By creating an account, you agree to our\nTerms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.black38),
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

  // ─── FORM FIELD BUILDER ───────────────────────────────────────────────────

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
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
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon:
                const Icon(Icons.lock_outline, color: Colors.black38, size: 20),
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
            hintText: 'Min 6 characters',
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ─── GST FIELD WITH VERIFICATION ──────────────────────────────────────────

  Widget _buildGSTField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GSTIN',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _gstinController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 15,
          onChanged: (value) {
            if (_gstVerified || _gstError != null) {
              setState(() {
                _gstVerified = false;
                _gstBusinessName = null;
                _gstError = null;
              });
            }
          },
          validator: (v) {
            if (!_isBusiness) return null;
            if (v == null || v.trim().isEmpty) {
              return 'GSTIN is required for business registration';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.description_outlined,
                color: Colors.black38, size: 20),
            hintText: '22AAAAA0000A1Z5',
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
            counterText: '',
            helperText: 'Required for business verification',
            helperStyle:
                const TextStyle(color: Colors.black38, fontSize: 11),
            errorText: _gstError,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _isVerifyingGST
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _gstVerified
                    ? const Icon(Icons.verified, color: Colors.green, size: 24)
                    : IconButton(
                        icon: Icon(Icons.check_circle_outline,
                            color: _primaryColor),
                        tooltip: 'Verify GSTIN',
                        onPressed:
                            _isVerifyingGST ? null : _validateAndVerifyGST,
                      ),
          ),
        ),

        // Verification success badge
        if (_gstVerified && _gstBusinessName != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF16A34A).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user,
                    color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✔ GST Verified',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _gstBusinessName!,
                        style: const TextStyle(
                            color: Color(0xFF15803D), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
