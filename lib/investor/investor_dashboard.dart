import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class InvestorHomeScreen extends StatefulWidget {
  final String userRole;

  const InvestorHomeScreen({required this.userRole, Key? key})
      : super(key: key);

  @override
  State<InvestorHomeScreen> createState() => _InvestorHomeScreenState();
}

class _InvestorHomeScreenState extends State<InvestorHomeScreen> {
  bool isVerified = false;
  bool isLoading = true;
  String investorId = FirebaseAuth.instance.currentUser!.uid;

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
        setState(() {
          isVerified = true;
        });
      }
    } catch (e) {
      print("Error checking verification status: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _requestVerification() async {
    try {
      await FirebaseFirestore.instance.collection('verification_requests').add({
        'investorId': investorId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
          "Request Sent", "Your verification request has been submitted.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.teal,
          colorText: Colors.white);
    } catch (e) {
      print("Error requesting verification: $e");
      Get.snackbar("Error", "Failed to send request.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Stream<QuerySnapshot> _getPortfoliosByStatus(String status) {
    return FirebaseFirestore.instance
        .collection('portfolio')
        .where('investors.$investorId',
            isEqualTo:
                status) // assumes a nested map like: investors: {uid: status}
        .snapshots();
  }

  Widget _buildPortfolioSection(String title, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _getPortfoliosByStatus(status),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return Text("No startups found.",
                  style: TextStyle(color: Colors.grey));

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;

                return Card(
                  color: Colors.grey[900],
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      data['name'] ?? 'No name',
                      style: TextStyle(color: Colors.tealAccent),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['description'] ?? 'No description',
                            style: TextStyle(color: Colors.grey[400])),
                        SizedBox(height: 4),
                        Text("Status: ${data['status'] ?? 'N/A'}",
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic)),
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
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Investor Dashboard"),
        backgroundColor: Colors.black,
        actions: [
          if (!isVerified)
            TextButton(
              onPressed: _requestVerification,
              child: Text("Get Verified",
                  style: TextStyle(color: Colors.tealAccent)),
            )
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
                    Icon(Icons.lock_outline, color: Colors.grey, size: 48),
                    SizedBox(height: 16),
                    Text("Your account is not yet verified.",
                        style:
                            TextStyle(color: Colors.grey[300], fontSize: 16)),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _requestVerification,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent),
                      child: Text("Request Verification",
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
