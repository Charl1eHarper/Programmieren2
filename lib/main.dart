import 'package:flutter/material.dart';
import 'package:hoophub/pages/community.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoophub/pages/homepage/homepage.dart'; // Ensure this path is correct
import 'package:hoophub/pages/test_firestore.dart'; // Ensure this path is correct




void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Ensures that Firebase is initialized
  await Firebase.initializeApp(); // Initializes Firebase
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
      home: const HomePage(), // Ensure this points to your actual home page
      routes: {
        '/community':(context) => const CommunityPage(),
        '/home':(context) => const HomePage(),
        '/test_firestore': (context) => TestFirestorePage(),
      },
    );
  }
}