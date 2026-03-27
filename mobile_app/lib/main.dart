import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/firebase_service.dart';
import 'providers/user_provider.dart';
import 'providers/business_shipment_provider.dart';
import 'providers/transporter_shipment_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try initializing Firebase. If it fails (missing options), we fallback gracefully
  // so the UI can still be previewed during development.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
