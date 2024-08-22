import 'package:flutter/material.dart';
import 'package:hoophub/pages/community.dart';
import 'package:hoophub/pages/homepage/homepage.dart'; // Ensure this path is correct

void main() {
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
        '/community':(context) => CommunityPage(),
        '/home':(context) => const HomePage()
      },
    );
  }
}