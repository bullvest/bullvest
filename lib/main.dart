import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bullvest/splash_screen.dart';
import 'package:bullvest/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(BullvestApp());
}

class BullvestApp extends StatefulWidget {
  @override
  State<BullvestApp> createState() => _BullvestAppState();
}

class _BullvestAppState extends State<BullvestApp> {
  @override
  void initState() {
    super.initState();
    _saveFCMToken();
  }

  Future<void> _saveFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Only save if user is logged in

      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Get the FCM token
      String? token = await messaging.getToken();
      print("FCM Token: $token");

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
        print("Token saved for user ${user.uid}");
      }

      // Listen for token refresh automatically
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'fcmToken': newToken});
          print("Token refreshed for user ${user.uid}");
        }
      });
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Bullvest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
