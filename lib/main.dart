// lib/main.dart
import 'package:devsecit_ambulance_driver/features/auth/screens/welcome_screen.dart';
import 'package:devsecit_ambulance_driver/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The root of your application MUST be MaterialApp.
    return MaterialApp(
      // This applies the custom theme you created earlier.
      // theme: ThemeData(colorScheme: ),
      debugShowCheckedModeBanner: false,
      color: Colors.white,
      // This sets your new WelcomeScreen as the first page of the app.
      home: const WelcomeScreen(),
    );
  }
}
