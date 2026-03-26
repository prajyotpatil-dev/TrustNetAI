import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../screens/onboarding/splash_screen.dart';
import '../screens/onboarding/role_selection_screen.dart';
import '../screens/onboarding/login_screen.dart';
// Business
import '../screens/business/business_dashboard_screen.dart';
import '../screens/business/track_shipment_screen.dart';
import '../screens/business/trust_score_screen.dart';
import '../screens/business/ai_risk_report_screen.dart';
import '../screens/business/network_trust_screen.dart';
// Transporter
import '../screens/transporter/transporter_dashboard_screen.dart';
import '../screens/transporter/create_shipment_screen.dart';
import '../screens/transporter/update_status_screen.dart';
import '../screens/transporter/upload_epod_screen.dart';
// Shared Profiles & Settings
import '../screens/shared/shared_screens.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/settings_screens.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // ── Onboarding ────────────────────────────────
      GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/role-selection', builder: (c, s) => const RoleSelectionScreen()),
      GoRoute(
        path: '/login',
        builder: (c, s) {
          final role = s.extra as String? ?? 'business';
          return LoginScreen(role: role);
        },
      ),

      // ── Business Routes ───────────────────────────
      GoRoute(path: '/business/dashboard', builder: (c, s) => const BusinessDashboardScreen()),
      GoRoute(
        path: '/business/track/:id',
        builder: (c, s) => TrackShipmentScreen(shipmentId: s.pathParameters['id'] ?? 'SH001'),
      ),
      GoRoute(path: '/business/trust-score', builder: (c, s) => const TrustScoreScreen()),
      GoRoute(path: '/business/risk-report', builder: (c, s) => const AIRiskReportScreen()),
      GoRoute(path: '/business/network-trust', builder: (c, s) => const NetworkTrustScreen()),

      // ── Transporter Routes ────────────────────────
      GoRoute(path: '/transporter/dashboard', builder: (c, s) => const TransporterDashboardScreen()),
      GoRoute(path: '/transporter/create-shipment', builder: (c, s) => const CreateShipmentScreen()),
      GoRoute(
        path: '/transporter/update-status/:id',
        builder: (c, s) => UpdateStatusScreen(shipmentId: s.pathParameters['id'] ?? 'SH001'),
      ),
      GoRoute(
        path: '/transporter/upload-epod/:id',
        builder: (c, s) => UploadEPODScreen(shipmentId: s.pathParameters['id'] ?? 'SH001'),
      ),

      // ── Shared Routes ─────────────────────────────
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      GoRoute(path: '/shipment-history', builder: (c, s) => const ShipmentHistoryScreen()),
      
      // ── Profile Sub-Routes ────────────────────────
      GoRoute(path: '/profile/edit', builder: (c, s) => const EditProfileScreen()),
      GoRoute(path: '/profile/change-password', builder: (c, s) => const ChangePasswordScreen()),
      GoRoute(path: '/profile/notifications', builder: (c, s) => const NotificationSettingsScreen()),
      GoRoute(path: '/profile/help', builder: (c, s) => const HelpSupportScreen()),
      GoRoute(path: '/profile/privacy', builder: (c, s) => const PrivacyPolicyScreen()),
    ],
  );
}
