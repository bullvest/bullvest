import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';

class PaystackService {
  static const String publicKey =
      'pk_test_ffbb61e55a4ad2c3b47ee2861998286a80b9b3e0';

  // ⚠️ NEVER hardcode live secret keys in production apps
  static const String secretKey =
      'sk_test_92972a84b747f18048ace1fb51a502bb04d21acd';

  static void openCheckout({
    required BuildContext context,
    required int amount, // Naira
    required String email,
    required String reference,
    required VoidCallback onSuccess,
    required VoidCallback onClosed,
  }) {
    FlutterPaystackPlus.openPaystackPopup(
      context: context,
      publicKey: publicKey,
      secretKey: secretKey,
      amount: (amount * 100).toString(), // Kobo
      customerEmail: email,
      reference: reference,
      callBackUrl: '',
      onSuccess: onSuccess,
      onClosed: onClosed,
    );
  }
}
