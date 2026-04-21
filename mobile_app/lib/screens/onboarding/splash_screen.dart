import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start auth check after a brief splash delay for branding
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // ── Not logged in → role selection ────────────────────────────
        if (mounted) context.go('/role-selection');
        return;
      }

      // ── User is logged in → fetch profile & route by role ──────────
      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      await userProvider.fetchUserProfile(currentUser.uid);

      if (!mounted) return;

      final user = userProvider.user;
      if (user == null) {
        // Profile missing in Firestore (edge case) — send to role selection
        context.go('/role-selection');
        return;
      }

      // Route based on role
      if (user.role == 'business') {
        context.go('/business/dashboard');
      } else {
        context.go('/transporter/dashboard');
      }
    } catch (e) {
      debugPrint('[Splash] Auth check failed: $e');
      // On any error, fall back to role selection
      if (mounted) context.go('/role-selection');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2563EB), // blue-600
              Color(0xFF1D4ED8), // blue-700
              Color(0xFF3730A3), // indigo-800
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _controller,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white24,
                        width: 4,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    size: 64,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield, color: Colors.white, size: 32),
                SizedBox(width: 8),
                Text(
                  'TrustNet AI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Logistics Trust Scoring Platform',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFFDBEAFE), // blue-100
              ),
            ),
            const SizedBox(height: 32),
            // Loading indicator while checking auth
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 32.0),
        child: Text(
          'Powered by AI · Secured by Trust',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFBFDBFE), // blue-200
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
