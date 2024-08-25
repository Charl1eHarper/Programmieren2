import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoophub/pages/homepage/homepage.dart'; // Ensure this path is correct
import 'package:hoophub/pages/landing.dart'; // Ensure this path is correct

class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LandingPage(); // Show the landing page if not logged in
          } else {
            return HomePage(); // Show the home page if logged in
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}