import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart'; // <-- Add this import
import 'package:bullvest/splash_screen.dart';
import 'package:bullvest/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(BullvestApp());
}

class BullvestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // <-- Use GetMaterialApp here
      title: 'Bullvest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.dark(
          primary: Colors.black,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
