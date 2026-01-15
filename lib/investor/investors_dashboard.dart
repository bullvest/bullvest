import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class InvestorsDashboard extends StatefulWidget {
  const InvestorsDashboard({Key? key}) : super(key: key);

  @override
  State<InvestorsDashboard> createState() => _InvestorsDashboardState();
}

class _InvestorsDashboardState extends State<InvestorsDashboard> {
  bool isVerified = false;
  bool isLoading = true;
  final String investorId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(investorId)
          .get();

      if (userDoc.exists && userDoc['verified'] == true) {
        setState(() => isVerified = true);
      }
    } catch (e) {
      print("Error checking verification status: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _requestVerification() async {
    try {
      await FirebaseFirestore.instance.collection('verification_requests').add({
        'investorId': investorId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Request Sent",
        "Your verification request has been submitted.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      print("Error requesting verification: $e");
      Get.snackbar(
        "Error",
        "Failed to send request.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Stream<QuerySnapshot> _getPortfoliosByStatus(String status) {
    return FirebaseFirestore.instance
        .collection('portfolio')
        .where('investors.$investorId', isEqualTo: status)
        .snapshots();
  }

  Widget _buildPortfolioSection(String title, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _getPortfoliosByStatus(status),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text(
                "No startups found.",
                style: TextStyle(color: Colors.grey[400]),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: docs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      data['name'] ?? 'No name',
                      style: const TextStyle(color: Colors.tealAccent),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          data['description'] ?? 'No description',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${data['status'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (data['funding'] != null)
                          Text(
                            'Funding: ${data['funding']}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Investor Dashboard'),
        actions: [
          if (!isVerified)
            TextButton(
              onPressed: _requestVerification,
              child: const Text(
                "Get Verified",
                style: TextStyle(color: Colors.tealAccent),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isVerified
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPortfolioSection(
                        "Startups You're Working With", "workingWith"),
                    _buildPortfolioSection("Invested Startups", "invested"),
                    _buildPortfolioSection("Rejected Startups", "rejected"),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.grey, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Your account is not yet verified.",
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _requestVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Request Verification"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
