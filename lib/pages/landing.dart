import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Add Google SignIn package

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'createdAt': Timestamp.now(),
      });
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: ${e.toString()}')));
    }
  }

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    }
  }

  // Google Sign-In Logic
  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase using the Google credential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Save user details in Firestore
      if (userCredential.additionalUserInfo!.isNewUser) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'createdAt': Timestamp.now(),
        });
      }

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign-in failed: ${e.toString()}')));
    }
  }

  Future<void> _loginAsGuest() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guest login failed: ${e.toString()}')));
    }
  }

  // Add the missing _showLoginDialog method
  Future<void> _showLoginDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign In / Create Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _login(); // Attempt login
                Navigator.pop(context); // Close the dialog after login
              },
              child: const Text('Sign In'),
            ),
            ElevatedButton(
              onPressed: () {
                _register(); // Attempt registration
                Navigator.pop(context); // Close the dialog after registration
              },
              child: const Text('Create Account'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Placeholder at the top
            const Placeholder(
              fallbackHeight: 100,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),

            // Animated welcome text
            SizedBox(
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 24.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    WavyAnimatedText('Welcome to the Experience'),
                  ],
                  isRepeatingAnimation: false,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Icons for login methods
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Email/Password Login Icon
                IconButton(
                  icon: const Icon(Icons.email, size: 40, color: Colors.blue),
                  onPressed: _showLoginDialog,
                  tooltip: 'Login with Email',
                ),
                // Google Login Icon
                IconButton(
                  icon: const Icon(Icons.account_circle, size: 40, color: Colors.red),
                  onPressed: _loginWithGoogle,
                  tooltip: 'Login with Google',
                ),
                // Guest Login Icon
                IconButton(
                  icon: const Icon(Icons.person_outline, size: 40, color: Colors.green),
                  onPressed: _loginAsGuest,
                  tooltip: 'Login as Guest',
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Footer Text
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Hopp Hub 2024, All Rights Reserved',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}