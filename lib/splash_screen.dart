import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX for navigation
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:bullvest/home_screen.dart'; // User landing screen
import 'package:bullvest/view_model/user_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:bullvest/login_screen.dart';
import 'package:bullvest/model/app_constants.dart';
import 'package:bullvest/api/firebase_api.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait for a brief moment before navigating
    Future.delayed(const Duration(seconds: 2), _checkAuthStatus);
  }

  // Function to check authentication status
  void _checkAuthStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        AppConstants.currentUser.id = user.uid;

        // Deep link handling
        /*  final Uri initialUri = Uri.base;
        final isDeepLinkToReel = initialUri.path == '/reel' &&
            initialUri.queryParameters['param'] != null;
        final reelId = initialUri.queryParameters['param'];
        

        // Immediately navigate
        if (isDeepLinkToReel) {
          Get.offAll(() => VideoReelsPage(reelId: reelId!));
        } else {
          Get.offAll(() => const VideoReelsPage());
        }
        */

        // Load remaining data asynchronously in background
        _loadUserData(user.uid);
      } else {
        // No user -> go to login
        Get.offAll(() => const LoginScreen());
      }
    } catch (e, stack) {
      print("❌ SplashScreen error: $e\n$stack");
      Get.snackbar("Error", "Something went wrong. Please try again.");
      Get.offAll(() => const LoginScreen());
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      // Parallel fetch Firestore and Storage image
      final userDocFuture =
          FirebaseFirestore.instance.collection('users').doc(userId).get();

      final imageFuture = AppConstants.currentUser.displayImage == null
          ? FirebaseStorage.instance
              .ref()
              .child("userImages/$userId/$userId.png")
              .getData(5 * 1024 * 1024)
          : Future.value(null);

      // Wait for Firestore + image
      final results = await Future.wait([userDocFuture, imageFuture]);

      DocumentSnapshot snapshot = results[0] as DocumentSnapshot;
      final imageDataInBytes = results[1] as Uint8List?;

      // Populate user info
      AppConstants.currentUser.snapshot = snapshot;
      AppConstants.currentUser.firstName = snapshot["firstName"] ?? "";
      AppConstants.currentUser.lastName = snapshot['lastName'] ?? "";
      AppConstants.currentUser.email = snapshot['email'] ?? "";
      AppConstants.currentUser.type = snapshot['type'] ?? "";
      AppConstants.currentUser.country = snapshot['country'] ?? "";
      AppConstants.currentUser.state = snapshot['state'] ?? "";

      // Set image if fetched
      if (imageDataInBytes != null) {
        AppConstants.currentUser.displayImage = MemoryImage(imageDataInBytes);
      }

      // Fetch posts in background without blocking
      //  AppConstants.currentUser.getMyPostingsFromFirestore().catchError((e) {
      //  print("❌ Error fetching postings: $e");
      // });

      // Initialize notifications & upload FCM token in background
      FirebaseApi().initNotifications().catchError((e) {
        print("❌ Error initializing notifications: $e");
      });
      FirebaseApi().uploadPendingFcmToken(userId).catchError((e) {
        print("❌ Error uploading FCM token: $e");
      });

      //  await PostingsManager().initializeUser();
      // await PostingsManager().initializePostings();

      // Check account status
      if (AppConstants.currentUser.status == 0) {
        await FirebaseAuth.instance.signOut();
        Get.snackbar(
          "Account Suspended",
          "Your account has been suspended. You've been logged out.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black,
          duration: Duration(seconds: 4),
        );
        Get.offAll(() => LoginScreen());
      }
    } catch (e) {
      print("❌ Error loading user data in background: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
              ],
              begin: FractionalOffset(0, 0),
              end: FractionalOffset(1, 0),
              stops: [0, 1],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.white,
              Colors.white,
              Colors.white,
            ],
          ),
          image: DecorationImage(
            image: AssetImage(""), // Add your image if needed
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.2), BlendMode.darken),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TweenAnimationBuilder for zooming effect
              TweenAnimationBuilder(
                tween: Tween<double>(
                    begin: 0.5,
                    end: 1.0), // Start at 50% scale and zoom to 100%
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut, // Smooth zooming curve
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale, // Apply the zoom scale
                    child: child,
                  );
                },
                child: Text("BULLVEST"), // Splash logo image
              ),
              SizedBox(height: 50),
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  "version 1.0.0", // Text on splash screen
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 10,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//ok
