import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

enum UserRole { investor, founder }

class _LoginScreenState extends State<LoginScreen> {
  UserRole? _selectedRole;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Firebase Authentication and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Sign-In method
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user role is already set in Firestore
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // Role is already set, navigate directly
          final role =
              userDoc.data()?['role'] ?? 'investor'; // Default to 'investor'
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(userRole: role)),
          );
        } else {
          // Role is not set, show role selection screen
          _showRoleSelectionDialog(user);
        }
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
    }
  }

  // Show role selection dialog after Google Sign-In
  void _showRoleSelectionDialog(User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Your Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<UserRole>(
                title: Text('Investor'),
                value: UserRole.investor,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
              RadioListTile<UserRole>(
                title: Text('Founder'),
                value: UserRole.founder,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedRole != null) {
                  // Save role to Firestore
                  _firestore.collection('users').doc(user.uid).set({
                    'role': _selectedRole == UserRole.investor
                        ? 'investor'
                        : 'founder',
                    'email': user.email,
                  });

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HomeScreen(
                            userRole: _selectedRole == UserRole.investor
                                ? 'investor'
                                : 'founder')),
                  );
                }
              },
              child: Text('Save Role'),
            ),
          ],
        );
      },
    );
  }

  // Login method
  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedRole == UserRole.investor) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(userRole: 'investor')),
        );
      } else if (_selectedRole == UserRole.founder) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(userRole: 'founder')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo or name
                Text(
                  'BullVest',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),

                // Google Sign-In button
                ElevatedButton(
                  onPressed: _signInWithGoogle,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'images/google.png', // Make sure to place the image in the correct location
                        height: 24, // Adjust the size as needed
                        width: 24,
                      ),
                      SizedBox(width: 8),
                      Text('Sign in with Google'),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
