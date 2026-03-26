import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/firebase_service.dart';
import 'providers/user_provider.dart';
import 'providers/shipment_provider.dart';
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
        ChangeNotifierProxyProvider<UserProvider, ShipmentProvider>(
          create: (_) => ShipmentProvider(),
          update: (_, userProvider, shipmentProvider) {
            final provider = shipmentProvider ?? ShipmentProvider();
            final uid = userProvider.user?.uid;
            if (uid != null && uid.isNotEmpty) {
              provider.listenShipments(uid);
            }
            return provider;
          },
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
