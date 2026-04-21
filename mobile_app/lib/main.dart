import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/firebase_service.dart';
import 'services/gst_verification_service.dart';
import 'providers/user_provider.dart';
import 'providers/business_shipment_provider.dart';
import 'providers/transporter_shipment_provider.dart';
import 'providers/ai_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Seed GST demo data on startup (idempotent — uses doc IDs, safe to call multiple times)
    await GSTVerificationService.seedDemoData();
  } catch (e) {
    debugPrint("Firebase initialization failed or not configured. UI will run in mock mode. Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        ChangeNotifierProxyProvider<FirebaseService, UserProvider>(
          create: (context) => UserProvider(context.read<FirebaseService>()),
          update: (context, firebaseService, previous) => previous ?? UserProvider(firebaseService),
        ),
        ChangeNotifierProxyProvider<UserProvider, BusinessShipmentProvider>(
          create: (_) => BusinessShipmentProvider(),
          update: (_, userProvider, provider) => provider ?? BusinessShipmentProvider(),
        ),
        ChangeNotifierProxyProvider<UserProvider, TransporterShipmentProvider>(
          create: (_) => TransporterShipmentProvider(),
          update: (_, userProvider, provider) => provider ?? TransporterShipmentProvider(),
        ),
        // AI Provider — Central intelligence layer
        ChangeNotifierProvider<AIProvider>(
          create: (_) => AIProvider(),
        ),
      ],
      child: const TrustNetApp(),
    ),
  );
}

class TrustNetApp extends StatelessWidget {
  const TrustNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TrustNet AI Flow',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
