import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService {
  /// Checks if subscription exists and is still valid
  static bool isSubscriptionActive(Map<String, dynamic>? subscription) {
    if (subscription == null) return false;

    if (!subscription.containsKey('expiresAt')) return false;

    final expiry = (subscription['expiresAt'] as Timestamp).toDate();
    return expiry.isAfter(DateTime.now());
  }

  /// Activates or renews subscription for 30 days
  static Future<void> activateSubscription(
      String userId, String reference) async {
    final expiryDate = DateTime.now().add(const Duration(days: 30));

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'subscription': {
        'active': true,
        'reference': reference,
        'expiresAt': Timestamp.fromDate(expiryDate),
      }
    });
  }

  /// Returns remaining days (0 if expired)
  static int getDaysRemaining(Map<String, dynamic>? subscription) {
    if (subscription == null || subscription['expiresAt'] == null) {
      return 0;
    }

    final expiry = (subscription['expiresAt'] as Timestamp).toDate();
    final diff = expiry.difference(DateTime.now()).inDays;

    return diff < 0 ? 0 : diff;
  }
}
