import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _loginErrorMessage = ''; // Variable to store login error messages

// Registration logic
  Future<void> _register(String email, String password) async {
    final navigator = Navigator.of(context);  // Capture the Navigator before async
    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseFirestore.instance //create new user
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'createdAt': Timestamp.now(),
      });
      navigator.pushReplacementNamed('/home');  // move to homepage after user creation
    } catch (e) {
      setState(() {
        _loginErrorMessage = _getErrorMessage(e); // get error if method fails
      });
    }
  }

// Login logic
  Future<void> _login() async {
    final navigator = Navigator.of(context);  // Capture the Navigator before async
    //pass credentials to firebase for verfication of login
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      navigator.pushReplacementNamed('/home');  // move to home after login
    } catch (e) {
      setState(() {
        _loginErrorMessage = _getErrorMessage(e); // get error if method fails
      });
    }
  }

  // Google login logic
  Future<void> _loginWithGoogle() async {
    final navigator = Navigator.of(context);  // Capture the Navigator before async to avoid losing context after await
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();  // prompt user to sign in with Google

      if (googleUser == null) return;  // if the sign-in was canceled, exit early

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;  //get Google authentication tokens

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );  // create Firebase credential using Google auth tokens

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);  // sign in to Firebase with the Google credential

      if (userCredential.additionalUserInfo!.isNewUser) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email,
          'createdAt': Timestamp.now(),
        });  // if the user is new, add their information to the Firestore database
      }

      navigator.pushReplacementNamed('/home');  // navigate to home screen after login
    } catch (e) {
      setState(() {
        _loginErrorMessage = _getErrorMessage(e);  // display error message
      });
    }
  }


// Guest login logic
  Future<void> _loginAsGuest() async {
    final navigator = Navigator.of(context);  // Capture the Navigator before async
    try {
      //make use of firebase anonymous signin
      UserCredential userCredential =
      await FirebaseAuth.instance.signInAnonymously();

      if (userCredential.user != null && userCredential.user!.isAnonymous) {
        navigator.pushReplacementNamed('/home');  // move to homepage after guest login
        _showGuestLimitationsDialog();
      }
    } catch (e) {
      setState(() {
        _loginErrorMessage = 'Gast-Anmeldung fehlgeschlagen'; //get error message
      });
    }
  }

  // Function to show guest limitations
  void _showGuestLimitationsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gastzugang'),
          content: const Text(
              'Sie verwenden die App als Gast. Einige Funktionen wie die Kontoeinstellungen sind eingeschränkt.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to display the sign-up popup
  void _showSignUpPopup(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
    TextEditingController();
    String signUpErrorMessage = ''; // Error message for the sign-up popup

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.grey],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Willkommen!',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Erstellen Sie Ihr Konto',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        // Email input
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                hintText: 'E-Mail',
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ),

                        // Password input
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Passwort',
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ),

                        // Confirm password input
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Passwort bestätigen',
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ),

                        if (signUpErrorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              signUpErrorMessage,
                              style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Sign up button
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              String email = emailController.text.trim();
                              String password = passwordController.text.trim();
                              String confirmPassword =
                              confirmPasswordController.text.trim();

                              if (password != confirmPassword) {
                                setState(() {
                                  signUpErrorMessage = 'Passwörter stimmen nicht überein!';
                                });
                              } else {
                                _register(email, password);
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: Colors.black,
                            ),
                            child: const Text(
                              'Konto erstellen',
                              style:
                              TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Function to get error messages without exposing Firebase state details
  String _getErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'E-Mail wird bereits verwendet!';
        case 'weak-password':
          return 'Passwort ist zu schwach!';
        case 'wrong-password':
          return 'Falsches Passwort!';
        case 'user-not-found':
          return 'Kein Konto für diese E-Mail gefunden!';
        case 'invalid-email':
          return 'Die E-Mail-Adresse ist ungültig!';
        default:
          return 'Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';
      }
    }
    return 'Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient from black to grey
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.grey],
              ),
            ),
          ),

          // Triangle at the top
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height * 0.5),
            painter: EvenWiderTrianglePainter(),
          ),

          // Content (logo, form, etc.)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Branding logo and text
                  Column(
                    children: [
                      Image.asset(
                        'assets/HoopHub.png',
                        height: 200,
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Werde eins mit dem Spiel',
                        style: TextStyle(fontSize: 16, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Login form (Email & Password)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: 'E-Mail',
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Passwort',
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_loginErrorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _loginErrorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Log In Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.black,
                      ),
                      child: const Text(
                        'Einloggen',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // "Or continue with" text
                  const Text('Oder weiter mit',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),

                  // Social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loginWithGoogle,
                        icon:
                        const Icon(Icons.account_circle, color: Colors.red),
                        label: const Text('Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _loginAsGuest,
                        icon: const Icon(Icons.person, color: Colors.blue),
                        label: const Text('Gast'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Footer
                  TextButton(
                    onPressed: () {
                      _showSignUpPopup(context);
                    },
                    child: const Text('Kein Konto? Jetzt erstellen'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to draw black from top triangle
class EvenWiderTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(-300, 0);
    path.lineTo(size.width + 300, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

















