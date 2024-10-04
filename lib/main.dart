import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hoophub/pages/account.dart';
import 'package:hoophub/pages/community.dart';
import 'package:hoophub/pages/homepage/homepage.dart';
import 'package:hoophub/pages/landing.dart';
import 'package:hoophub/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures that Firebase is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Ensure this is correctly initialized
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
      home: const LandingPage(), // Set LandingPage as the initial page
      routes: {
        '/community': (context) => const CommunityPage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LandingPage(),
        '/account': (context) => AccountPage(),
        '/landing': (context) => const LandingPage(),  // Define the landing page route
      },
    );
  }
}
