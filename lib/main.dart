import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:canteen_management_app/providers/auth_provider.dart';
import 'package:canteen_management_app/providers/cart_provider.dart';
import 'package:canteen_management_app/providers/menu_provider.dart';
import 'package:canteen_management_app/providers/order_provider.dart';
import 'package:canteen_management_app/screens/splash_screen.dart';
import 'package:canteen_management_app/services/notification_service.dart';
import 'package:canteen_management_app/services/notification_handler.dart';
import 'package:canteen_management_app/utils/app_theme.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase in the same zone
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Only initialize notifications if not on web platform
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canteen Management',
      theme: AppTheme.theme,
      home: NotificationHandler(
        child: const SplashScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
