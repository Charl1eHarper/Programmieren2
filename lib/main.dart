import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hoophub/pages/community.dart';
import 'package:hoophub/pages/homepage/homepage.dart';
import 'package:hoophub/pages/test_firestore.dart';
import 'package:hoophub/pages/landing.dart';
import 'package:hoophub/auth_checker.dart'; // Add this import for AuthChecker
import 'package:hoophub/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures that Firebase is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Stelle sicher, dass dies korrekt initialisiert wird
  ); // Initializes Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoopHub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthChecker(), // Use AuthChecker as the initial page
      routes: {
        '/community': (context) => const CommunityPage(),
        '/home': (context) => const HomePage(),
        '/test_firestore': (context) => TestFirestorePage(),
        '/login': (context) => const LandingPage(), // You can still directly navigate to LandingPage if needed
      },
    );
  }
}