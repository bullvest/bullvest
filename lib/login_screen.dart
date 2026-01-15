import 'package:bullvest/model/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/global.dart';
import 'package:bullvest/signup_screen.dart';
import 'package:bullvest/reset_password_screen.dart';
import 'founder/founder_nav.dart';
import 'investor/investor_nav.dart';
import 'package:bullvest/view_model/user_view_model.dart';
import 'package:bullvest/model/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();

  bool showPassword = false;
  bool isSubmitting = false;

  void toggleShowPassword() {
    setState(() => showPassword = !showPassword);
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      // Firebase authentication
      UserCredential userCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailTextController.text.trim(),
              password: _passwordTextController.text.trim());

      String uid = userCred.user!.uid;

      // Fetch user role from Firestore
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        Get.snackbar(
          'Error',
          'User not found in database',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        setState(() => isSubmitting = false);
        return;
      }

      final userData = userDoc.data()!;
      String role = userData['type'] ?? 'investor'; // default to investor

      // Set current user in global AppConstants
      AppConstants.currentUser = UserModel.fromMap(userData, uid);

      // Navigate based on role
      if (role.toLowerCase() == 'founder') {
        Get.offAll(() => const FounderBottomNav());
      } else {
        Get.offAll(() => const InvestorBottomNav());
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login Failed',
        e.message ?? 'Something went wrong',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo placeholder
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.tealAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'B',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App name
                  const Text(
                    'Bullvest',
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Card container for form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailTextController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle:
                                  const TextStyle(color: Colors.tealAccent),
                              prefixIcon: const Icon(Icons.email,
                                  color: Colors.tealAccent),
                              filled: true,
                              fillColor: Colors.grey[850],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) => value!.contains("@")
                                ? null
                                : "Enter valid email",
                          ),
                          const SizedBox(height: 20),

                          // Password
                          TextFormField(
                            controller: _passwordTextController,
                            obscureText: !showPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle:
                                  const TextStyle(color: Colors.tealAccent),
                              prefixIcon: const Icon(Icons.lock,
                                  color: Colors.tealAccent),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.tealAccent,
                                ),
                                onPressed: toggleShowPassword,
                              ),
                              filled: true,
                              fillColor: Colors.grey[850],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) =>
                                value!.length >= 6 ? null : "Min 6 characters",
                          ),
                          const SizedBox(height: 25),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.black)
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  Get.to(() => const ResetPasswordScreen()),
                              child: const Text(
                                "Forgot password?",
                                style: TextStyle(color: Colors.tealAccent),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[700])),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("OR",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              Expanded(child: Divider(color: Colors.grey[700])),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Signup prompt
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("New here?",
                                  style: TextStyle(color: Colors.grey)),
                              TextButton(
                                onPressed: () =>
                                    Get.to(() => const SignupScreen()),
                                child: const Text(
                                  "Sign up now",
                                  style: TextStyle(
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
