import 'dart:io';
import 'dart:typed_data';
import 'package:bullvest/login_screen.dart';
import 'package:bullvest/model/app_constants.dart';
import 'package:bullvest/model/user_model.dart';
import 'package:bullvest/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:bullvest/reset_password_screen.dart';
import 'package:flutter/services.dart';
import 'package:bullvest/api/firebase_api.dart';

class UserViewModel {
  RxBool isSubmitting = false.obs;
  UserModel userModel = UserModel();

  /// Sign up user
  Future<void> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
    String country,
    String state,
    String mobileNumber,
    String type,
    File imageFileOfUser,
  ) async {
    isSubmitting.value = true;
    Get.snackbar("Please wait", "Your account is being created...");

    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String currentUserID = result.user!.uid;

      AppConstants.currentUser.id = currentUserID;
      AppConstants.currentUser.firstName = firstName;
      AppConstants.currentUser.lastName = lastName;
      AppConstants.currentUser.country = country;
      AppConstants.currentUser.state = state;
      AppConstants.currentUser.mobileNumber = mobileNumber;
      AppConstants.currentUser.email = email;
      AppConstants.currentUser.type = type;
      AppConstants.currentUser.password = password;

      await saveUserToFirestore(
        type,
        mobileNumber,
        country,
        state,
        email,
        firstName,
        lastName,
        currentUserID,
      ).whenComplete(() async {
        await addImageToFirebaseStorage(imageFileOfUser, currentUserID);
      });

      await FirebaseApi().uploadPendingFcmToken(currentUserID);

      await sendWelcomeEmail(email, firstName, mobileNumber, state, country);

      Get.snackbar("Success", "Your account has been created.");
      Get.to(() => HomeScreen(userRole: "investor"));
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Save user data in Firestore
  Future<void> saveUserToFirestore(
    String type,
    String mobileNumber,
    String country,
    String state,
    String email,
    String firstName,
    String lastName,
    String userId,
  ) async {
    Map<String, dynamic> dataMap = {
      "type": type,
      "mobileNumber": mobileNumber,
      "country": country,
      "state": state,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "status": 1.0,
      "myPostingIDs": [],
      "savedPostingIDs": [],
    };

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set(dataMap);
  }

  /// Upload user image to Firebase Storage
  Future<void> addImageToFirebaseStorage(
      File imageFileOfUser, String userId) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child("userImages")
        .child(userId)
        .child("$userId.png");

    await ref.putFile(imageFileOfUser);
    Uint8List imageBytes = await imageFileOfUser.readAsBytes();

    AppConstants.currentUser.displayImage = MemoryImage(imageBytes);
  }

  /// Send welcome email
  Future<void> sendWelcomeEmail(
    String email,
    String firstName,
    String mobileNumber,
    String state,
    String country,
  ) async {
    final url = Uri.parse("https://cotmade.com/app/send_email.php");

    final response = await http.post(url, body: {
      "email": email,
      "firstName": firstName,
      "mobileNumber": mobileNumber,
      "state": state,
      "country": country,
      "type": AppConstants.currentUser.type,
    });

    if (response.statusCode == 200) {
      debugPrint("Email sent successfully.");
    } else {
      debugPrint("Failed to send email: ${response.body}");
    }
  }

  /// Login user
  Future<void> login(String email, String password) async {
    isSubmitting.value = true;
    Get.snackbar("Please wait", "Checking your credentials...");

    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = result.user!.uid;
      AppConstants.currentUser.id = userId;

      await getUserInfoFromFirestore(userId);

      if (AppConstants.currentUser.status == 0) {
        Get.snackbar("Suspended", "Your account is currently suspended.");
        Get.to(() => LoginScreen());
        return;
      }

      Get.snackbar("Welcome", "You are logged in successfully.");
      Get.to(() => HomeScreen(userRole: AppConstants.currentUser.type!));

      // Background data load
      Future.microtask(() async {
        try {
          await getImageFromStorage(userId);
          await FirebaseApi().uploadPendingFcmToken(userId);
        } catch (e) {
          debugPrint("Background load failed: $e");
        }
      });
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Login Failed", _handleAuthError(e));
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: $e");
    } finally {
      isSubmitting.value = false;
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No user found with that email.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'invalid-email':
        return "Email is badly formatted.";
      case 'user-disabled':
        return "Account has been disabled.";
      default:
        return "Authentication failed.";
    }
  }

  /// Forgot password
  Future<void> forgotPassword(String email) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (query.docs.isEmpty) {
      Get.snackbar("Error", "Email does not exist.");
    } else {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.to(() => ResetPasswordScreen());
    }
  }

  /// Get user info from Firestore
  Future<void> getUserInfoFromFirestore(String userId) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!snapshot.exists) return;

    AppConstants.currentUser.snapshot = snapshot;
    AppConstants.currentUser.firstName = snapshot["firstName"] ?? "";
    AppConstants.currentUser.lastName = snapshot['lastName'] ?? "";
    AppConstants.currentUser.email = snapshot['email'] ?? "";
    AppConstants.currentUser.type = snapshot['type'] ?? "";
    AppConstants.currentUser.country = snapshot['country'] ?? "";
    AppConstants.currentUser.state = snapshot['state'] ?? "";
    AppConstants.currentUser.isHost = snapshot['isHost'] ?? false;
    AppConstants.currentUser.status = (snapshot['status'] ?? 1).toDouble();
  }

  /// Get profile image from Firebase Storage
  Future<ImageProvider?> getImageFromStorage(String userId) async {
    if (AppConstants.currentUser.displayImage != null) {
      return AppConstants.currentUser.displayImage;
    }

    final data = await FirebaseStorage.instance
        .ref()
        .child("userImages")
        .child(userId)
        .child("$userId.png")
        .getData(5 * 1024 * 1024);

    if (data != null) {
      AppConstants.currentUser.displayImage = MemoryImage(data);
    }

    return AppConstants.currentUser.displayImage;
  }
}
