import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'package:bullvest/login_screen.dart';
import 'role_router.dart'; // Navigate according to role

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation: scale logo
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    // Delay before checking auth
    Future.delayed(const Duration(seconds: 2), _checkAuthStatus);
  }

  // Check Firebase auth and load user data
  Future<void> _checkAuthStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        AppConstants.currentUser.id = user.uid;

        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!snapshot.exists) throw Exception("User not found in Firestore.");

        // Populate user constants
        AppConstants.currentUser.snapshot = snapshot;
        AppConstants.currentUser.firstName = snapshot['firstName'] ?? '';
        AppConstants.currentUser.lastName = snapshot['lastName'] ?? '';
        AppConstants.currentUser.email = snapshot['email'] ?? '';
        AppConstants.currentUser.type = snapshot['type'] ?? 'investor';
        AppConstants.currentUser.country = snapshot['country'] ?? '';
        AppConstants.currentUser.state = snapshot['state'] ?? '';

        // Redirect to RoleRouter
        Get.offAll(() => const RoleRouter());
      } else {
        // Not logged in
        Get.offAll(() => const LoginScreen());
      }
    } catch (e, stack) {
      print("❌ SplashScreen error: $e\n$stack");
      Get.snackbar(
        "Error",
        "Something went wrong. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
        duration: const Duration(seconds: 4),
      );
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black87,
              Colors.black54,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ScaleTransition(
                  scale: _animation,
                  child: Text(
                    "BULLVEST",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      color: Colors.tealAccent.shade400,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                const Text(
                  "The investor-founder marketplace",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                // Progress indicator
                const CircularProgressIndicator(
                  color: Colors.tealAccent,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
