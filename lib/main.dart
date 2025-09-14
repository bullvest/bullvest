import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bullvest/splash_screen.dart';
import 'package:bullvest/login_screen.dart';
import 'package:bullvest/firebase_options.dart';

void main() async {
  // Ensure Firebase is initialized before running the app
  //WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp(); // Firebase initialization

  runApp(BullvestApp());
}

class BullvestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bullvest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(), // Login screen route
      },
    );
  }
}
