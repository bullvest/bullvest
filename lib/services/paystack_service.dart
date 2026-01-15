import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';

class PaystackService {
  static final PaystackPlugin _plugin = PaystackPlugin();

  // ⚠️ USE TEST KEY FOR DEVELOPMENT
  // Replace with LIVE key in production
  static const String _publicKey =
      'pk_test_ffbb61e55a4ad2c3b47ee2861998286a80b9b3e0';

  /// Initialize Paystack (call in main.dart)
  static void initialize() {
    _plugin.initialize(publicKey: _publicKey);
  }

  /// Charge card for subscription
  static Future<CheckoutResponse?> chargeCard({
    required int amount, // in Naira
    required String email,
    required String reference,
  }) async {
    final charge = Charge()
      ..amount = amount * 100 // Paystack uses kobo
      ..email = email
      ..reference = reference
      ..currency = 'NGN';

    try {
      final response = await _plugin.checkout(
        navigatorKey.currentContext!,
        charge: charge,
        method: CheckoutMethod.card,
        fullscreen: false,
        logo: _paystackLogo(),
      );

      return response;
    } catch (e) {
      debugPrint('Paystack error: $e');
      return null;
    }
  }

  static Widget _paystackLogo() {
    return const FlutterLogo(size: 32);
  }
}

/// GLOBAL NAVIGATOR KEY (IMPORTANT)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
