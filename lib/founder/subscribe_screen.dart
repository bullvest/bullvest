import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'package:bullvest/services/paystack_service.dart';
import 'subscription_service.dart';
import 'package:bullvest/view_model/user_view_model.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({Key? key}) : super(key: key);

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  bool _loading = false;

  Future<void> _subscribe() async {
    setState(() => _loading = true);

    final reference = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final response = await PaystackService.chargeCard(
        amount: 10000, // ₦10,000
        email: AppConstants.currentUser.email ?? '', // Fix for null safety
        reference: reference,
      );

      if (response != null && response.status) {
        await SubscriptionService.activateSubscription(
          AppConstants.currentUser.id ?? '',
          reference,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } else {
        _showError('Payment cancelled or failed');
      }
    } catch (e) {
      _showError('Payment failed. Try again.');
    }

    setState(() => _loading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Founder Subscription'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.lock,
              color: Colors.tealAccent,
              size: 72,
            ),
            const SizedBox(height: 24),
            const Text(
              'Founder Subscription',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '₦10,000 / 30 Days',
              style: TextStyle(
                color: Colors.tealAccent,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Post startups\n'
              '• Receive investor leads\n'
              '• Appear in investor discovery\n\n'
              'Notifications & emails remain active without subscription.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Subscribe Now'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
