import 'package:bullvest/home_screen.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:bullvest/global.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:bullvest/signup_screen.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/services.dart';
import 'package:bullvest/reset_password_screen.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();

  bool _isSubmitting = false;
  String password = ''; // Initialize the password variable
  bool showPassword = false; // Initialize the showPassword flag

  void toggleShowPassword() {
    setState(() {
      showPassword = !showPassword; // Toggle the showPassword flag
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Logo (optional)
                  // Image.asset("images/afrikk_prev_ui.png", height: 160),

                  Text(
                    'Bullvest',
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🔐 Form Start
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email
                        TextFormField(
                          style: TextStyle(color: Colors.tealAccent),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.tealAccent),
                            prefixIcon: Icon(Icons.email),
                            prefixIconColor: Colors.tealAccent,
                            filled: true,
                            fillColor: Colors.black,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: Colors.tealAccent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: BorderSide(color: Colors.tealAccent),
                            ),
                          ),
                          controller: _emailTextController,
                          validator: (value) =>
                              value!.contains("@") ? null : "Enter valid email",
                        ),
                        const SizedBox(height: 20),

                        // Password
                        TextFormField(
                          style: TextStyle(color: Colors.tealAccent),
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.tealAccent),
                            prefixIcon: Icon(Icons.lock),
                            prefixIconColor: Colors.tealAccent,
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: toggleShowPassword,
                            ),
                            filled: true,
                            fillColor: Colors.black,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: Colors.tealAccent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: BorderSide(color: Colors.tealAccent),
                            ),
                          ),
                          controller: _passwordTextController,
                          validator: (value) =>
                              value!.length >= 6 ? null : "Min 6 characters",
                        ),
                        const SizedBox(height: 25),

                        // Login button
                        Obx(() {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: userViewModel.isSubmitting.value
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        userViewModel.login(
                                          _emailTextController.text.trim(),
                                          _passwordTextController.text.trim(),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent,
                              ),
                              child: userViewModel.isSubmitting.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.black,
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 18),
                                    ),
                            ),
                          );
                        }),
                        const SizedBox(height: 15),

                        // Forgot password
                        TextButton(
                          onPressed: () {
                            Get.to(ResetPasswordScreen());
                          },
                          child: Text(
                            "Forgot your password?",
                            style: TextStyle(
                                fontSize: 14, color: Colors.tealAccent),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.tealAccent)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text("OR"),
                            ),
                            Expanded(child: Divider(color: Colors.tealAccent)),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // Signup prompt
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("New here?",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.white)),
                            TextButton(
                              onPressed: () => Get.to(SignupScreen()),
                              child: Text("Sign up now",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.tealAccent)),
                            ),
                          ],
                        ),
                      ],
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
